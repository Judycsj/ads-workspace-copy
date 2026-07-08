<!-- ads-workspace-gdoc-sync: gdoc_id=1TZ7_y06krCHmwUsskYMwllAQxzSJPmd1aOCeuaQm45U gdoc_url=https://docs.google.com/document/d/1TZ7_y06krCHmwUsskYMwllAQxzSJPmd1aOCeuaQm45U/edit -->

# srdi_mart.dwm_sr_data_warehouse_homepage_other_user

**分层：** DWM（数据集市中间层）
**主键：** `user_id` + `module` + `operation` + `grass_region` + `local_date`
**分区：** `grass_region` / `local_date` / `operation`
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE`，按分区写入）
**引用频次/访问频次：** 145

---

## 业务描述

本表记录 Shopee 首页各非主流量入口模块（Other 模块）在**用户粒度**下的曝光、点击及下单行为数据，覆盖东南亚及台湾主要站点（VN、TW、TH、PH、SG、MY、ID）和非亚洲地区站点。

**核心业务场景：**
- 统计首页 Home Circle（家庭圈）、Banner（主 Banner/轮播图）、Skinny Banner（细条幅 Banner）、Digital Product（数字商品）、Deals Nearby（附近优惠）、Shopee Food 等模块的用户级别曝光量、点击量和订单 GMV（USD）。
- 支持对首页各非核心模块进行分模块、分站点、分用户的效果归因分析。
- 多渠道订单合并：整合 DP（数字商品）、Shopee Food（外卖）、Campaign Banner 三条订单链路，统一换算为 USD GMV。

**适合回答的问题：**
- 某站点某日首页 Home Circle 模块有多少用户下单？GMV 合计为多少？
- Banner / Skinny Banner 的每日用户级曝光与点击量分布如何？
- Digital Product 从首页入口产生了多少用户订单？
- 非亚洲站点首页各模块的转化情况如何？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/国家区域代码，如 VN、TH、SG、MY、ID、PH、TW 及非亚洲站点 |
| `local_date` | date | 本地日期（当地时区），数据统计日期 |
| `operation` | string | 行为类型：`impression`（曝光）、`click`（点击）、`order`（下单） |

### 维度：用户与模块

| 字段名 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | Shopee 用户 ID（买家），仅统计 `user_id > 0` 的登录用户 |
| `module` | string | 首页模块名称，取值包括：`Home Circle`、`Banner`、`Skinny Banner`、`Digital Product`、`Deals Nearby`、`Shopee Food` |

### 指标：行为与交易

| 字段名 | 类型 | 说明 |
|---|---|---|
| `operation_cnt` | double | 对应 `operation` 类型的行为次数：曝光/点击时为交互次数，下单（`order`）时为订单数量 |
| `gmv` | double | 用户下单产生的 GMV（USD），仅在 `operation = 'order'` 时有值；曝光和点击行为该字段为 `null`。金额已通过每日汇率换算为美元 |

---

## 查询使用须知

**必须包含的过滤条件：**
- 必须指定 `local_date` 分区以避免全表扫描，例如：`WHERE local_date = '2025-01-01'`。
- 建议同时指定 `grass_region` 缩小分区范围。
- 若只关注订单数据，需加过滤 `operation = 'order'`；若只关注曝光/点击，需加 `operation IN ('impression', 'click')`。

**不可直接 SUM 的字段：**
- `gmv`：当 `operation != 'order'` 时值为 `null`，聚合前须先过滤 `operation = 'order'`，否则结果含义混乱。
- `operation_cnt`：在 `operation = 'order'` 时含义为订单数，在 `operation IN ('impression', 'click')` 时含义为交互次数，跨 `operation` 类型直接 SUM 无业务意义，需分开汇总或使用 `CASE WHEN`。

**时效性说明：**
- 本表为每日全量分区覆盖，数据反映 `local_date` 当天的完整统计，通常在次日调度完成后可用。
- 表中数据以**本地时区（local time）**为基准，与 UTC 时区表存在时间偏差，跨表关联时需注意时区对齐。
- VN 站点 Shopee Food 数据需通过 `now_uid -> shopee_uid` 映射转换，若映射不完整可能存在 `user_id` 为 null 的订单记录。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 首页模块曝光（impression）和点击（click）行为数据，按 `target_type`、`page_type`、`page_section` 过滤首页 Other 模块 |
| `digitalpurchase.traffic_dwd_dp_order_by_traffic_entrance_di_v2` | 数字商品（DP）及 DP 本地服务订单，包含 Home Circle 入口、Digital Product 快捷入口、Deals Nearby 入口 |
| `mp_campaign.dwd_eventid_orderid_atc_place_banner_di__reg_s0_live` | Campaign Banner 关联订单，覆盖 Home Square（Home Circle）、Home Carousel（Banner）、Home Skinny（Skinny Banner）三类 Banner 的下单数据 |
| `shopeefood.shopeefood_mart_dwd_id_traffic_external_direct_order_attribute_di` | Shopee Food 印尼站（ID）首页入口及 Home Circle 订单 |
| `shopeefood.shopeefood_mart_dwd_th_traffic_external_direct_order_attribute_di` | Shopee Food 泰国站（TH）首页入口及 Home Circle 订单 |
| `shopeefood.shopeefood_mart_dwd_my_traffic_external_direct_order_attribute_di` | Shopee Food 马来西亚站（MY）首页入口及 Home Circle 订单 |
| `shopeefood.shopeefood_mart_dwd_vn_traffic_external_direct_order_attribute_di` | Shopee Food 越南站（VN）首页入口及 Home Circle 订单（buyer_id 为 now_uid，需映射） |
| `shopeefood.shopeefood_mart_cdm_dim_vn_buyer_now_shopee_mapping_da` | VN Shopee Food 用户 ID 映射表，将 now_uid 映射为 Shopee user_id |
| `mp_order.dim_exchange_rate__reg_s0_live` | 每日汇率维表，用于将本地货币 GMV 换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
曝光/点击链路：
dwd_sr_data_warehouse_platform
  → imp_click_merged（按 target_type 映射模块名，汇总 operation_cnt）
  → 写入目标表（gmv = null）

订单链路（亚洲站点）：
  DP 订单（Home Circle 入口）  ┐
  Shopee Food 订单（Home Circle）┤ → homecircle
  Campaign Banner 订单（Home Square）┘

  Campaign Banner（Home Carousel/Skinny）→ banner_skynny
  DP 订单（Digital Product / Deals Nearby 入口）→ dp_local
  Shopee Food（首页 shopee_food section，ID/MY/VN/TH）→ shopee_food

  homecircle + banner_skynny + dp_local + shopee_food
  → order_merged（统一标记 operation = 'order'）
  → 写入目标表

订单链路（非亚洲站点）：
  逻辑与亚洲站点相同，但不含 Shopee Food 模块（shopee_food 已注释掉）
  → order_merged → 写入目标表
```

### 关键步骤

**ETL 文件 1（亚洲站点：VN、TW、TH、PH、SG、MY、ID）**

1. **`exchange_rate`（Temporary View）**：从汇率维表取亚洲站点当日汇率。
2. **`homecircle`（Temporary View）**：合并 DP 订单（Home Circle 入口）+ 各国 Shopee Food Home Circle 订单（VN 需 now_uid→shopee_uid 映射）+ Campaign Banner Home Square 订单；GMV 换算为 USD（原始金额 ×0.00001 / exchange_rate）。
3. **`banner_skynny`（Temporary View）**：从 Campaign Banner 表取 Home Carousel（→Banner）、Home Skinny（→Skinny Banner）订单，汇总 order_cnt 和 gmv_usd。
4. **`dp_local`（Temporary View）**：从 DP 订单表按入口来源码过滤，拆分出 `Digital Product` 和 `Deals Nearby` 两个模块。
5. **`shopee_food`（Temporary View）**：从各国 Shopee Food 表取首页 shopee_food 版块订单，模块标记为 `Shopee Food`。
6. **`order_merged`（Temporary View）**：UNION ALL 合并以上四个 view，统一附加 `operation = 'order'`。
7. **`imp_click_merged`（Temporary View）**：从 `dwd_sr_data_warehouse_platform` 取首页 `banner`/`skinny_banner`/`home_circle` 三类 target_type 的曝光和点击记录，按 user_id + module + operation + grass_region + local_date 汇总 operation_cnt。
8. **`INSERT OVERWRITE`**：UNION ALL 合并 `imp_click_merged`（gmv=null）与 `order_merged`，按分区写入目标表。

**ETL 文件 2（非亚洲站点）**

逻辑结构与文件 1 完全对称，区别如下：
- 站点过滤条件改为 `grass_region NOT IN ('VN','TW','TH','PH','SG','MY','ID')`。
- `order_merged` 中不包含 `shopee_food`（Shopee Food 非亚洲暂无数据，相关 UNION ALL 已注释）。
- 同样执行 `INSERT OVERWRITE`，写入非亚洲站点分区。

### 注意事项

1. **Multi-writer 风险**：本表由两个独立 ETL 文件并发写入，分别覆盖亚洲站点分区和非亚洲站点分区。若两个 Job 同时执行且分区边界管理不当（如 `grass_region` 分区重叠），存在数据互相覆盖的风险，需确保调度层保证两个 Job 写入不同的 `grass_region` 分区集合。
2. **GMV 字段为 null 的情况**：曝光和点击行为记录中 `gmv` 字段固定写入 `null`，聚合时必须先按 `operation` 过滤，避免误将 null 计入 GMV 统计。
3. **VN 站点 Shopee Food 用户 ID 映射**：VN Shopee Food 订单通过 `now_uid` LEFT JOIN `shopee_uid` 关联，若映射缺失则 `user_id` 为 null，可能低估 VN 站点部分模块的用户覆盖度。
4. **金额单位转换**：DP 和 Shopee Food 原始金额单位为"厘"，ETL 中已乘以 `0.00001` 转换为标准货币单位，再除以当日汇率换算为 USD，表中 `gmv` 字段已为 USD 口径，不可再次换算。
5. **`operation_cnt` 语义双重性**：该字段在 `operation='order'` 时表示订单数（`count(distinct order_id)` 聚合），在 `operation IN ('impression','click')` 时表示行为次数（`sum(operation_cnt)`），跨类型合并时需加以区分。

---

*文档生成时间：2026-05-17*