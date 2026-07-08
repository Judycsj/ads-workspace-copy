<!-- ads-workspace-gdoc-sync: gdoc_id=1VWY4oSpAj7zoh-JhVKODD5-WhjHhX8I-HKtvxfopRGA gdoc_url=https://docs.google.com/document/d/1VWY4oSpAj7zoh-JhVKODD5-WhjHhX8I-HKtvxfopRGA/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf

**分层：** DWD（明细层）
**主键：** `grass_region` + `cspu_id` + `item_id` + `exp_tag` + `traffic_tag` + `version_date`
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour`
**更新频率：** 小时级实时更新（hf = hourly frequency）
**引用频次 / 访问频次：** 1466

---

## 业务描述

本表记录搜索替换（Search Replace）场景下，**以 CSPU 维度**对候选替换商品进行**实时（小时粒度）累计曝光、点击、加购**指标的明细数据，数据源自 Paimon 实时统计表。

**核心业务场景：**

- 搜索替换实验效果评估：按实验分组（`exp_tag`）和流量桶（`traffic_tag`）对比替换策略的转化表现。
- 替换版本管理：通过 `version_date` 标识每次版本重置后的最新统计窗口，支持下游做差分减法还原区间增量。
- 跨地区（`grass_region`）、跨时区（`local_date` / `regional_date`）的指标对齐。

**适合回答的问题：**

- 某个 CSPU / 商品在当前版本下的搜索替换曝光量、点击率、加购量是多少？
- 实验组与对照组（control）替换效果对比如何？
- 某地区最近一小时/一天的搜索替换漏斗数据？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 国家/地区标识，如 `ID`、`TH`、`MY` 等，数据按地区分区写入 |
| `local_date` | date | 当地时区日期，由新加坡时间（SG）转换为对应地区时区后的日期 |
| `local_hour` | int | 当地时区小时，由 SG 时间转换为对应地区时区后的小时（0–23） |
| `regional_date` | date | 新加坡时间（SG）对应的日期，即调度触发时的参考日期 |
| `regional_hour` | int | 新加坡时间（SG）对应的小时，即调度触发时的参考小时（0–23） |

### 维度：商品与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 标准商品单元 ID（Canonical SPU），替换候选商品的聚合维度 |
| `item_id` | bigint | 具体商品 ID，与 `cspu_id` 共同唯一标识一条替换记录 |
| `exp_tag` | string | 实验分组标签，如 `control`（对照组）或实验组编号，从上游 `tag_concat` 字符串中按 `:` 分割取第 2 段 |
| `traffic_tag` | string | 流量桶标签，标识流量来源或分桶策略，从 `tag_concat` 字符串中按 `:` 分割取第 1 段 |
| `version_date` | int | 当前统计版本日期（整型），标识最近一次版本重置的时间点；当 `exp_tag` 为 `control` 时强制置 0，其余情况取版本数组中对应位置的值；同一 `(cspu_id, item_id, exp_tag)` 组合仅保留最新版本 |

### 指标：搜索替换累计漏斗指标（版本内 N 日累计，后缀 `_nd`）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_nd` | bigint | 版本内累计曝光次数（N 日滚动累计，非区间增量） |
| `click_cnt_nd` | bigint | 版本内累计点击次数（N 日滚动累计，非区间增量） |
| `atc_cnt_nd` | bigint | 版本内累计加购次数（N 日滚动累计，Add-to-Cart，非区间增量） |

---

## 查询使用须知

### 必须包含的过滤条件

- **务必指定 `grass_region`**：数据按国家分区写入，跨地区查询会触发全分区扫描，严重影响性能。
- **务必指定 `regional_date` + `regional_hour`**（或 `local_date` + `local_hour`）：表为小时级分区，不限制时间范围会导致全量历史扫描。
- 如需获取当前快照，通常取最新一个小时分区；如需当日数据，过滤 `regional_date = current_date`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt_nd` / `click_cnt_nd` / `atc_cnt_nd` | 后缀 `_nd` 表示版本内**滚动累计值**，不同小时分区的同一条记录之间存在重叠计数，**不可跨小时分区直接 SUM**；如需区间增量，需由下游用相邻版本差分计算 |
| `version_date` | 版本标识字段，无数值聚合意义，不可 SUM/AVG |

- 同一 `(grass_region, cspu_id, item_id, exp_tag)` 在同一小时分区内可能存在多个 `traffic_tag`，按业务需求决定是否跨 `traffic_tag` 聚合。
- 跨 `version_date` 直接累加无业务意义，版本重置后计数从 0 重新开始。

### 时效性说明

- 本表为**小时级准实时表**（hf），数据延迟通常为当前小时结束后数分钟内可用。
- 指标字段均为**版本内滚动累计（`_nd`）**，非单小时增量，使用时需结合 `version_date` 判断统计窗口起点。
- 时区转换以**新加坡时间（SG）为基准**，`local_date`/`local_hour` 已转换为各地区本地时区，使用时注意区分两套时间维度。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.srdi_mart.cheapest_item_replacement_statistics_search_v2_dump` | 搜索替换实验的实时统计原始表，包含按 tag 数组排列的曝光、点击、加购累计值及版本信息，按 `country` 字段过滤当前地区数据 |

---

## ETL 逻辑摘要

### 数据流

```
paimon.srdi_mart.cheapest_item_replacement_statistics_search_v2_dump
    （按 country 过滤，lateral view posexplode 展开 tag_array）
        ↓
  [TempView] traffic_tag_metrics_{region}
    （提取 exp_tag、traffic_tag、version_date 及各指标）
        ↓
  [TempView] current_version_{region}
    （按 cspu_id + item_id + exp_tag 分组，取 max(version_date)）
        ↓
  INSERT OVERWRITE → dwd_sr_data_warehouse_pb_search_replace_realtime_metrics_hf
    （与 current_version 内连接，仅保留最新版本记录；附加时区转换生成 local_date/local_hour）
```

### 关键步骤

**Step 1 — TempView `traffic_tag_metrics_{region}`**
- 从上游 Paimon 表按 `country` 过滤当前 `grass_region` 的数据。
- 使用 `lateral view posexplode(tag_array)` 将数组形式的 tag 及对应指标数组按位置展开为行。
- 从 `tag_concat`（格式为 `traffic_tag:exp_tag`）中拆分出 `traffic_tag`（第 0 段）和 `exp_tag`（第 1 段）。
- `version_date` 双重兜底：当 `exp_tag = 'control'` 时强制赋值为 `0`，否则取 `version_array[pos]`。
- 按位置对齐提取 `imp_cnt_nd`、`click_cnt_nd`、`atc_cnt_nd`。

**Step 2 — TempView `current_version_{region}`**
- 对 Step 1 的结果按 `(cspu_id, item_id, exp_tag)` 分组，取 `max(version_date)` 以处理同一实验组下因多个 `traffic_tag` 导致版本不一致的问题，确保仅保留最新版本。

**Step 3 — INSERT OVERWRITE 写入目标表**
- 将 Step 1 结果与 Step 2 结果做 `INNER JOIN`，关联条件为 `(item_id, cspu_id, exp_tag, version_date)`，以此过滤掉非最新版本的历史记录。
- 调用 `date_timezone_convert` 函数将调度参数 `regional_date`/`regional_hour`（SG 时间）转换为对应 `grass_region` 的本地时区，生成 `local_date` 和 `local_hour`。
- 以 `INSERT OVERWRITE` 方式写入，分区键为 `(grass_region, local_date, local_hour, regional_date, regional_hour)`。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件，不存在 multi-writer 并发写入风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE … PARTITION` 模式，每次调度覆盖当前小时分区，具有幂等性，重跑安全。
- **参数化地区**：SQL 通过 `${grass_region}` / `${grass_region_without_quote}` 参数化，同一脚本支持多地区调度，TempView 名称含地区后缀以避免并发会话冲突。
- **版本重置场景**：上游表存在点对点触发的版本重置机制，同一实验组下不同 `traffic_tag` 可能处于不同版本，Step 2 的 `max(version_date)` 逻辑是对此场景的显式处理，下游使用时需注意 `version_date` 变化意味着累计指标归零重新计算。
- **`_nd` 指标语义**：字段名中的 `nd` 并非固定 N 天窗口，而是"当前版本内至今的累计值"，窗口长度由 `version_date` 决定，跨小时分区或跨版本聚合需特别谨慎。

---

*文档生成时间：2026-05-17*