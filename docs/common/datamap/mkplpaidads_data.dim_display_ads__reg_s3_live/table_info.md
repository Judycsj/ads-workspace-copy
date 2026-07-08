<!-- ads-workspace-gdoc-sync: gdoc_id=1Q6gXIOYsYyDp5Mis28U7FI8yIC1fuPvrrHFiqskpOwI gdoc_url=https://docs.google.com/document/d/1Q6gXIOYsYyDp5Mis28U7FI8yIC1fuPvrrHFiqskpOwI/edit -->

# mkplpaidads_data.dim_display_ads__reg_s3_live

## Description

- **Desc:** Display Ads 维度表，存储品牌广告 (Brand/Display Ads) 的广告计划元信息，包括预算、出价、店铺、素材审核、结算等属性。用作 Display Ads 广告表现数据（impression/click/revenue）的维度宽表，为 `dw_*_ads_revenue` 和报表下游提供 budget time window 校验和 shop_id 映射。
- **Granularity:** daily x ads_id x tz_type x grass_region
- **Use Case:**
  - Display Ads 净收入归因：为 `dws_user_net_ads_revenue_1d` 提供 shop_id 和 budget 有效期过滤，确保只计入预算周期内的展示广告花费
  - Display Ads 展示收入：`dws_advertise_display_ads_revenue` 通过 ads_id JOIN 获取预算时间窗口，计算 CPM 基础上的 expense/revenue
  - NG 流量与 TMS 差异报表：`ads_report_ng_tms_diff` 使用 budget_end_datetime 过滤有效的 Display Ads，排除预算已过期的广告
  - 品牌广告手动分析：Display Ads 投放统计、预算分析、素材时间线追踪
- **Update Frequency:** Daily

## Key Metrics

- 预算类: budget_local_amt, budget_usd_amt, estimate_expense_local_amt, estimate_expense_usd_amt (SUM 聚合)
- CPM 出价: estimate_local_cpm / estimate_cpm_local, estimate_usd_cpm / estimate_cpm_usd (MAX 取值)
- 预估量: estimate_imp_cnt

## Key Dimensions

- 主键: ads_id, grass_date, tz_type, grass_region
- 店铺: shop_id
- 位置: location (slot position)
- 广告状态: ads_status (1=active, 4=...)
- 时间维度: budget_start_datetime, budget_end_datetime, create_datetime, last_update_datetime, last_creative_upload_datetime, last_creative_approve_datetime
- 结算: billing_company, billing_address, billing_email
- 落地页: landing_page_link
- 活动: campaign_detail

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, tz_type, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | BR, CO, ID, MX, MY, PH, SG, TH, TW, VN (from workflow region coverage) |
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

- Studio Tasks References: 56 files (4 manual tasks, 52 workflow files)
- L7D Query Count: -
- Completeness: -
- Popularity: -
