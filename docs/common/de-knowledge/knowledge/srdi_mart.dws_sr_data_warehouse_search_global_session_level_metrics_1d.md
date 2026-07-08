<!-- ads-workspace-gdoc-sync: gdoc_id=1KBGxE2Gxn-9OS0vvjT4dDLYgPJ2MYMaaGWYEdjD4teM gdoc_url=https://docs.google.com/document/d/1KBGxE2Gxn-9OS0vvjT4dDLYgPJ2MYMaaGWYEdjD4teM/edit -->

# srdi_mart.dws_sr_data_warehouse_search_global_session_level_metrics_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `global_session_id` + `user_id` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1，按分区覆盖写入）
**引用频次 / 访问频次：** 287

---

## 业务描述

本表为搜索域 **Session 粒度全局指标汇总宽表**，以 `(global_session_id, user_id)` 为聚合粒度，统计用户在 **预搜索页（pre_search）** 内与语音搜索功能相关的行为指标。

**核心业务场景：**
- 衡量语音搜索入口（麦克风按钮）的点击渗透情况
- 分析语音搜索会话中实际触发语音识别行为的频次
- 识别语音搜索连续重试的 Session，用于评估语音搜索识别质量与用户挫败率

**适合回答的问题：**
- 每日有多少 Session / 用户点击了麦克风按钮？
- 语音搜索的 `action_voice_search` 事件在各大区的触发分布如何？
- 有多少 Session 在短时间内（< 60 秒）连续触发了多次语音搜索（疑似重试）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 MY、TH、VN 等），所有查询必须指定此分区 |
| `local_date` | date | 业务日期（本地时区），所有查询必须指定此分区 |

### 维度：Session 与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_session_id` | string | 全局会话 ID，跨页面唯一标识一次用户会话 |
| `user_id` | bigint | 用户 ID（仅含登录用户，ETL 过滤条件 `user_id > 0`） |

### 指标：语音搜索行为计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `mic_click_cnt` | bigint | 预搜索页键盘区域麦克风按钮的点击次数（`page_type='pre_search'`，`page_section='keyboard'`，`target_type='mic'`，`operation='click'`） |
| `action_voice_search_cnt` | bigint | 预搜索页触发语音搜索动作的次数（`page_type='pre_search'`，`original_operation='action_voice_search'`，`page_section IS NULL`，`target_type IS NULL`） |
| `retry_needed_count` | bigint | 疑似重试的语音搜索次数：在同一 Session 内，某次 `action_voice_search` 事件与下一次同类事件的时间间隔小于 60,000 毫秒（60 秒），视为用户重试；可用于评估语音识别失败率 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪（强制）**：每次查询必须同时指定 `grass_region` 和 `local_date`，否则将触发全分区扫描，造成严重的资源浪费：
  ```sql
  WHERE grass_region = 'MY'
    AND local_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

- **跨日聚合注意事项**：`mic_click_cnt`、`action_voice_search_cnt`、`retry_needed_count` 为同一 `(global_session_id, user_id)` 在当天的累计计数，跨日聚合时可直接 SUM。但若需计算**比率类指标**（如语音搜索重试率 = `retry_needed_count / action_voice_search_cnt`），**不可对分子分母分别 SUM 后相除**；应先 SUM 分子、SUM 分母，再做除法：
  ```sql
  -- 正确姿势
  SUM(retry_needed_count) * 1.0 / NULLIF(SUM(action_voice_search_cnt), 0)
  ```
- 本表已按 `(global_session_id, user_id)` 预聚合，**不要再对同一 Session 进行二次 GROUP BY 后 SUM**，否则会重复计算。

### 时效性说明

- 本表为 **`_1d` 后缀的天级快照表**，每日 T+1 产出，反映前一自然日的完整数据。
- 当天数据不可用，实时/准实时场景请勿依赖本表。
- 每次写入为 `INSERT OVERWRITE` 按分区覆盖，历史分区数据不受当日写入影响。

### 其他注意事项

- 本表仅包含**登录用户**（`user_id > 0`），匿名用户行为不在统计范围内。
- 语音搜索相关指标的统计范围严格限定在 `page_type = 'pre_search'`，其他页面的麦克风或语音行为不计入本表。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索平台行为明细事件表，提供用户级别的点击、操作事件流，包含 `page_type`、`page_section`、`target_type`、`original_operation`、`event_timestamp` 等字段，是本表所有指标的唯一数据源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    └─► [过滤：pre_search 页语音相关事件，登录用户]
        └─► Temp View: dwd_search_metrics（含 LEAD 窗口函数计算下一次语音搜索时间）
            └─► [聚合：按 global_session_id + user_id 汇总计数]
                └─► Temp View: dws_search_metrics
                    └─► INSERT OVERWRITE: dws_sr_data_warehouse_search_global_session_level_metrics_1d
```

### 关键步骤

**Step 1 — Temporary View `dwd_search_metrics`（事件过滤 + 窗口计算）**

从 DWD 平台事件表中筛选出与语音搜索相关的两类事件：
- 麦克风点击：`page_section[0] = 'keyboard'` AND `target_type = 'mic'` AND `original_operation = 'click'`
- 语音搜索动作：`original_operation = 'action_voice_search'` AND `page_section IS NULL` AND `target_type IS NULL`

同时通过 `LEAD(event_timestamp) OVER (PARTITION BY global_session_id, original_operation ORDER BY event_timestamp)` 计算每次语音搜索事件的"下一次同类事件时间"（`next_search_time`），用于后续判断是否为重试行为。

**Step 2 — Temporary View `dws_search_metrics`（Session 级聚合）**

按 `(user_id, global_session_id)` 分组，通过条件 SUM 聚合三类指标：
- `mic_click_cnt`：麦克风点击次数
- `action_voice_search_cnt`：语音搜索触发次数
- `retry_needed_count`：`action_voice_search` 事件存在后续事件且两次事件时间差 < 60,000ms 的次数（`next_search_time IS NOT NULL AND (next_search_time - event_timestamp) < 60000`）

**Step 3 — INSERT OVERWRITE（写目标表）**

以 `PARTITION (grass_region, local_date)` 覆盖写入目标分区，每次执行幂等，可安全重跑。

### 注意事项

- **单一写入者**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无多文件并发写入风险。
- **覆盖写入**：使用 `INSERT OVERWRITE PARTITION`，重跑时会完整替换该 `(grass_region, local_date)` 分区数据，历史分区不受影响，重跑安全。
- **窗口函数依赖排序**：`retry_needed_count` 的计算依赖 LEAD 窗口函数，若上游 DWD 表的 `event_timestamp` 精度或时区处理发生变化，可能影响重试判断结果，需关注上游变更。
- **`page_section` 为数组类型**：ETL 中通过 `page_section[0]` 取第一个元素进行条件判断，使用上游数据时需注意该字段的数组结构。

---

*文档生成时间：2026-05-17*