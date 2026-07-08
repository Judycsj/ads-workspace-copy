<!-- ads-workspace-gdoc-sync: gdoc_id=13xjLRlsL9PzwUgju8-77VggOthEUqvus4nkDk2ZhJyE gdoc_url=https://docs.google.com/document/d/13xjLRlsL9PzwUgju8-77VggOthEUqvus4nkDk2ZhJyE/edit -->

# srdi_mart.dws_sr_data_warehouse_search_food_card_metrics_1d

**分层：** dws_search
**主键：** user_id, page_type, page_section, target_type, global_session_id, search_session_id, search_entrance, search_mid, search_scenario_key, location, item_id, request_id, keyword, grass_region, local_date
**分区：** grass_region（大区）, local_date（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次：** 137

---

## 业务描述

本表是 **搜索食品卡片（Food Card）** 的日粒度汇总宽表，面向 Shopee 搜索场景下的外卖/食品类目。表将同一天内的 **曝光 & 点击行为**（来自平台埋点流水）与 **搜索归因订单**（来自各地区外卖流量归因表）通过全外连接（FULL OUTER JOIN）拼合，形成"一行 = 一组搜索上下文 × 商品"的汇总记录。

**核心业务场景：**
- 搜索结果页（SRP）食品商品卡片的曝光、点击效果分析
- 搜索联想/推荐词（curated_search）的 Food 卡片点击 & 转化分析
- 搜索归因订单的 GMV、订单量统计（毛/净口径）
- 多地区（grass_region）搜索食品业务的 AB 实验、场景效果对比

**适合回答的问题：**
- 某关键词/某 search_mid 下食品卡片的曝光点击率（CTR）是多少？
- 搜索食品场景各入口（search_entrance）的 GMV 贡献如何？
- 指定日期、地区的食品搜索搜索场景（search_scenario_key）转化率对比？
- 某商品（item_id）在搜索中的排位（location）与订单转化的关系？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `VN`、`TH`、`MY` 等；每次写入覆盖单一分区 |
| `local_date` | date | 业务日期（当地时区），数据统计口径日期 |

### 维度：搜索上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 页面类型，如 `search`（搜索结果页）、`search_suggest_page`（搜索建议页）；源自埋点 `original_page_type` |
| `page_section` | string | 页面区块，如 `search_bar`；取埋点 `page_section[0]`，无则为空字符串 |
| `target_type` | string | 点击目标类型，如 `item`（商品）、`curated_search`（推荐搜索词）|
| `search_entrance` | string | 搜索入口标识，来自埋点或订单归因数据中的 `search_entrance` 字段 |
| `search_mid` | string | 搜索 mid 标识；对 curated_search 场景做了补填：SRP 场景补填为 `srp_curated_search`，搜索建议页场景补填为 `sup_curated_search` |
| `search_scenario_key` | string | 搜索场景 key，关联 Atlas 特征映射表中的 `scenario_key`（源字段名 `scenario_key`）|
| `global_session_id` | string | 全局会话 ID，标识一次用户会话 |
| `search_session_id` | string | 搜索会话 ID，标识一次搜索会话 |
| `request_id` | string | 搜索请求 ID，唯一标识一次搜索请求 |
| `keyword` | string | 搜索关键词，已做 `trim(lower(...))` 标准化处理 |
| `location` | int | 商品在搜索结果中的排位/位置（position） |

### 维度：用户与商品

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；VN 地区使用 Shopee UID 替换 Now UID（通过 now-shopee 映射表转换），其他地区直接使用原始 user_id |
| `item_id` | bigint | 食品商品 ID（`item_type = 2` 的商品） |

### 维度：订单归因事件（明细透传）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_click_event_id` | string | 订单点击归因事件 ID（`event_id`），仅归因订单侧有值；曝光/点击侧为 NULL |
| `order_click_event_data` | string | 订单点击归因事件原始 data JSON，仅归因订单侧有值；曝光/点击侧为 NULL |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 该维度组合下的食品卡片曝光次数（`operation = 'impression'` 的累计） |
| `click_cnt` | bigint | 该维度组合下的食品卡片点击次数（`operation = 'click'` 的累计） |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gross_order_cnt` | double | 毛口径订单数；按单个订单中商品数量做拆分（`1.0 / dish_num`），避免一笔订单多件商品重复计数 |
| `net_order_cnt` | double | 净口径订单数；在 `gross_order_cnt` 基础上乘以 `is_net` 标志（退款/取消订单不计入） |
| `gross_gmv_local` | double | 毛口径 GMV（本地货币）；VN 除以 100，其他地区除以 100,000 转换为标准单位 |
| `net_gmv_local` | double | 净口径 GMV（本地货币）；在毛 GMV 基础上乘以 `is_net` 标志 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 是分区字段，查询时**必须同时指定**，否则会触发全表扫描，造成资源浪费和慢查询。
  ```sql
  WHERE grass_region = 'VN'
    AND local_date = '2024-01-01'
  ```
- 如需跨日期聚合，应明确列举日期范围，避免遗漏分区裁剪。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gross_order_cnt` / `net_order_cnt` | 已按 `1/dish_num` 拆分为小数，累加合理；但**跨 item_id 聚合后结果为折算订单数**，需理解口径含义 |
| `gross_gmv_local` / `net_gmv_local` | 已按地区换算为本地货币标准单位，**不同 `grass_region` 的 GMV 不可直接加总**（货币单位不同）|
| `order_click_event_id` / `order_click_event_data` | 明细字段，仅用于追溯归因链路，不可聚合 |

### 全外连接导致的 NULL 值

- 本表由曝光/点击侧与订单侧做 **FULL OUTER JOIN** 合并。因此：
  - 有曝光/点击但无归因订单的行：`gross_order_cnt`、`net_order_cnt`、`gross_gmv_local`、`net_gmv_local`、`order_click_event_id`、`order_click_event_data` 为 NULL。
  - 有归因订单但无曝光/点击的行：`imp_cnt`、`click_cnt` 为 NULL。
- 聚合时建议使用 `COALESCE(imp_cnt, 0)` 等处理 NULL。

### 时效性说明

- 本表为 **T+1** 日粒度表（`_1d` 后缀），每日对当日分区执行 INSERT OVERWRITE，数据通常在次日产出。
- 不适用于实时/准实时监控场景。

### VN 地区特殊逻辑

- VN 地区的 `user_id` 已通过 Now UID → Shopee UID 的映射表进行替换，与其他地区的 `user_id` 口径不同，**跨地区 user_id 不可直接关联**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索平台埋点流水，提供曝光（impression）与点击（click）行为明细 |
| `traffic_omni_oa.dim_atlas_search_feature_map__reg_live` | Atlas 搜索特征映射维表，提供 `page_type` → `scenario_key` 的映射 |
| `srdi_mart.dim_sr_data_warehouse_search_mid_mapping` | 搜索 mid 映射维表（ETL 中 REFRESH 以确保元数据最新） |
| `shopeefood.shopeefood_mart_cdm_dim_vn_buyer_now_shopee_mapping_da` | VN 地区 Now UID → Shopee UID 用户映射表 |
| `shopeefood.shopeefood_mart_dwd_${grass_region}_traffic_external_direct_order_attribute_di_v2` | 各地区外卖流量归因订单明细表（每个地区单独一张），提供搜索归因订单数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_atlas_search_feature_map__reg_live
        │ (page_type → scenario_key 映射)
        ▼
srdi_mart.dwd_sr_data_warehouse_platform  ─────────────────────────────────────────┐
        │ (impression/click 过滤 + 聚合)                                             │
        │ LEFT JOIN omni_search_mapping                                              │
        │ LEFT JOIN vn_uid_mapping                                                   │
        ▼                                                                            │
  [dwd_search_imp_click]  (曝光点击汇总临时视图)                                      │
        │                                                                            │
shopeefood_mart_dwd_${region}_traffic_external_direct_order_attribute_di_v2        │
        │ (search 归因订单过滤 + 字段解析)                                            │
        │ LEFT JOIN vn_uid_mapping                                                   │
        ▼                                                                            │
  [dwd_search_order] → [search_food_order]  (订单汇总临时视图)                       │
        │                                                                            │
        └──────── FULL OUTER JOIN ────────────────────────────────────────────────  ┘
                        │
                        ▼
  srdi_mart.dws_sr_data_warehouse_search_food_card_metrics_1d
  (INSERT OVERWRITE PARTITION grass_region, local_date)
```

### 关键步骤

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| Step 1 | `omni_search_mapping_scope` | 从 Atlas 特征映射维表读取当日数据，按 `mapped_page_type` 聚合得到 `scenario_key`，用于后续曝光点击侧的场景 key 补填 |
| Step 2 | `REFRESH TABLE dim_sr_data_warehouse_search_mid_mapping` | 刷新 search_mid 映射维表的元数据缓存，确保后续查询使用最新数据 |
| Step 3 | `vn_region_uid_mapping` | 仅 VN 地区加载 Now UID → Shopee UID 映射，用于两侧数据的 user_id 统一 |
| Step 4 | `dwd_search_imp_click` | 从 `dwd_sr_data_warehouse_platform` 过滤出 Food 类型的曝光/点击事件（`item_type=2` 的商品卡片 + Food curated_search），JOIN omni_search_mapping 补 scenario_key，JOIN vn_uid_mapping 做 UID 转换，按维度组合聚合 `imp_cnt` 和 `click_cnt` |
| Step 5 | `dwd_search_order` | 从各地区归因订单表读取数据，解析 JSON 字段（`search_entrance`、`keyword`、`request_id` 等），计算 `dish_num` 用于订单拆分 |
| Step 6 | `search_food_order` | 过滤 `level_1_attribution_scenes = 'shopee search'` 且在 `search_result`/`suggestion_keyword_list`/`search_result_top_module` 归因场景内的订单，做 search_mid 空值补填，JOIN vn_uid_mapping 做 UID 转换，按维度聚合 `gross_order_cnt`、`net_order_cnt`、`gross_gmv`、`net_gmv` |
| Step 7 | INSERT OVERWRITE | 将 `dwd_search_imp_click`（曝光点击）与 `search_food_order`（归因订单）按全部维度字段做 **FULL OUTER JOIN**（用 `<=>` 空安全等值判断），写入目标表对应 grass_region + local_date 分区 |

### 注意事项

- **单一 Writer：** 本表仅有 1 个 ETL 文件写入，无多 writer 并发风险；但每次调度按 `(grass_region, local_date)` 单分区覆写，多地区并发调度时各分区独立，不互相影响。
- **全外连接 NULL 风险：** 曝光点击侧与订单侧存在不重叠数据，聚合时需注意 NULL 处理。
- **VN UID 映射一致性：** 曝光点击侧和订单侧均独立 JOIN `vn_region_uid_mapping`，若映射表数据不完整，VN 用户的曝光和订单可能因 UID 不一致而无法正确 JOIN，导致行数膨胀。
- **GMV 货币单位差异：** VN 地区金额除以 100，其他地区除以 100,000，**跨地区汇总需额外做币种换算**，本表不提供统一货币口径。
- **`order_click_event_id` / `order_click_event_data` 字段：** ETL SQL 中这两个字段（`event_id`、`data`）仅在订单子查询中出现，但在最终 INSERT SELECT 中未被显式选出（SELECT 列表中不含这两列）。DataMap snapshot 中存在该字段，实际写入值需以线上数据核实，**使用时建议先验证是否有有效值**。
- **`dim_sr_data_warehouse_search_mid_mapping` 仅做 REFRESH：** 该维表在 ETL 中只做了元数据刷新，未参与实际 JOIN，search_mid 的补填逻辑通过 CASE WHEN 硬编码实现。

---

*文档生成时间：2026-05-17*