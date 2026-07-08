<!-- ads-workspace-gdoc-sync: gdoc_id=19Lc3jkKsstHArOaGlGURKOYbj0dYczfh7Cyp9V9eRJ0 gdoc_url=https://docs.google.com/document/d/19Lc3jkKsstHArOaGlGURKOYbj0dYczfh7Cyp9V9eRJ0/edit -->

# srdi_mart.dwd_sr_data_warehouse_abtest_traffic_user_group

**分层：** DWD（明细层）
**主键：** `grass_region` + `local_date` + `local_hour` + `user_id` + `device_id` + `exp_group_id`（联合唯一）
**分区：** `grass_region` / `local_date` / `local_hour`
**更新频率：** 双写模式；日粒度分区（`local_hour = -1`）每日全量覆写，小时粒度分区（`local_hour >= 0`）每小时覆写
**引用频次 / 访问频次：** 235

---

## 业务描述

本表记录搜推平台 A/B 实验流量中**用户与实验组**的归属明细，是搜推 A/B 实验分析的核心流量宽表。

**核心业务场景：**
- 追踪每个用户（`user_id`）或设备（`device_id`）在某个实验组（`exp_group_id`）下产生的曝光、点击、加购、下单、PDP 浏览等行为流量；
- 支持实验组维度的 UV、去重用户数、小时级与天级实验效果监控；
- 作为上游明细表，向 ADS/DWS 层聚合表输出实验组流量基础数据。

**适合回答的问题：**
- 某实验组在某天（或某小时）内有哪些用户/设备参与？
- 某实验组的每日/每小时独立用户规模是多少？
- 各站点（`grass_region`）实验组流量分布情况如何？
- 实验上线后流量是否在预期时间内完成分桶曝光？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识（如 US、SG 等），用于多地域分区隔离 |
| `local_date` | date | 本地日期，对应行为发生的自然日 |
| `local_hour` | int | 本地小时；日粒度写入时固定为 `-1`，小时粒度写入时为实际小时（0–23） |

### 维度：用户与实验标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 注册用户 ID；未登录用户可能为空或 0，需结合 `device_id` 联合标识用户 |
| `device_id` | string | 设备唯一标识，用于覆盖未登录用户的流量归因 |
| `exp_group_id` | bigint | A/B 实验组 ID；由上游 `exp_group_ids` 数组展开（explode）而来，每行对应一个实验组，值恒大于 0 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区过滤**：查询时务必同时指定 `grass_region`、`local_date`，以避免全表扫描。
2. **小时分区区分**：
   - 查询**天级**数据时，需加 `local_hour = -1`；
   - 查询**小时级**数据时，需加 `local_hour = <具体小时>`（0–23）；
   - 若同时查询天级与小时级，需显式列举或使用 `local_hour >= -1` 并注意去重逻辑，避免数据重叠计算。

### 不可直接 SUM / COUNT 的字段

- **`user_id` / `device_id` 的去重统计**：同一用户可能在同一实验组内多次出现（多次行为事件），统计实验组 UV 时必须使用 `COUNT(DISTINCT user_id)` 或 `COUNT(DISTINCT device_id)`，不可直接 `COUNT(*)`。
- **跨 `local_hour` 汇总**：日粒度分区（`local_hour = -1`）与小时粒度分区（`local_hour >= 0`）的行为操作类型不同（见数据来源说明），两者不可混合聚合，否则会造成口径混用。

### 时效性说明

- **日粒度分区**（`local_hour = -1`）：T+1 产出，覆盖前一自然日 `omni_impression`、`omni_click`、`cart`、`order`、`ppv` 五类操作。
- **小时粒度分区**（`local_hour >= 0`）：准实时，每小时滚动产出，覆盖当日当小时 `impression`、`click`、`view` 三类操作。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推平台行为明细宽表，提供 `user_id`、`device_id`、`exp_group_ids`、行为操作类型及时间维度；本表所有数据均源自该表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │
        ├─── [日粒度 ETL] 过滤 operation IN (omni_impression, omni_click, cart, order, ppv)
        │     local_hour 固定写 -1
        │     explode(exp_group_ids) → exp_group_id
        │     ↓
        │   INSERT OVERWRITE ... partition(grass_region, local_date, local_hour=-1)
        │
        └─── [小时粒度 ETL] 过滤 operation IN (impression, click, view) & local_hour=<N>
              local_hour 保留实际小时值
              explode(exp_group_ids) → exp_group_id
              ↓
            INSERT OVERWRITE ... partition(grass_region, local_date, local_hour=N)
```

### 关键步骤

**ETL 1：日粒度写入（`_di.sql`）**

| 步骤 | 描述 |
|---|---|
| Statement 1 — Temporary View | 从 `dwd_sr_data_warehouse_platform` 过滤指定站点、指定日期，行为类型限定为 `omni_impression`、`omni_click`、`cart`、`order`、`ppv`，且 `exp_group_ids` 非空（`size > 0`）；`local_hour` 硬编码为 `-1` 作为日粒度标识 |
| Statement 2 — INSERT OVERWRITE | 对 `exp_group_ids` 数组执行 `LATERAL VIEW EXPLODE`，将每个 `exp_group_id` 展开为独立行，过滤 `exp_group_id > 0`，按动态分区写入目标表 |

**ETL 2：小时粒度写入（`_hi.sql`）**

| 步骤 | 描述 |
|---|---|
| Statement 1 — Temporary View | 从 `dwd_sr_data_warehouse_platform` 过滤指定站点、指定日期、**指定小时**，行为类型限定为 `impression`、`click`、`view`，且 `exp_group_ids` 非空；`local_hour` 保留实际值 |
| Statement 2 — INSERT OVERWRITE | 同上，对 `exp_group_ids` 执行 `LATERAL VIEW EXPLODE` 展开，过滤 `exp_group_id > 0`，按动态分区写入目标表 |

### 注意事项

1. **Multi-Writer 并发风险**：本表由两个独立 Spark Job（日粒度 `_di` 和小时粒度 `_hi`）写入不同的 `local_hour` 分区。两者写入分区互不重叠（`-1` vs `0–23`），正常情况下不存在分区冲突，但需注意调度时序，避免日粒度 Job 与小时粒度 Job 在极端情况下写入相同分区。
2. **INSERT OVERWRITE 覆写语义**：每次执行均为分区级别的全量覆写，重跑历史分区数据安全，但调度过程中避免同一分区的并发写入。
3. **行为操作类型口径差异**：日粒度与小时粒度的 `operation` 过滤集合**不同**（前者为全渠道 omni 操作，后者为标准曝光/点击/浏览），下游使用时须关注两套数据的口径差异，不可混用。
4. **`exp_group_id` 展开后行数膨胀**：一条原始行为记录可能携带多个实验组 ID，explode 后行数会成倍增加，下游聚合时注意去重。

---

*文档生成时间：2026-05-17*