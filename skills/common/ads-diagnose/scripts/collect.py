# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "httpx>=0.27",
# ]
# ///
"""ads-diagnose data collector (P1: Step 0-3).

固化 ads-diagnose 主 skill 的确定性数据采集，避免每次由 LLM 拼 SQL：
  Step 0  ID 识别（双集群探测 + type 判定）
  Step 1  campaign 概览（按 grass_date 聚合，聚合别名加 s_/m_ 前缀避开 nested aggregate）
  Step 2  ad 级按 entrance 明细
  Step 3  停投 (unactive) + STATUS 操作日志兜底
外加纯确定性派生比率（cost_ratio_1d/7d、avg_coef、cvr、pgmv 校准比）。

不做异常检测（A/B 命中）与归因——那些留给 LLM。

用法:
  uv run collect.py <id> [--date YYYY-MM-DD] [--region MY]

输出: 结构化 JSON 到 stdout。LLM 直接消费，跳过 Step 0-3 拼 SQL。
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor

import httpx

# 集群配置（与 SKILL.md「如何查询 ClickHouse」一致；凭证同 md，无新增暴露）
SG = {
    "url": "https://clickhouse-office-only-ytl.data-infra.shopee.io",
    "auth": (
        "mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online",
        "b46o8QVbhaN5",
    ),
    "db": "mkplpaidads_search_ads_ads_debug",
}
VA2 = {
    "url": "https://clickhouse-office-only-us-va2.data-infra.shopee.io",
    "auth": ("mkplpaidads_search_ads-cluster_us_2replicas_online", "b46o8QVbhaN5"),
    "db": "mkplpaidads_search_ads_ads_diagnosis",
}
# STATUS / INACTIVE 表始终在 SG，不区分 region
STATUS_DB = "mkplpaidads_search_ads_ads_debug"


def cluster_for_region(region: str) -> dict:
    return VA2 if region == "BR" else SG


def run_sql(cluster: dict, sql: str) -> list[dict]:
    """执行 SQL（自动追加 FORMAT TabSeparatedWithNames），解析为 list[dict]。"""
    body = sql.strip().rstrip(";") + "\nFORMAT TabSeparatedWithNames"
    t0 = time.time()
    resp = httpx.post(cluster["url"], content=body.encode(), auth=cluster["auth"], timeout=120.0)
    if os.environ.get("ADS_COLLECT_TIMING"):
        tag = " ".join(sql.split())[:55]
        host = cluster["url"].split("//", 1)[-1][:22]
        print(f"[timing] {time.time() - t0:5.1f}s {host} | {tag}", file=sys.stderr)
    if resp.status_code >= 400:
        raise RuntimeError(f"ClickHouse {resp.status_code}: {resp.text[:600]}")
    text = resp.text.strip("\n")
    if not text:
        return []
    lines = text.split("\n")
    header = lines[0].split("\t")
    rows = []
    for line in lines[1:]:
        vals = line.split("\t")
        rows.append({h: _coerce(v) for h, v in zip(header, vals)})
    return rows


def _coerce(v: str):
    if v in ("", "\\N"):
        return None
    try:
        f = float(v)
        return int(f) if f.is_integer() and "e" not in v.lower() and "." not in v else f
    except ValueError:
        return v


def _ratio(num, den):
    if num is None or den in (None, 0):
        return None
    return num / den


# ---------- Step 0: ID 识别 ----------

def identify(id_: int, start: str, end: str, region: str | None = None) -> dict:
    q = f"""
SELECT DISTINCT type, ads_id, item_id, campaign_id, shop_id, grass_region
FROM {{db}}.ads_union_key_metrics_daily__reg_s0_live
WHERE (campaign_id = {id_} OR ads_id = {id_} OR item_id = {id_} OR shop_id = {id_})
    AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
LIMIT 20
"""
    # 已知 region 时直接查对应集群，跳过探测；否则串行短路：优先 SG（覆盖多数
    # region），命中即返回，仅 SG 空时才查 VA2（BR）。不用并发——CH 对同账号并发查询
    # 会排队，反而更慢。
    clusters = (cluster_for_region(region),) if region else (SG, VA2)
    for cluster in clusters:
        rows = run_sql(cluster, q.format(db=cluster["db"]))
        if rows:
            return _resolve(id_, rows, cluster)
    return {"error": f"ID {id_} not found in either cluster within {start}..{end}"}


def _resolve(id_: int, rows: list[dict], cluster: dict) -> dict:
    types = {r["type"] for r in rows}
    region = rows[0]["grass_region"]
    base = {"input_id": id_, "region": region,
            "cluster": "US-VA2" if cluster is VA2 else "SG", "db": cluster["db"],
            "candidates_types": sorted(types)}
    # 按"哪个 id 列 == 输入"判定（输入 campaign_id 会同时匹配 campaign 行与其下 ads 行，
    # 故不能用 type 集合判定；按列归属 + 优先级判定）
    if any(r["type"] == "campaign" and r["campaign_id"] == id_ for r in rows):
        kind = "campaign_id"
    elif any(r["type"] == "campaign" and r["shop_id"] == id_ for r in rows):
        kind = "shop_id"
    elif any(r["type"] == "ads" and r["ads_id"] == id_ for r in rows):
        kind = "ads_id"
    elif any(r["type"] == "ads" and r["item_id"] == id_ for r in rows):
        kind = "item_id"
    else:
        kind = "ambiguous"
    r0 = rows[0]
    base.update({"id_kind": kind, "campaign_id": r0["campaign_id"],
                 "shop_id": r0["shop_id"], "ads_id": r0["ads_id"], "item_id": r0["item_id"]})
    return base


# ---------- Step 0.5: shop → top campaigns ----------

def top_campaigns(shop_id: int, region: str, start: str, end: str) -> list[dict]:
    c = cluster_for_region(region)
    q = f"""
SELECT campaign_id,
       SUM(revenue_usd) AS total_rev,
       SUM(advv_usd) AS total_advv,
       SUM(ads_broad_order) AS total_order
FROM {c['db']}.ads_union_key_metrics_daily__reg_s0_live
WHERE type = 'campaign' AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
    AND shop_id = {shop_id} AND grass_region = '{region}'
GROUP BY campaign_id
ORDER BY total_rev DESC
LIMIT 10
"""
    return run_sql(c, q)


# ---------- Step 1: campaign 概览（按天聚合） ----------

def campaign_overview(campaign_id: int, shop_id: int, region: str, start: str, end: str) -> list[dict]:
    c = cluster_for_region(region)
    q = f"""
SELECT grass_date,
    s_revenue_usd AS revenue_usd, s_advv_usd AS advv_usd, s_direct_gmv_usd AS direct_gmv_usd, s_broad_gmv_usd AS broad_gmv_usd,
    s_ads_imp AS ads_imp, s_ads_clk AS ads_clk, s_ads_direct_order AS ads_direct_order, s_ads_broad_order AS ads_broad_order,
    s_revenue_usd_7d AS revenue_usd_7d, s_advv_usd_7d AS advv_usd_7d, s_broad_gmv_usd_7d AS broad_gmv_usd_7d,
    s_request_cnt AS request_cnt, s_after_recall_num AS after_recall_num, s_after_prerank_num AS after_prerank_num,
    s_after_rank_num AS after_rank_num, s_after_mixrank_num AS after_mixrank_num,
    m_pricing_type AS pricing_type, m_target_roi AS target_roi, m_idx_roi_upperbound AS idx_roi_upperbound, m_active_hour AS active_hour,
    s_ecpm_sum_by_imp AS ecpm_sum_by_imp, s_coef_sum_by_imp AS coef_sum_by_imp,
    if(s_ads_imp > 0, s_coef_sum_by_imp / s_ads_imp, NULL) AS avg_coef,
    m_final_coef AS final_coef,
    if(s_ads_imp > 0, s_troi_sum_by_imp / s_ads_imp, NULL) AS target_roi_by_imp,
    m_daily_budget AS daily_budget, m_rt_daily_budget_min_by_imp_v2 AS rt_daily_budget_min_by_imp_v2, m_account_balance_shop AS account_balance_shop,
    s_pctr_sum_by_imp AS pctr_sum_by_imp, s_pcr_broad_sum_by_clk AS pcr_broad_sum_by_clk, s_item_price_sum_by_imp AS item_price_sum_by_imp, s_pcr_direct_fail_imp_cnt AS pcr_direct_fail_imp_cnt,
    s_daily_pgmv_sum_last_7d_clk AS daily_pgmv_sum_last_7d_clk, s_daily_model_pgmv_sum_last_7d_clk AS daily_model_pgmv_sum_last_7d_clk,
    s_mpc_e_gmv AS mpc_e_gmv, s_mpc_e_cost AS mpc_e_cost
FROM (
    SELECT grass_date,
        SUM(revenue_usd) AS s_revenue_usd, SUM(advv_usd) AS s_advv_usd, SUM(direct_gmv_usd) AS s_direct_gmv_usd, SUM(broad_gmv_usd) AS s_broad_gmv_usd,
        SUM(ads_imp) AS s_ads_imp, SUM(ads_clk) AS s_ads_clk, SUM(ads_direct_order) AS s_ads_direct_order, SUM(ads_broad_order) AS s_ads_broad_order,
        SUM(revenue_usd_7d) AS s_revenue_usd_7d, SUM(advv_usd_7d) AS s_advv_usd_7d, SUM(broad_gmv_usd_7d) AS s_broad_gmv_usd_7d,
        SUM(request_cnt) AS s_request_cnt, SUM(after_recall_num) AS s_after_recall_num, SUM(after_prerank_num) AS s_after_prerank_num,
        SUM(after_rank_num) AS s_after_rank_num, SUM(after_mixrank_num) AS s_after_mixrank_num,
        max(pricing_type) AS m_pricing_type, max(target_roi) AS m_target_roi, max(idx_roi_upperbound) AS m_idx_roi_upperbound, max(active_hour) AS m_active_hour,
        SUM(ecpm_sum_by_imp) AS s_ecpm_sum_by_imp, SUM(coef_sum_by_imp) AS s_coef_sum_by_imp,
        max(final_coef) AS m_final_coef, SUM(troi_sum_by_imp) AS s_troi_sum_by_imp,
        max(daily_budget) AS m_daily_budget, max(rt_daily_budget_min_by_imp_v2) AS m_rt_daily_budget_min_by_imp_v2, max(account_balance_shop) AS m_account_balance_shop,
        SUM(pctr_sum_by_imp) AS s_pctr_sum_by_imp, SUM(pcr_broad_sum_by_clk) AS s_pcr_broad_sum_by_clk, SUM(item_price_sum_by_imp) AS s_item_price_sum_by_imp, SUM(pcr_direct_fail_imp_cnt) AS s_pcr_direct_fail_imp_cnt,
        SUM(daily_pgmv_sum_last_7d_clk) AS s_daily_pgmv_sum_last_7d_clk, SUM(daily_model_pgmv_sum_last_7d_clk) AS s_daily_model_pgmv_sum_last_7d_clk,
        SUM(mpc_e_gmv) AS s_mpc_e_gmv, SUM(mpc_e_cost) AS s_mpc_e_cost
    FROM {c['db']}.ads_union_key_metrics_daily__reg_s0_live
    WHERE type = 'campaign' AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
        AND shop_id = {shop_id} AND grass_region = '{region}' AND campaign_id = {campaign_id}
    GROUP BY grass_date
) t
ORDER BY grass_date DESC
LIMIT 100
"""
    rows = run_sql(c, q)
    for r in rows:
        r["cost_ratio_1d"] = _ratio(r.get("revenue_usd"), r.get("advv_usd"))
        r["cvr"] = _ratio(r.get("ads_broad_order"), r.get("ads_clk"))
        r["ctr"] = _ratio(r.get("ads_clk"), r.get("ads_imp"))
        r["pgmv_calib_ratio"] = _ratio(r.get("daily_pgmv_sum_last_7d_clk"), r.get("daily_model_pgmv_sum_last_7d_clk"))
        r["pgmv_gmv_ratio"] = _ratio(r.get("daily_pgmv_sum_last_7d_clk"), r.get("broad_gmv_usd"))
        r["pctr_pcoc"] = _ratio(r.get("pctr_sum_by_imp"), r.get("ads_clk"))
        r["pcr_pcoc"] = _ratio(r.get("pcr_broad_sum_by_clk"), r.get("ads_broad_order"))
        r["mixrank_rate"] = _ratio(r.get("after_mixrank_num"), r.get("after_rank_num"))
    return rows


# ---------- Step 2: ad 级按 entrance ----------

def ad_by_entrance(campaign_id: int, shop_id: int, region: str, start: str, end: str) -> list[dict]:
    c = cluster_for_region(region)
    q = f"""
SELECT grass_date, entrance,
    s_revenue_usd AS revenue_usd, s_advv_usd AS advv_usd, s_broad_gmv_usd AS broad_gmv_usd,
    s_ads_imp AS ads_imp, s_ads_clk AS ads_clk, s_ads_broad_order AS ads_broad_order,
    if(s_ads_imp > 0, s_coef_sum_by_imp / s_ads_imp, NULL) AS avg_coef,
    if(s_ads_imp > 0, s_troi_sum_by_imp / s_ads_imp, NULL) AS target_roi_by_imp,
    if(s_after_rank_num > 0, s_after_mixrank_num / s_after_rank_num, NULL) AS mixrank_rate
FROM (
    SELECT grass_date, entrance,
        SUM(revenue_usd) AS s_revenue_usd, SUM(advv_usd) AS s_advv_usd, SUM(broad_gmv_usd) AS s_broad_gmv_usd,
        SUM(ads_imp) AS s_ads_imp, SUM(ads_clk) AS s_ads_clk, SUM(ads_broad_order) AS s_ads_broad_order,
        SUM(coef_sum_by_imp) AS s_coef_sum_by_imp, SUM(troi_sum_by_imp) AS s_troi_sum_by_imp,
        SUM(after_rank_num) AS s_after_rank_num, SUM(after_mixrank_num) AS s_after_mixrank_num
    FROM {c['db']}.ads_union_key_metrics_daily__reg_s0_live
    WHERE type = 'ads' AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
        AND shop_id = {shop_id} AND grass_region = '{region}' AND campaign_id = {campaign_id}
    GROUP BY grass_date, entrance
) t
ORDER BY grass_date DESC, revenue_usd DESC
LIMIT 300
"""
    return run_sql(c, q)


def campaign_ads_ids(campaign_id: int, shop_id: int, region: str, start: str, end: str) -> list[int]:
    c = cluster_for_region(region)
    q = f"""
SELECT DISTINCT ads_id
FROM {c['db']}.ads_union_key_metrics_daily__reg_s0_live
WHERE type = 'ads' AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
    AND shop_id = {shop_id} AND grass_region = '{region}' AND campaign_id = {campaign_id} AND ads_id > 0
LIMIT 500
"""
    return [r["ads_id"] for r in run_sql(c, q)]


# ---------- Step 3: 停投 + STATUS 操作日志 ----------

def unactive_reasons(shop_id: int, region: str, start: str, end: str) -> list[dict]:
    q = f"""
SELECT grass_date, ads_id, item_id, placement, operation, reason
FROM {STATUS_DB}.unactive_ads_reason_metrics
WHERE shop_id = {shop_id} AND grass_region = '{region}'
    AND grass_date BETWEEN DATE('{start}') AND DATE('{end}')
ORDER BY grass_date DESC
LIMIT 200
"""
    return run_sql(SG, q)


def status_ops(ads_ids: list[int], region: str, start: str, end: str) -> list[dict]:
    """R1.1/R1.2 的 STATUS 变更兜底：只取 reason 中的 TROI/budget 变更。

    性能：`operation != 'INDEX' OR status != 0` 泛条件会匹配海量状态行、叠加
    `ORDER BY hour` 排序，实测 12s；去掉二者后仅 0.8s，且关键 change roi/budget
    行一条不丢。停投（advertise status / campaign paused）由 unactive_reasons 覆盖，
    无需在此重复。行数少，排序放本地。
    """
    if not ads_ids:
        return []
    ids = ",".join(str(a) for a in ads_ids)
    q = f"""
SELECT grass_date, hour, id AS ads_id, operation, reason, visible, status
FROM {STATUS_DB}.dwd_ads_index_status_live
WHERE grass_region = '{region}' AND grass_date BETWEEN '{start}' AND '{end}'
    AND id IN ({ids})
    AND (reason LIKE '%change_budget%' OR reason LIKE '%change roi%'
         OR reason LIKE '%target roi%' OR reason LIKE '%change_target%')
LIMIT 300
"""
    rows = run_sql(SG, q)
    rows.sort(key=lambda r: (str(r.get("grass_date")), r.get("hour") or 0), reverse=True)
    return rows


# ---------- 主流程 ----------

def date_window(date: str | None) -> tuple[str, str, str]:
    d = dt.date.fromisoformat(date) if date else dt.date.today()
    return (d - dt.timedelta(days=7)).isoformat(), (d + dt.timedelta(days=5)).isoformat(), d.isoformat()


def rolling_7d(daily: list[dict], d0: str) -> dict:
    d0d = dt.date.fromisoformat(d0)
    window = {(d0d - dt.timedelta(days=i)).isoformat() for i in range(7)}
    days = [r for r in daily if r["grass_date"] in window]
    cost = sum(r["revenue_usd"] or 0 for r in days)
    advv = sum(r["advv_usd"] or 0 for r in days)
    gmv = sum(r["broad_gmv_usd"] or 0 for r in days)
    return {"days_covered": len(days), "cost_7d": cost, "advv_7d": advv,
            "broad_gmv_7d": gmv, "cost_ratio_7d": _ratio(cost, advv)}


def render_daily_markdown(daily: list[dict], d0: str, focus_date: str | None = None) -> str:
    """把逐日数据渲染成 markdown 表，LLM 直接贴进报告——避免逐格重打 + 抄错数字。

    拆成两张窄表（贴合 SKILL「输出格式」，避免终端宽表折行）：
      表A 效果&出价 | 表B PCOC&漏斗。用户输入日 d0 加粗；病灶日（focus_date≠d0）加 ★。
    **始终渲染完整窗口**——重定位只影响归因焦点，不截断表格。
    """
    rows = sorted(daily, key=lambda r: str(r["grass_date"]))

    def f(x, n=2):
        return "-" if x is None else f"{x:.{n}f}"

    def i(x):
        return "-" if x is None else str(int(round(x)))

    a = ["| 日期 | Rev | Advv | CR_1d | avg_coef | final_coef | TROI | CVR% |",
         "|------|-----|------|-------|----------|-----------|------|------|"]
    b = ["| 日期 | pgmv_pcoc | pctr_pcoc | pcr_pcoc | Imp | Clk | 混排% | Balance |",
         "|------|-----------|-----------|----------|-----|-----|-------|---------|"]
    for r in rows:
        d = str(r["grass_date"])
        dm = f"**{d}**" if d == d0 else d
        if focus_date and d == focus_date and focus_date != d0:
            dm += " ★病灶日"
        cr = "∞" if (r.get("advv_usd") in (0, None) and r.get("revenue_usd")) else f(r.get("cost_ratio_1d"), 2)
        cvr = f(r["cvr"] * 100 if r.get("cvr") is not None else None, 1)
        mix = f(r["mixrank_rate"] * 100 if r.get("mixrank_rate") is not None else None, 1)
        a.append(f"| {dm} | {f(r.get('revenue_usd'), 1)} | {f(r.get('advv_usd'), 1)} | {cr} "
                 f"| {f(r.get('avg_coef'), 2)} | {f(r.get('final_coef'), 2)} | {f(r.get('target_roi_by_imp'), 2)} | {cvr} |")
        b.append(f"| {dm} | {f(r.get('pgmv_gmv_ratio'), 2)} | {f(r.get('pctr_pcoc'), 2)} | {f(r.get('pcr_pcoc'), 2)} "
                 f"| {i(r.get('ads_imp'))} | {i(r.get('ads_clk'))} | {mix} | {i(r.get('account_balance_shop'))} |")
    return "#### 表A 效果&出价\n" + "\n".join(a) + "\n\n#### 表B PCOC&漏斗\n" + "\n".join(b)


def build_module_signals(daily: list[dict], ad_ent: list[dict], status_ops: list[dict], d0: str) -> dict:
    """预算好 L1 合表「关键数值」列需要的确定性信号（d0/d1/7d 值 + 比率）。

    只给数字，不给阈值判定——四态判定(命中/未命中/证据不足/不适用)、方向过滤
    由 LLM 按 factual_nodes 权威定义做。这样 LLM 不必再从 daily 逐日翻找算 d0/d1
    比率（确定性、易错、耗 token），只做判定推理。
    """
    by = {str(r["grass_date"]): r for r in daily}
    dts = sorted(by)
    if not dts:
        return {}
    if d0 not in by:
        cand = [x for x in dts if x <= d0]
        d0 = cand[-1] if cand else dts[-1]
    idx = dts.index(d0)
    r0 = by[d0]
    r1 = by[dts[idx - 1]] if idx > 0 else None
    d0date = dt.date.fromisoformat(d0)
    win = {(d0date - dt.timedelta(days=k)).isoformat() for k in range(7)}
    wdays = [by[x] for x in dts if x in win]

    def g(r, k):
        return r.get(k) if r else None

    def wavg(k):
        vals = [d[k] for d in wdays if d.get(k) is not None]
        return sum(vals) / len(vals) if vals else None

    def per_imp(r, k):
        return _ratio(g(r, k), g(r, "ads_imp"))

    ip_vals = [per_imp(d, "item_price_sum_by_imp") for d in wdays]
    ip_vals = [v for v in ip_vals if v is not None]
    ip_avg = sum(ip_vals) / len(ip_vals) if ip_vals else None

    return {
        "_days": {"d0": d0, "d1": dts[idx - 1] if idx > 0 else None},
        "R1_self": {
            "troi_d0": g(r0, "target_roi_by_imp"), "troi_d1": g(r1, "target_roi_by_imp"),
            "troi_ratio_d0_d1": _ratio(g(r0, "target_roi_by_imp"), g(r1, "target_roi_by_imp")),
            "budget_d0": g(r0, "daily_budget"), "budget_d1": g(r1, "daily_budget"),
            "budget_ratio_d0_d1": _ratio(g(r0, "daily_budget"), g(r1, "daily_budget")),
            "balance_d0": g(r0, "account_balance_shop"),
            "balance_ratio_d0_d1": _ratio(g(r0, "account_balance_shop"), g(r1, "account_balance_shop")),
            "balance_min_7d": min((d["account_balance_shop"] for d in wdays if d.get("account_balance_shop") is not None), default=None),
            "active_hour_d0": g(r0, "active_hour"), "active_hour_d1": g(r1, "active_hour"),
            "budget_line_ratio_d0": _ratio(g(r0, "revenue_usd"), g(r0, "rt_daily_budget_min_by_imp_v2")),
            "status_change_rows": [x for x in status_ops if "change" in str(x.get("reason", "")).lower()],
        },
        "R2_item": {"item_price_d0": per_imp(r0, "item_price_sum_by_imp"), "item_price_7d_avg": ip_avg,
                    "ratio_d0_vs_7d": _ratio(per_imp(r0, "item_price_sum_by_imp"), ip_avg)},
        "R3_model": {"pgmv_gmv_ratio_d0": g(r0, "pgmv_gmv_ratio"), "pgmv_gmv_ratio_7d_avg": wavg("pgmv_gmv_ratio"),
                     "pgmv_calib_ratio_d0": g(r0, "pgmv_calib_ratio"), "pctr_pcoc_d0": g(r0, "pctr_pcoc"), "pcr_pcoc_d0": g(r0, "pcr_pcoc")},
        "R4_bidding": {"avg_coef_d0": g(r0, "avg_coef"), "avg_coef_7d_avg": wavg("avg_coef"),
                       "final_coef_d0": g(r0, "final_coef"), "final_coef_7d_avg": wavg("final_coef")},
        "R5_pipeline": {"prerank_rate_d0": _ratio(g(r0, "after_prerank_num"), g(r0, "after_recall_num")),
                        "rank_rate_d0": _ratio(g(r0, "after_rank_num"), g(r0, "after_prerank_num")),
                        "mixrank_rate_d0": g(r0, "mixrank_rate")},
        "R6_adslot": {"mixrank_rate_d0": g(r0, "mixrank_rate"), "mixrank_rate_d1": g(r1, "mixrank_rate"),
                      "ecpm_per_imp_d0": per_imp(r0, "ecpm_sum_by_imp"), "ecpm_per_imp_d1": per_imp(r1, "ecpm_sum_by_imp"),
                      "avg_coef_d0": g(r0, "avg_coef"), "cvr_d0": g(r0, "cvr"), "ctr_d0": g(r0, "ctr")},
        "R7_R9_shop": {"scope": "single_campaign（脚本仅诊断单 campaign；shop 级需扩展）"},
        "R8_external": {"note": "需外部大盘/竞争数据，脚本无覆盖 → 通常证据不足"},
        "R10_scenario": {"entrances_d0": [
            {"entrance": e["entrance"], "rev": e.get("revenue_usd"), "advv": e.get("advv_usd"),
             "cost_ratio": _ratio(e.get("revenue_usd"), e.get("advv_usd"))}
            for e in ad_ent if str(e["grass_date"]) == d0 and (e.get("revenue_usd") or 0) > 0]},
    }


def build_anomaly_contribution(daily: list[dict], d0: str) -> dict:
    """7d 超收/欠收异常的逐日金额贡献分解，定位「病灶日」。

    口径对齐 R4 xyz agent（date_range → 按 gap_usd 最大选 local_date）：
      超收(cost_ratio_7d>1.25): gap_i = rev_i - advv_i（只算正贡献日）
      欠收(cost_ratio_7d<0.75): gap_i = advv_i - rev_i
    窗口固定为用户 _0 的 [_0-6, _0]，**只定位一次、不以病灶日重新开窗**（防递归）。
    重定位触发：_0 贡献 <25% 且 病灶日 >40% 且 病灶日≠_0。
    """
    by = {str(r["grass_date"]): r for r in daily}
    if not by:
        return {}
    if d0 not in by:
        cand = [x for x in sorted(by) if x <= d0]
        d0 = cand[-1] if cand else sorted(by)[-1]
    d0date = dt.date.fromisoformat(d0)
    win = [(d0date - dt.timedelta(days=k)).isoformat() for k in range(7)]
    wdays = [(x, by[x]) for x in sorted(win) if x in by]
    tot_rev = sum((r["revenue_usd"] or 0) for _, r in wdays)
    tot_advv = sum((r["advv_usd"] or 0) for _, r in wdays)
    cr7 = _ratio(tot_rev, tot_advv)
    out = {"cost_ratio_7d": cr7, "window": [win[-1], win[0]], "d0": d0, "focus_date": d0, "relocate_focus": False}
    if cr7 is None or 0.75 <= cr7 <= 1.25:
        out["direction"] = "无（7d cost_ratio 在 0.75~1.25，未触发超收/欠收）"
        return out
    over = cr7 > 1.25
    out["direction"] = "超收" if over else "欠收"

    def gap(r):
        rev, advv = r["revenue_usd"] or 0, r["advv_usd"] or 0
        return rev - advv if over else advv - rev

    per = [(x, gap(r)) for x, r in wdays]
    pos_total = sum(g for _, g in per if g > 0)
    rows = sorted(
        ({"date": x, "gap_usd": g, "pct": (g / pos_total if pos_total > 0 and g > 0 else 0.0)} for x, g in per),
        key=lambda z: z["gap_usd"], reverse=True,
    )
    top = rows[0]
    d0pct = next((z["pct"] for z in rows if z["date"] == d0), 0.0)
    relocate = top["date"] != d0 and d0pct < 0.25 and top["pct"] > 0.40
    out.update({"total_positive_gap_usd": pos_total, "per_day": rows,
                "top_contrib_day": top["date"], "top_contrib_pct": top["pct"],
                "d0_contrib_pct": d0pct, "relocate_focus": relocate,
                "focus_date": top["date"] if relocate else d0})
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="ads-diagnose data collector (Step 0-3)")
    ap.add_argument("id", type=int, help="campaign_id / ads_id / item_id / shop_id")
    ap.add_argument("--date", help="诊断日 YYYY-MM-DD (默认今天)")
    ap.add_argument("--region", help="可选，已知 region 时传入")
    args = ap.parse_args()

    start, end, d0 = date_window(args.date)
    resolved = identify(args.id, start, end, args.region)
    if "error" in resolved:
        print(json.dumps(resolved, ensure_ascii=False))
        return 1

    region = args.region or resolved["region"]
    out: dict = {"query": {"input_id": args.id, "date": d0, "start": start, "end": end},
                 "resolved": resolved}

    if resolved["id_kind"] == "shop_id":
        out["mode"] = "shop"
        out["top_campaigns"] = top_campaigns(args.id, region, start, end)
        out["note"] = "输入为 shop_id：先选定 top campaign 后对单个 campaign_id 重跑本脚本"
        print(json.dumps(out, ensure_ascii=False, indent=2, default=str))
        return 0

    campaign_id = resolved["campaign_id"]
    shop_id = resolved["shop_id"]
    out["mode"] = "campaign"

    # 串行执行：CH 对同账号并发查询会排队，串行反而更快（各查询裸测 <1.5s）
    daily = campaign_overview(campaign_id, shop_id, region, start, end)
    out["daily"] = daily
    out["rolling_7d_ending_d0"] = rolling_7d(daily, d0)
    contrib = build_anomaly_contribution(daily, d0)
    out["anomaly_contribution"] = contrib
    fd = contrib.get("focus_date") if contrib.get("relocate_focus") else None
    out["daily_markdown"] = render_daily_markdown(daily, d0, fd)
    out["ad_by_entrance"] = ad_by_entrance(campaign_id, shop_id, region, start, end)
    ads_ids = campaign_ads_ids(campaign_id, shop_id, region, start, end)
    out["unactive_reasons"] = unactive_reasons(shop_id, region, start, end)
    out["status_ops"] = status_ops(ads_ids, region, start, end)
    out["module_signals"] = build_module_signals(daily, out["ad_by_entrance"], out["status_ops"], d0)
    if contrib.get("relocate_focus"):
        # 病灶日 ≠ 用户 _0：额外给以病灶日为中心的信号（D* vs D*-1），归因/ dispatch 用它
        out["focus_signals"] = build_module_signals(daily, out["ad_by_entrance"], out["status_ops"], contrib["focus_date"])

    print(json.dumps(out, ensure_ascii=False, indent=2, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
