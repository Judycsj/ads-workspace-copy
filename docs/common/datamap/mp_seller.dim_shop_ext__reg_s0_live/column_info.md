<!-- ads-workspace-gdoc-sync: gdoc_id=1SxsqEStUJ0_WoKAffc3QahDed5kHq3kMgVesT5vxL9E gdoc_url=https://docs.google.com/document/d/1SxsqEStUJ0_WoKAffc3QahDed5kHq3kMgVesT5vxL9E/edit -->

# Columns: mp_seller.dim_shop_ext__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

从 SQL 代码中未提取到对 dim_shop_ext 自身的 CASE-WHEN 映射。Seller type 相关的 CASE-WHEN 逻辑在消费方（dim_advertiser workflow）中完成：

| Column (消费方别名) | Value | Meaning |
|--------|-------|---------|
| ggp_seller_name (seller_name) | Lovito - GGP | Lovito |
| ggp_seller_name (seller_name) | Flock project - GGP | SCS |
| cb_seller_type (seller_type) | CNCB | Others |
| - | - | 其他情况匹配 local_scs 后归类为 Local SCS / Unknown |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (~100% 查询)
- `grass_region`: `upper('${region}')` / `upper('${grass_region}')` (标准 8 区)
- `grass_date`: `${grass_date}` (str) / `DATE'${PREV_2D}'` (dim_advertiser 场景用 T-2 日期避免延迟) / `date('${grass_date}')` (escrow 场景)

## All Columns

以下列来源于代码库中的实际 SQL 引用。未从代码库获取到 DDL，完整列清单需运行 `--source from-di` 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | Shop 唯一标识，JOIN 主键 | - | - |
| is_cb_shop | tinyint | 是否跨境卖家（1=CB, 0=非CB） | - | - |
| cb_shop_origin_region | string | CB 卖家原始国家/地区 | - | - |
| ggp_seller_name | string | GGP 统一卖家名称 | - | - |
| cb_seller_type | string | CB 卖家类型（CNCB 等） | - | - |
| is_cb_sip_affiliated | tinyint | 是否 CB SIP 附属店铺 | - | - |
| is_local_sip_affiliated | tinyint | 是否本地 SIP 附属店铺 | - | - |

> 注：该表为 mp_seller 库中的外部维表，代码库中无 DDL。`from-code` 模式仅能提取实际引用的列。完整列清单请运行 `--source from-di`。
