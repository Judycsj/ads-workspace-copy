<!-- ads-workspace-gdoc-sync: gdoc_id=1Q6bYRCiNO6R2lnpQyJXdlsV0SDlyN6XE-f_OadwIVuo gdoc_url=https://docs.google.com/document/d/1Q6bYRCiNO6R2lnpQyJXdlsV0SDlyN6XE-f_OadwIVuo/edit -->

# mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live

## Description

- **Desc:** 广告 Tracking 日志日表 (VIEW)。基于上游小时表 `mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live` 创建的日级 VIEW，按 `grass_region` 做时区转换（ID/TH/VN -> Asia/Jakarta, BR -> America/Araguaina, MX -> America/Mexico_City, CO -> America/Bogota, CL -> America/Santiago），将上游小时粒度的 `grass_date` + `h` 字段转换为本地日期的 `grass_date`。记录用户与广告的每一次交互事件（曝光、点击、加购、下单等），是广告效果归因、反欺诈、流量分析和 PCOC 校准的核心上游数据源。
- **Granularity:** daily x grass_region x event (event_timestamp)
- **Use Case:**
  - 流控超投检测（Search Ads flow control / overcharge detection）
  - ROI3 券流量漏斗分析（ROI3 voucher traffic funnel）
  - AB 实验效果基准表（request-level benchmark）
  - PCOC 校准（ROI2 predicted click over click）
  - 填充率分析（adstype fill rate）
  - 反欺诈识别（fraud detection）
- **Update Frequency:** Daily（VIEW，上游小时表持续写入）

## Key Metrics

- 交互量: impression_cnt, click_cnt（按 operation=1/2 统计）
- 扣费: deduction_price（从 internal.deduction_info 提取）, bid_deduction_price, voucher_deduction_price
- 算法预估: pCTR, pCR, pCVR (从 item_json_data JSON 提取)
- 广告券: item_voucher.display_ads_voucher_label, is_roi3_best_voucher

## Key Dimensions

- 分区: grass_region, grass_date
- 事件: operation (1=Impression, 2=Click, 3=View, 4=AddToCart, 5=PlaceOrder, 1001=ShopImpression, 1002=ShopClick)
- 广告: ads_id, campaign_id, ads_placement, pricing_type, ads_entrance, entrance
- 内容: item_id, shop_id, user_id, ads_request_id
- 反欺诈: fraud_type, duplicate_label

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | VIEW (基于上游表) |
| Partition Columns | 无 (VIEW，依赖上游 `grass_region`, `grass_date`) |
| HDFS Path | 无 (VIEW) |
| Retention | 无 (VIEW) |
| Column Count | ~115 |
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, MX, CO, CL |
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

- Studio Tasks References: 61 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
