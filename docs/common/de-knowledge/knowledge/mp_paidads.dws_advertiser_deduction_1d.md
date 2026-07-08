<!-- ads-workspace-gdoc-sync: gdoc_id=13FUtSrEqmqF8e6VyonzDgNOTlh07Bm75YXIvWgHWV7I gdoc_url=https://docs.google.com/document/d/13FUtSrEqmqF8e6VyonzDgNOTlh07Bm75YXIvWgHWV7I/edit -->

# mp_paidads.dws_advertiser_deduction_1d

**分层**：DWS（数据服务层 / 轻度汇总层）
**主键**：`shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖写入（INSERT OVERWRITE）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表记录广告主（店铺维度）每日广告扣费明细，按信用额度类型（付费 / 免费）与到期属性（带过期时间 / 不带过期时间）四个维度细分，同时提供本地货币与 USD 双币种金额，支持广告成本的多维度核算与对账。

核心使用场景包括：广告主日常账单核对、免费信用额度消耗监控、付费信用额度消耗分析，以及跨地区 USD 统一口径的广告支出汇总报表。通过区分带过期时间与不带过期时间的信用额度，运营团队可精准追踪临时促销赠送额度（有过期限制）与长期通用额度的分别消耗情况。

本表提供 `local`（本地时区）与 `regional`（大区时区）两套时区口径，各地区按本地时区参数化调度，可灵活满足不同统计口径的报表需求。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区口径分区。`local` = 按各地区本地时区统计；`regional` = 按大区时区统计。⚠️ 查询时**必须指定**该字段，否则同一条业务数据将被重复计算（两套时区各写一份）。 |
| `grass_region` | string | 地区编码（大写），如 `TW`、`VN`、`MX` 等，各地区独立调度写入。⚠️ 查询时**必须指定**，避免全表扫描。 |
| `grass_date` | date | 数据统计日期（业务日期），格式 `YYYY-MM-DD`。⚠️ 查询时**必须指定**，避免全表扫描。 |

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主的唯一标识。 |

### 指标：付费信用额度广告扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 付费且**不带过期时间**的信用额度当日广告扣费，本地货币，单位元（原始金额已 ÷100000 换算）。 |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 付费且**不带过期时间**的信用额度当日广告扣费，USD。⚠️ 由本地货币金额除以当日汇率派生，多行直接 SUM 时需确认汇率口径一致。 |
| `paid_expenditure_w_expiry_amt_local_1d` | double | 付费且**带过期时间**的信用额度当日广告扣费，本地货币，单位元（原始金额已 ÷100000 换算）。 |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 付费且**带过期时间**的信用额度当日广告扣费，USD。⚠️ 由本地货币金额除以当日汇率派生，多行直接 SUM 时需确认汇率口径一致。 |

### 指标：免费信用额度广告扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_wo_expiry_amt_local_1d` | double | 免费且**不带过期时间**的信用额度当日广告扣费，本地货币，单位元（原始金额已 ÷100000 换算）。 |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 免费且**不带过期时间**的信用额度当日广告扣费，USD。⚠️ 由本地货币金额除以当日汇率派生，多行直接 SUM 时需确认汇率口径一致。 |
| `free_expenditure_w_expiry_amt_local_1d` | double | 免费且**带过期时间**的信用额度当日广告扣费，本地货币，单位元（原始金额已 ÷100000 换算）。 |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 免费且**带过期时间**的信用额度当日广告扣费，USD。⚠️ 由本地货币金额除以当日汇率派生，多行直接 SUM 时需确认汇率口径一致。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，避免全表扫描和数据重复：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'`（最常用口径） | 同一店铺同一天的数据被重复统计一倍（local + regional 各一份） |
| `grass_region` | `grass_region = 'TW'` | 全地区数据混合扫描，结果错误且查询性能极差 |
| `grass_date` | `grass_date = '2026-04-21'` | 拉取历史全量数据，造成性能问题 |

> `tz_type` 推荐优先使用 `local`（本地时区口径），与大多数业务报表保持一致。若需与大区时区口径对齐，使用 `regional`。两种口径**不可混用后 SUM**。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|------|---------|-------------|
| `*_amt_usd_1d`（所有 USD 字段） | 由本地货币 ÷ 当日汇率派生计算，跨地区或跨日期 SUM 时汇率基准不同，结果存在误差 | 跨地区汇总时，建议先在各地区分别 SUM 本地货币金额，再用统一汇率表转换；或直接接受当日汇率隐含的近似误差 |

### 时效性说明

- 本表为**每日全量覆盖**写入，取当日最新分区（`grass_date = <目标日期>`）即为最终值，无历史累计问题。
- `regional` 时区口径在 ETL 中会读取 `grass_date` 和 `grass_date - 1` 两天的原始事件日志，并按 Unix timestamp 过滤到目标日期边界，因此 `regional` 分区数据略晚于 `local` 分区可用，使用时需确认调度已完成。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告曝光/扣费明细事实表，提供四类信用额度的原始扣费金额（单位：1/100000 元），按 `grass_region`、`grass_date` 及 `expenditure_amt_local > 0` 过滤后汇总至店铺粒度 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维度表，提供各地区当日本地货币兑 USD 的汇率，用于将本地货币金额转换为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  │
  │  过滤：grass_region, grass_date, expenditure_amt_local > 0
  │  聚合：GROUP BY shop_id, grass_region
  │  换算：÷ 100000.0（分→元）
  │
  ▼
[子查询 a：店铺级本地货币扣费汇总]
  │                                          mp_order.dim_exchange_rate__reg_s0_live
  │                                            │
  │                                            │  过滤：grass_region, grass_date
  │                                            ▼
  │──── LEFT OUTER JOIN (MAPJOIN) ────── [exrate：当日汇率]
  │         ON grass_region
  │
  ▼
[USD 字段派生：本地货币 ÷ exchange_rate]
  │
  ├──→ INSERT OVERWRITE PARTITION(tz_type='local',   grass_region, grass_date)
  │       来源过滤：grass_date = '${grass_date}'（精确匹配日期）
  │
  └──→ INSERT OVERWRITE PARTITION(tz_type='regional', grass_region, grass_date)
          来源过滤：grass_date ∈ [grass_date-1, grass_date]
                   AND timestamp ∈ [草日期起始, 草日期结束)（Unix timestamp 精确边界）
```

### 关键 CTE 说明

本 ETL 无显式 CTE，采用内联子查询结构：

| 子查询 / 步骤 | 来源表 | 作用 |
|--------------|--------|------|
| 子查询 `a`（local） | `dwd_advertise_performance_di` | 按 `grass_date` 精确过滤，聚合四类信用额度扣费至店铺粒度，金额除以 100000 还原为元 |
| 子查询 `a`（regional） | `dwd_advertise_performance_di` | 跨两天读取原始日志，按 Unix timestamp 边界截取目标日期区间，适配大区时区偏移场景 |
| `exrate` | `dim_exchange_rate` | 取当日单行汇率，通过 MAPJOIN 广播至全部 shop_id 行，避免大表 JOIN |

### 注意事项

1. **金额单位换算**：上游 `dwd_advertise_performance_di` 中原始扣费字段（如 `expense_free_credit_with_expiry`）以平台最小货币单位存储，ETL 中统一 ÷ 100000.0 还原为标准货币元，使用时无需二次换算。

2. **汇率 LEFT JOIN**：与汇率表做 LEFT OUTER JOIN，若当日汇率缺失，USD 金额字段将为 `NULL`（而非 0）。使用前建议过滤或添加 `COALESCE` 处理。

3. **两套时区口径差异**：
   - `local` 口径：直接按 `grass_date` 匹配事件记录的草日期，统计口径简单清晰。
   - `regional` 口径：因大区时区与本地时区存在偏差，需读取跨两天的原始事件（`grass_date-1` ～ `grass_date`），并通过 Unix timestamp 精确截断，确保时区对齐。**两套口径的同日数据数值可能不同，不可混用**。

4. **`expenditure_amt_local > 0` 过滤**：仅聚合实际产生扣费的广告事件，零消耗记录不进入本表，下游使用时需注意本表存在自然缺失（无扣费的 shop_id 不会出现）。

5. **参数化调度**：`${region}`、`${upper_region}`、`${grass_date}` 均为调度框架注入的参数，各地区独立任务并发执行，本表覆盖所有已开通地区。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告扣费明细事实层，提供按信用额度类型细分的原始扣费金额 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维度表，提供当日本地货币兑 USD 汇率 |

*文档生成时间：2026-04-22*