<!-- ads-workspace-gdoc-sync: gdoc_id=1PAX91s_os2U6NL6v6anmQquR7GSKhPkafuOJLdlckwA gdoc_url=https://docs.google.com/document/d/1PAX91s_os2U6NL6v6anmQquR7GSKhPkafuOJLdlckwA/edit -->

# mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live

## Description

- **Desc:** ODS-layer raw ads tracking log table, recording all client-side ad tracking events (impressions, clicks, views, add-to-cart, place-order, shop impressions/clicks, banner events, video events). Data is ingested directly from the ads tracking SDK with Parquet schema merge enabled. This is the primary source-of-truth for all downstream DWD tracking tables.
- **Granularity:** hourly x region (one row per tracking event per user per timestamp)
- **Use Case:** Source table for DWD-layer ad tracking ETL (dwd_advertise_tracking_item_hi, dwd_advertise_tracking_shop_hi, dwd_advertise_tracking_view_item_hi, dwd_advertise_tracking_atc_item_hi); ad hoc event-level debugging; raw tracking log exploration for QA; video ads tracking analysis
- **Update Frequency:** Hourly (partition per hour per region)

## Key Metrics

This is a raw event log table - no pre-aggregated metrics. Key fields extracted by downstream:
- Deduction info: `items[].internal.deduction_info.deduction_price`, `items[].internal.deduction_info.bidprice`
- Product card pricing: `items[].product_card.price`, `items[].product_card.price_before_discount`
- Add-to-cart: `items[].add_cart_amount`, `items[].add_cart_price`
- CPM: `items[].internal.cpm_deduction_info.cpm`

## Key Dimensions

- Partition: `grass_date`, `grass_region`, `h` (hour)
- Event: `operation` (1=Impression, 2=Click, 3=View, 4=AddToCart, 5=PlaceOrder, 1001=ShopImpression, 1002=ShopClick, 6=CloseBanner, 7/8/9/10=Report, 17=ShopItemImpression, 18=MoreShopClick)
- Placement: `placement` (top-level), `items[].internal.deduction_info.placement` (ads placement)
- Platform: `platform` (1=IOS_WEB, 2=IOS_APP, 3=ANDROID_WEB, 4=ANDROID_APP, 5=PC_MALL, 6=IOS_LITE, 7=ANDROID_LITE, 9=ANDROID_APP_LITE, 99=XIAPI, 128=OTHERS)
- Entrance: `entrance`, `sub_entrance`
- User: `userid`, `sessionid`, `deviceid`
- Item: `items[].itemid`, `items[].shopid`, `items[].adsid`, `items[].campaignid`
- Shop: `shops[].shopid`
- Search: `search_props.scenario`, `search_props.search_entrance`, `search_props.search_mid`
- Video: `video_props.current_page`, `video_props.content_type`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet (spark.sql.parquet.mergeSchema = true) |
| Partition Columns | `grass_region` (string), `grass_date` (date), `h` (int) |
| HDFS Path | `hdfs://R2/projects/mkplpaidads_data/hdfs/prod/operation_data/ads_tracking_parquet` |
| Retention | 30d (partition.retention.period) |
| Column Count | ~40 top-level columns (with deeply nested struct/array sub-fields) |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |

## Popularity

- Studio Tasks References: 160 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
