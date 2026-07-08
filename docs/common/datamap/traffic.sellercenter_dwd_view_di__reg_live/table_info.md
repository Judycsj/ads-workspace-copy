<!-- ads-workspace-gdoc-sync: gdoc_id=1jqhw6aFHHre9cL5ZurbbtkUQgFh1TV2Y0LQ-2L3zMRo gdoc_url=https://docs.google.com/document/d/1jqhw6aFHHre9cL5ZurbbtkUQgFh1TV2Y0LQ-2L3zMRo/edit -->

# traffic.sellercenter_dwd_view_di__reg_live

## Description

- **Desc:** Seller Center PC Web 端页面浏览（View）事件日志表，记录卖家在 Shopee Seller Center 各页面的访问行为。数据来源于前端埋点上报，每条记录代表一次页面浏览事件（PV），包含页面类型(page_type)、访问时间戳(event_timestamp)、来源页面(source_page_id)、前端加载性能耗时(module_to_enter/enter_to_mounted/module_to_mounted)等信息。属于 traffic 域的 ODS/DWD 层基础埋点表，是 Seller Center 流量分析的核心数据源。
- **Granularity:** daily x region x user x event（每行 = 一次页面浏览事件）
- **Use Case:**
  1. **导航栏 Click-to-View 时延分析** — 计算卖家点击侧边导航栏后落地页浏览的时间差（3s/5s/10s/30s），评估导航响应速度
  2. **广告页面访问来源分布** — 分析 Ads Homepage / Top-up / Product Creation / Reward Center 等广告页面的 source_page_id 来源分布，追踪卖家进入广告功能的路径
  3. **前端页面加载性能监控** — 通过 module_to_enter / enter_to_mounted / module_to_mounted 三阶段耗时，监控各页面分区域、分桶的加载性能
  4. **充值漏斗转化分析** — 追踪从充值页面浏览(Top-up Page) → checkout → 充值成功 的完整转化漏斗
  5. **Seller Center 全站页面浏览分析** — 覆盖 Order/Product/Marketing/Customer Service/Finance/Data/Shop 等各模块页面的浏览行为
- **Update Frequency:** Daily (T+1)

## Key Metrics

- **浏览指标:** PV（页面浏览量），UV（COUNT DISTINCT shop_id / user_id）
- **性能指标:** module_to_enter_time（模块加载到进入耗时）、enter_to_mounted_time（进入到挂载耗时）、module_to_mounted_time（模块加载到挂载总耗时）、P50/P90 分位数、3s/5s 达标率
- **时延指标:** 浏览时间戳与点击时间戳的时间差（3s/5s/10s/30s 窗口命中数及命中率）
- **漏斗指标:** 充值页面浏览数 → checkout 到达数 → 充值成功数，各步骤转化率
- **来源指标:** source_page_id 分布、entry_point 占比、source_page_id 缺失率

## Key Dimensions

- **分区:** grass_date, grass_region
- **页面类型:** page_type（seller_center_shopee_ads / seller_center_top_up / seller_center_value_added_service_checkout / seller_center_product_ad_detail / seller_center_create_product_ads / seller_center_shop_ad_detail / seller_center_create_shop_ads / seller_center_livestream_ad_detail / seller_center_create_display_ads / seller_center_shopee_ads_rewards_page / seller_center_my_order / return_refund_list 等多种 Seller Center 页面）
- **时区:** tz_type（固定 local）
- **来源:** source_page_id（JSON 字段 data.source_page_id，1-11 枚举对应不同入口）
- **实体:** shop_id, user_id, event_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | -（未在代码库中找到 DDL，请运行 --source from-di 补充）|
| Partition Columns | grass_date, grass_region（从 WHERE 子句推断）|
| HDFS Path | -（未在代码库中找到 DDL）|
| Retention | -（未在代码库中找到 DDL）|
| Column Count | -（未在代码库中找到 DDL）|
| Region Coverage | ID, MY, PH, SG, TH, TW, VN, BR, OTHER（从 WHERE 过滤条件推断）|
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

- Studio Tasks References: 19 files (19 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
