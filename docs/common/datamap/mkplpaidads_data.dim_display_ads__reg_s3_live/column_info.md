<!-- ads-workspace-gdoc-sync: gdoc_id=1bs9KaVSrCedyEGSiemmd4Cy41rJB7m31y_e09v4tsTI gdoc_url=https://docs.google.com/document/d/1bs9KaVSrCedyEGSiemmd4Cy41rJB7m31y_e09v4tsTI/edit -->

# Columns: mkplpaidads_data.dim_display_ads__reg_s3_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

表中 budget 和 estimate 类金额字段均为 ads_id 级别的唯一值，跨 ads_id 聚合时直接 SUM 即可。未观察到 SUM(DISTINCT) 模式。

注意：estimate_local_cpm / estimate_usd_cpm 为出价单价，跨维度聚合时应使用 MAX 而非 SUM。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| ads_status | 1 | 有效/正常投放 |
| ads_status | 4 | (待确认，from-di 补充) |
| tz_type | local | 当地时间口径 |
| tz_type | regional | 区域/标准口径 |
| location | 1 | Location/slot 1 (常用于过滤) |

### 常见 WHERE 值 (Common Filter Values)

- **分区过滤（必选）**:
  - `grass_date`: 每日分区（如 `DATE('${grass_date}')`）
  - `tz_type`: 'local' (workflow 默认) / 'regional' (部分报表)
  - `grass_region`: upper('${region}')，覆盖 BR/ID/MX/MY/PH/SG/TH/TW/VN/CO/CL
- **业务过滤**:
  - `ads_status in (1, 4)`: 过滤有效和已删除广告
  - `location = 1`: 只查看特定位置
- **预算时间窗口过滤** (在 JOIN 后的外层 WHERE 使用):
  - `substr(cast(budget_end_datetime as string), 0, 11) >= DATE('${grass_date}')`: 预算未过期
  - `substr(budget_start_datetime, 1, 10) <= '${grass_date}'`: 预算已开始

## All Columns

> 列名和类型从代码库 SQL 使用中推断。标注 "-" 的字段请运行 --source from-di 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告计划 ID (主键，JOIN 关联键) | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| location | int | 广告位位置/slot | - | - |
| budget_start_datetime | string | 预算开始时间 | - | - |
| budget_end_datetime | string | 预算结束时间 | - | - |
| estimate_imp_cnt | bigint | 预估曝光量 | - | - |
| ads_status | int | 广告状态 | - | - |
| create_datetime | string | 创建时间 | - | - |
| last_update_datetime | string | 最后更新时间 | - | - |
| last_creative_upload_datetime | string | 最后创意上传时间 | - | - |
| last_creative_approve_datetime | string | 最后创意审核时间 | - | - |
| landing_page_link | string | 落地页链接 | - | - |
| billing_company | string | 结算公司 | - | - |
| billing_address | string | 结算地址 | - | - |
| billing_email | string | 结算邮箱 | - | - |
| campaign_detail | string | 活动详情 (JSON?) | - | - |
| budget_local_amt | bigint/decimal | 预算金额(本地币) | - | - |
| budget_usd_amt | bigint/decimal | 预算金额(USD) | - | - |
| estimate_local_cpm / estimate_cpm_local | bigint/decimal | 预估 CPM(本地币) | - | - |
| estimate_usd_cpm / estimate_cpm_usd | bigint/decimal | 预估 CPM(USD) | - | - |
| estimate_expense_local_amt | bigint/decimal | 预估花费(本地币) | - | - |
| estimate_expense_usd_amt | bigint/decimal | 预估花费(USD) | - | - |
| grass_date | date [PARTITION] | 分区日期 | - | - |
| tz_type | string [PARTITION] | 时区类型 (local/regional) | - | - |
| grass_region | string [PARTITION] | 区域代码 | - | - |

> 注意: 列名和类型从 SQL SELECT 语句推断，可能存在遗漏或精度差异。运行 --source from-di 可获取完整的 DDL 列定义、description、query frequency 和 MAX 采样值。
