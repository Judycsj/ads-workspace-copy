<!-- ads-workspace-gdoc-sync: gdoc_id=1y8rc7cI_zoCgSnt0g6jAYKbACsWnK5lzoIce3dJZw9E gdoc_url=https://docs.google.com/document/d/1y8rc7cI_zoCgSnt0g6jAYKbACsWnK5lzoIce3dJZw9E/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_vitem

**分层**：DIM（维度层）
**主键**：`vitem_id`（在指定分区内唯一）
**分区**：`grass_region`（大区）/ `local_date`（本地日期）
**更新频率**：每日一次（按大区分区覆盖写入）
**访问频次**：28,318 次

---

## 业务描述

本表为搜推数仓（SRDI）虚拟 SKU（vSKU）维度表，记录各大区下每个 **vitem**（虚拟商品条目）的生命周期时间属性，包括首次创建日期与首次发布日期。

**核心业务场景**：
- 追踪 vitem 在各大区的首次出现时间（`create_local_date`）和首次发布时间（`publish_local_date`）；
- 为搜索、推荐算法提供 vitem 时效性维度，支撑新品识别、商品生命周期分析；
- 作为 vSKU 体系的基础维度被下游宽表和指标表关联使用。

**适合回答的问题**：
- 某 vitem 在某大区是什么时候第一次出现/发布的？
- 某日期在某大区新增了哪些 vitem？
- 指定 vitem 的上架年龄（当前日期 - `create_local_date`）是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 MY、TH、VN 等），按大区分区存储 |
| `local_date` | date | 数据业务日期（本地日期），每日全量覆盖写入 |

### 维度：vitem 基础属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品条目 ID，分区内主键；新 vitem 首次出现时由当日上游映射表引入 |
| `create_local_date` | date | vitem 在该大区的首次创建日期；存量 vitem 沿用历史值，当日新增 vitem 取当日分区日期 |
| `publish_local_date` | date | vitem 在该大区的首次发布日期；存量 vitem 沿用历史值，当日新增 vitem 取当日分区日期 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将触发全分区扫描，查询成本极高。
- **`local_date`**：建议指定单日（通常取最新业务日期），该表按日全量快照存储，不同日期分区的同一 `vitem_id` 数据语义等同于"截至该日的最新状态"。

```sql
-- 推荐写法示例
WHERE grass_region = 'MY'
  AND local_date = '2026-05-16'
```

### 不可直接聚合的字段

- 本表无数值指标字段，不存在直接 SUM/AVG 的场景。
- `vitem_id` 为 bigint 类型，**不可对其做算术聚合**，仅用于关联或计数（`COUNT(DISTINCT vitem_id)`）。
- 跨大区 `UNION`/`JOIN` 时注意 `vitem_id` 在不同 `grass_region` 下相互独立，不具备全局唯一性。

### 时效性说明

- 本表为**每日全量快照维度表**，每个 `(grass_region, local_date)` 分区保存截至该日所有存量 + 当日新增 vitem 的时间属性。
- `create_local_date` / `publish_local_date` 仅在 vitem **首次出现当日**被赋值为当日日期，后续日期分区沿用历史值，因此可跨分区比较。
- 若需获取最新状态，取 `local_date = current_date - 1`（T-1 数据，当日 ETL 完成后可用）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 自关联：读取前一日分区（`local_date - 1`）作为存量基线，保留历史 `create_local_date` 和 `publish_local_date` |
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | 读取当日分区，获取当日所有活跃 `vitem_id`，识别新增 vitem |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_vsku_vitem [local_date - 1]  ──┐
                                                      ├─ FULL OUTER JOIN ──▶ dim_sr_data_warehouse_vsku_vitem [local_date]
dim_sr_data_warehouse_vsku_model_mapping_hf [当日]  ──┘
```

整体逻辑为**增量合并快照**：以前一日自身分区为存量基线，与当日上游映射表取全外连接，生成当日最新全量快照并覆盖写入。

### 关键步骤

1. **Statement 1 — 构建存量基线视图（`before_data_*`）**
   从本表前一日分区（`local_date - 1`）读取所有存量 `vitem_id`，并携带其历史 `create_local_date`、`publish_local_date`。

2. **Statement 2 — 构建当日增量视图（`today_data_*`）**
   从上游高频映射表（`vsku_model_mapping_hf`）读取当日分区，按 `vitem_id` 去重，获得当日全量活跃 vitem 集合。

3. **Statement 3 — FULL OUTER JOIN 合并并写入目标分区**
   对存量与当日集合做全外连接（`on a.vitem_id = b.vitem_id`）：
   - 若 vitem 存在于存量（`a.vitem_id IS NOT NULL`）：保留历史 `create_local_date` 和 `publish_local_date`；
   - 若为当日新增 vitem（仅出现在 `b` 中）：`create_local_date` 和 `publish_local_date` 均设为当日日期；
   - 以 `INSERT OVERWRITE … PARTITION(grass_region, local_date)` 全量覆盖写入当日分区。

### 注意事项

- **自引用风险**：ETL 同时读取和写入同一张表（不同分区），需确保读取分区（`local_date - 1`）在写入分区（`local_date`）之前已完整落地，避免读写竞争。
- **首日冷启动**：若前一日分区不存在（如大区首次上线），`before_data` 视图为空，所有 vitem 均视为新增，`create_local_date` 和 `publish_local_date` 将以首日日期初始化。
- **single-writer**：本表为单 ETL 文件写入（`multi_writer: false`），不存在多文件并发写入同一分区的风险。
- **分区覆盖模式**：写入方式为 `INSERT OVERWRITE`，每次执行会完整替换目标 `(grass_region, local_date)` 分区数据，重跑安全。
- **`grass_region` 参数化**：SQL 通过 `${grass_region}` / `${grass_region_without_quote}` 参数区分大区，不同大区间互相隔离，同一日期可并行执行多个大区任务。

---

*文档生成时间：2026-05-17*