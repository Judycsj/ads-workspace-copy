<!-- ads-workspace-gdoc-sync: gdoc_id=1a8Gp_XMdZG-nNeWfKCowDu_0JrP8c6IDux_lrMfdctA gdoc_url=https://docs.google.com/document/d/1a8Gp_XMdZG-nNeWfKCowDu_0JrP8c6IDux_lrMfdctA/edit -->

# srdi_mart.ads_sr_data_warehouse_search_be_scores_metrics_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date` + `request_type`
**分区**：`grass_region`（大区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1）
**访问频次**：97 次

---

## 业务描述

本表汇总搜索后端（Search Backend）打分日志中各维度的得分及 Boost 参数指标，以日为粒度、大区为分区，按请求类型（广告/自然、虚拟商品/普通商品）进行分组聚合。

**核心业务场景：**
- 监控搜索后端对不同类型请求（广告 vs. 自然流量、虚拟商品 vs. 普通商品）的打分分布情况；
- 分析搜索排序模型各 Boost 参数（GMV Boost、Ads Boost、Rel Boost 等）随时间的变化趋势；
- 评估广告生态健康度，辅助排序策略调优和广告负载调整。

**适合回答的问题：**
- 某大区某日广告类虚拟商品的平均 CTR/CVR/CTCVR 打分是多少？
- 各请求类型的 eCPM、CPC 出价总量如何分布？
- `mergescore_boost`、`rel_boost` 等排序参数近期是否出现异常波动？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 PH、TH、MY 等），用于分区过滤 |
| `local_date` | date | 业务日期（本地日期），每日更新，用于分区过滤 |

### 维度：请求类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_type` | string | 请求类型分组，取值为 `ads_vitem`（广告+虚拟商品）、`ads_not_vitem`（广告+普通商品）、`organic_vitem`（自然流量+虚拟商品）、`organic_not_vitem`（自然流量+普通商品）|

### 指标：流量规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_count` | bigint | 该分组下的商品曝光记录数（COUNT），代表后端日志条目数量 |

### 指标：广告竞价与 eCPM

| 字段 | 类型 | 说明 |
|---|---|---|
| `cpc_bid` | double | 广告 CPC 出价总和（SUM），来源于 `ad_info.cpc_bid`，自然流量记录为 NULL |
| `ecpm` | double | eCPM 分值总和（SUM），来源于 `ad_info.ecpm` |
| `ecpm_weight` | double | eCPM 权重总和（SUM），来源于 `ad_info.ecpm_weight` |

### 指标：排序模型打分

| 字段 | 类型 | 说明 |
|---|---|---|
| `ctr` | double | CTR 预估分值总和（SUM），来源于后端日志 `ctr_score` |
| `cvr` | double | CVR 预估分值总和（SUM），来源于后端日志 `cvr_score` |
| `ctcvr` | double | CTCVR 预估分值总和（SUM），计算方式为 `SUM(ctr_score * cvr_score)` |
| `rel_score` | double | 相关性分值总和（SUM），来源于后端日志 `rel_lx_score` |

### 指标：排序 Boost 参数

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_boost` | double | GMV Boost 参数总和（SUM），来源于 `ads_mix_params.gmv_boost` |
| `mergescore_boost` | double | MergeScore Boost 参数总和（SUM），来源于 `ads_mix_params.mergescore_boost` |
| `ad_load_boost` | double | 广告负载 Boost 参数总和（SUM），来源于 `ads_mix_params.ad_load_boost` |
| `ads_boost` | double | 广告综合 Boost 参数总和（SUM），来源于 `ads_mix_params.ads_boost` |
| `order_boost` | double | 订单 Boost 参数总和（SUM），来源于 `ads_mix_params.order_boost` |
| `rel_boost` | double | 相关性 Boost 参数总和（SUM），来源于 `ads_mix_params.rel_boost` |
| `tc_boost` | double | TC（可信度/质量）Boost 参数总和（SUM），来源于 `ads_mix_params.tc_boost` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能。
- **`local_date`**：必须指定具体日期或日期范围，推荐使用等值过滤 `local_date = DATE '2025-01-01'`。
- 示例：
  ```sql
  WHERE grass_region = 'PH'
    AND local_date = DATE '2025-01-01'
  ```

### 不可直接 SUM 的字段

本表所有数值指标均为**分组预聚合后的 SUM 值**，跨 `request_type` 求和时需注意以下事项：

| 字段 | 注意事项 |
|---|---|
| `ctr`、`cvr`、`ctcvr`、`rel_score` | 为分值总和，**不代表比率**；若需计算平均打分，需除以 `item_count`，不可直接跨行 SUM 后得出均值 |
| `ctcvr` | 为 `SUM(ctr_score * cvr_score)`，非 `ctr * cvr`，不可用 `ctr / item_count * cvr / item_count` 反推 |
| `cpc_bid`、`ecpm`、`ecpm_weight` | 仅广告类型（`request_type IN ('ads_vitem', 'ads_not_vitem')`）有意义，自然流量对应值为 0 或 NULL，跨类型求和无业务意义 |
| 所有 Boost 字段 | 为排序参数的 SUM 值，跨 `request_type` 合并时仅作汇总使用，均值需除以 `item_count` |

### 时效性说明

- 本表为 **`_1d` 日级表**，每日 T+1 更新，反映前一自然日的数据；
- 不含实时或小时级数据，不适用于当日实时监控场景；
- 每次写入以 `INSERT OVERWRITE` 方式覆盖对应 `(grass_region, local_date)` 分区，历史分区数据不受影响。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 搜索后端原始打分日志，提供商品维度的广告标识、商品类型、CTR/CVR/相关性打分、广告竞价信息及排序 Boost 参数 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search_be_log
    │  过滤指定 grass_region + local_date
    ▼
be_log_data_raw（临时视图）
    │  JSON 解析 ad_info / ads_mix_params 字段
    │  标记 is_ads / is_vitem
    ▼
be_log_data_grouped（临时视图）
    │  按 request_type 分组聚合所有打分与 Boost 指标
    ▼
srdi_mart.ads_sr_data_warehouse_search_be_scores_metrics_1d
    （INSERT OVERWRITE 指定分区）
```

### 关键步骤

**Step 1 — 临时视图 `be_log_data_raw`**
- 从 DWD 层按 `grass_region` 和 `local_date` 过滤原始日志；
- 使用 `FROM_JSON` 将 `ad_info`（含 `cpc_bid`、`ecpm_weight`、`ecpm`）和 `ads_mix_params`（含多个 Boost 字段）从 JSON 字符串解析为结构体；
- 生成布尔派生列：`is_ads`（`ads_id > 0`）、`is_vitem`（`ctx_item_type = 2`）。

**Step 2 — 临时视图 `be_log_data_grouped`**
- 基于 `is_ads` 和 `is_vitem` 的组合，通过 `CASE WHEN` 派生 `request_type`（四分类）；
- 按 `request_type` 分组，对所有打分列（`ctr_score`、`cvr_score`、`rel_lx_score` 及 `ctr_score * cvr_score`）和 Boost 参数执行 `SUM` 聚合；
- 同步统计 `item_count`（行数）。

**Step 3 — INSERT OVERWRITE 写目标表**
- 以 `INSERT OVERWRITE ... PARTITION (grass_region, local_date)` 的静态分区方式写入目标表；
- 覆盖当次调度指定分区，不影响其他分区历史数据。

### 注意事项

- **单一 Writer**：该表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
- **静态分区覆写**：每次运行以 `INSERT OVERWRITE` 覆盖目标分区，重跑幂等安全，但若同一分区并发执行存在数据覆盖风险，需保障调度互斥。
- **JSON 解析依赖**：`ad_info` 和 `ads_mix_params` 字段依赖 DWD 层原始 JSON 格式，如上游字段结构变更，解析结果可能出现 NULL，影响所有广告竞价及 Boost 指标。
- **自然流量广告字段**：`is_ads = FALSE` 的记录，`ad_info` 字段通常为空 JSON，解析后 `cpc_bid`、`ecpm`、`ecpm_weight` 等字段均为 NULL，SUM 时对应 `organic_*` 分组的广告相关指标值为 0 或 NULL，属正常现象。

---

*文档生成时间：2026-05-17*