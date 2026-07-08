<!-- ads-workspace-gdoc-sync: gdoc_id=1Df-JhLh0cafBjEXLgH6EmDLsqTmH93Qu8K29lrN-prQ gdoc_url=https://docs.google.com/document/d/1Df-JhLh0cafBjEXLgH6EmDLsqTmH93Qu8K29lrN-prQ/edit -->

# srdi_mart.dwm_sr_data_warehouse_dd_others_user_location

**分层：** DWM（数据仓库中间层）
**主键：** `grass_region` + `local_date` + `operation` + `user_id` + `feature_detail` + `location`
**分区：** `grass_region` / `local_date` / `operation`
**更新频率：** 每日（T+1）
**访问频次：** 235

---

## 业务描述

本表记录 Shopee 首页 **Daily Discover（每日发现）** 模块中，各类业务入口（食品外卖、保险、Banner、Campaign、数字商品、ShopeePay Near Me）在用户维度的**曝光、点击、订单**行为及对应 GMV，并关联用户生命周期标签。

**核心业务场景：**

- 分析 Daily Discover 各 Feature（food、insurance、banner、campaign、digital_product、shopeepay_near_me）的用户级漏斗：曝光 → 点击 → 下单
- 按用户生命周期（`life_cycle`）拆解各入口的运营效果
- 分区域（`grass_region`）统计 Daily Discover 各模块的 GMV 贡献
- 定位不同位置（`location`）的点击/曝光分布

**适合回答的问题：**

- 不同地区 Daily Discover 各模块每日的曝光 / 点击 / 下单人数及 GMV 是多少？
- 各用户生命周期阶段在 Daily Discover 中的行为差异如何？
- 首页 Daily Discover 各坑位（location）的点击表现如何？
- 食品外卖、保险、数字商品等模块分别带来了多少 GMV？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 国家/地区代码，如 ID、MY、TH、VN、PH 等 |
| `local_date` | date | 业务本地日期，数据统计口径日期 |
| `operation` | string | 行为类型：`impression`（曝光）、`click`（点击）、`order`（下单）、`ppv`（保险 PDP 浏览） |

### 维度：用户维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；VN 地区食品外卖通过 now_uid → shopee_uid 映射转换 |
| `life_cycle` | string | 用户生命周期标签，来源于 `dim_sr_data_warehouse_user_label` |
| `platform` | string | 用户所在平台，如 iOS、Android 等 |
| `app_version` | string | App 版本号 |

### 维度：行为维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | Daily Discover 功能入口标识，枚举值：`home-daily_discover-food`、`home-daily_discover-insurance`、`home-daily_discover-banner`、`home-daily_discover-campaign`、`home-daily_discover-digital_product`、`home-daily_discover-shopeepay_near_me` |
| `location` | int | 展示坑位编号；food 类从订单数据中通过正则提取，impression/click 来自平台事件流；insurance、banner、campaign、dp 类订单场景下为 NULL |

### 指标：行为量及 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `operation_cnt` | double | 行为次数：曝光/点击为事件计数（可累加）；订单场景为去重订单数（`COUNT(DISTINCT order_id)`），**不可与曝光/点击直接合并 SUM** |
| `gmv` | double | 以 USD 计的 GMV；impression/click 行为下为 NULL；订单行为下为各业务线本币 GMV 经汇率转换后的美元值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部指定**，否则将触发全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
    AND operation = 'click'
  ```
- 若需跨 `operation` 类型分析，建议显式枚举 `operation IN ('impression', 'click', 'order')`，避免漏读或混读保险 PDP 的 `ppv` 行为。

### 不可直接 SUM 的字段

| 字段 | 风险说明 |
|---|---|
| `operation_cnt`（order 场景） | 订单行为的 `operation_cnt` 来源于 `COUNT(DISTINCT order_id)`，已去重；与 impression/click 的行为计数语义不同，**不可跨 operation 合并 SUM** |
| `gmv` | impression/click 行为下为 NULL；跨 `feature_detail` 合并时需确认无重复归因（campaign 与 banner 的订单归因逻辑独立，food 与 dp 的 GMV 分别来自各自的订单表） |

### 时效性说明

- 本表为**每日全量覆写**（`INSERT OVERWRITE ... PARTITION`），每日产出 T-1 数据。
- 食品外卖 GMV 依赖汇率表 `dim_exchange_rate__reg_s0_live`，当日汇率缺失时 GMV 将为 NULL 或计算异常。
- 由于为 multi-writer（两个 ETL 文件分别写入），impression/click 数据与 order 数据**在同一分区下同时存在**，查询时务必通过 `operation` 分区字段区分。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 首页 Daily Discover 的曝光/点击事件明细；同时用于提取保险用户 platform/app_version 标签及保险点击用户池 |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户生命周期（life_cycle）标签维表 |
| `shopeefood.shopeefood_mart_dwd_id_traffic_external_direct_order_attribute_di` | ID 区食品外卖订单（Daily Discover 来源） |
| `shopeefood.shopeefood_mart_dwd_my_traffic_external_direct_order_attribute_di` | MY 区食品外卖订单 |
| `shopeefood.shopeefood_mart_dwd_th_traffic_external_direct_order_attribute_di` | TH 区食品外卖订单 |
| `shopeefood.shopeefood_mart_dwd_vn_traffic_external_direct_order_attribute_di` | VN 区食品外卖订单（需 now_uid → shopee_uid 映射） |
| `shopeefood.shopeefood_mart_cdm_dim_vn_buyer_now_shopee_mapping_da` | VN 区 Now 用户 ID 与 Shopee 用户 ID 映射 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 各地区汇率，用于将本币 GMV 换算为 USD |
| `fp_traffic.dws_traffic_insurance_entry_attribution_di` | 保险 PDP 访问归因，提取 Daily Discover 入口用户 |
| `insurance.dwd_spin_reg_policy_info_df` | 保险保单信息，统计 Daily Discover 带来的保单数量及 GMV |
| `digitalpurchase.traffic_dwd_dp_order_by_traffic_entrance_di_v2` | 数字商品及 ShopeePay Near Me 订单（Daily Discover 入口） |
| `mp_campaign.dwd_eventid_orderid_atc_place_microsite_di__reg_s0_live` | Campaign 订单归因明细 |
| `mp_campaign.dwd_eventid_pre_curr_next_view_microsite_di__reg_s0_live` | Campaign 事件 ID 前后页关联，用于判断是否来自 Daily Discover |
| `mp_campaign.dwd_eventid_orderid_atc_place_banner_di__reg_s0_live` | Banner 订单归因明细（DD Banner Card 1 / 27） |

---

## ETL 逻辑摘要

### 数据流

本表由**两个独立 ETL 文件**共同写入，分别负责不同 `operation` 分区：

```
ETL 1（impression_click）:
  dwd_sr_data_warehouse_platform
    └─ 过滤 home/daily_discover 曝光点击
    └─ 关联 dim_sr_data_warehouse_user_label（life_cycle）
    └─ INSERT OVERWRITE（operation = impression / click 分区）

ETL 2（order）:
  多来源食品外卖订单（ID/MY/TH/VN）─┐
  保险 PDP 访问 + 保单               ├─ order_merged（UNION ALL）
  数字商品/ShopeePay Near Me 订单   ─┤
  Campaign + Banner 订单            ─┘
    └─ 关联 dim_sr_data_warehouse_user_label（life_cycle）
    └─ 关联 fx_rate（汇率换算 GMV 为 USD）
    └─ INSERT OVERWRITE（operation = order / ppv 分区）
```

### 关键步骤

**ETL 1 — impression_click**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `imp_click_tracking_${grass_region}` | 从 `dwd_sr_data_warehouse_platform` 过滤 home/daily_discover 曝光点击，按 target_type 映射 feature_detail，按用户+平台+版本+feature_detail+location+operation 聚合 operation_cnt |
| Step 2 | `user_label_${grass_region}` | 从 `dim_sr_data_warehouse_user_label` 取当日用户 life_cycle 标签 |
| Step 3 | `INSERT OVERWRITE` | 将 Step 1 与 Step 2 LEFT JOIN，gmv 填 NULL，写入目标表 impression/click 分区 |

**ETL 2 — order**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `food_order_wo_vn` | 聚合 ID/MY/TH 三区食品外卖订单，提取 location（正则）、operation_cnt（去重订单数）、本币 GMV |
| Step 2 | `food_order_vn` | 聚合 VN 区食品外卖订单，user_id 字段为 now_uid |
| Step 3 | `vn_user_mapping` | VN now_uid → shopee_uid 映射 |
| Step 4 | `food_order_w_local_gmv` | VN 食品外卖 LEFT JOIN 映射后与非 VN UNION ALL，统一字段结构 |
| Step 5 | `fx_rate` | 取各地区当日汇率 |
| Step 6 | `food_order` | 本币 GMV / 汇率 → USD GMV |
| Step 7 | `insurance_pdp_view_raw` | 从保险归因表提取 Daily Discover 来源的 PDP 浏览事件，按用户取最早事件 rank |
| Step 8 | `insurance_pdp_view` | 筛选 from_source = 'Daily Discover' 且首次访问，operation = ppv |
| Step 9 | `policy` | 从 `dwd_sr_data_warehouse_platform` 取保险点击用户池，INNER JOIN 保单表，统计 order 数及保费 GMV（USD） |
| Step 10 | `insurance_order_raw` | ppv + order UNION ALL |
| Step 11 | `insurance_user_tag` | 从 `dwd_sr_data_warehouse_platform` 取保险用户的 platform/app_version |
| Step 12 | `insurance_order` | insurance_order_raw LEFT JOIN insurance_user_tag 补充 platform/app_version |
| Step 13 | `dp_loc_order` | 从数字商品订单表取 Daily Discover 来源的 dp/shopeepay_near_me 订单，GMV 换算 USD，feature_detail 由 dp_from_source 正则映射 |
| Step 14 | `campaign_banner_order` | 从 Campaign 微站订单归因 + Banner 订单归因取 Daily Discover 来源订单，聚合 order_cnt 及 GMV（USD） |
| Step 15 | `order_merged` | food + insurance + dp + campaign/banner UNION ALL，统一结构 |
| Step 16 | `user_label` | 从 `dim_sr_data_warehouse_user_label` 取全量地区当日 life_cycle 标签 |
| Step 17 | `INSERT OVERWRITE` | order_merged LEFT JOIN user_label，写入目标表 order/ppv 分区 |

### 注意事项

1. **Multi-writer 风险：** 两个 ETL 文件分别以 `INSERT OVERWRITE ... PARTITION` 写入不同 `operation` 分区（impression/click vs order/ppv）。若调度顺序或参数配置异常，可能导致一侧分区被另一侧覆盖，需确保两个 Job 的分区参数不重叠。
2. **VN 食品外卖 ID 映射：** VN 区使用 now_uid 而非 shopee_uid，若 `vn_user_mapping` 映射缺失，`user_id` 将为 NULL，导致该部分记录无法与用户标签关联。
3. **汇率缺失：** `fx_rate` 以 `FIRST(exchange_rate)` 取值，若当日汇率数据未就绪，食品外卖及数字商品 GMV 将计算异常（除以 NULL）。
4. **location 字段来源不一致：** impression/click 场景 location 来自事件流结构化字段；food order 场景通过 `regexp_extract(data, '"location":([0-9]+)', 1)` 从 JSON 串提取，类型需显式 CAST 为 INT；insurance、banner、campaign、dp 订单场景 location 为 NULL。
5. **Campaign 归因复杂度：** campaign_banner_order 依赖多表 JOIN 及事件 ID 链路追踪，归因窗口及 tz_type 设置对结果影响较大，需关注上游归因表的更新完整性。
6. **保险 policy 仅覆盖 ID/PH/MY/TH：** VN 等其他地区的保险订单暂不纳入统计范围。

---

*文档生成时间：2026-05-17*