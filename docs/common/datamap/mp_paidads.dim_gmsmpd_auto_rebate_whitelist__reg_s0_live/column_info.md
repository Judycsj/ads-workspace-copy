<!-- ads-workspace-gdoc-sync: gdoc_id=17EKg0qtH1v4w3U_Huu8NROGxi8PccdMMLnFExYmYgAE gdoc_url=https://docs.google.com/document/d/17EKg0qtH1v4w3U_Huu8NROGxi8PccdMMLnFExYmYgAE/edit -->

# Columns: mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表为维度表，所有字段均为维度属性字段，无累加指标字段。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| type | 1 | gms whitelist (商品广告自动返利) |
| type | 2 | mpd whitelist (多商品展示广告自动返利) |
| type | 3 | campaign_tag whitelist (含有campaign_tag的卖家) |
| type | 4 | auto escrow whitelist (自动托管) |
| type | 5 | weekly_rebate_rules (周返利规则) |
| feature_mode | 1 | ModeOpenToAll (全员开放) |
| feature_mode | 2 | ModeWhiteList (白名单模式) |
| feature_mode | 3 | ModeBlackList (黑名单模式) |
| feature_mode | 4 | ModeOpenToNone (全员关闭) |
| feature_mode | 5 | GrayScaleByShopId (按店铺灰度) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 常见区域 'BR', 'VN', 'MY', 'SG', 'ID', 'TH', 'TW', 'MX'
- `type`: 5 (weekly_rebate_rules 规则查询)
- `grass_date`: 通常按日期范围查询，如 `between DATE('2026-04-01') and DATE('2026-04-30')`

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | BIGINT | shop_id | - | - |
| whitelist_date | DATE | 开白日期 | - | - |
| type | INT | 白名单类型：1=gms, 2=mpd, 3=campaign_tag, 4=auto escrow, 5=weekly_rebate_rules | - | - |
| feature_mode | TINYINT | feature toggle模式：1=ModeOpenToAll, 2=ModeWhiteList, 3=ModeBlackList, 4=ModeOpenToNone, 5=GrayScaleByShopId | - | - |
| grass_region | STRING | region (分区列) | - | - |
| grass_date | DATE | date (分区列) | - | - |
