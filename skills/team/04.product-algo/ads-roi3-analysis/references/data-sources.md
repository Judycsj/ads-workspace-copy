# 数据源与口径索引/Data Sources & Caliber Index

原则：**只索引、不复制**——datamap 和各 skill references 是字段级事实源，这里登记"用哪张表、什么口径、有什么坑"。数字均为带时间戳的快照，方法可复用、数字不可。

## 1. 核心表注册/Core Tables

| 表 | 用途 | 粒度 | 已知坑 |
|---|---|---|---|
| `mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live` | ROI3 P0 指标（advv、broad_gmv、platform_gmv、`total_voucher_cost`、`ads_voucher_cost`、`platform_order_cnt` 等），日报/实验读数主源；**按 exp_tag 全流量聚合（含 base 桶），跨臂比券成本/做 SRM 的首选** | 日级，ClickHouse | T+1；直连失败走 DataSuite ClickHouse fallback；⚠️ DataSuite 会话约数分钟过期（`pycookiecheat` 缺失/token 失效），连查会断，需刷新 Chrome 登录 datasuite.shopee.io；仅有 ads/total 两档券成本，MP smart/local 拆分需扩列 |
| `mp_paidads.dwd_unified_order_event_hi__reg_s0_live` | 预算转移实验 realized cost 读数（按 voucher_click_context 分桶） | 小时级，Presto | 落库滞后约 2h；当日非满日不可判；⚠️ **`voucher_click_context` 只落在 ads 券订单上**（`orders==voucher_orders`），跨臂比 MP/总券会**选择偏差**（test 兑券率高→base 大量平台券-only 订单隐形），须改用分流日志按 user 分桶 |
| `mp_paidads.ods_log_unified_order_event_hi__{reg}_s0_live` | 订单-商品行级 GMV/补贴（券效率类分析） | 小时级，按 region 分表 | 订单级重查询必须串行 |
| `mp_paidads.dwd_trace_bidding_hyperx_hi__reg_s0_live` | 控制器 trace（pacing/CDF/PID 证据） | 小时级 | 归 ads-roi3-budget-control-analysis 解读 |
| `mp_voucher.dim_voucher__reg_live` | 券维表（券类型识别权威；smart 券 = `voucher_groups` 含 'reg smart voucher'） | 维表 | 字段说明见 `docs/common/datamap/mp_voucher.dim_voucher__reg_live/` |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | AB 分流日志（按 user_id 给全流量分桶，**跨臂干净读数/无选择偏差的分桶源**）；转移实验 = scene 1361 / layer 190830 / project Ads / `is_assignment_log=1` | 日级（`local_date`） | 表巨大，`COUNT(DISTINCT user_id)` 极慢；join 订单级查询重，串行 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告端曝光/点击/成交 | 日级 | itemPrice/去重口径见 datamap |

## 2. 关键口径/Key Calibers

**券识别（跑券类型分析前必读，别现翻记忆/旧 SQL）**：
- **广告券** = `ads_voucher_id > 0` 的 SV，成本 `sv_rebate_by_shopee_amt_usd`。
- **MP smart 券**（= 算法分发平台券 = 非 local 平台券）= `pv_promotion_id` 命中 `dim_voucher` 中 `voucher_groups` 含 `'reg smart voucher'` 的促销，成本 `pv_rebate_by_shopee_amt_usd`，100% Shopee 出资。⚠️ **订单表/ods_log 无 `is_smart_reg_voucher`、`is_smart_ads_voucher` 列**，必须 join `mp_voucher.dim_voucher__{reg}_live`（`CROSS JOIN UNNEST(voucher_groups)`；**网关不支持 lambda**，别用 `filter(...)`）。与 dim 旧验证零偏差。
- **MP 整体** = 全部平台券（`pv_promotion_id > 0` 的 `pv_rebate_by_shopee`）；**MP local = MP整体 − MP smart**（local 与 ads/smart 共用 group，只能整体减 smart 反推）。
- datamap 权威：`docs/common/datamap/mp_voucher.dim_voucher__reg_live/`。seller_voucher 金额**包含** ads_voucher（口径不互斥）。

**平台 GMV**：`platform_gmv_usd/1e5`，`ORDER_STATUS_PLACED` 下单口径 gross（未扣退货/支付失败）。

**预算转移实验 realized cost**（快照口径，2026-06-17 更新）：
- **桶（AB 分流日志 scene 1361 / layer 190830 / project Ads）**：base = 695005（共同对照，80%）/ 档1 = 695006（5%）/ 档2 = 695008（5%）。早期配对 5% 对照（695007/695009）已废，勿再用。
- 成本：`SUM(IF(ads_voucher_id > 0, sv_rebate_by_shopee_amt_usd, 0)) / 1e5`；**满日累计才是判断准绳**（日内漂移大）。
- ⚠️ **base 80% vs test 5% 流量不等**：R 必须归一——R(等流量) = 16 × cost(test)/cost(base)，或 cost/order；别直接比绝对总成本。
- ⚠️ **跨臂比"总券/MP/平台券"或做 SRM**：用全流量源——首选 P0 ClickHouse 表（按 exp_tag，`total_voucher_cost`/`platform_order_cnt`，秒级）；要 MP smart/local 拆分则用 **AB 分流日志按 user_id 分桶**（`srdi_mart.dim_sr_data_warehouse_abtest_user_group`，scene 1361/layer 190830/project Ads/`is_assignment_log=1`）join `ods_log` —— **不要**用 `voucher_click_context`（只在 ads 券订单上，有选择偏差）。订单级 join 重（~8min/满日，串行）。
- 已知坑：SG 无数据；BR 残缺（R<1 不可信）；MY 低量日（base 订单骤降到 ~30k）会把比值撑虚高，看绝对花费/多日。

**value 口径选择**：advv / broad_gmv / platform_gmv / guardrail 必须显式选择；advv 与 broad_gmv 在边际分析中曾给出**方向相反**的结论（定律"口径决定结论"）——高风险决策多口径并行。

### 2.1 今天/实时 vs 满日：数据源硬路由（最高优先，反复踩坑沉淀 2026-06-27）

**先看时间窗再选源。"今天/实时/intraday/当日"绝不能用 ClickHouse P0 或 perf 表——它们都是天级 T+1，物理上没有当日数据。**

| 时间窗 | 必用源 | 实验分桶 |
|---|---|---|
| **今天 / 实时 / 当日小时** | 券消耗→`mp_paidads.dwd_unified_order_event_hi__reg_s0_live`（小时级，有 `local_hour`/`h`，券成本 `sv_rebate_by_shopee_amt_usd`，`ads_voucher_id>0`=广告券）；曝光/点击/rev/advv→ReportNG 小时表 `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`（自带 `ab_sign` 列） | **ab_sign token 匹配**。⚠️ unified order **无独立 ab_sign 列**，ab_sign 内嵌在 `voucher_click_context` JSON 的 `"ab_sign":"\|new_ab_sign\|...\|<gid>\|..."` 里（pipe 分隔）→ 用 `strpos(voucher_click_context,'\|703307\|')>0` 做 token 匹配（带竖线防子串误配，**勿**裸 `LIKE '%703307%'`） |
| 满日 / 历史 / 日级 | P0 ClickHouse `ads_roi3_strategy_algo_metrics_clickhouse_1d`（exp_tag）/ perf `dwd_advertise_performance_di`（ab_sign）/ 分流日志（user_id） | exp_tag / ab_sign / user |

- **打平流量**：满日用分流日志 user 数；今天 intraday 分流日志 T+1 不可得 → 用设计流量比（base 50% vs test 5% → test 总消耗 ×10）做"打平绝对值"，标"per-user 待满日复核"。**订单数比 ≠ 流量比**（订单受发券强度污染：压档订单变少、加档订单变多，SRM 别用 exp-vs-base 订单比，用同系数对照桶互比）。
- **selection-bias 提醒的边界**：`voucher_click_context` 只落广告点击归因订单——**满日跨臂比"总券/MP/平台券"会偏**（用 P0/分流日志）；但**当日 roi3 广告券消耗读数本就只看广告券，用其内嵌 ab_sign 分桶是合法当日口径**。两件事别混。
- intraday 是部分日（落库滞后约 2h）+ 单口径 → 结论按"方向信号/未坐实"分级，坐实需满日 + per-user + 多日 + CI。

## 3. 跑数工具/Execution

- 统一走 `ads-text2da`（Presto：personal-presto 优先；ClickHouse：runner 优先，DataSuite fallback）。
- 脚本：`.claude/skills/ads-text2da/scripts/run_personal_presto_query.py --sql-file <f> --format csv --output <o>`。
- ⚠️ **必须用 venv python 直跑**：`/Users/roger.li/.local/text2da-presto-venv/bin/python <脚本>`。用系统 `python3` 入口时 re-exec 逻辑失效，报 `dataservice is not available in the active interpreter`（2026-06-13 验收发现；venv 与 dataservice 本身正常）。
- 队列 `mkplpaidads-adhoc`（priority 25, IDC SG）：重查询**串行**执行，并行会饿死队列；网关不支持 lambda。
- 首次使用任何字段前：先查 datamap（`sra-table-info-query`）或 desc 表确认字段名。
- ⚠️ **口径优先查本文件 §2 + `docs/common/datamap/`，禁止现翻个人记忆/`tmp/` 旧 SQL 重新发现已登记口径**（2026-06-17 教训：MP smart 券口径本已在 §2 + datamap，却绕了记忆+旧文档一大圈才找到）。本文件查不到再下沉到记忆/旧分析。
- ClickHouse 走 `run_clickhouse_query.py`；DataSuite 会话过期（`pycookiecheat` 缺失/token 失效）会连查中断 → 刷新 Chrome 登录 datasuite.shopee.io 后重试，别因此降级到慢的 raw-log Presto。

## 4. 实验配置快照/Experiment Snapshots

详见 spoke 的 `ads-roi3-experiment-analysis/references/experiment-contracts.md`。系数交付文件（实际存在）：
`docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr3-kp6-202605061738/resource/roi3-voucher-strength-response-model/strategy/coef_arrays_v1.json`
（注：早期记录的 `live-experiment-state.json` 实时快照当前不在 master 分支，用时先确认；实时系数以 sp-ab/线上配置为准。）

## 5. 上游指针/Pointers

| 内容 | 路径 |
|---|---|
| 框架设计蓝本（五轴/契约/定律台账） | `skills/team/04.product-algo/ads-roi3-analysis/references/framework-design.md` |
| 券效率分析复跑入口（附录 E） | `docs/personal/roger.li/roi3/analysis/voucher-efficiency-mp-vs-ads-2026-06-10.md` |
| 发券强度边际方法与数据 | `docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr3-kp6-202605061738/resource/roi3-voucher-strength-response-model/` |
| 事实层取证 playbook / FAQ | `docs/team/04.product-algo/roi3/knowledge_template/` |
| 校验类问题清单（20 题） | `docs/personal/roger.li/roi3/questions.md` |
