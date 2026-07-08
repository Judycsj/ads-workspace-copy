<!-- ads-workspace-gdoc-sync: gdoc_id=1R9f73gGFaJeoHgmSyrRPTcWR1iYqrtLhdJeiYHdN88E gdoc_url=https://docs.google.com/document/d/1R9f73gGFaJeoHgmSyrRPTcWR1iYqrtLhdJeiYHdN88E/edit -->

# Columns: mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未从代码库中识别到显著的 SUM(DISTINCT) 模式。所有指标列均为 DOUBLE 类型可加指标。

注意：跨 common_feature / user_id / item_id 聚合时，omni_gmv_usd_1d 已经在写入时按 (user_id, item_id, common_feature) 粒度做了 GROUP BY 汇总，可以直接 SUM。

### 枚举值映射 (Value Mappings)

common_feature 列枚举值（从 omni 归因逻辑得出的完整映射，3+ 文件出现）：

| Value | Description |
|-------|-------------|
| Platform | 全平台汇总 (所有推荐场景合并) |
| Global Search | 全局搜索 |
| Image Search | 图片搜索 |
| You May Also Like | 商品详情页推荐 (YMAL/PDP) |
| Live Streaming | 直播推荐 |
| Daily Discover | 每日发现 |
| Order Successful Recommendation | 下单成功页推荐 |
| Cart Recommendation | 购物车推荐 |
| My Purchase Page Recommendation | 我的购买页推荐 |
| Order Detail Page Recommendation | 订单详情页推荐 |
| Games | 游戏推荐 |
| Video | 视频推荐 |
| Me YMAL | "我的" 页推荐 |
| Voucher Landing Recommendation | 券落地页推荐 |
| Hot Deals Landing Recommendation | 热卖落地页推荐 |
| Shop YMAL | 店铺相关推荐 |
| Search Shop | 搜索店铺结果 |
| Others | 其他未分类场景 |

业务分组（常见查询模式）：
- PP (Post-Purchase): My Purchase Page, Order Successful, Order Detail Page, Cart Recommendation, Me YMAL, Shop YMAL, Shipping Info Page YMAL

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询)
- `common_feature`:
  - 'Platform' (~80% 查询，全平台汇总)
  - 'Daily Discover', 'Global Search', 'You May Also Like' (场景分析)
  - NOT IN ('Platform','Others') (细分场景汇总)
- `grass_region`: SG, TW, PH, BR, ID ... (按站点)
- `grass_date`: 范围查询 (between X and Y) 或单天
- `item_id > 0` / `omni_gmv_usd_1d > 0` / `paid_ads_revenue_usd_1d > 0` (数据质量过滤)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| common_feature | string | 推荐场景/归因特征 | - | - |
| user_id | bigint | 用户 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| omni_gmv_usd_1d | double | 归因 GMV (USD, 1d) | - | - |
| estimate_mp_revenue_usd_1d | double | MP 预估收入 = commissions + handling + paid_ads_revenue | - | - |
| estimate_mandatory_commission_fee_usd_1d | double | 强制佣金 (USD, 1d) | - | - |
| estimate_local_c2c_mandatory_commission_fee_usd_1d | double | MP C2C 强制佣金 | - | - |
| estimate_local_mall_mandatory_commission_fee_usd_1d | double | Mall 强制佣金 | - | - |
| estimate_cb_mandatory_commission_fee_usd_1d | double | CB 强制佣金 | - | - |
| estimate_optional_commission_fee_usd_1d | double | 自选佣金 (USD, 1d) | - | - |
| estimate_local_c2c_optional_commission_fee_usd_1d | double | MP C2C 自选佣金 | - | - |
| estimate_local_mall_optional_commission_fee_usd_1d | double | Mall 自选佣金 | - | - |
| estimate_cb_optional_commission_fee_usd_1d | double | CB 自选佣金 | - | - |
| estimate_handling_fee_usd_1d | double | 手续费合计 (buyer + seller) | - | - |
| estimate_seller_handling_fee_usd_1d | double | 卖家手续费 | - | - |
| estimate_buyer_handling_fee_usd_1d | double | 买家手续费 | - | - |
| estimate_promotion_excl_3pl_usd_1d | double | Item+Voucher+Logst 补贴 (不含 3PL Margin) | - | - |
| estimate_logst_prm_usd_1d | double | 物流补贴 | - | - |
| estimate_item_card_prm_usd_1d | double | 商品卡补贴 | - | - |
| estimate_voucher_prm_usd_1d | double | 券补贴 | - | - |
| estimate_coin_prm_usd_1d | double | 金币补贴 | - | - |
| proxy_pc2_usd_1d | double | 代理 PC2 = mandatory + optional + handling + paid_ads_revenue - paid_ads_voucher | - | - |
| adjusted_proxy_pc2_usd_1d | double | 调整后代理 PC2 (按本地类目 PC2 rate 调整) = omni_gmv * adjusted_proxy_pc2_rate | - | - |
| paid_ads_revenue_usd_1d | double | 付费广告毛收入 (gross expenditure) | - | - |
| paid_ads_broad_gmv_usd_1d | double | 付费广告 Broad GMV | - | - |
| paid_ads_voucher_amt_usd_1d | double | 付费广告券成本 (ads part, 不含 cofund) | - | - |
| commission_base_amt_usd_1d | double | 佣金基数 (2026-05 DDL 新增列) | - | - |
| tz_type | string | 时区类型 [Partition] | - | - |
| grass_region | string | 站点 [Partition] | - | - |
| grass_date | date | 数据日期 [Partition] | - | - |
