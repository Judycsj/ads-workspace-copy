<!-- ads-workspace-gdoc-sync: gdoc_id=159DNarL0aOa2cmkIxUx50vy3fRyoM140QdgqyxkwBvk gdoc_url=https://docs.google.com/document/d/159DNarL0aOa2cmkIxUx50vy3fRyoM140QdgqyxkwBvk/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `local_hour` + `is_item_card` + `user_id` + `is_ads` + `mapping_general` + `shop_id` + `item_id` + `model_id`
**分区：** `grass_region`（站点大区）/ `local_date`（本地日期）/ `local_hour`（本地小时）
**更新频率：** 每日全量覆写（按分区 INSERT OVERWRITE）
**引用频次 / 访问频次：** 44,404 次

---

## 业务描述

本表是搜推（Search & Recommendation）数仓的**商品曝光-点击-成交核心聚合宽表**，以「站点-日期-小时-场景-商品-用户-广告标识」为粒度，汇总各业务场景下的流量与 GMV 指标。

**核心业务场景覆盖：**

| `mapping_general` 取值 | 含义 |
|---|---|
| `Search` | 全局搜索场景 |
| `Daily Discover` | 首页发现场景 |
| `You May Also Like` | 猜你喜欢场景 |
| `Post Purchase` | 购后推荐场景 |
| `Shop` | 店铺场景（仅 item card） |
| `Video` | 视频场景 |
| `Live Streaming` | 直播场景 |
| `S&R__ALL__` | 搜推汇总口径（Search + Image Search + Daily Discover + User Scenario） |
| `__ALL__` | 全平台口径（仅 item card） |

**适合回答的典型问题：**
- 某站点、某日期、某场景下的曝光量、点击量、下单量、GMV 是多少？
- 各搜推场景的广告与自然流量 GMV 对比如何？
- 特定商品 / 店铺在不同场景下的转化表现？
- 搜推全链路（含多触点归因）的成交贡献？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识，如 `ID`、`MY`、`TH` 等；所有查询必须携带该过滤条件 |
| `local_date` | date | 数据所属本地日期（`YYYY-MM-DD`）；所有查询必须携带该过滤条件 |
| `local_hour` | int | 数据所属本地小时（0–23）；表中同时作为分区字段与维度字段使用 |

### 维度：业务场景与商品信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_item_card` | string | 是否为商品卡片，取值 `'true'`/`'false'`；`'false'` 在部分场景下表示多触点归因复制的订单日志，非真实商品卡片曝光 |
| `is_ads` | string | 是否为广告流量，取值 `'true'`/`'false'` |
| `mapping_general` | string | 业务场景归因标签，见业务描述中的枚举值；同一订单可因多触点归因出现在多个场景行中 |
| `user_id` | bigint | 用户 ID |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 商品 SKU / 规格 ID |

### 指标：流量指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；已在 ETL 中按维度聚合 SUM，跨行相加时需注意 `mapping_general` 多触点重复计数问题 |
| `click_cnt` | bigint | 点击次数；同上，多场景归因下存在重复计数风险 |

### 指标：成交指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单量（支持小数，来自上游聚合）；多触点归因复制的订单在不同 `mapping_general` 下均有记录，跨场景直接 SUM 会重复 |
| `gmv` | double | 成交金额（美元口径）；同上，存在多触点场景重复计数风险 |
| `gmv_local` | double | 成交金额（本地货币口径）；同 `gmv` 注意事项 |
| `pc2_gmv` | double | PC2（支付完成二阶段）口径 GMV（美元）；同 `gmv` 注意事项 |
| `seller_gmv` | double | 卖家维度 GMV（美元）；同 `gmv` 注意事项 |
| `seller_gmv_local` | double | 卖家维度 GMV（本地货币）；同 `gmv` 注意事项 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：表按站点分区，查询时必须指定，否则触发全分区扫描，性能极差。
- **`local_date`**：表按日期分区，查询时必须指定。
- 建议同时指定 `local_hour` 以进一步缩小扫描范围；若需全天汇总，可省略该条件但需注意数据量。

```sql
-- 推荐写法
WHERE grass_region = 'ID'
  AND local_date = '2025-05-17'
  -- AND local_hour BETWEEN 0 AND 23  -- 全天可省略
```

### 不可直接跨场景 SUM 的字段

本表存在**多触点归因复制逻辑**：同一笔订单若被多个场景归因，会在 ETL 中被复制到多行（`source1`、`source2` 归因链路），以确保每个场景均能统计到该订单的贡献。因此：

| 操作场景 | 风险 |
|---|---|
| 对 `mapping_general` 不加过滤直接 SUM `order_cnt`/`gmv` 等成交指标 | **结果偏高**，存在跨场景重复计数 |
| 使用 `S&R__ALL__` 与具体子场景（`Search`、`Daily Discover` 等）混用聚合 | 口径不同，不可叠加 |
| 使用 `__ALL__` 与其他 `mapping_general` 同时 SUM | `__ALL__` 是全平台 item card 口径，与场景口径不可叠加 |

**正确做法**：在 WHERE 条件中锁定单一 `mapping_general` 值后再聚合，或在业务需要汇总多场景时使用去重逻辑。

### 时效性说明

- 本表为**日粒度增量按分区覆写**表，每日 T+1 产出前一天全天数据（`local_date`）。
- `local_hour` 为当日 0–23 小时细分，**非实时流**，不支持当日准实时查询。
- 若需查询最近 N 天趋势，需按 `local_date` 枚举多个分区，注意 `grass_region` 分区必须同步指定。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 唯一上游来源，提供商品卡片维度的曝光、点击、订单及 GMV 明细，含主触点与多触点归因（source1/source2）的 feature_group、reporting 维度信息 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards
        │  (过滤 grass_region + local_date，聚合 operation/小时/商品/用户维度)
        ▼
traffic_data_raw                    ← Step 0：原始流量聚合视图
        │
        ├──► every_scene_data_raw_step1/step2   ← 常规搜推子场景（Search/DD/YMAL/PP/Shop）
        ├──► video_and_live_data_raw_step1/step2 ← 视频与直播场景
        ├──► sr_data_raw_step1/step2             ← S&R 汇总口径（S&R__ALL__）
        └──► platform_data_raw_step2             ← 全平台 item card 口径（__ALL__）
                        │
                        ▼ UNION ALL 合并后按维度聚合
        srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `traffic_data_raw` | 从上游 DWM 表按 `grass_region`、`local_date` 过滤，仅保留 `order`、`omni_impression`、`omni_click` 三类 operation，按主触点 + source1/source2 归因维度聚合基础指标 |
| Step 2 | `every_scene_data_raw_step1` | 从 `traffic_data_raw` 提取常规搜推场景，将 reporting 维度映射为 `mapping_general`（Search / Daily Discover / You May Also Like / Post Purchase / Shop） |
| Step 3 | `every_scene_data_raw_step2` | UNION ALL 三路：① 主触点直接归因行；② source1 归因订单复制（scene 不同于主触点）；③ source2 归因订单复制（scene 不同于主触点和 source1），去重避免同一订单在同一场景计双份 |
| Step 4 | `video_and_live_data_raw_step1/step2` | 同 Step 2/3 逻辑，针对 `feature_group in ('Video','Live Streaming')` 场景，仅 Live Streaming 支持 source1/source2 归因复制 |
| Step 5 | `sr_data_raw_step1/step2` | 同 Step 2/3 逻辑，映射 `S&R__ALL__` 汇总标签（覆盖 Global Search + Image Search + Daily Discover + User Scenario） |
| Step 6 | `platform_data_raw_step2` | 直接从 `traffic_data_raw` 取全部 `is_item_card='true'` 行，标记 `mapping_general='__ALL__'`，不做场景过滤 |
| Step 7 | INSERT OVERWRITE | 将四路 UNION ALL 结果按维度（`is_item_card`、`user_id`、`is_ads`、`mapping_general`、`shop_id`、`item_id`、`model_id`、`local_hour`）SUM 聚合后写入目标表；使用 `REBALANCE` hint 优化输出文件均衡 |

### 注意事项

- **Multi-writer**：本表为单文件写入（`multi_writer=false`），无并发写入风险。
- **分区覆写策略**：采用 `INSERT OVERWRITE ... PARTITION (grass_region, local_date, local_hour)` 动态分区，每次仅覆写目标日期的分区，历史分区不受影响。
- **多触点归因重复**：ETL 显式通过 `source1_mapping_general != mapping_general` 和 `source2_mapping_general != source1_mapping_general` 条件防止同一场景双计，但跨不同 `mapping_general` 的重复是业务设计预期（每个场景均需见到被归因订单），使用时需在业务层处理。
- **is_item_card 含义特殊**：归因复制的订单行强制设置 `is_item_card='false'`，该值仅表示该行来源于归因链路复制，并非真实的非商品卡片曝光，查询时需结合 `mapping_general` 综合判断。
- **operation 过滤**：上游数据已在 Step 1 过滤为 `order/omni_impression/omni_click`，目标表中不保留 `operation` 字段，所有行均为三类 operation 的聚合结果。

---

*文档生成时间：2026-05-17*