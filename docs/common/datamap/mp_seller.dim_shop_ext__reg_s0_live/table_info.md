<!-- ads-workspace-gdoc-sync: gdoc_id=1DTIyaZ-YylkclsFP5Np6V1rBeO7Z08CO1ttvCKK6TQg gdoc_url=https://docs.google.com/document/d/1DTIyaZ-YylkclsFP5Np6V1rBeO7Z08CO1ttvCKK6TQg/edit -->

# mp_seller.dim_shop_ext__reg_s0_live

## Description

- **Desc:** Shopee 卖家扩展维度表（dim_shop_ext），存储每个 shop 的扩展属性，包括卖家类型（CB/CNCB）、SIP 附属关系、CB shop 原始地区等信息。由 mp_seller 库维护，ads 团队作为读引用维度表使用。
- **Granularity:** shop level (one row per shop per day per region per timezone)
- **Use Case:**
  - 广告主维表构建：提供 seller_type、seller_type_1p、is_cb_sip_affiliated 字段，用于 dim_advertiser 表的生产
  - 净广告收入报表：JOIN on shop_id 补充 SIP 附属信息（is_cb_sip_affiliated, is_local_sip_affiliated）
  - Escrow 订单宽表：获取 shop 的 cb_shop_origin_region 和 is_cb_shop 标记
  - Take Rate 分析：补充 SIP 维度用于 take rate 计算（playground/实验场景）
- **Update Frequency:** Daily (分区表，按 grass_date 增量更新)

## Key Metrics

该表为维度表，不包含业务指标。主要提供以下维度的标识字段：

- 卖家身份类: is_cb_shop, cb_seller_type (CNCB), ggp_seller_name
- SIP 附属类: is_cb_sip_affiliated, is_local_sip_affiliated
- 地区来源类: cb_shop_origin_region

## Key Dimensions

- 分区: grass_region, grass_date, tz_type
- 业务主键: shop_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | - |
| DQC Status | - |
| Table Size | - |

## Business Properties

| Property | Value |
|----------|-------|
| Technical PIC | 未抓取 DataMap，请运行 --source from-di 补充 |
| Team | 未抓取 DataMap，请运行 --source from-di 补充 |
| Business Domain | 未抓取 DataMap，请运行 --source from-di 补充 |
| DW Layer | 未抓取 DataMap，请运行 --source from-di 补充 |

## Popularity

- Studio Tasks References: 15 files (12 workflow, 3 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
