<!-- ads-workspace-gdoc-sync: gdoc_id=1kugZom3WDnox7F8S09y7GXPe7--nAp4JVu1qxtksk_w gdoc_url=https://docs.google.com/document/d/1kugZom3WDnox7F8S09y7GXPe7--nAp4JVu1qxtksk_w/edit -->

# mp_mgmt.dws_order_item_rebate_di__reg_s0_live

## Description

- **Desc:** 订单商品级别的 rebate/Promotion Reimbursement (PRM) 明细表，记录每笔订单商品的各类促销返利估算金额（item voucher + logistics + card + voucher + coin 的净额），用于 PC2 (Profit Contribution 2) 计算中的成本/返利部分。
- **Granularity:** daily x order_item x model x group x bundle_order_item x grass_region
- **Use Case:**
  1. PC2 流水线 (dws_user_pc2_1d): 作为 `rebate_base` 与 `dws_order_item_rev_di` 和 `dwd_order_item_atc_journey_di` JOIN，计算用户级 PC2
  2. Common Feature PC2 (dws_common_feature_user_item_pc2_1d): 同上但追加 common_feature 维度
  3. 数据校验: playground 中用于对比 target output 与上游源表的 commission/rebate 金额
- **Update Frequency:** Daily (推断自上游 dws_order_item_rev_di 的调度频率)

## Key Metrics

- 返利类: estimate_net_total_item_voucher_logst_prm_usd_level1, estimate_net_total_logst_prm_usd_level1, estimate_net_total_item_card_prm_usd_level1, estimate_net_total_voucher_prm_usd_level1, estimate_net_total_coin_prm_usd_level1

## Key Dimensions

- 分区: grass_date, grass_region
- 主键: order_id, item_id, model_id, group_id, bundle_order_item_id
- 过滤: is_bi_excluded_rev_prm

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX (9 standard regions) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 41 files (33 workflow + 8 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -
