<!-- ads-workspace-gdoc-sync: gdoc_id=1-h0hNHRgVeCb1r8qs_YCGVs0FoORHQUfXTy5LnZyZLk gdoc_url=https://docs.google.com/document/d/1-h0hNHRgVeCb1r8qs_YCGVs0FoORHQUfXTy5LnZyZLk/edit -->

# mp_paidads.dws_advertise_revenue_1d__reg_s0_live

## Description

- **Desc:** 广告收入日汇总表（DWS 层）。从广告主交易明细表（dwd_advertiser_transaction_di）提取每种付费类型的支出（paid/free, with/without expiry），按 ads_id x placement x campaign_id x entrance x pricing_type 粒度累加为日收入，并换算 USD 金额。是广告效果表和扣费追踪表的上游收入源。
- **Granularity:** daily x ads_id x placement x campaign_id x entrance x pricing_type x sub_entrance x traffic_source x tz_type x grass_region
- **Use Case:**
  1. 广告效果报表（dws_advertise_performance_1d）— 作为全额收入源，与曝光/点击/订单效果数据 FULL JOIN 生成完整效果表
  2. Campaign 累计扣费追踪（dws_campaign_deduction_td）— SUM(total_expenditure) 聚合到 campaign 维度，累加历史扣费
  3. Campaign 日预算消耗监控（dws_campaign_deduction_budget_1d）— 计算单日消耗 daily_deduction，判断是否触发预算预警
  4. 分付费类型的收入分析 — 区分付费信用（paid）和免费信用（free），以及是否过期（expiry）
- **Update Frequency:** Daily (T+1)

## Key Metrics

- 收入类（Cost）:
  - `total_expenditure_amt_local_1d` / `total_expenditure_amt_usd_1d` — 总花费（本币/USD）
  - `paid_expenditure_wo_expiry_amt_local_1d` / `paid_expenditure_wo_expiry_amt_usd_1d` — 付费信用未过期花费
  - `paid_expenditure_w_expiry_amt_local_1d` / `paid_expenditure_w_expiry_amt_usd_1d` — 付费信用已过期花费
  - `free_expenditure_wo_expiry_amt_local_1d` / `free_expenditure_wo_expiry_amt_usd_1d` — 免费信用未过期花费
  - `free_expenditure_w_expiry_amt_local_1d` / `free_expenditure_w_expiry_amt_usd_1d` — 免费信用已过期花费

- 汇率：JOIN mp_order.dim_exchange_rate__reg_s0_live 获取 exchange_rate，USD = Local / exchange_rate

## Key Dimensions

- 分区: tz_type, grass_region, grass_date
- 广告标识: ads_id, placement, campaign_id
- 业务维度: entrance, pricing_type, sub_entrance, traffic_source
- 商品/店铺: shop_id, item_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type (string), grass_region (string), grass_date (DATE) |
| HDFS Path | `${HIVE_PATH}/dws_advertise_revenue_1d` |
| Retention | - |
| Column Count | 18 (non-partition) + 3 (partition) |
| Region Coverage | US (BR, CO, CL, MX) — 当前活跃写入; Legacy 覆盖 SG/MY/TH/PH/VN/TW/ID/BR/MX/CO/CL 全域 |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 66 files (4 write, 62 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
