<!-- ads-workspace-gdoc-sync: gdoc_id=13hMlkS5Yi5khfrxmWR-G5Lghf9jh_3cDXJdpmpfZY3s gdoc_url=https://docs.google.com/document/d/13hMlkS5Yi5khfrxmWR-G5Lghf9jh_3cDXJdpmpfZY3s/edit -->

# mp_order.dwd_order_item_all_ent_df

## Description

- **Desc:** 全量订单商品明细表（All Entities）。记录所有订单中每个商品项的详细信息，包括买家、卖家、商品、支付、优惠券补贴等维度。由 Data Infra 团队维护，是平台订单数据的基础底座表。
- **Granularity:** order_id x item_id（每行 = 一个订单中的一个商品项）
- **Use Case:**
  - ROI3 平台指标日报：提取平台订单信息，关联广告券和实验分组计算 Redeem/Cost 等指标
  - 广告券核销分析：关联 `dim_voucher` 识别 ADS-ROI 券，统计核销量和补贴成本
  - 订单-广告点击匹配：用 order_id/item_id/user_id 将订单数据关联到 `dwd_advertise_performance_di` 进行 CVR/Uplift 分析
  - 折扣率分析：计算广告券补贴金额与商品价格的折扣率，按实验分组比较
  - Take Rate / 收入计算：用于 Shop Take Rate 和店铺净收入计算
- **Update Frequency:** Daily

## Key Metrics

- 订单类: `order_cnt`（恒为 1，SUM 得订单数）, `gmv_usd`
- 优惠券补贴类: `net_sv_rebate_by_shopee_amt_usd`（卖家券补贴含广告券）, `pv_rebate_by_shopee_amt_usd`（平台券补贴）
- 金额类: `merchandise_subtotal_amt_usd`, `item_price_before_discount_pp_usd`, `order_price_pp_usd`
- 运费类: `actual_shipping_rebate_by_shopee_amt_usd`, `shipping_discount_by_3pl_to_seller_amt_usd`, `actual_shipping_rebate_by_seller_amt_usd`

## Key Dimensions

- 分区: `grass_date`, `grass_region`
- 订单: `order_id`, `buyer_id`, `seller_id`, `shop_id`
- 商品: `item_id`, `level1_global_be_category_id`
- 优惠券: `sv_promotion_id`, `pv_promotion_id`
- 时间: `create_datetime`, `pay_datetime`, `create_timestamp`
- 时区: `tz_type`（'local' / 'regional'）

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date, grass_region |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, TH, PH, VN, MY, TW, SG, BR |
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

- Studio Tasks References: 17 files (12 workflows + 5 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
