<!-- ads-workspace-gdoc-sync: gdoc_id=1h3BM_5ypXEwQULW08YIMI1Ne_ayxO46QFIgHjnioqn8 gdoc_url=https://docs.google.com/document/d/1h3BM_5ypXEwQULW08YIMI1Ne_ayxO46QFIgHjnioqn8/edit -->

# Columns: mp_paidads.ads_simple_roi2_npb_item_hi__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

跨 item_id 聚合时不可直接 SUM：
- `platform_order_avg` — 日均订单数为平均值，需按 item_id 先求 AVG 或采用加权平均

### 枚举值映射 (Value Mappings)

*from-code: CASE-WHEN 抽取（2+ 文件出现）*

| Column | Value | Meaning |
|--------|-------|---------|
| (derived) npb_stage | 1 | 新商品无订单（create_day_cnt <= 20 且 platform_order_acc = 0） |
| (derived) npb_stage | 2 | 新商品有少量订单（create_day_cnt <= 20 且 platform_order_acc >= 1 且 <= 20） |
| (derived) npb_stage | 0 | 非 NPB 阶段商品 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 标准地区 'ID','MY','PH','SG','TH','TW','VN','BR','CL','CO','MX'
- `grass_date`: date'YYYY-MM-DD' 格式，分区过滤通常取最新
- `h`: 小时分区整数值，通常取最新小时（如 23）
- 跨区域 OR 条件查询时，各 region 取各自的 latest (grass_date, h)

## All Columns

*DDL 未在代码库中找到，以下列名和类型从 SELECT 语句推断。建议运行 `--source from-di` 补充完整信息。*

| Column Name | Type (Inferred) | Description | L7/14/30D Query | MAX(column) |
|-------------|-----------------|-------------|-----------------|-------------|
| grass_region | string | 地区编码 | - | - |
| grass_date | date/string | 数据日期（分区列） | - | - |
| h | int | 小时分区（分区列） | - | - |
| item_id | bigint/string | 商品 ID | - | - |
| create_day_cnt | int | 商品创建天数 | - | - |
| platform_impression_acc | bigint | 平台累计曝光量 | - | - |
| platform_click_acc | bigint | 平台累计点击量 | - | - |
| platform_order_acc | bigint | 平台累计订单数 | - | - |
| platform_order_avg | double | 平台日均订单数 (ADO) | - | - |
