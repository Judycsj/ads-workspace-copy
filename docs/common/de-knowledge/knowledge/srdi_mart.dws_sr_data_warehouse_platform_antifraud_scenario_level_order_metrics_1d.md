<!-- ads-workspace-gdoc-sync: gdoc_id=1op9cWJ4H0syU1Q0kzxTncRaBoKLF99uJArG64K0R37M gdoc_url=https://docs.google.com/document/d/1op9cWJ4H0syU1Q0kzxTncRaBoKLF99uJArG64K0R37M/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_antifraud_scenario_level_order_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `scenario` + `is_ads` + `antifraud_tag`
**分区：** `grass_region`（地区）, `local_date`（业务日期）
**更新频率：** 每日一次（覆盖写，保留近 15 天滚动窗口数据）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表是搜推数仓平台反欺诈专题的**场景级订单指标汇总表**，粒度为「地区 × 业务场景 × 是否广告 × 反欺诈标签 × 日期」。

表中数据由用户 × 商品级明细表聚合而来，每次执行时覆盖写入目标日期及其前 14 天（共 15 天）的数据，形成滚动刷新窗口，可用于持续修正当日及近期历史数据。

**核心业务场景：**
- 评估不同搜索 / 推荐场景下，被反欺诈系统识别为异常的订单规模与 GMV 占比；
- 对比广告流量与自然流量在反欺诈各标签下的订单分布差异；
- 支持反欺诈效果监控、场景维度的风险分析及平台质量治理。

**适合回答的问题示例：**
- 某地区最近 N 天（≤15 天），各场景下被标记为欺诈的订单数和 GMV 是多少？
- 广告订单与非广告订单在不同反欺诈标签下的质量差异如何？
- 哪个场景的反欺诈风险订单占比最高？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，标识数据所属的业务区域（如国家或大区），由 ETL 参数注入 |
| `local_date` | date | 业务日期分区，格式 `yyyy-MM-dd`，ETL 覆盖最近 15 天数据 |

### 维度：场景与流量类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario` | string | 业务场景，标识订单产生的搜索或推荐场景入口（如搜索、首页推荐等） |
| `is_ads` | string | 是否为广告流量，用于区分广告订单与自然流量订单 |

### 维度：反欺诈标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `antifraud_tag` | int | 反欺诈标签，标识订单被反欺诈系统识别的风险类型或等级；具体枚举值含义需参考业务字典 |

### 指标：订单量与交易额

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数，由上游用户 × 商品级明细表的 `order_cnt` 聚合（`SUM`）得到，代表场景维度下的订单总量 |
| `gmv` | double | 成交金额（GMV），由上游明细表的 `gmv` 聚合（`SUM`）得到，代表场景维度下的订单总 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（强制）**：查询时必须同时指定 `grass_region` 和 `local_date`，避免全表扫描：
  ```sql
  WHERE grass_region = 'your_region'
    AND local_date = '2024-01-01'
  ```
- **时效性注意**：ETL 每次执行会覆盖写入目标日期及其前 14 天的数据（滚动 15 天窗口）。若需获取稳定历史数据，建议使用距当前日期 **≥ 15 天**以前的分区，避免读到仍在刷新中的数据。

### 可直接 SUM 的字段

- `order_cnt`、`gmv` 均为加法可加指标，跨维度聚合时可直接 `SUM`。

### 不可直接 SUM 的字段

- 本表无比率、均值、去重或分位数指标，所有数值指标均支持直接聚合。
- `antifraud_tag` 为整型枚举维度字段，不应对其进行数值求和，应用于分组或过滤。

### 时效性说明

- 本表为 **`_1d`（按天）** 汇总表，每日调度刷新，每次覆盖最近 15 天数据分区。
- 当日数据在调度完成后方可查询，存在一定产出延迟，使用前建议确认最新分区是否已就绪。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_antifraud_user_item_level_order_metrics_1d` | 提供用户 × 商品粒度的反欺诈订单明细指标，本表在此基础上按场景、广告标识、反欺诈标签聚合 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_antifraud_user_item_level_order_metrics_1d
    （用户 × 商品级明细，近 15 天滚动窗口）
        │
        │  过滤：grass_region + [local_date - 14, local_date]
        │  聚合：GROUP BY scenario, is_ads, antifraud_tag, local_date
        │  指标：SUM(order_cnt), SUM(gmv)
        ▼
srdi_mart.dws_sr_data_warehouse_platform_antifraud_scenario_level_order_metrics_1d
    （场景级汇总，按 grass_region + local_date 分区覆盖写入）
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| 1 | 数据读取与过滤 | 从上游明细表读取指定 `grass_region` 、且 `local_date` 在 `[目标日期 - 14天, 目标日期]` 范围内的数据 |
| 2 | 维度聚合 | 按 `scenario`、`is_ads`、`antifraud_tag`、`local_date` 分组，对 `order_cnt` 和 `gmv` 执行 `SUM` |
| 3 | 分区覆盖写入 | 以 `INSERT OVERWRITE` 方式写入目标表，动态分区为 `grass_region`（静态，由参数注入） + `local_date`（动态） |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
- **覆盖写入范围**：每次执行将覆盖目标 `grass_region` 下近 15 个 `local_date` 分区的数据，历史分区数据会被刷新，下游不应缓存中间结果。
- **参数依赖**：`${grass_region}` 和 `${local_date}` 均为调度参数，调度脚本需确保参数正确传入，否则可能导致错误分区被覆盖。
- **上游依赖**：目标表产出依赖上游 `_user_item_level_` 明细表先行就绪，调度编排需保障上游先于本表完成。

---

*文档生成时间：2026-05-18*