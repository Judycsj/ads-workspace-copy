<!-- ads-workspace-gdoc-sync: gdoc_id=1uZSiAqoH_hSYXYd8U06BZ_TM2RSGVtvvp34XgosEeG8 gdoc_url=https://docs.google.com/document/d/1uZSiAqoH_hSYXYd8U06BZ_TM2RSGVtvvp34XgosEeG8/edit -->

# srdi_mart.dws_sr_data_warehouse_voice_search_session_level_metrics_1d

**分层**：dws_search（数据仓库服务层 - 搜索域）
**主键**：`voice_session_id` + `search_session_id`（联合唯一标识一条语音搜索会话记录）
**分区**：`grass_region`（站点/地区）、`local_date`（本地日期）
**更新频率**：每日调度，T+1 更新（覆盖写入，`INSERT OVERWRITE`）
**引用频次 / 访问频次**：1337

---

## 业务描述

本表以**语音搜索会话（Voice Search Session）**为粒度，汇聚用户在 Shopee 各搜索入口（全局搜索、PDP 内搜索、预填充搜索）发起语音搜索的全链路日指标，覆盖搜索行为指标、语音识别模型信息、用户体验时延指标及下游转化指标。

**核心业务场景：**
- 语音搜索功能的使用量、转化率（点击、下单、GMV）分析
- 语音识别模型效果对比（LLM 模型 vs. MPI 模型，或两者同时命中）
- 语音识别质量追踪：关键词纠错（`ori_keyword` vs. `mod_keyword`）、状态码链路、等待时延
- 儿童语音搜索（Kids Voice Search）专项分析
- 语音窗口曝光与点击漏斗分析（`voice_window_ctr`）
- 移动端 VAD（Voice Activity Detection）策略效果对比

**适合回答的典型问题：**
- 某站点某日语音搜索的日活用户数、会话数、点击率、成交率是多少？
- LLM / MPI 语音识别模型各自覆盖的会话比例及转化差异？
- 开启 Mobile VAD 的用户等待时延与未开启用户相比有何差异？
- 语音搜索无结果会话（`no_result_cnt > 0`）的占比及分布？
- 前端分类（`fe_classification`）与模型分类（`llm_classification`、`mpi_classification`）的一致性如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `ID`、`MY`、`TH` 等，所有查询必须携带此过滤条件 |
| `local_date` | date | 本地日期（按各站点时区换算），所有查询必须携带此过滤条件 |

---

### 维度：会话与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `voice_session_id` | string | 语音搜索会话 ID，来自 DWD 搜索宽表 `voice_search_session_id` 字段，作为关联语音识别模型数据的核心键 |
| `search_session_id` | string | 搜索会话 ID；当搜索行为存在时取自搜索宽表，无结果会话通过 FULL JOIN 从 `no_result_cnt` 补全 |
| `qp_request_id` | string | 搜索请求 ID（来自 `dws_search_metrics` 中的 `request_id`），用于关联 Query Service 日志 |
| `user_id` | bigint | 用户 ID，过滤 `user_id > 0` 排除无效用户 |

---

### 维度：语音识别与关键词

| 字段 | 类型 | 说明 |
|---|---|---|
| `ori_keyword` | string | 用户原始语音识别关键词（Kids 语音搜索场景，来自 ODS Query Service 日志 `kids_voice_search.ori_keyword`） |
| `mod_keyword` | string | 经改写后的关键词（Kids 语音搜索场景，来自 ODS Query Service 日志 `kids_voice_search.mod_keyword`） |
| `audio_url` | string | 语音音频文件 URL；优先取 LLM 模型记录，若缺失则回退到 MPI 模型记录（`COALESCE(llm.audio_url, mpi.audio_url)`） |
| `llm_response` | string | 语音识别结果文本；优先取 LLM 模型 `response`，若缺失则取 MPI 模型 `response.text`（`COALESCE`） |
| `llm_classification` | string | LLM 模型对语音请求的意图分类标签（来自 `compass_voice_search_scheduled` 的 `request.classification`） |
| `llm_is_realtime` | boolean | 是否为实时流式语音识别模式（LLM 模型）；`true` 表示实时，`false` 表示非实时 |
| `model_source` | string | 命中的语音识别模型来源：`LLM`（仅 LLM）、`MPI`（仅 MPI）、`BOTH`（两者均命中）、`NULL`（均未命中） |
| `language` | string | 语音识别使用的语言（来自 MPI 模型请求参数 `request.language`） |
| `segments` | string | 语音识别分段信息（来自 MPI 模型请求参数 `request.segments`，JSON 格式字符串） |
| `mpi_classification` | int | MPI 模型（AudioAI ASR）对语音请求的分类标签（来自 `response.labels.classification`，转为整型） |
| `fe_classification` | int | 前端（FE）上报的语音搜索分类标签（来自 DWD Platform 表 `fe_voice_search_classification`，取最大值） |

---

### 维度：用户体验与设备特征

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_kid` | boolean | 是否为儿童语音搜索请求（来自 ODS Query Service 日志，`kids_voice_search` 字段非空时为 `true`） |
| `use_mobile_vad` | boolean | 是否使用移动端 VAD（Voice Activity Detection）；优先从 DWD Platform 关联，其次从搜索宽表补充 |
| `is_manual_stop` | boolean | 用户是否手动停止录音（来自 DWD Platform 表 `fe_status_code_info` 聚合） |
| `status_code_info` | array\<string\> | 前端语音识别状态码链路数组（来自 DWD Platform 的 `fe_status_code_info`，每个元素含状态码、时间戳、识别结果等结构信息） |

---

### 指标：搜索行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 语音搜索结果页曝光次数（`operation = 'impression'`，`target_type IN ('item','video','livestream')`） |
| `click_cnt` | bigint | 语音搜索结果页点击次数（`operation = 'click'`） |
| `no_result_cnt` | bigint | 语音搜索无结果曝光次数（`target_type = 'no_recall_general'`，`operation = 'impression'`） |

---

### 指标：转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 语音搜索归因下单件数，汇聚 source0/source1/source2 三层归因链路 |
| `gmv` | double | 语音搜索归因成交金额（GMV），汇聚三层归因链路 |

---

### 指标：时延与体验

| 字段 | 类型 | 说明 |
|---|---|---|
| `wait_time` | bigint | 用户等待语音识别完成的时长（毫秒），基于状态码时间戳计算：最终识别结果时间戳 MAX - 录音起始时间戳 MIN |
| `delay_time` | double | 相邻状态码事件间隔的平均值（毫秒），通过 `LEAD` 窗口函数计算各状态码时间戳差值后取均值，反映识别过程中的平均帧间延迟 |

---

### 指标：语音窗口漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `voice_window_ctr` | double | 语音窗口点击率，计算公式：`voice_window_click_cnt / voice_window_imp_cnt`（用户级别汇总后相除，**不可直接 SUM**） |

---

## 查询使用须知

### 必须携带的过滤条件

- **分区过滤**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全表扫描，严重影响性能和集群稳定性：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-15'
  ```
- 若需查询多日数据，建议使用 `local_date BETWEEN '...' AND '...'` 并限制时间范围。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `voice_window_ctr` | 比率型指标，由用户级 `click_cnt / imp_cnt` 计算得到；跨会话聚合应重新从分子/分母原始数据计算 |
| `delay_time` | 均值型指标（各状态码帧间隔的平均值），直接 SUM 无统计意义，跨会话聚合需回溯原始状态码序列或以加权方式处理 |
| `wait_time` | 会话级时延，跨会话应使用 `AVG`/分位数而非 `SUM` |
| `gmv` | 含多层归因（source0/source1/source2），跨粒度聚合时注意归因口径一致性，避免重复计数 |
| `order_cnt` | 同 `gmv`，含多层归因叠加，跨粒度聚合注意归因重叠 |
| `status_code_info` | `array<string>` 类型，不可数值聚合，需配合 `EXPLODE` 展开后使用 |

### 时效性说明

- 本表为 **日粒度（1d）** 表，数据为 T+1 可用（当日数据次日产出）。
- LLM 模型数据源（`compass_voice_search_scheduled`）和 MPI 模型数据源（`audioai_model_log`）均采用 `dt BETWEEN DATE_SUB(local_date, 1) AND DATE_ADD(local_date, 1)` 的宽窗口拉取，以兼容非亚洲站点时区偏移及印尼（ID）23 点边界问题，最终通过时区转换对齐至本地日期。
- `ods_query_service_analysis_log_1h_raw` 亦使用宽窗口（`local_date` 至 `local_date + 1`）并做时区转换过滤，确保各站点数据准确归属。

### 其他注意事项

- `voice_session_id` 与 `search_session_id` 不一定同时存在：无搜索结果的会话可能只有 `search_session_id`（通过 FULL JOIN 补入），无语音识别记录的搜索会话可能 `voice_session_id` 为 NULL。
- `model_source` 为 `NULL` 表示该会话在 LLM 和 MPI 模型日志中均未找到记录，不等价于识别失败。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 核心搜索行为宽表，提供点击、曝光、下单行为事件及三层归因（source0/source1/source2），以及无结果曝光统计、Mobile VAD 标记 |
| `search_data.ods_query_service_analysis_log_1h_raw` | Query Service 原始日志，提供 Kids 语音搜索标记（`is_kid`）及原始/改写关键词 |
| `llm_algo.compass_voice_search_scheduled` | LLM 语音搜索模型日志，提供音频 URL、识别文本、意图分类、是否实时流式等信息 |
| `audioai_data_one.audioai_model_log__reg_continuous_s0_live` | MPI（AudioAI ASR）模型日志，提供音频 URL、识别文本、语言、分段及分类标签 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台行为宽表（pre_search 页面），提供前端状态码链路（`fe_status_code_info`）、Mobile VAD 标记、手动停止标记、前端分类 |
| `srdi_mart.dws_sr_data_warehouse_search_global_session_level_metrics_1d` | 全局搜索会话级日表，提供用户维度语音窗口点击次数（`action_voice_search_cnt`）用于计算 CTR 分子 |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 平台用户基准日表，提供 `pre_search` 页 `voice_window` 区块曝光次数，用于计算 CTR 分母 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search
  └─► dwd_search_metrics (click/imp/order/gmv，三层归因 UNION)
        └─► dws_search_metrics (按 user_id + search_session_id 聚合)

ods_query_service_analysis_log_1h_raw
  └─► ods_query_service (is_kid / ori_keyword / mod_keyword)

compass_voice_search_scheduled
  └─► llm_voice_search_raw → llm_voice_search_json_cols
        ├─► llm_voice_search_realtime (实时流，取最小 chunk_id)
        └─► dws_llm_voice_search (非实时 UNION 实时最小 chunk)

audioai_model_log__reg_continuous_s0_live
  └─► mpi_voice_search (ASR 模型日志)

dwd_sr_data_warehouse_platform
  ├─► dwd_status_code_info (状态码链路 + VAD + 手动停止)
  │     ├─► status_code_info_explode (EXPLODE 展开)
  │     │     ├─► status_code_next_timestamp → status_code_avg_delay_time (delay_time)
  │     │     ├─► status_code_final_recog_result (最终识别结果锚点)
  │     │     └─► status_code_wait_time (wait_time)
  │     └─► (status_code_info 直接输出)
  ├─► use_mobile_vad_link (VAD 标记 via 搜索宽表补充路径)
  └─► fe_classification (前端分类)

dws_sr_data_warehouse_search_global_session_level_metrics_1d
  └─► voice_window_click (用户维度语音窗口点击总数)

dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d
  └─► voice_window_impression (用户维度语音窗口曝光总数)

最终 INSERT OVERWRITE：以 dws_search_metrics 为主驱动表，
通过 LEFT JOIN / FULL JOIN 关联以上所有中间视图写入目标表。
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `dwd_search_metrics` | 从 DWD 搜索宽表按 voice_search 过滤，UNION 三层归因（source0 含 click/imp/order，source1/source2 仅 order）提取原始行为事件 |
| Step 2 | `dws_search_metrics` | 对 Step 1 按 `(user_id, search_session_id)` 分组，聚合 click_cnt、imp_cnt、order_cnt、gmv，取 MAX voice_session_id 和 request_id |
| Step 3 | `ods_query_service` | 从 Query Service 日志提取 is_kid 标记及 Kids 场景关键词，宽窗口 + 时区转换对齐本地日期 |
| Step 4 | `llm_voice_search_raw` → `llm_voice_search_json_cols` | 解析 LLM 模型 JSON 请求/响应，提取 voice_session_id、audio_url、classification、is_realtime、finished |
| Step 5 | `llm_voice_search_realtime` | 对实时流式请求（`is_realtime=true, finished=true`），按 `voice_session_id` 分组取最小 `chunk_id`（含音频的首帧） |
| Step 6 | `dws_llm_voice_search` | 合并非实时记录与实时首帧记录，形成 LLM 模型会话级唯一记录 |
| Step 7 | `dwd_status_code_info` | 从 DWD Platform 表聚合前端状态码数组、VAD 标记、手动停止标记 |
| Step 8 | `status_code_info_explode` | LATERAL VIEW EXPLODE 展开状态码数组为逐行结构体 |
| Step 9 | `status_code_next_timestamp` | 使用 `LEAD` 窗口函数计算相邻状态码时间戳差，用于后续 delay_time 计算 |
| Step 10 | `status_code_avg_delay_time` | 对 Step 9 按 voice_session_id 聚合，取帧间隔均值得到 `delay_time` |
| Step 11 | `status_code_final_recog_result` | 确定最终识别结果锚点：非 VAD 取 `status_code=200` 行，VAD 取 `status_code=9002 AND finished=true` 的最新时间戳行 |
| Step 12 | `status_code_wait_time` | JOIN Step 8 与 Step 11，计算 `MAX(终点时间戳) - MIN(起点时间戳)` 得到 `wait_time` |
| Step 13 | `no_result_cnt` | 从 DWD 搜索宽表过滤 `target_type='no_recall_general'` 统计无结果曝光数 |
| Step 14 | `use_mobile_vad_link` | 从 DWD 搜索宽表补充 voice_session_id 维度的 Mobile VAD 标记 |
| Step 15 | `mpi_voice_search` | 从 AudioAI 模型日志提取 MPI 识别结果、语言、分段及分类 |
| Step 16 | `voice_window_click` | 从全局搜索会话日表按用户汇总语音窗口点击总数 |
| Step 17 | `voice_window_impression` | 从平台基准日表按用户汇总 voice_window 区块曝光总数 |
| Step 18 | `fe_classification` | 从 DWD Platform 表提取前端上报的语音分类标签 |
| Step 19 | **INSERT OVERWRITE** | 以 `dws_search_metrics` 为驱动，FULL JOIN `no_result_cnt`（兼顾无搜索行为的纯无结果会话），LEFT JOIN 其余所有中间视图，写入目标表指定分区 |

### 注意事项

- **单一写入文件**：本表由单个 ETL 文件写入，无 multi-writer 风险，但采用 `INSERT OVERWRITE PARTITION` 方式，每次运行会全量覆盖指定 `(grass_region, local_date)` 分区，重跑幂等安全。
- **LLM 实时流处理逻辑**：实时模式（`is_realtime=true`）下只有最小 `chunk_id` 携带音频 URL，ETL 通过 `ROW_NUMBER` 取 rank=1 来保证不丢失音频信息；非实时模式则直接使用完整记录。
- **`model_source` 判断逻辑**：依赖 LLM 与 MPI 两路数据均完成 LEFT JOIN 后，通过 CASE WHEN 对 `voice_session_id` 匹配情况分类，空值表示两个模型均无记录，非识别失败。
- **`voice_window_ctr` 除零风险**：当 `voice_window_imp_cnt = 0` 时，计算 `1.0 * click_cnt / imp_cnt` 将产生除零异常或 `Infinity`，下游使用时需做空值或除零保护。
- **时区宽窗口策略**：LLM 和 MPI 数据源均采用 `[local_date - 1, local_date + 1]` 三日宽窗口抓取，再配合时区过滤对齐，需注意不同站点（尤其是 ID）在边界日期可能拉取较大数据量。
- **FULL JOIN 语义**：`no_result_cnt` 通过 FULL JOIN 接入，意味着即使该 `search_session_id` 在主表（搜索行为路径）中无任何点击/曝光记录，只要有无结果曝光，也会产生一行输出，此类记录的 `user_id`、`click_cnt`、`imp_cnt` 等字段将为 NULL。

---

*文档生成时间：2026-05-17*