<!-- ads-workspace-gdoc-sync: gdoc_id=17LMXVvOoFjBVYEGH-yRQK5wd1uPwdnFPtvzFydT491Y gdoc_url=https://docs.google.com/document/d/17LMXVvOoFjBVYEGH-yRQK5wd1uPwdnFPtvzFydT491Y/edit -->

# Columns: traffic.dwd_position_lead_atc_di__reg_live

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('SG'), upper('MY'), upper('PH'), upper('TH'), upper('TW'), upper('VN'), upper('MX'), upper('CO'), upper('CL'), upper('BR') — 覆盖 10 个 region
- `grass_date`: 滚动 14 天窗口 — `between date'${yesterday}' - interval '14' day and date'${yesterday}'`
- `user_id`: 过滤非空 — `user_id is not null`

## All Columns

*DDL 未在 ads 代码库中找到，以下从 SQL 引用推断。运行 --source from-di 补全完整列清单。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| user_id | bigint | 用户 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| grass_region | string | 区域分区键 | - | - |
| grass_date | date | 日期分区键 | - | - |
