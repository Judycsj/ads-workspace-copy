<!-- ads-workspace-gdoc-sync: gdoc_id=169otXHenFJ1EEL6D2hK05Q9ZeJitl9zWV3cvS6DihAs gdoc_url=https://docs.google.com/document/d/169otXHenFJ1EEL6D2hK05Q9ZeJitl9zWV3cvS6DihAs/edit -->

# mp_paidads.dws_shop_performance_1d__reg_s0_live

## Description

- **Desc:** Shop-level daily ads performance summary table. Aggregates per-shop order volume, GMV (total + ads-driven), ads expense (both day and MTD), take rate, and SKU-level ads penetration metrics. Serves as the foundation for CRM shop performance reporting.
- **Granularity:** daily x shop x grass_region (tz_type='local' only in production)
- **Use Case:**
  - CRM shop performance MTD reporting (feeds `ads_crm_shop_performance_mtd__reg_s0_live`)
  - Ads expense reconciliation against raw performance data (`dwd_advertise_performance_di`)
  - Shop-level take rate and ads penetration analysis
  - Regional ads expense daily summary
- **Update Frequency:** Daily (one workflow per region, 11 regions)

## Key Metrics

- **订单类:** total_order_cnt (count distinct order_id), checkout_cnt
- **GMV类:** total_gmv, shop_total_gmv_mtd, direct_ads_gmv, broad_ads_gmv
- **广告消耗类:** ads_expense (= expenditure_amt_local + display_ads_expense), ads_expense_mtd
- **比率类:** take_rate_mtd (= ads_expense_mtd / shop_total_gmv_mtd) (NOT summable), sku_with_ads_expense_ratio_mtd (= sku_with_ads_expense_mtd / active_item_cnt) (NOT summable)
- **SKU渗透类:** sku_with_ads_expense_mtd, sku_with_ads_expense_search_mtd, sku_with_ads_expense_discovery_mtd
- **商品数:** active_item_cnt (snapshot from dws_shop_listing_td)

## Key Dimensions

- **分区:** grass_date, grass_region, tz_type
- **主键:** shop_id
- **地域:** 11 regions (ID, MY, PH, SG, TH, TW, VN, BR, CO, CL, MX)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | PARQUET |
| Partition Columns | tz_type, grass_region, grass_date |
| HDFS Path | ${HIVE_PATH}/dws_shop_performance_1d__reg_s0_live |
| Retention | - |
| Column Count | 17 |
| Region Coverage | 11 regions (ID, MY, PH, SG, TH, TW, VN, BR, CO, CL, MX) |
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

- Studio Tasks References: 22 files (11 write + 11 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
