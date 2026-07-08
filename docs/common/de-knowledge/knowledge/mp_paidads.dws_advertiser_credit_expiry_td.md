<!-- ads-workspace-gdoc-sync: gdoc_id=1mWJixoWf2uSaOYZ1on0jfKLne-agy97OxpOpCAoZk94 gdoc_url=https://docs.google.com/document/d/1mWJixoWf2uSaOYZ1on0jfKLne-agy97OxpOpCAoZk94/edit -->

# mp_paidads.dws_advertiser_credit_expiry_td

**分层：** DWS（数据汇总层）
**主键：** `shop_id` + `user_id` + `grass_region` + `grass_date` + `tz_type`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**引用频次：** 1 次（候选表范围内）

---

## 业务描述

本表记录广告主（卖家）在付费广告系统中**截至当日（till date，累计口径）**的广告预算信用额度到期失效金额，粒度为 `shop_id`（店铺）× `grass_date`。数据按信用充值来源（Manual 手动充值、Seller Mission 卖家任务、SRM 客户关系管理）以及信用类型（付费信用 Paid Credit、免费信用 Free Credit）进行拆分，同时提供本地货币与 USD 双币种口径，支持跨市场统一分析。

本表的核心使用场景包括：（1）监控各渠道信用额度的失效情况，识别高失效风险的广告主群体；（2）结合充值记录与消耗记录，分析信用利用效率；（3）为财务结算、风控及广告主运营提供 TD（累计至今）维度的到期失效金额基准数据。

由于采用 **td（till date）累计存储**方式，每个 `grass_date` 分区中的数据均包含该日期之前的所有历史累计值，而非单日增量。下游查询时，通常只需取最新分区日期的数据，即可获得截至当日的完整累计口径。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区分区类型。当前写入值固定为 `'local'`（各地区按本地时区参数化调度）。查询时须指定该字段以避免全表扫描。⚠️ 目前只有 `local` 分区有数据，不要遗漏此过滤条件 |
| `grass_region` | string | 市场/地区标识（大写，如 `'MY'`、`'TH'`）。为分区字段，查询时必须指定以裁剪数据量 |
| `grass_date` | date | 数据日期分区。每个分区存储**截至该日期的所有历史累计值**（td 口径），通常取最新分区即可获得最新累计数据 |

### 维度：主键与广告主属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 卖家店铺 ID，信用到期金额统计的最小粒度单元 |
| `user_id` | bigint | 广告主用户 ID，与 `shop_id` 共同标识一个广告主账户，来源于 `dim_advertiser` 维表 |

### 指标：手动充值（Manual Topup）信用到期金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `manual_free_credit_expired_amt_td` | double | 手动充值渠道下，截至当日累计失效的**免费信用**金额（本地货币）。⚠️ 为 td 累计值，跨日期 SUM 会重复计算，应仅取单一 `grass_date` 分区 |
| `manual_free_credit_expired_amt_usd_td` | double | 手动充值渠道下，截至当日累计失效的**免费信用**金额（USD）。⚠️ 同上，td 累计值，勿跨日期 SUM |
| `manual_paid_credit_expired_amt_td` | double | 手动充值渠道下，截至当日累计失效的**付费信用**金额（本地货币）。⚠️ td 累计值，勿跨日期 SUM |
| `manual_paid_credit_expired_amt_usd_td` | double | 手动充值渠道下，截至当日累计失效的**付费信用**金额（USD）。⚠️ td 累计值，勿跨日期 SUM |

### 指标：卖家任务充值（Seller Mission Topup）信用到期金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_mission_free_credit_expired_amt_td` | double | Seller Mission 渠道下，截至当日累计失效的**免费信用**金额（本地货币）。⚠️ td 累计值，勿跨日期 SUM |
| `seller_mission_free_credit_expired_amt_usd_td` | double | Seller Mission 渠道下，截至当日累计失效的**免费信用**金额（USD）。⚠️ td 累计值，勿跨日期 SUM |
| `seller_mission_paid_credit_expired_amt_td` | double | Seller Mission 渠道下，截至当日累计失效的**付费信用**金额（本地货币）。⚠️ td 累计值，勿跨日期 SUM |
| `seller_mission_paid_credit_expired_amt_usd_td` | double | Seller Mission 渠道下，截至当日累计失效的**付费信用**金额（USD）。⚠️ td 累计值，勿跨日期 SUM |

### 指标：SRM 充值（SRM Topup）信用到期金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `srm_free_credit_expired_amt_td` | double | SRM（客户关系管理）渠道下，截至当日累计失效的**免费信用**金额（本地货币）。⚠️ td 累计值，勿跨日期 SUM |
| `srm_free_credit_expired_amt_usd_td` | double | SRM 渠道下，截至当日累计失效的**免费信用**金额（USD）。⚠️ td 累计值，勿跨日期 SUM |
| `srm_paid_credit_expired_amt_td` | double | SRM 渠道下，截至当日累计失效的**付费信用**金额（本地货币）。⚠️ td 累计值，勿跨日期 SUM |
| `srm_paid_credit_expired_amt_usd_td` | double | SRM 渠道下，截至当日累计失效的**付费信用**金额（USD）。⚠️ td 累计值，勿跨日期 SUM |

### 指标：汇总信用到期金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `total_free_credit_expired_amt_td` | double | 三个渠道（Manual + Seller Mission + SRM）截至当日累计失效的**免费信用**总金额（本地货币）。⚠️ 为 ETL 中三渠道字段直接相加的派生值，td 累计口径，勿跨日期 SUM；若需重新计算，应对三个分渠道字段求和 |
| `total_free_credit_expired_amt_usd_td` | double | 三个渠道截至当日累计失效的**免费信用**总金额（USD）。⚠️ 派生累计值，同上 |
| `total_paid_credit_expired_amt_td` | double | 三个渠道截至当日累计失效的**付费信用**总金额（本地货币）。⚠️ 派生累计值，同上 |
| `total_paid_credit_expired_amt_usd_td` | double | 三个渠道截至当日累计失效的**付费信用**总金额（USD）。⚠️ 派生累计值，同上 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区字段，否则将触发全表扫描，导致资源浪费和性能劣化：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区（当前实际只有 `local`，但不过滤仍会增加扫描量） |
| `grass_region` | `grass_region = 'MY'`（按需指定目标市场） | 全市场扫描，数据量成倍增长 |
| `grass_date` | `grass_date = '2026-05-20'`（通常取最新日期） | 读取所有历史分区，产生大量冗余数据且结果错误（td 值被重复叠加） |

### 不可直接 SUM 的字段

本表所有指标字段均为 **td（till date）累计存储**，每个分区已包含历史全量累计，**不得跨多个 `grass_date` 分区对指标字段执行 SUM**，否则将造成重复计算。

| 字段类型 | 典型字段 | 正确使用方式 |
|----------|----------|--------------|
| td 累计金额字段（本地货币 / USD） | 所有 `*_expired_amt_td` / `*_expired_amt_usd_td` 字段 | 固定在**单一 `grass_date` 分区**中查询，对不同 `shop_id` 横向 SUM 是合法的 |
| 汇总派生字段 | `total_free_credit_expired_amt_td` 等四个 `total_*` 字段 | 由 ETL 在三渠道字段相加后写入，若需验证，应手动计算：`manual_* + seller_mission_* + srm_*` |

> **正确示例**：
> ```sql
> -- 查询某市场当日各店铺累计到期失效付费信用总额
> SELECT shop_id, total_paid_credit_expired_amt_usd_td
> FROM mp_paidads.dws_advertiser_credit_expiry_td
> WHERE tz_type = 'local'
>   AND grass_region = 'MY'
>   AND grass_date = '2026-05-20';
> ```

### 时效性说明

本表为 **td（截至某日累计）**口径，每日全量覆盖写入最新分区。使用时应始终取**当前调度周期写入的最新 `grass_date` 分区**，历史分区数据是该日期的历史快照，不会随最新数据更新而变化。若需计算**单日新增到期金额**，应用相邻两日分区的指标做差值：

```
单日新增 = grass_date=T 的 td 值 − grass_date=T-1 的 td 值
```

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主信用充值明细表（DWD 层），提供信用充值订单类型、充值主类型、余额金额等原始明细；ETL 中过滤出已设置到期时间且到期日 ≤ 当日的记录，作为已失效信用的计算来源 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，提供 `shop_id` 与 `user_id` 的对应关系；作为驱动表确保所有广告主均有记录（LEFT JOIN，无信用到期数据的店铺相关字段以 0.0 填充） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
  │  过滤条件：
  │  - grass_region = ${region}
  │  - grass_date = ${grass_date}
  │  - credit_topup_expiry_end_timestamp IS NOT NULL AND > 0
  │  - date(credit_topup_expiry_end_datetime) <= ${grass_date}  ← 仅保留已到期记录
  │
  ▼
[credit_view]  临时视图
  │  按 (grass_region, shop_id) × (credit_order_type, credit_topup_main_type)
  │  分类展开为各渠道 × 信用类型的金额列（CASE WHEN）
  │
  ▼
[聚合层]  GROUP BY grass_region, shop_id
  │  SUM 汇总各分渠道金额
  │
  ▼
[派生层]  计算 total_* 字段
  │  = manual_* + seller_mission_* + srm_*
  │
mp_paidads.dim_advertiser__reg_s0_live
  │  过滤：grass_region = ${region}, grass_date = ${grass_date}
  │  DISTINCT shop_id, user_id, grass_region
  │
  ▼ LEFT JOIN（dim 驱动，credit 补充）
  │  ON shop_id AND grass_region
  │  COALESCE(指标字段, 0.0)  ← 无到期记录的店铺补 0
  │
  ▼
dws_advertiser_credit_expiry_td__reg_s0_live
  partition (tz_type='local', grass_region, grass_date)
  INSERT OVERWRITE（全量覆盖当日分区）
```

### 关键 CTE 说明

| CTE / 子查询 | 来源表 | 作用 |
|---|---|---|
| `credit_view`（临时视图） | `dwd_advertiser_credit_topup_df` | 筛选当日已到期的信用充值记录（`expiry_end_timestamp` 非空且 > 0，到期日 ≤ 当日），携带余额金额和订单/主类型编码 |
| 内层 CASE WHEN 展开 | `credit_view` | 将 `(credit_order_type, credit_topup_main_type)` 编码组合映射为各渠道×信用类型列：`order_type=3→Manual`，`order_type=8→Seller Mission`，`order_type=9→SRM`；`main_type=2→Paid`，`main_type=3→Free` |
| 聚合子查询 | 内层展开结果 | `GROUP BY (grass_region, shop_id)` 对各渠道列求 SUM，汇总至店铺粒度 |
| 派生 `total_*` 子查询 | 聚合结果 | 将三渠道同类型金额相加，生成四个 `total_*` 字段 |
| `dim` 子查询 | `dim_advertiser` | 获取当日全量广告主 `(shop_id, user_id)` 映射，确保即使无到期记录的店铺也出现在结果中 |

### 注意事项

1. **信用到期判定口径**：ETL 仅保留 `credit_topup_expiry_end_timestamp IS NOT NULL AND > 0` 且 `date(credit_topup_expiry_end_datetime) <= grass_date` 的记录。即只要到期日截止到当日（含当日），均纳入累计统计。

2. **td 累计覆盖写入**：每次调度对当日分区执行 INSERT OVERWRITE，历史分区不回刷。td 值是从 DWD 层每次全量重新聚合，因此当日分区的数据代表从最早有记录至当日的完整累计。

3. **无到期记录店铺补 0**：以 `dim_advertiser` 为驱动表 LEFT JOIN，确保所有在维表中存在的广告主均有一行输出，到期金额字段通过 `COALESCE(field, 0.0)` 补零，避免下游出现 NULL 导致聚合异常。

4. **渠道与信用类型编码对照**：
   - `credit_order_type = 3`：Manual（手动充值）
   - `credit_order_type = 8`：Seller Mission（卖家任务充值）
   - `credit_order_type = 9`：SRM（客户关系管理充值）
   - `credit_topup_main_type = 2`：Paid Credit（付费信用）
   - `credit_topup_main_type = 3`：Free Credit（免费信用）

5. **多地区参数化调度**：ETL 通过 `${region}`、`${grass_date}` 参数化，各地区按本地时区独立调度，写入对应的 `grass_region` 分区，本表覆盖所有支持地区。

---

*文档生成时间：2026-05-20*