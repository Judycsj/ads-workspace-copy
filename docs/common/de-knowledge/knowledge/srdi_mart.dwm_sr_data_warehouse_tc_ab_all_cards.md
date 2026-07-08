<!-- ads-workspace-gdoc-sync: gdoc_id=1_IldnYt4oT0KLY9eXsQXbc574xBJynBCiiXJ0rjSuIk gdoc_url=https://docs.google.com/document/d/1_IldnYt4oT0KLY9eXsQXbc574xBJynBCiiXJ0rjSuIk/edit -->

# srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards

**分层：** DWM（数据仓库中间层）
**主键：** `grass_region` + `local_date` + `local_hour` + `regional_date` + `regional_hour` + `operation` + `shop_id` + `item_id` + `model_id` + `user_id` + `is_item_card` + `feature_detail` + `feature_group` + `reporting_business_line` + `reporting_module` + `reporting_object`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour` / `operation`
**更新频率：** 每日按区域、按日期分区覆盖写入（INSERT OVERWRITE）
**访问频次：** 4950

---

## 业务描述

本表是搜索与推荐（Search & Recommendation）方向的数仓中间层宽表，整合了**商品卡片（Item Card）**与**非商品卡片（Non-Item Card）**两类流量的曝光、点击及订单核心指标，用于支撑 A/B 实验分析、流量漏斗归因、GMV 追踪等业务场景。

**核心业务场景：**

- **A/B 实验效果分析：** 结合 `exp_group_ids`、`feature_group`、`feature_detail` 等维度，评估不同实验组的曝光/点击/转化表现。
- **搜索与推荐全场景流量漏斗：** 覆盖搜索（Global Search、Image Search）、首页（Daily Discover）、推荐（User Scenario、You May Also Like）等业务线的完整曝光→点击→成单链路。
- **GMV 归因与 seller 维度分析：** 提供商品维度（`item_id`、`shop_id`）及 vSKU 维度的 GMV 数据，支持商家和类目归因。
- **卡片类型区分：** 通过 `is_item_card` 区分商品卡片与非商品卡片，满足差异化分析需求。

**适合回答的问题举例：**

- 某大区某日各业务线的曝光量/点击量/CTR 是多少？
- 某 A/B 实验组相对于对照组 GMV 提升了多少？
- 搜索场景下非商品卡片的曝光分布如何？
- 某商品/店铺在特定时段内的下单 GMV 是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 ID、MY、TH 等），每个分区对应一个区域 |
| `local_date` | date | 当地日期，ETL 按此日期分区覆盖写入 |
| `local_hour` | int | 当地小时（0–23），来自日志时间戳按 `grass_region` 时区转换 |
| `regional_date` | date | 区域标准日期（新加坡时区，SG） |
| `regional_hour` | int | 区域标准小时（新加坡时区，SG） |
| `operation` | string | 操作类型：`omni_impression`（曝光）、`omni_click`（点击）、`order`（下单） |

---

### 维度：卡片与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_item_card` | string | 是否为商品卡片：`'true'` 为商品卡片（来自 DWD 平台表），`'false'` 为非商品卡片（来自 omni 场景日志） |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 型号/SKU 模型 ID；非商品卡片场景下为 null |
| `user_id` | bigint | 用户 ID |
| `request_id` | string | 请求 ID；当前 ETL 恒为 null，预留字段 |
| `order_vsku_item_id` | bigint | 成单关联的 vSKU 商品 ID；仅当 `spu_vsku_order_property.has_spu_vsku=true` 时有值，非商品卡片为 null |
| `traffic_vsku_item_id` | bigint | 流量关联的 vSKU 商品 ID；仅当 `click_spu_vsku_property.ctx_item_type=2` 时有值，非商品卡片为 null |

---

### 维度：流量特征与归因

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 当前流量来源特征详情，格式为 `mapped_page_type-page_section-target_type`（商品卡片来自 DWD 归因字段，非商品卡片来自 omni 日志拼接） |
| `feature_group` | string | 流量特征分组标识 |
| `reporting_business_line` | string | 上报业务线（如 Search、Homepage、Rcmd） |
| `reporting_module` | string | 上报模块（如 Global Search、Daily Discover、User Scenario） |
| `reporting_object` | string | 上报对象（如 you may also like） |
| `is_ads` | boolean | 是否为广告流量 |
| `exp_group_ids` | array\<int\> | A/B 实验组 ID 列表；当前 ETL 恒为 null，预留字段 |

---

### 维度：多来源归因（Source1 / Source2）

| 字段 | 类型 | 说明 |
|---|---|---|
| `source1_feature_detail` | string | 来源1的流量特征详情；非商品卡片为 null |
| `source1_feature_group` | string | 来源1的特征分组；非商品卡片为 null |
| `source1_reporting_business_line` | string | 来源1的业务线；非商品卡片为 null |
| `source1_reporting_module` | string | 来源1的模块；非商品卡片为 null |
| `source1_reporting_object` | string | 来源1的对象；非商品卡片为 null |
| `source1_is_ads` | boolean | 来源1是否为广告流量；非商品卡片为 null |
| `source2_feature_detail` | string | 来源2的流量特征详情；非商品卡片为 null |
| `source2_feature_group` | string | 来源2的特征分组；非商品卡片为 null |
| `source2_reporting_business_line` | string | 来源2的业务线；非商品卡片为 null |
| `source2_reporting_module` | string | 来源2的模块；非商品卡片为 null |
| `source2_reporting_object` | string | 来源2的对象；非商品卡片为 null |
| `source2_is_ads` | boolean | 来源2是否为广告流量；非商品卡片为 null |

---

### 指标：流量行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；`operation='omni_impression'` 分区下有值，其余分区为 0 |
| `click_cnt` | bigint | 点击次数；`operation='omni_click'` 分区下有值，其余分区为 0 |
| `order_cnt` | double | 下单笔数（商品卡片来自 DWD，非商品卡片恒为 0） |

---

### 指标：GMV 指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 下单 GMV（美元，place_order_gmv）；`operation='order'` 分区下有值，非商品卡片恒为 0 |
| `gmv_local` | double | 下单 GMV（当地货币）；非商品卡片恒为 0 |
| `pc2_gmv` | double | PC2 口径下单 GMV（美元）；非商品卡片恒为 0 |
| `pc2_gmv_local` | double | PC2 口径下单 GMV（当地货币）；非商品卡片恒为 0 |
| `seller_gmv` | double | 卖家 GMV（美元，place_seller_gmv）；非商品卡片恒为 0 |
| `seller_gmv_local` | double | 卖家 GMV（当地货币）；非商品卡片恒为 0 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：必须指定，避免全量扫描所有区域分区，该字段是第一级分区。
2. **`local_date`**：必须指定具体日期或日期范围，是第二级分区，每次写入以 `local_date` 为单位覆盖。
3. **`operation`**：该字段是分区字段，同一行数据中 `imp_cnt`/`click_cnt`/`order_cnt` 只有对应 `operation` 分区下才有非零值。跨 `operation` 聚合时须注意不要重复计算。

推荐过滤模板：
```sql
WHERE grass_region = 'ID'
  AND local_date = '2025-01-01'
  AND operation IN ('omni_impression', 'omni_click', 'order')
```

### 不可直接 SUM 的字段

- **`imp_cnt` / `click_cnt` / `order_cnt`**：因 `operation` 为分区维度，同一 `(item_id, user_id, ...)` 组合在不同 `operation` 分区各有一行，跨 `operation` 汇总时需先按 `operation` 过滤后再 SUM，或在聚合时加 `operation` 过滤条件，否则会重复累加其他分区的 0 值行（安全，但应避免无谓的全分区扫描）。
- **CTR / CVR 等比率指标**：本表不存储比率，需用 `click_cnt / NULLIF(imp_cnt, 0)` 等方式手动计算，且分子分母须来自同一聚合粒度。
- **`exp_group_ids`（array 类型）**：不可直接 SUM，需展开（EXPLODE）后再分析实验组维度。
- **`gmv` / `gmv_local` / `pc2_gmv` / `pc2_gmv_local` / `seller_gmv` / `seller_gmv_local`**：仅在 `operation='order'` 分区下有业务含义，跨 `operation` 合并 SUM 时需加 `operation='order'` 过滤，否则结果仍正确（其余分区为 0）但会产生不必要的扫描。

### 时效性说明

- 本表为**按日全量覆盖**表，每日针对指定 `grass_region` + `local_date` 执行 INSERT OVERWRITE。
- **不存在累计（`*_td`）或滑动窗口（`*_nd`）指标**，所有指标均为当日当小时粒度的事实行。
- 数据一般在次日 ETL 完成后可用，不适用于实时/准实时场景。
- 非商品卡片（`is_item_card='false'`）的 `order_cnt`、所有 GMV 字段恒为 0，`source1_*`、`source2_*` 字段恒为 null，查询订单/GMV 时建议加 `is_item_card='true'` 过滤。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供商品卡片（Item Card）的曝光、点击、订单事件及 GMV 数据，以及 SPU/vSKU 归因属性 |
| `traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live` | 提供全场景事件日志，用于抽取非商品卡片（Non-Item Card）的曝光、点击事件 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │
        ▼ (Statement 1)
item_card_data_{region}          ← 商品卡片：按维度聚合 imp/click/order/GMV

traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live
        │
        ▼ (Statement 2)
omni_scenario_data_{region}      ← 全场景原始事件，含卡片类型标识

        │
        ▼ (Statement 3，UDF 过滤非商品卡片)
non_item_card_data_{region}      ← 非商品卡片：仅 imp/click，无 order/GMV

        │
        ▼ (Statement 4，UNION ALL)
srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards  ← 目标表（分区覆盖写入）
```

### 关键步骤

**Statement 1 — 创建临时视图 `item_card_data_{region}`**
- 来源：`srdi_mart.dwd_sr_data_warehouse_platform`
- 过滤条件：指定 `grass_region`、`local_date`，`operation IN ('omni_impression','omni_click','order')`
- 逻辑：按完整维度 GROUP BY，用 `SUM(IF(operation=..., value, 0))` 将三种操作类型的计数/GMV 汇聚到同一行，同时通过 SPU/vSKU 嵌套属性计算 `order_vsku_item_id`、`traffic_vsku_item_id`
- 输出：`is_item_card='true'`，包含完整 source1/source2 归因字段

**Statement 2 — 创建临时视图 `omni_scenario_data_{region}`**
- 来源：`traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live`
- 过滤条件：指定 `grass_region`、`grass_date`，`tz_type='local'`，`scenario_event_type IN ('card_impression','card_click','button_click')`，`event_type IN ('impression','click')`；业务线/模块/对象白名单过滤（Search、Homepage Daily Discover、Rcmd User Scenario、You May Also Like）
- 逻辑：时间戳分别按 `grass_region` 本地时区和 SG 时区转换，拼接 `feature_detail`（`mapped_page_type-page_section-target_type`）和 `original_feature_detail`

**Statement 3 — 创建临时视图 `non_item_card_data_{region}`**
- 来源：Statement 2 的 `omni_scenario_data_{region}`
- 关键过滤：`get_eventtype_and_cardtype(original_feature_detail, event_type)[1]='0'`，通过 UDF 提取卡片类型标识，仅保留非商品卡片
- 逻辑：按维度 GROUP BY，用 `SUM(IF(event_type=...,1,0))` 分别统计曝光和点击

**Statement 4 — INSERT OVERWRITE 写目标表**
- 写入策略：`INSERT OVERWRITE ... PARTITION(grass_region, local_date, local_hour, regional_date, regional_hour, operation)`，按动态分区覆盖
- 数据来源：`UNION ALL` 合并 `item_card_data_{region}` 与 `non_item_card_data_{region}`
- 非商品卡片补全策略：`source1_*`、`source2_*`、`model_id`、`exp_group_ids`、`order_vsku_item_id`、`traffic_vsku_item_id` 均填 null；`order_cnt`、`gmv`、`gmv_local`、`pc2_gmv`、`pc2_gmv_local`、`seller_gmv`、`seller_gmv_local` 均填 0；`event_type` 映射为 `omni_impression`/`omni_click` 作为 `operation` 分区值
- `request_id`、`exp_group_ids` 两个字段在全部数据中均为 null，属于预留字段

### 注意事项

1. **单一写入（non multi-writer）**：本表仅由单一 ETL 文件写入，不存在多个 writer 并发写同一分区的风险。
2. **动态分区覆盖**：每次按 `grass_region` + `local_date` 维度执行覆盖，同一区域同一日期的历史数据会被完整替换，重跑历史数据时需注意是否会影响其他日期分区。
3. **UDF 依赖**：Statement 3 依赖 `get_eventtype_and_cardtype` UDF 进行卡片类型判断，若 UDF 版本变更可能影响非商品卡片的过滤结果。
4. **`is_item_card` 字段类型为 string 而非 boolean**：值为字符串 `'true'`/`'false'`，过滤时应使用 `is_item_card = 'true'` 而非 `is_item_card = TRUE`。
5. **GMV 字段精度**：GMV 相关字段类型为 double，跨大量行聚合时注意浮点精度累积误差，建议在汇总层使用 `ROUND` 处理。
6. **`operation` 分区与指标对应关系**：`imp_cnt` 仅在 `operation='omni_impression'` 有意义，`click_cnt` 仅在 `operation='omni_click'` 有意义，`order_cnt`/GMV 仅在 `operation='order'` 有意义；其余分区对应指标值为 0，分析时请按需过滤。

---

*文档生成时间：2026-05-17*