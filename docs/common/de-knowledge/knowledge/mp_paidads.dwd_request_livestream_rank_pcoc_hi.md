<!-- ads-workspace-gdoc-sync: gdoc_id=1zhZ0K55VQJ7t-THGptjOb15MpbG7jWkOhk5uHqxgoao gdoc_url=https://docs.google.com/document/d/1zhZ0K55VQJ7t-THGptjOb15MpbG7jWkOhk5uHqxgoao/edit -->

# mp_paidads.dwd_request_livestream_rank_pcoc_hi

**分层**：DWD（明细数据层）
**主键**：`grass_date` + `grass_region` + `h` + `ads_id` + `user_id` + `request_id` + `ls_session_id` + `placement` + `streamer_id` + `streamer_type`
**分区**：`grass_date`（日期）、`grass_region`（地区）、`h`（小时）
**更新频率**：每小时更新（Hudi MERGE INTO，增量滚动写入）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录直播广告排名请求粒度的点击出价置信度（PCOC）明细数据，每行对应一次广告请求中某个广告位（`placement`）下某条广告（`ads_id`）的排名信号与多时间窗口绩效快照。表名中 `pcoc` 代表 **Predicted Click-Over-Cost**，即将点击率预估（pCTR）与点击转化率预估（pCR）联合用于广告排序定价的核心评分体系。

本表的核心价值在于将实时排名侧信号（pCTR、pCR）与报表侧实际曝光、下单、消耗数据在请求粒度上打通，支撑直播广告排序模型效果评估、出价策略归因、实时 A/B 实验监控等场景。各时间窗口指标（1h / 3h / 6h）采用滚动写入策略，同一请求记录在每小时调度中被累积更新，因此可用于观察广告效果随时间的衰减与放大规律。

本表以 Apache Hudi 格式存储，通过 `MERGE INTO` 进行增量 Upsert，各地区按本地时区参数化调度，覆盖全球所有开通直播广告的市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码（大写），如 `ID`、`TH`、`VN` 等，用于分区裁剪 |
| `grass_date` | date | 本地日期（由上游 `local_date` 映射而来），各地区按本地时区参数化调度 |
| `h` | int | 本地小时（0–23），与 `grass_date` 共同定位到小时粒度分区；同一请求在后续调度中会被 3h、6h 窗口更新覆盖 ⚠️ 该字段同时作为 Hudi 主键组成部分，直接过滤时需与 `grass_date`、`grass_region` 联合使用 |

### Hudi 系统字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `_hoodie_commit_seqno` | string | Hudi 提交序列号，系统内部字段，业务查询无需使用 |
| `_hoodie_commit_time` | string | Hudi 提交时间戳，可用于追溯数据写入时间，业务查询无需使用 |
| `_hoodie_file_name` | string | Hudi 存储文件名，系统内部字段，业务查询无需使用 |
| `_hoodie_partition_path` | string | Hudi 分区路径，系统内部字段，业务查询无需使用 |
| `_hoodie_record_key` | string | Hudi 记录唯一键，系统内部字段，业务查询无需使用 |

### 维度：主键与广告请求属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `request_id` | string | 广告请求唯一标识，与 `ads_id` 联合构成本表业务主键的核心 |
| `ads_id` | bigint | 广告 ID，标识参与本次请求排名的具体广告素材 |
| `user_id` | bigint | 发起广告请求的用户 ID（受众侧） |
| `ls_session_id` | bigint | 直播场次 ID，标识本次广告所属的直播会话 |
| `streamer_id` | bigint | 主播 ID，标识直播间归属主播 |
| `streamer_type` | int | 主播类型，枚举值，区分不同类别主播（如官方、达人等），具体枚举含义需参考维表 |
| `placement` | int | 广告位类型，枚举值，标识广告在直播间中的展示位置（如浮窗、购物车等） |

### 指标：排名模型预估信号

| 字段 | 类型 | 说明 |
|------|------|------|
| `pctr` | double | 预估点击率（Predicted Click-Through Rate），由排名模型输出，为 0~1 之间的概率值 ⚠️ 为预计算比率，不可直接 SUM，聚合时需用加权平均或分子/分母重新计算 |
| `pcr` | double | 预估点击转化率（Predicted Click-to-Order Rate），排名评分使用的校准后版本 ⚠️ 为预计算比率，不可直接 SUM，聚合时需用加权平均或分子/分母重新计算 |
| `pcr_orig` | double | 预估点击转化率原始值（校准前），与 `pcr` 对比可观察校准效果 ⚠️ 为预计算比率，不可直接 SUM，聚合时需用加权平均或分子/分母重新计算 |

### 指标：1小时窗口绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `view_cnt_1h` | bigint | 请求发生后第 1 小时内的广告曝光次数 |
| `checkout_cnt_1h` | bigint | 请求发生后第 1 小时内的下单次数 |
| `ads_rev_usd_1h` | double | 请求发生后第 1 小时内的广告消耗（美元），由本地货币消耗除以汇率换算 ⚠️ 汇率取自前一日维表快照（`BIZ_YESTERDAY`），非实时汇率，跨地区对比时需注意汇率时效性 |

### 指标：3小时窗口绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `view_cnt_3h` | bigint | 请求发生后滚动 3 小时内的广告曝光次数 ⚠️ 每小时调度时累积更新，取最新分区数据即为当前最新 3h 累计值 |
| `checkout_cnt_3h` | bigint | 请求发生后滚动 3 小时内的下单次数 ⚠️ 同上，每小时 Upsert 更新 |
| `ads_rev_usd_3h` | double | 请求发生后滚动 3 小时内的广告消耗（美元） ⚠️ 汇率取自前一日维表快照，每小时 Upsert 更新 |

### 指标：6小时窗口绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `view_cnt_6h` | bigint | 请求发生后滚动 6 小时内的广告曝光次数 ⚠️ 每小时调度时累积更新，取最新分区数据即为当前最新 6h 累计值 |
| `checkout_cnt_6h` | bigint | 请求发生后滚动 6 小时内的下单次数 ⚠️ 同上，每小时 Upsert 更新 |
| `ads_rev_usd_6h` | double | 请求发生后滚动 6 小时内的广告消耗（美元） ⚠️ 汇率取自前一日维表快照，每小时 Upsert 更新 |

### 指标：24小时与7日窗口绩效（预留）

| 字段 | 类型 | 说明 |
|------|------|------|
| `view_cnt_24h` | bigint | 滚动 24 小时曝光次数 ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |
| `checkout_cnt_24h` | bigint | 滚动 24 小时下单次数 ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |
| `ads_rev_usd_24h` | double | 滚动 24 小时广告消耗（美元） ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |
| `view_cnt_7d` | bigint | 滚动 7 日曝光次数 ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |
| `checkout_cnt_7d` | bigint | 滚动 7 日下单次数 ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |
| `ads_rev_usd_7d` | double | 滚动 7 日广告消耗（美元） ⚠️ 当前 ETL 中固定写入 `NULL`，字段预留，暂不可用于分析 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区字段，避免触发全表扫描：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_region` | `grass_region = 'ID'`（大写地区码） | 扫描所有地区分区，资源浪费，可能超时 |
| `grass_date` | `grass_date = '2024-01-15'` 或指定日期范围 | 扫描全量历史数据，查询极慢 |
| `h` | 按需指定，如 `h = 14`；若分析全天可省略但需评估数据量 | 单日单地区数据量较大，建议同时过滤 `h` |

> ⚠️ 本表以 Hudi 格式存储，分区为 `grass_region` + `grass_date` + `h` 三级，缺少任一分区条件均可能导致大范围扫描。

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确计算方式 |
|------|----------|--------------|
| `pctr` | 预计算比率 | 聚合时使用加权平均：`SUM(pctr * view_cnt_1h) / NULLIF(SUM(view_cnt_1h), 0)` |
| `pcr` | 预计算比率（校准后） | 同上，以曝光或点击数加权 |
| `pcr_orig` | 预计算比率（校准前） | 同上，以曝光或点击数加权 |
| `ads_rev_usd_*` | 汇率换算派生字段 | 直接 SUM 可用于同地区汇总；**跨地区汇总**时需注意各地区汇率取自各自前一日快照，存在时效差异，建议回溯本地货币原值再统一换算 |
| `view_cnt_24h`、`checkout_cnt_24h`、`ads_rev_usd_24h`、`view_cnt_7d`、`checkout_cnt_7d`、`ads_rev_usd_7d` | 当前恒为 NULL | 不得参与任何计算，避免结果全部为 NULL；待上线后再使用 |

### 时效性说明

- **滚动窗口字段的时效性**：`view_cnt_3h`、`checkout_cnt_3h`、`ads_rev_usd_3h`、`view_cnt_6h`、`checkout_cnt_6h`、`ads_rev_usd_6h` 在每小时调度中通过 Hudi MERGE INTO 累积更新。同一 `(request_id, ads_id, grass_date, h, grass_region)` 记录的上述字段会被持续 Upsert，**查询时应取 Hudi 表的最新快照**，无需手工去重；但若下游有快照缓存，需确认缓存已刷新至最新提交。
- **汇率时效性**：`ads_rev_usd_*` 系列字段使用前一业务日（`BIZ_YESTERDAY`）的汇率换算，非实时汇率。跨天对比或汇率波动较大期间，数据存在约 1 日的汇率滞后。
- **1h 窗口字段**：`view_cnt_1h`、`checkout_cnt_1h`、`ads_rev_usd_1h` 在首次写入后不再被后续调度更新（MERGE 的 `WHEN MATCHED` 子句仅更新 3h 和 6h 字段），数据固定为请求发生当小时的快照值，时效性稳定。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.temp_request_livestream_rank_pcr_hi` | 提供请求粒度的排名侧信号，包含 `pctr`、`pcr`、`pcr_orig`、`local_date`、`local_h` 及广告维度信息 |
| `mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live` | 提供报表侧的曝光（`view`）、下单（`checkout`）、消耗（`cost`）明细，按 1h / 3h / 6h 时间窗口聚合 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 提供各地区前一业务日汇率，用于将本地货币消耗换算为美元 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.temp_request_livestream_rank_pcr_hi
  （排名信号：pctr, pcr, pcr_orig, local_date, local_h）
            │
            │  JOIN ON request_id + ads_id
            ▼
mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live
  （报表明细：view, checkout, cost）
  按 1h / 3h / 6h 窗口条件聚合
            │
            │  LEFT JOIN ON grass_region
            ▼
mp_order.dim_exchange_rate__reg_s0_live
  （汇率：exchange_rate，取前一业务日快照）
            │
            ▼
        output CTE
  （cost/100000 / exchange_rate → ads_rev_usd_*）
  （24h / 7d 字段写入 NULL）
            │
            ▼
  Hudi MERGE INTO（Optimistic Concurrency Control）
            │
  ┌─────────┴─────────┐
  │ MATCHED（已存在）  │  NOT MATCHED（新记录）
  │ 仅更新 3h + 6h 字段│  INSERT 全量字段
  └───────────────────┘
            │
            ▼
dwd_request_livestream_rank_pcoc_hi__reg_s0_live
（各地区按本地时区参数化调度，每小时执行）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `rank_pcr` | `mp_paidads.temp_request_livestream_rank_pcr_hi` | 过滤当前地区、当前小时的排名侧信号，提供 pCTR、pCR 及本地时间维度 |
| `report_ng_request` | `mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live` | 按 `request_id + ads_id` 聚合 1h / 3h / 6h 三个时间窗口的曝光、下单、本地货币消耗；`cost` 原始单位为 1/100000，聚合时除以 100000 还原 |
| `dim_exchage_rate` | `mp_order.dim_exchange_rate__reg_s0_live` | 取前一业务日各地区汇率，供本地货币→美元换算 |
| `output` | `rank_pcr` + `report_ng_request` + `dim_exchage_rate` | 将三路数据拼合，计算 USD 消耗指标，24h / 7d 字段填充 NULL，输出最终写入结构 |

### 注意事项

1. **Hudi 写入模式**：采用乐观并发控制（`optimistic_concurrency_control`）+ 文件系统锁（`FileSystemBasedLockProvider`），失败写入策略为 `LAZY`，自动清理关闭（`hoodie.clean.automatic=FALSE`）。生产环境中若出现并发写入冲突，需关注锁路径 `${HIVE_PATH}/dwd_request_livestream_rank_pcoc_hi__reg_s0_live/lock/6h` 下的锁文件残留。

2. **MERGE 更新范围限制**：`WHEN MATCHED` 仅更新 `checkout_cnt_3h`、`view_cnt_3h`、`ads_rev_usd_3h`、`checkout_cnt_6h`、`view_cnt_6h`、`ads_rev_usd_6h` 六个字段，其余字段（包括 1h 窗口指标、pCTR、pCR 等）在首次 INSERT 后**不会被后续调度覆盖**，保持初始写入值不变。

3. **cost 单位换算**：上游 `ods_log_ads_report_livestream_hi` 中 `cost` 字段以整数微分单位存储（实际金额 × 100000），ETL 中通过 `/ 100000.0` 还原为本地货币金额后再除以汇率得到 USD，下游若直接使用本地消耗原值需注意此换算关系。

4. **24h / 7d 字段均为 NULL**：当前版本 ETL 未实现 24h 和 7d 窗口的数据回填，六个相关字段（`view_cnt_24h`、`checkout_cnt_24h`、`ads_rev_usd_24h`、`view_cnt_7d`、`checkout_cnt_7d`、`ads_rev_usd_7d`）在所有写入路径中均为 `NULL`，查询时勿将其用于任何计算逻辑。

5. **JOIN 类型注意**：`rank_pcr` 与 `report_ng_request` 为 INNER JOIN，若某条请求在排名日志中存在但在报表日志中无曝光 / 下单 / 消耗记录（`view > 0 or checkout > 0 or cost > 0` 过滤后），该请求将不会写入本表；汇率维表为 LEFT JOIN，汇率缺失时 USD 字段为 NULL。

6. **时间参数说明**：SQL 中的 `${TS_1H}`、`${TS_3H}`、`${TS_6H}`、`${DT_1H}`、`${DT_6H}` 等为调度系统注入的时间参数，分别代表当前调度周期的各时间窗口边界，由调度平台按各地区本地时区计算后传入。

---

*文档生成时间：2026-04-22*