<!-- ads-workspace-gdoc-sync: gdoc_id=1L5T_9rI83w3sv0PD0nYZIyoEifSEg101A1F9IKegsQ4 gdoc_url=https://docs.google.com/document/d/1L5T_9rI83w3sv0PD0nYZIyoEifSEg101A1F9IKegsQ4/edit -->

# srdi_mart.dws_sr_data_warehouse_pdp_view_event_level_stay_duration_1h

**分层：** DWS（数据汇总层）
**主键：** `event_id`
**分区：** `grass_region` / `regional_date` / `regional_hour`
**更新频率：** 每小时一次（INSERT OVERWRITE 覆写对应分区）
**访问频次：** 1492 次

---

## 业务描述

本表记录用户在商品详情页（PDP，Product Detail Page）的**点击进入事件粒度**停留时长及"查看更多"行为数据，以小时为粒度聚合，覆盖各区域（`grass_region`）。

**核心业务场景：**

- 衡量用户在 PDP 页面的浏览深度与停留质量，辅助评估商品详情页内容吸引力；
- 结合 `is_see_more` 标识，分析用户是否主动展开"查看更多"模块，判断商品描述的用户参与度；
- 为搜索/推荐（SRDI）场景提供 PDP 侧的用户行为反馈，支持曝光→点击→停留的漏斗分析；
- 可关联 `request_id` 追溯来源推荐请求，评估各推荐策略带来的 PDP 停留质量。

**适合回答的问题：**

- 某小时内各区域用户在 PDP 停留时长的分布如何？
- 用户点击某类商品后平均停留多久？
- 哪些推荐请求（`request_id`）带来的 PDP 停留时长更长？
- 用户进入 PDP 后触发"查看更多"的比例是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识，如 ID、MY、TH 等，对应 Shopee 各市场 |
| `regional_date` | date | 事件发生的本地日期（按区域时区转换） |
| `regional_hour` | string | 事件发生的本地小时（按区域时区转换） |

### 维度：事件与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_id` | string | 点击事件唯一标识，为本表核心主键；同时作为关联 view 事件、see_more 事件的连接键 |
| `session_id` | string | 用户会话 ID，用于区分同一用户的不同会话 |
| `user_id` | bigint | 用户 ID（登录用户） |
| `device_id` | string | 设备 ID，可覆盖未登录用户 |
| `platform` | string | 用户访问平台，如 iOS、Android 等 |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，从事件 `data` 字段多路径解析（itemid / item.itemid / context.itemid / search_params.itemid），取首个非空值 |
| `shop_id` | bigint | 店铺 ID，从事件 `data` 字段多路径解析（shopid / item.shopid / context.shopid / search_params.shopid），取首个非空值 |

### 维度：推荐上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `pub_id` | string | 推荐发布者 ID，标识来源推荐位置 |
| `pub_context_id` | string | 推荐上下文 ID，关联具体推荐上下文 |
| `request_id` | string | 推荐请求 ID，从事件 `data.recommendation_info` 字段中正则提取（`REQID:([^,]*)`），用于关联上游推荐请求 |

### 维度：时间戳

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_timestamp` | bigint | 事件发生时间戳（毫秒级 Unix 时间戳） |
| `log_timestamp` | bigint | 日志上报时间戳（毫秒级 Unix 时间戳），用于 stay_duration 的 lead 窗口计算基准 |

### 指标：PDP 行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `stay_duration` | int | 用户在 PDP 页面的停留时长（毫秒），通过 `log_timestamp` 的 LEAD 窗口函数计算相邻事件时间差，并按 `event_id` 取 `max` 聚合；**仅保留 `stay_duration > 0` 或 `is_see_more = true` 的记录** |
| `is_see_more` | boolean | 用户是否在该 PDP 点击了"查看更多"按钮（`target_type = 'see_more_button'` 且 `page_section[0] = 'product_detail'`）；`true` 表示有点击行为，`false` 表示无 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤必须同时指定三个分区字段**，以避免全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2024-01-01'
    AND regional_hour = '08'
  ```
- `regional_hour` 为字符串类型，查询时注意使用字符串值（如 `'08'`，而非整数 `8`）。

### 不可直接 SUM/AVG 的字段

- **`stay_duration`**：该字段已经是事件粒度的停留时长（经 LEAD 窗口 + max 聚合得出），跨行 SUM 求总停留或直接 AVG 均有业务意义，但须注意：
  - 本表只保留 `stay_duration > 0` 或 `is_see_more = true` 的记录，计算整体均值时分母需对齐（不可与原始点击总数直接对比）；
  - `stay_duration = NULL` 的行（即无法关联 view 事件时 left join 产生的空值）已通过写入过滤条件排除，但结合其他表 join 时仍需注意空值处理。
- **`is_see_more`**：布尔类型，统计比率时需 `SUM(CASE WHEN is_see_more THEN 1 ELSE 0 END) / COUNT(*)` 方式计算，不可直接 SUM boolean 列（部分引擎不支持）。

### 时效性说明

- 本表为**小时级准实时表**，每小时由 ETL 任务执行一次 INSERT OVERWRITE，覆写对应 `(grass_region, regional_date, regional_hour)` 分区。
- 数据通常在当前小时结束后约数分钟至数十分钟内可用，**不保证实时**。
- stay_duration 的计算依赖下一小时的事件数据（通过读取当前小时 +1 的 view 事件做 LEAD），因此最新小时分区的 `stay_duration` 可能存在截断偏低的情况，建议分析时使用 T-1 小时及更早的已完结分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic.shopee_traffic_dwd_event_stream_hi__reg_s1_live` | 唯一上游表，提供原始流量事件流数据；在 ETL 中被读取三次，分别用于：①计算 PDP view 事件的停留时长；②识别"查看更多"按钮点击事件；③获取 item click 事件的维度与时间戳信息 |

---

## ETL 逻辑摘要

### 数据流

```
traffic.shopee_traffic_dwd_event_stream_hi__reg_s1_live
    │
    ├──[operation='view', page_type='product']──────────► view_source_table
    │       (当前小时 + 下一小时数据，LEAD 计算停留时长)
    │                                                         │
    │                                                    view_table (max stay_duration by event_id)
    │                                                         │
    ├──[target_type='see_more_button', page_type='product']──► see_more_source_button
    │       (当前小时 + 下一小时数据)
    │                                                         │
    │                                                    see_more_button (group by event_id)
    │                                                         │
    └──[operation='click', target_type='item']──────────► click_table (仅当前小时)
                                                              │
                                                         joined_table (left join view_table & see_more_button)
                                                              │
                                         INSERT OVERWRITE  目标表（stay_duration>0 OR is_see_more=true）
```

### 关键步骤

1. **`view_source_table`（Temporary View）**
   - 从上游流量表筛选 `page_type = 'product'` 且 `operation = 'view'` 的事件；
   - 读取范围覆盖**当前小时及下一小时**的数据（通过两段时间条件并集），以确保 LEAD 窗口函数能够获取跨小时的下一个事件时间戳；
   - 使用 `LEAD(log_timestamp, 1) OVER(PARTITION BY deviceid, userid, session_id ORDER BY log_timestamp ASC)` 计算相邻事件时间差作为候选 `stay_duration`；
   - 若为最后一条事件（LEAD 无值），`stay_duration = 0`（COALESCE 兜底用当前 log_timestamp 相减）。

2. **`view_table`（Temporary View）**
   - 按 `pre_event_id`（即 click 事件的 `event_id`）分组，取 `MAX(stay_duration)`，消除同一事件可能出现的多行数据影响。

3. **`see_more_source_button`（Temporary View）**
   - 筛选 `target_type = 'see_more_button'`、`page_type = 'product'`、`page_section[0] = 'product_detail'` 的事件；
   - 同样读取当前小时及下一小时数据。

4. **`see_more_button`（Temporary View）**
   - 按 `pre_event_id` 分组去重，标记 `see_more = true`。

5. **`click_table`（Temporary View）**
   - 筛选 `operation = 'click'`、`target_type = 'item'`，**仅读取当前小时**（`regional_date = local_date AND regional_hour = local_hour`）的事件；
   - 从 `data` JSON 字段中多路径 COALESCE 解析 `item_id`、`shop_id`；
   - 从 `data.recommendation_info` 正则提取 `request_id`。

6. **`joined_table`（Temporary View）**
   - 以 `click_table.event_id` 为驱动，LEFT JOIN `view_table`（补充停留时长）；
   - 再 LEFT JOIN `see_more_button`（补充是否查看更多），未匹配时 COALESCE 为 `false`。

7. **INSERT OVERWRITE（写目标表）**
   - 按 `(grass_region, regional_date, regional_hour)` 覆写分区；
   - 过滤条件：`stay_duration > 0 OR is_see_more = true`，排除无效停留且未触发"查看更多"的噪声记录。

### 注意事项

- **非 multi-writer**：本表仅有一个 ETL 文件写入，无多写冲突风险。
- **双小时读取策略**：为正确计算 PDP 停留时长，view 事件和 see_more 事件均读取当前小时 +1 的数据参与 LEAD 计算，但最终写入目标表的数据分区仍为当前小时（`local_date` / `local_hour`），不会污染其他分区。
- **最新分区停留时长偏低风险**：当 ETL 在小时边界附近运行时，下一小时数据可能尚未完整入库，导致部分用户的 LEAD 值缺失，`stay_duration` 被截断为 0 并被过滤，最新小时记录数可能偏少。
- **过滤后数据偏差**：`stay_duration > 0 OR is_see_more = true` 的过滤会丢弃部分有效点击记录（停留极短且未点击查看更多），使用本表统计整体 PDP 点击量时需注意分母口径与原始点击表不一致。
- **`stay_duration` 单位**：基于 `log_timestamp` 相减计算，`log_timestamp` 为毫秒级时间戳，因此 `stay_duration` 单位为毫秒。

---

*文档生成时间：2026-05-17*