<!-- ads-workspace-gdoc-sync: gdoc_id=19Sm5rRFsaqBHNpS8LMxVslLCGVpBkseOqzd22QHwyCs gdoc_url=https://docs.google.com/document/d/19Sm5rRFsaqBHNpS8LMxVslLCGVpBkseOqzd22QHwyCs/edit -->

# srdi_mart.dws_sr_data_warehouse_search_srp_other_feature_metrics_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** user_id, device_id, target_types, keyword, is_ads, sort_type, grass_region, local_date
**分区：** grass_region（大区）, local_date（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次：** 597

---

## 业务描述

本表聚合 SRP（搜索结果页）上**非标准主流搜索卡片**以外的其他特色功能模块的每日行为与交易指标，涵盖以下核心业务场景：

| 场景类型 | 说明 |
|---|---|
| **AI Topic Card** | 全局搜索、PDP 内搜索、预填充搜索中 AI 话题卡片的曝光与点击 |
| **AI Topic Landing 商品结果** | AI 话题落地页中商品结果区的曝光、点击及订单归因 |
| **视频商品卡（Video Item Card）** | SRP AI Card / Hashtag Card 落地页内视频流中商品类内容的行为与 GMV |
| **视频视频卡（Video Video Card）** | 同上落地页内视频流中视频类内容（business_id=1003）的行为与 GMV |

适合回答的问题示例：
- 某大区某日 AI Topic Card 带来多少曝光、点击及 GMV？
- 视频商品卡与视频视频卡的点击率和转化率对比如何？
- 特定关键词下各特色功能模块的加购和成单情况？
- 有投广告（is_ads=true）与非投广告流量在搜索特色模块的效果差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 ID、MY、TH 等），写入时由调度参数 `${grass_region}` 注入 |
| `local_date` | date | 业务日期，写入时由调度参数 `${local_date}` 注入 |

---

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；ETL 过滤 `user_id > 0`，仅保留已登录用户 |
| `device_id` | string | 设备 ID |

---

### 维度：特色功能模块分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `target_types` | array\<string\> | 特色功能模块类型标签，由 ETL 中多层 CASE WHEN 计算得出，取值包括：`ai_topic_card_union`、`ai_topic_landing-topic_result-item_union`、`video-item_card`、`video-video_card`、`unknow`；一条记录可属于多个类型（例如 AI Topic Landing 的 order 事件同时标注两个 tag） |

---

### 维度：搜索上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 用户搜索关键词 |
| `last_keyword` | string | 上一次搜索关键词（来源于上游 DWD 表，ETL 中未显式计算，值来自 GROUP BY 外传递；注意：当前 ETL GROUP BY 未包含该字段，实际写入可能为 NULL 或由上游源列透传，使用时需验证） |
| `is_ads` | string | 是否广告流量；原始值为 NULL 时默认填充为 `'false'`，否则转为字符串类型 |
| `sort_type` | string | 排序类型；原始值为 NULL 时默认填充为 `'NA'`，否则转为字符串类型 |
| `location_type` | string | 位置类型（来源于上游 DWD 表；当前 ETL SELECT 列表未显式包含，实际写入可能为 NULL，使用前需验证字段有效性） |

---

### 指标：流量行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；统计 `operation = 'impression'` 的 `operation_cnt` 之和 |
| `click_cnt` | bigint | 点击次数；统计 `operation = 'click'` 的 `operation_cnt` 之和 |
| `ppv_cnt` | bigint | 商品详情页浏览次数（PV）；当前 ETL 写入固定值 `NULL`，暂不可用 |
| `cart_cnt` | bigint | 加购次数；当前 ETL 写入固定值 `NULL`，暂不可用 |

---

### 指标：转化与交易

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单数量；统计 `operation = 'order'` 的 `operation_cnt` 之和 |
| `gmv` | double | 成交金额（Gross Merchandise Value）；统计 `operation = 'order'` 的 `place_order_gmv` 之和 |
| `pc2_gmv` | double | PC2 口径 GMV；统计 `operation = 'order'` 的 `pc2_gmv` 之和，为特定归因口径下的 GMV 统计 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则触发全表扫描，影响性能与成本：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- 若需跨大区查询，建议枚举 `grass_region IN (...)` 而非省略该条件。
- 若需跨日期范围，建议使用 `local_date BETWEEN '...' AND '...'`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gmv` / `pc2_gmv` | 已为分组聚合后的 SUM 值，跨 keyword/is_ads/sort_type 等维度叠加时会产生重复计算，需结合业务口径决定是否可加总 |
| `order_cnt` | 同上，跨维度汇总时注意是否存在同一订单被多个 `target_types` 标签计入的情况（ETL 中 order 事件可同时归属多个 tag） |
| `target_types` | 为 array 类型，不可直接过滤等值，需使用 `ARRAY_CONTAINS(target_types, 'xxx')` 进行查询 |

### 字段有效性说明

- `ppv_cnt` 和 `cart_cnt`：ETL 中硬编码为 `NULL`，**当前版本不可用**，勿用于计算。
- `last_keyword` 和 `location_type`：ETL SELECT 列表中未显式出现，字段值来源于上游表的透传或默认 NULL，**使用前请验证非空率**。
- `is_ads`：NULL 已被统一转换为字符串 `'false'`，过滤时应使用字符串类型，如 `is_ads = 'true'`。
- `sort_type`：NULL 已被统一转换为字符串 `'NA'`。

### 时效性说明

- 本表为 **`_1d` 后缀的天级聚合表**，每日产出一个分区，数据反映自然日维度的汇总结果。
- 数据以调度日期的 `${local_date}` 分区为准，通常 T+1 产出前一日数据，不适用于实时或准实时场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索平台 DWD 明细宽表，提供用户行为事件（impression / click / order）、特色功能来源字段（feature_detail、source1_feature_detail、source2_feature_detail）、内容类型（content_type、business_id）、位置信息（sv_source_page、position_current_page）及交易金额字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │
    │  过滤条件：
    │  - 分区：grass_region = ${grass_region}, local_date = ${local_date}
    │  - user_id > 0（已登录用户）
    │  - operation IN ('click', 'impression', 'order')
    │  - feature_detail / source_feature_detail 命中特色功能模块白名单
    │
    ▼ GROUP BY user_id, device_id, target_types, keyword, is_ads, sort_type
    │
    │  聚合：imp_cnt / click_cnt / order_cnt / gmv / pc2_gmv
    │
    ▼
srdi_mart.dws_sr_data_warehouse_search_srp_other_feature_metrics_1d
    （INSERT OVERWRITE PARTITION(grass_region, local_date)）
```

### 关键步骤

1. **数据过滤（WHERE 子句）**
   - 按分区键（grass_region、local_date）裁剪数据范围。
   - 仅保留 `user_id > 0` 的已登录用户。
   - 仅保留 `operation IN ('click', 'impression', 'order')` 三类行为事件。
   - 通过多个 OR 条件筛选命中特色功能模块的行：
     - `feature_detail` 命中视频行为（video-*）、Topic Result（topic_result-*）、AI Topic Card（ai_topic_card）相关枚举值；
     - 或 `source1_feature_detail` / `source2_feature_detail` 命中 AI Minifeed Card（ai_minifeed_card）相关归因链路。

2. **target_types 维度计算（CASE WHEN）**
   - 按 operation、feature_detail、content_type、business_id、sv_source_page、position_current_page 的组合，将每条记录映射到对应特色功能标签（array 类型），实现灵活的多标签归类：
     - `ai_topic_card_union`：AI 话题卡片曝光/点击；
     - `ai_topic_landing-topic_result-item_union`：AI 话题落地页商品结果曝光/点击/订单（order 事件同时归入 `ai_topic_card_union`）；
     - `video-item_card`：SRP 视频流中商品卡（content_type = 'item'）；
     - `video-video_card`：SRP 视频流中视频卡（business_id = 1003）；
     - `unknow`：未命中任何规则的兜底值。

3. **is_ads / sort_type 空值处理**
   - 使用 `IF(field IS NOT NULL, CAST(field AS STRING), default_value)` 统一空值处理，避免维度 NULL 打散分组。

4. **聚合计算**
   - `imp_cnt`：`SUM(IF(operation='impression', operation_cnt, NULL))`
   - `click_cnt`：`SUM(IF(operation='click', operation_cnt, NULL))`
   - `order_cnt`：`SUM(IF(operation='order', operation_cnt, NULL))`
   - `gmv`：`SUM(IF(operation='order', place_order_gmv, NULL))`
   - `pc2_gmv`：`SUM(IF(operation='order', pc2_gmv, NULL))`
   - `ppv_cnt` / `cart_cnt`：硬编码 `NULL`。

5. **写入目标表**
   - `INSERT OVERWRITE TABLE ... PARTITION(grass_region=..., local_date=...)` 按分区全量覆写，保证幂等性。

### 注意事项

- **单 Writer 写入**：该表仅有一个 ETL 文件写入（multi_writer = false），无并发写入风险。
- **分区覆写幂等性**：每次调度对指定 (grass_region, local_date) 分区执行全量 INSERT OVERWRITE，重跑安全，但历史分区数据若未重跑则不会自动修正。
- **target_types 多值归属**：order 事件中 AI Topic Landing 商品结果同时被打上两个 tag（`ai_topic_landing-topic_result-item_union` 和 `ai_topic_card_union`），导致订单/GMV 在这两个 tag 下各计一次，跨 target_types 汇总时需注意**避免重复计数**。
- **ppv_cnt / cart_cnt 字段占位**：当前 ETL 输出为 NULL，业务指标体系中该字段可能由其他表补充，使用时需确认来源。
- **last_keyword / location_type 字段完整性**：ETL SELECT 列表未显式包含这两个字段，建议实际使用前通过 `COUNT(*) vs COUNT(last_keyword)` 验证数据完整性。

---

*文档生成时间：2026-05-17*