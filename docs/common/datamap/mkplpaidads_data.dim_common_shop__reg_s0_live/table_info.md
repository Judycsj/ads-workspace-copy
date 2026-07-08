<!-- ads-workspace-gdoc-sync: gdoc_id=18d6osyf6pSbPpfYQCpoRuVnYbASHC0WDDsAqb8bZwqM gdoc_url=https://docs.google.com/document/d/18d6osyf6pSbPpfYQCpoRuVnYbASHC0WDDsAqb8bZwqM/edit -->

# mkplpaidads_data.dim_common_shop__reg_s0_live

## Description

- **Desc:** 通用店铺维度视图，从 dim_fp_shop 抽取标准化店铺属性字段，按 region 分流 (regional / us_east)。提供店铺基础信息、店主关系、评分统计、销售数据、发货地等维度的统一口径，供 Ads 各产品线 (Search/Discovery/Brand/Display) 作为店铺维表 JOIN。
- **Granularity:** daily x grass_region x shop_id
- **Use Case:**
  - ShopID-to-UserID 映射 (广告主信用/扣款流水，构建 shop↔user 关联)
  - 店铺状态过滤 (活跃/非活跃店铺选取：`status = 1`)
  - 店铺元信息增强 (通过 shop_id + grass_region JOIN 获取 sold_cnt, creation_date 等)
  - 冷启动/成熟店铺分层 (基于 create_timestamp 与日期比较分类)
  - 店铺分地域分析 (按 grass_region 维度聚合)
- **Update Frequency:** Daily

## Key Metrics

- 店铺规模类: sold_total_cnt (累计销量), item_cnt (在售商品数), shop_follow_cnt (店铺关注数)
- 评分质量类: rating_good_cnt, rating_normal_cnt, rating_bad_cnt, rating_star, rating_count
- 服务质量类: response_rate (回复率), response_time (回复时间), cancellation_rate (取消率)
- 履约质量类: fulfillment_rate_flag (履约率标记), late_shipment_rate_flag (延迟发货率标记)
- 店铺属性类: is_official_shop (官方店), is_shopee_verified (优选卖家), is_star_seller (星卖家), cb_option (跨境选项)

## Key Dimensions

- 分区: dt, grass_region
- 店铺标识: shop_id (PK per region)
- 店主: user_id, user_name
- 状态: status
- 位置: latitude, longitude, pick_up_address
- 标记: is_official_shop, is_shopee_verified, is_star_seller, is_auto_reply_on, is_ship_from_overseas, has_order, has_decoration
- 标签: label_ids

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | VIEW (CREATE OR REPLACE VIEW, based on mkplpaidads_data.dim_fp_shop) |
| Partition Columns | dt (string) |
| HDFS Path | N/A (VIEW, no physical storage) |
| Retention | N/A (VIEW, depends on upstream dim_fp_shop) |
| Column Count | 34 |
| Region Coverage | 8 standard regions (SG, MY, PH, TW, TH, ID, VN, BR) via `regional` mk_type; US via `us_east` mk_type |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 57 files (2 write, 55 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
