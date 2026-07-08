<!-- ads-workspace-gdoc-sync: gdoc_id=1TefAo7-bwvRdI_vXv_kBOer01ZOlCFtLChuYdWDQtkA gdoc_url=https://docs.google.com/document/d/1TefAo7-bwvRdI_vXv_kBOer01ZOlCFtLChuYdWDQtkA/edit -->

# Columns: mp_paidads.ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live

> DDL 来源: `data_paidadsmart/workflows/data_warehouse_us/ods/ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live/Data Processing/add_partition`
> SG 集群使用 `spark.sql.parquet.mergeSchema=true`，列通过 schema evolution 自动追加。

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。每行代表一笔独立的充值交易 (order_id)，所有列均可直接 SUM/COUNT。

**注意**: `amount`, `discount_price`, `original_price`, `voucher_amount` 单位为本地货币 x100000，SUM 后需除以 100000.0 换算为实际币值。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| order_type | 1 | deduction (扣款) |
| order_type | 2 | topup_from_order (订单充值) |
| order_type | 3 | topup_manual (手动充值) |
| order_type | 4 | topup_wallet (钱包充值) |
| order_type | 5 | deduct_order (扣款订单) |
| order_type | 6 | topup_svs (SVS 充值) |
| order_type | 7 | free credit without expiry (无过期免费信用金) |
| order_type | 8 | topup_from_seller_mission (卖家任务充值) |
| order_type | 9 | topup_from_srm (SRM 充值) |
| order_type | 10 | topup_negative (负充值/退款) |
| order_type | 14 | manual credit (配合 manual 表使用) |
| order_type | 16 | ads credit topup (从 credit 表获取金额) |
| order_type | 20 | (特定充值类型, BR 地区使用) |
| order_type | 21 | (特定充值类型, MY 地区使用) |
| order_type | 28 | auto escrow (自动托管) |
| status | 2 | 已完成/成功 |
| tz_type | local | 本地时区 (~90% 查询) |
| tz_type | regional | 跨区域时区 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (几乎所有查询，按本地时区过滤)
- `grass_date`: date('${BIZ_DT}') 或 date('${grass_date}') -- 单日快照
- `grass_region`: upper('${region}') -- 按国家/地区过滤，标准区 include SG/MY/PH/TW/TH/VN/ID/BR
- `order_time < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))`: 确保只取当天本地时间的数据
- `order_id > 0`: 过滤无效订单
- `order_type = 6`: SVS 充值专用
- `order_type = 9`: SRM 免费信用金专用
- `order_type = 28`: 自动托管专用
- `order_type NOT IN (1, 11, 15)`: 排除扣款类操作
- `status = 2`: 已完成状态的交易

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| orderid | BIGINT | 充值订单 ID (主键) | - | - |
| order_type | INT | 订单类型 (见枚举映射) | - | - |
| userid | BIGINT | 广告主用户 ID | - | - |
| shopid | BIGINT | 店铺 ID | - | - |
| amount | BIGINT | 充值金额 (本地货币 x100000) | - | - |
| status | INT | 订单状态 (2=已完成) | - | - |
| notified | BOOLEAN | 是否已通知 | - | - |
| order_time | BIGINT | 订单创建时间 (unix timestamp) | - | - |
| discount_price | BIGINT | 套餐折扣价 (x100000) | - | - |
| original_price | BIGINT | 套餐原价 (x100000) | - | - |
| package_expiry | BIGINT | 套餐过期时间 (unix timestamp) | - | - |
| package_id | BIGINT | 套餐 ID | - | - |
| voucher_id | BIGINT | 代金券 ID | - | - |
| voucher_amount | BIGINT | 代金券金额 (x100000) | - | - |
| voucher_expiry | BIGINT | 代金券过期时间 (unix timestamp) | - | - |
| ads_package_id | BIGINT | 广告套餐 ID (schema-evolved) | - | - |
| decoded_extinfo | STRING | JSON 扩展信息, 含 svsEntityType/svsEntityId (schema-evolved) | - | - |
| grass_region | STRING | 地区 (分区列) [PARTITION] | - | - |
| grass_date | DATE | 数据日期 yyyy-MM-dd (分区列) [PARTITION] | - | - |
| tz_type | STRING | 时区类型 (分区列) [PARTITION] | - | - |
