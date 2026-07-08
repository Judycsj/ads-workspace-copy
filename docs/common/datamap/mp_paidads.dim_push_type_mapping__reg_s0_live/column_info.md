<!-- ads-workspace-gdoc-sync: gdoc_id=12Xp7jL7TBraqFgO77TEiiDAqlJBzX72S8k8PFHcqCXA gdoc_url=https://docs.google.com/document/d/12Xp7jL7TBraqFgO77TEiiDAqlJBzX72S8k8PFHcqCXA/edit -->

# Columns: mp_paidads.dim_push_type_mapping__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。DIM 表仅包含映射列，不存在聚合场景中的非累加问题。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| push_type | ads_push | 广告相关的推金类型（sub_push_type 有匹配到 maps） |
| push_type | non_ads_push | 非广告推金（LEFT JOIN 未匹配，push_type IS NULL） |

### 常见 WHERE 值 (Common Filter Values)

DIM 表在所有引用中均全量加载（无 WHERE 过滤条件），因表较小无需分区过滤。

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| sub_push_type | string | 子推金类型标识，来自上游 credit_topup 业务逻辑派生，例如 'Ads Discount Voucher', 'Ads Discount Package' 或 credit_topup_sub_type_name | - | - |
| push_type | string | 推金分类类型，用于区分广告推金与非广告推金。业务产出为 'ads_push' 或 NULL | - | - |
