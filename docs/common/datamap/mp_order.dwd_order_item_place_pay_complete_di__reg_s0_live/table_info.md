<!-- ads-workspace-gdoc-sync: gdoc_id=1SnY0LkXuloD39W4aYwMYEayFm5l-9h39c8ofPvIHdQI gdoc_url=https://docs.google.com/document/d/1SnY0LkXuloD39W4aYwMYEayFm5l-9h39c8ofPvIHdQI/edit -->

# mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live

## Description

- **Desc:** Order item-level detail table (DWD layer) from the Order domain, containing placed/paid/completed order items with financial details including GMV, seller GMV, commission fees, rebates, and shipping costs. Provides the single source of truth for platform order volume and GMV metrics at order-item granularity.
- **Granularity:** daily x order_id x item_id x model_id x region
- **Use Case:** Platform GMV calculation, Take Rate denominator, AB test outlier labeling (buyer GMV percentile), Shop performance aggregation (total orders/GMV), Feature generation (paid order count, item price), Data quality validation (ads GMV vs order GMV comparison), CRM shop metrics
- **Update Frequency:** Daily

## Key Metrics

- GMV: gmv, gmv_usd, seller_gmv, seller_gmv_usd
- Commission: commission_fee, commission_fee_usd
- Volume: item_amount (items sold count), order_id (COUNT DISTINCT for order count)
- Price components: merchandise_subtotal_amt_usd, order_price_pp, order_price_pp_usd
- Rebates (seller): sv_rebate_by_seller_amt, pv_rebate_by_seller_amt, sv_coin_earn_by_seller_amt, pv_coin_earn_by_seller_amt
- Rebates (shopee): sv_rebate_by_shopee_amt, pv_rebate_by_shopee_amt, item_rebate_by_shopee_amt, card_rebate_by_shopee_amt, card_rebate_by_bank_amt
- Fees: gross_buyer_service_fee, buyer_paid_shipping_fee, actual_buyer_paid_shipping_fee, insurance_premium_by_buyer_amt, buyer_txn_fee, coin_used_cash_amt

## Key Dimensions

- Partition: grass_date, grass_region, tz_type
- Business: shop_id, item_id, model_id, buyer_id, order_id
- Flags: is_placed, is_bi_excluded, is_cod_order, add_on_deal_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type (string), grass_region (string), grass_date (date) |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL (also per-region sharded tables: `dwd_order_item_place_pay_complete_di__${region}_s0_live`) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | Order |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 254 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
