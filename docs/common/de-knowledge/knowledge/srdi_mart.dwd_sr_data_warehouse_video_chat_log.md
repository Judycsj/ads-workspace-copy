<!-- ads-workspace-gdoc-sync: gdoc_id=1ts5MA5kJ4b09oxqbYThhw_O2WSTu8sYnpUWbV54dmtQ gdoc_url=https://docs.google.com/document/d/1ts5MA5kJ4b09oxqbYThhw_O2WSTu8sYnpUWbV54dmtQ/edit -->

# srdi_mart.dwd_sr_data_warehouse_video_chat_log

**分层：** DWD（明细层）
**主键：** `grass_region` + `dt` + `hour` + `round_id` + `biz_session_id`
**分区：** `grass_region`（大区）/ `dt`（日期）/ `hour`（小时）
**更新频率：** 准实时，按小时分区增量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次：** 186

---

## 业务描述

本表为 SRDI 搜推数仓 **视频聊天（Video Chat）对话日志明细表**，记录视频聊天业务中每一轮对话（round）的原始日志流水，包含会话标识、对话历史内容、元数据及时间戳等信息。

**核心业务场景：**
- 追踪视频聊天各轮次（round）的完整对话历史，支持对话质量分析；
- 为上层 DWS / ADS 层提供经过清洗的明细数据，用于搜推策略效果评估；
- 支持按大区（grass_region）、日期、小时维度进行时序分析，适用于实时/近实时监控场景。

**适合回答的问题（示例）：**
- 某大区某小时内视频聊天的轮次数量及分布；
- 特定会话（biz_session_id）的完整对话历史；
- 视频聊天日志的时序趋势及分区级明细查询。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识（如 SG、US 等），取自上游 `region` 字段的大写形式，用于按地区分区存储 |
| `dt` | date | 数据日期，对应上游 `dt` 字段（取 date 部分），按天分区 |
| `hour` | int | 数据小时（0–23），对应上游 `hour` 字段的整型转换，按小时分区 |

### 维度：会话与轮次标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `biz_session_id` | string | 业务会话 ID，标识一次完整的视频聊天会话 |
| `round_id` | bigint | 对话轮次 ID，标识会话内的单次对话轮次，由上游同名字段转换为 bigint |

### 维度：接入端点

| 字段 | 类型 | 说明 |
|------|------|------|
| `endpoint` | string | 接入端点标识，标记该轮对话发起的客户端或服务端端点类型 |

### 指标：对话内容与时间

| 字段 | 类型 | 说明 |
|------|------|------|
| `history_details` | string | 对话历史详情，存储该轮次的完整对话内容（通常为 JSON 或序列化文本） |
| `history_metas` | string | 对话历史元数据，存储与对话相关的元信息（如模型参数、策略标签等，通常为 JSON 或序列化文本） |
| `time_stamp` | bigint | 日志时间戳（毫秒或秒级 Unix 时间戳），标记该条日志的实际发生时间 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定分区字段**，查询时至少过滤 `grass_region` 和 `dt`，以避免全表扫描，例如：
  ```sql
  WHERE grass_region = 'SG'
    AND dt = '2024-09-15'
  ```
- 如需精确到小时粒度，应同时过滤 `hour`：
  ```sql
  WHERE grass_region = 'SG'
    AND dt = '2024-09-15'
    AND hour = 10
  ```
- **历史数据注意事项**：上游 ETL 对 2024-09-14 14:00 之前的数据有特殊重摄处理（14:00 后重新入库），查询 2024-09-14 数据时应注意该时间节点前后的数据可能存在重复或补录情况。

### 不可直接 SUM 的字段

- `history_details`、`history_metas`：为序列化文本字段，不可进行数值聚合，需解析后使用；
- `time_stamp`：时间戳字段，直接 SUM 无业务意义，应用于时序排序或时间范围过滤；
- `round_id`：为业务 ID，直接 SUM 无意义，应用于去重计数（COUNT DISTINCT）。

### 时效性说明

- 本表为**准实时小时级表**，每小时按 `grass_region + dt + hour` 分区执行 INSERT OVERWRITE；
- 当前小时数据在该小时结束后约完成写入，存在一定延迟，不适合作为严格实时数据源；
- 历史数据存在 **2024-09-14 14:00 前数据补录** 的特殊边界，建议查询时从 `2024-09-15` 起或明确处理该边界。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `video_growth.video_chat_history__reg_continuous_s0_live` | 视频聊天原始日志流水，提供对话历史、会话/轮次 ID、端点、时间戳及分区字段（dt、hour、region）等全量字段 |

---

## ETL 逻辑摘要

### 数据流

```
video_growth.video_chat_history__reg_continuous_s0_live
    ──[过滤 dt、region + 历史数据特殊边界]──▶
        srdi_mart.dwd_sr_data_warehouse_video_chat_log
            分区：grass_region / dt / hour
```

### 关键步骤

1. **数据过滤**：从上游流水表中筛选满足以下条件的记录：
   - `date(dt) = ${local_date}`（当日数据）；
   - 历史补录边界：仅处理 2024-09-15 及之后的数据，或 2024-09-14 14:00（含）之后的数据，排除可能重复的早期记录；
   - `upper(region) = ${grass_region}`（按大区过滤，统一大写匹配）。

2. **字段转换**：
   - `round_id`：显式转换为 `bigint`；
   - `hour`：显式转换为 `int`；
   - 其余字段（`biz_session_id`、`history_details`、`history_metas`、`endpoint`、`time_stamp`）直接透传。

3. **分区写入**：以 `INSERT OVERWRITE` 方式写入目标表，动态分区为 `hour`，静态分区为 `grass_region` 和 `dt`（由调度参数 `${grass_region}`、`${local_date}` 注入）。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险，分区边界清晰；
- **INSERT OVERWRITE 幂等性**：每次调度对同一 `grass_region + dt + hour` 分区执行覆写，具有幂等性，支持任务重跑；
- **历史数据边界**：ETL SQL 中硬编码了 2024-09-14 14:00 的数据补录边界，该逻辑为历史一次性修复，后续若有类似补录需求需关注 SQL 变更；
- **region 大小写**：上游字段 `region` 原始值大小写不固定，ETL 通过 `upper(region)` 统一处理，下游查询中 `grass_region` 均为大写值。

---

*文档生成时间：2026-05-17*