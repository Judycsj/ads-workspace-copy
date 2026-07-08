<!-- ads-workspace-gdoc-sync: gdoc_id=1wOluKMj7Zdq642tG6KwfhgrcAeVA4-m0fjWK3VADErM gdoc_url=https://docs.google.com/document/d/1wOluKMj7Zdq642tG6KwfhgrcAeVA4-m0fjWK3VADErM/edit -->

# srdi_mart.dws_sr_data_warehouse_rcmd_ads_user_item_location_1d

**分层：** DWS（数据汇总层）
**主键：** `user_id` + `item_id` + `common_feature` + `type` + `location` + `is_roi2` + `main_product_type` + `product_type` + `sub_product_type` + `card_type` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）, `local_date`（业务本地日期）
**更新频率：** 每日一次（T+1，按分区 INSERT OVERWRITE）
**访问频次：** 625 次

---

## 业务描述

本表是 SRDI 搜推数仓推荐广告（Ads）域的用户-商品-位置日粒度宽表，聚合了推荐场景下广告与自然流量的全链路行为指标。

**核心业务场景：**
- **广告效果分析：** 统计推荐各入口（Daily Discover、You May Also Like、购物车推荐等）的广告曝光、点击、订单及 GMV 表现，支持 ROI 分析。
- **Import Search 归因：** 量化搜索广告对推荐场景（尤其是 Daily Discover）的 GMV 及收入贡献，支持跨渠道归因分析。
- **Omni 全链路指标：** 融合入口卡片（entry）与商品详情（item）两级曝光/点击，以及订单/GMV 的广告 vs. 自然流量拆分，支持漏斗分析。
- **AB 实验评估：** 关联用户实验分组（`exp_group_ids`），支持实验粒度的推荐广告效果对比。
- **商品广告标记：** 通过 `if_ads_item` 标识商品是否为广告商品，支持广告商品与自然商品的分桶分析。

**适合回答的问题举例：**
- 某大区/某日 Daily Discover 广告的曝光量、点击率、直接 GMV 分别是多少？
- ROI2 广告位（placement=40）与非 ROI2 广告位的转化对比如何？
- 某商品在 YMAL 场景下，广告 vs. 自然流量的订单量和 GMV 分别为多少？
- 搜索广告通过推荐入口带来的 Import GMV 是多少？
- 各实验组用户在推荐场景下的广告效果差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `SG`、`MY`、`PH` 等，每个分区对应一个大区 |
| `local_date` | date | 业务本地日期（local timezone），ETL 按此字段分区写入 |

### 维度：用户与商品

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；仅保留 `user_id > 0` 的有效用户 |
| `item_id` | bigint | 商品 ID；原始为 NULL 时填充 `-1` |
| `exp_group_ids` | array\<int\> | 用户所属 AB 实验分组 ID 列表，来源于 `dim_sr_data_warehouse_abtest_user_group`，同一用户可属于多个实验组 |

### 维度：推荐场景与入口

| 字段 | 类型 | 说明 |
|---|---|---|
| `common_feature` | string | 推荐场景名称，枚举值：`Daily Discover`、`You May Also Like`、`Cart Recommendation`、`Order Successful Recommendation`、`Order Detail Page Recommendation`、`My Purchase Page Recommendation` |
| `type` | string | 场景内流量来源子类型。`all` 表示全量；Daily Discover 下细分：`external`（DD 外流/卡片入口）、`mixfeed_internal_organic_entrance`（MixFeed 内流自然）、`mixfeed_internal_ads_entrance`（MixFeed 内流广告）；其他场景默认为 `all` |
| `location` | bigint | 推荐位置坑位编号；NULL 填充 `-1`；Daily Discover `all` 类型下该字段为 NULL（坑位不做区分） |
| `card_type` | string | 卡片类型，枚举值：`item card`、`video card`、`mix feed card`、`others` |
| `is_roi2` | int | 是否为 ROI2 广告位（placement=40）；`1` 表示是，`0` 表示否 |
| `if_ads_item` | int | 商品是否为广告商品；`1` 表示是（来源于 `dws_advertise_user_exp_common_feature_performance_1d`），`0` 表示否 |

### 维度：广告产品分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `main_product_type` | string | 广告主产品类型，来源于 `dim_advertise`；无法匹配时填充 `others` |
| `product_type` | string | 广告产品类型，来源于 `dim_advertise`；无法匹配时填充 `others` |
| `sub_product_type` | string | 广告子产品类型，来源于 `dim_advertise`；无法匹配时填充 `others` |

### 指标：广告直接行为（Ads Direct）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告曝光次数（来源：`dwd_advertise_performance_di`，含 entrance 3/31/32/4/8/9/10/11） |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `ads_order_cnt` | double | 广告直接带来的订单数 |
| `ads_direct_gmv_usd` | double | 广告直接 GMV（USD），由 `ads_order_gmv_local / exchange_rate` 换算 |
| `ads_broad_gmv_usd` | double | 广告宽口径 GMV（USD），由 `broad_gmv_amt_local / exchange_rate` 换算，含归因窗口内的间接成交 |
| `ads_revenue_usd` | double | 广告消耗/收入（USD），由 `expenditure_amt_local / exchange_rate` 换算 |

### 指标：Import Search 归因（跨渠道）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_import_search_revenue` | double | 搜索广告通过推荐入口带来的广告收入（USD），适用于 Daily Discover、YMAL 等场景 |
| `ads_import_search_gmv` | double | 搜索广告通过推荐入口带来的直接 GMV（USD） |
| `ads_import_search_broad_gmv` | double | 搜索广告通过推荐入口带来的宽口径 GMV（USD） |
| `omni_import_search_gmv` | double | Omni 全链路口径下，搜索对推荐场景的 Import GMV（USD），来源于 `dwd_sr_data_warehouse_platform` 中 `reporting_object='search'` 或 `feature_detail` 含搜索标记的订单 |

### 指标：Omni 入口卡片（Entry）曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_entry_impr_cnt` | bigint | Omni 入口卡片总曝光次数（广告 + 自然） |
| `omni_entry_impr_ads_cnt` | bigint | Omni 入口卡片广告曝光次数 |
| `omni_entry_impr_organic_cnt` | bigint | Omni 入口卡片自然曝光次数 |
| `omni_entry_click_cnt` | bigint | Omni 入口卡片总点击次数（广告 + 自然） |
| `omni_entry_click_ads_cnt` | bigint | Omni 入口卡片广告点击次数 |
| `omni_entry_click_organic_cnt` | bigint | Omni 入口卡片自然点击次数 |

### 指标：Omni 商品（Item）曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_item_impr_cnt` | bigint | Omni 商品级别总曝光次数（广告 + 自然） |
| `omni_item_impr_ads_cnt` | bigint | Omni 商品级别广告曝光次数 |
| `omni_item_impr_organic_cnt` | bigint | Omni 商品级别自然曝光次数 |
| `omni_item_click_cnt` | bigint | Omni 商品级别总点击次数（广告 + 自然） |
| `omni_item_click_ads_cnt` | bigint | Omni 商品级别广告点击次数 |
| `omni_item_click_organic_cnt` | bigint | Omni 商品级别自然点击次数 |

### 指标：Omni 订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_order_cnt` | double | Omni 全链路总订单数（广告 + 自然） |
| `omni_ads_order_cnt` | double | Omni 全链路广告订单数 |
| `omni_organic_order_cnt` | double | Omni 全链路自然订单数 |
| `omni_gmv_usd` | double | Omni 全链路总 GMV（USD，广告 + 自然） |
| `omni_ads_gmv_usd` | double | Omni 全链路广告 GMV（USD） |
| `omni_organic_gmv_usd` | double | Omni 全链路自然 GMV（USD） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 是复合分区键，查询时**必须同时指定**，否则将触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'SG' AND local_date = '2024-01-01'
  ```
- `local_date` 类型为 `date`，传参时注意类型匹配，避免隐式类型转换导致分区裁剪失效。
- `common_feature` 与 `type` 组合定义了业务语义，通常需配合过滤，防止重复计算：
  - 若仅需全量场景汇总，过滤 `type = 'all'`；
  - 若需分析 Daily Discover 细分流量，按 `type IN ('external', 'mixfeed_internal_organic_entrance', 'mixfeed_internal_ads_entrance')` 过滤。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `exp_group_ids` | array 类型，表示用户的实验分组列表，需先 EXPLODE 展开后再聚合 |
| `ads_direct_gmv_usd` / `ads_broad_gmv_usd` / `ads_revenue_usd` | 已由本地货币按汇率换算为 USD，跨大区不可直接 SUM（汇率口径不同） |
| `omni_gmv_usd` / `omni_ads_gmv_usd` / `omni_organic_gmv_usd` | 同上，跨大区不可直接 SUM |
| `omni_order_cnt` / `omni_ads_order_cnt` / `omni_organic_order_cnt` | 类型为 double，含 Omni 归因逻辑，勿与 `ads_order_cnt`（bigint）混用直接求和 |
| `if_ads_item` | 通过 `MAX` 聚合得出（ETL 中为 `max(if(T3.item_id is not null, 1, 0))`），作为商品级别标记使用，不应对用户粒度直接 SUM |

### 时效性说明

- 本表为 **1d（日粒度）** 表，`local_date` 分区每日 INSERT OVERWRITE 写入，代表该大区本地时区当日汇总数据。
- 数据通常在 T+1 产出，不适用于实时/准实时场景。
- 表内所有金额指标均以 **USD** 结算，汇率取自 `dim_exchange_rate__reg_s0_live`（`first(exchange_rate)`），单日汇率固定，跨日对比时汇率可能存在差异。

### 指标口径区分说明

- **`ads_*` 系列**：来源于广告系统（`dwd_advertise_performance_di`），口径为广告平台记录的曝光/点击/订单/GMV，属于**广告侧口径**。
- **`omni_entry_*` 系列**：来源于流量日志（`dwd_scenario_event_log_di`），记录的是**入口卡片层**的行为，Daily Discover 下不区分坑位（location 为 null）。
- **`omni_item_*` 系列**：来源于平台宽表（`dwd_sr_data_warehouse_platform`），记录的是**商品详情层**的 omni 行为（omni_impression、omni_click）。
- **`import_search_*` 系列**：衡量搜索广告对推荐场景的跨渠道 GMV 贡献，需结合 `ad_item` 的 entrance 信息做 join 归因，口径较特殊，不等同于推荐场景本身的 GMV。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细日志，提供广告曝光、点击、订单、GMV、消耗、entrance、search_entrance 等核心广告指标 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表，提供 ads_id 到 placement、main_product_type、product_type、sub_product_type 的映射 |
| `mp_paidads.dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live` | 广告商品标记汇总表，用于判断 item 是否为广告商品（`if_ads_item`） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供本地货币到 USD 的汇率，每日取 `first(exchange_rate)` |
| `traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live` | 流量场景事件日志，提供 omni 维度的入口卡片曝光、点击行为（impression/click），含 is_ads、feature、feature_group 等字段 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | SRDI 平台宽表，提供 omni_impression、omni_click、order 操作的商品级行为数据，含 source1/source2 多级归因链路 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | AB 实验用户分组维表，提供用户的实验分组信息（`exp_group_ids`） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di  ──┐
mp_paidads.dim_advertise                  ──┤
mp_order.dim_exchange_rate                ──┤──► 广告直接指标 (paidads_all_result)
mp_paidads.dwd_advertise_performance_di  ──┘    含 import_search 归因

traffic_omni_oa.dwd_scenario_event_log_di ──┐
srdi_mart.dwd_sr_data_warehouse_platform   ──┤──► Omni 全场景指标 (omni_all_final_result)
                                            │    含 entry/item 曝光点击 + 订单 GMV

srdi_mart.dwd_sr_data_warehouse_platform   ──►  DD external/mixfeed 细分指标
                                                (omni_dd_external_mixfeed_final_result)

srdi_mart.dim_sr_data_warehouse_abtest_user_group ──► 实验分组 (user_exp_data)
mp_paidads.dws_advertise_user_exp_...             ──► 广告商品标记 (filtered_paidads)

以上结果 UNION ALL 后 JOIN 实验分组与广告商品标记
──► INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_rcmd_ads_user_item_location_1d
```

### 关键步骤

| 步骤 | Temporary View / Cache Table | 说明 |
|---|---|---|
| 1 | `fx_rate` | 从汇率维表取当日大区汇率（`first(exchange_rate)`），用于金额 USD 换算 |
| 2 | `dim_ads`（cached） | 从广告维表取 ads_id → placement/product_type 映射，ROW_NUMBER 去重（保留 placement 最大行）；对 ads_id 为 NULL/-1/0 的加盐处理（`salted_ads_id`）防止数据倾斜 |
| 3 | `dwd_ads`（cached） | 从广告明细表取 placement=40（ROI2）的 request_id 级别记录，用于后续 omni 维度 is_roi2 判断 |
| 4 | `tmp_dwd_paidads_detail` | 过滤指定 entrance（3/31/32/4/8/9/10/11），提取广告明细，生成 card_type 分类 |
| 5 | `paidads_part_results` | 对 paidads 明细按 (user_id, item_id, common_feature, type, location, is_roi2, ads_id, card_type) 聚合，生成广告直接指标；`type='all'` 为全量，`type` 细分仅限 Daily Discover entrance（3/31/32） |
| 6 | `ad_item`（cached） | 从广告明细取有曝光的商品列表，按 entrance 分组，用于 import_search 归因 join 键 |
| 7 | `dwd_advertise_performance`（cached） | 取 entrance=1（搜索广告）且 search_entrance 在指定推荐入口范围内的记录，换算为 USD，作为 import_search 归因的广告侧数据源 |
| 8 | `dws_import_search_revenue` | 将 `ad_item` 与 `dwd_advertise_performance` 按 item_id join，按 common_feature 和 type 分 8 个 UNION ALL 分支归因，生成各场景 import_search 收入与 GMV |
| 9 | `paidads_all_result` | 合并 paidads_part_results（广告直接行为）与 dws_import_search_revenue（import_search 归因），join dim_ads 补充产品类型，聚合为广告侧最终结果 |
| 10 | `omni_entry_all_type_imp_click` | 从 `dwd_scenario_event_log_di` 取入口卡片曝光/点击，join `dwd_ads` 判断 is_roi2，join `dim_ads` 补充产品类型；type 固定为 `all`，Daily Discover 下 location 置 null |
| 11 | `omni_item_all_type_imp_click_order` | 从 `dwd_sr_data_warehouse_platform` 取 step0/step1/step2 三级归因链路（支持多 source 归因），聚合 omni_impression/omni_click/order 的商品级别指标，含 import_gmv 计算 |
| 12 | `omni_all_final_result` | UNION ALL 合并 omni_entry 和 omni_item 两条数据流，聚合为全场景 Omni 指标 |
| 13 | `omni_dd_entry_imp_click` | Daily Discover 专用：从 `dwd_scenario_event_log_di` 取 scenario_event_type 为 card_impression/card_click/button_click 的事件，生成 type=external 的 entry 曝光点击 |
| 14 | `omni_dd_item_imp_click` | Daily Discover MixFeed 内流：从 `dwd_sr_data_warehouse_platform` 取 source1_page_section=daily_discover、source1_target_type=item_mix_feed_card 的视频页商品行为，生成 type=mixfeed_internal 的 item 曝光点击 |
| 15 | `dd_all_order` / `dd_internal_order` | Daily Discover 订单归因：`dd_all_order` 取 DD 触发的全量订单，`dd_internal_order` 取 MixFeed 内流触发的订单 |
| 16 | `dd_mixfeed_final_order_gmv` | 外流订单 = `dd_all_order` - `dd_internal_order`（按 location 匹配扣减），MixFeed 内流订单直接取，两者 UNION ALL 后聚合为 DD external/mixfeed 的订单 GMV |
| 17 | `omni_dd_external_mixfeed_final_result` | 合并 DD external/mixfeed 的 entry 曝光点击、item 曝光点击、订单 GMV，join dim_ads 和 dwd_ads 补充维度，聚合为 DD 细分流量最终结果 |
| 18 | `user_exp_data` | 从 AB 实验维表 collect_list 聚合用户实验分组列表 |
| 19 | `filtered_paidads` | 从广告汇总表取 if_ads_item=1 的 (common_feature, item_id) 列表，用于 BROADCAST JOIN 标记广告商品 |
| 20 | **INSERT OVERWRITE** | 将 paidads_all_result、omni_all_final_result、omni_dd_external_mixfeed_final_result 三路 UNION ALL，LEFT JOIN user_exp_data（补实验分组）和 filtered_paidads（标记广告商品，BROADCAST），最终聚合写入目标分区 |

### 注意事项

1. **单文件单写入：** 本表无 multi-writer，ETL 由单一 SQL 文件驱动，按 `(grass_region, local_date)` 分区执行 INSERT OVERWRITE，重跑同一分区会完整覆盖。
2. **`type` 字段与 `location` 组合存在特殊规则：** Daily Discover `type='all'` 时 `location` 为 NULL（ETL 中强制置 null），因此对 Daily Discover 全量汇总不能依赖 `location` 做坑位维度分析，需使用 `type IN ('external', 'mixfeed_internal_*')` 的细分行。
3. **salted_ads_id 防倾斜：** ads_id 为 NULL、-1 或 0 时会随机加盐（`CAST(FLOOR(RAND() * 20) AS STRING)` 后缀），导致同一 null ads_id 会 join 到不同的 dim_ads 行（实际均为 NULL 不匹配），这是有意设计，避免广告 id 缺失时导致 join 倾斜。
4. **货币换算口径：** 所有金额指标均已换算为 USD，汇率使用当日大区的 `first(exchange_rate)`，不同日期的汇率存在差异，跨日期 SUM 金额时需注意汇率波动影响。
5. **DD 订单外流扣减逻辑：** `dd_mixfeed_final_order_gmv` 中外流订单通过"全量 - 内流"方式计算，若 `dd_all_order` 与 `dd_internal_order` 的 location join 条件不精确，可能导致外流订单出现负数，查询时需注意该字段的数据质量。
6. **`omni_order_cnt` 类型为 double：** 来源于 `dwd_sr_data_warehouse_platform` 的 `operation_cnt`（double），与 `ads_order_cnt` 的 bigint 类型不同，混用时注意精度问题。

---

*文档生成时间：2026-05-17*