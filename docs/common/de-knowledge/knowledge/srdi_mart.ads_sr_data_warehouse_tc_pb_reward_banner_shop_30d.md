<!-- ads-workspace-gdoc-sync: gdoc_id=1CdfzNo39ytA0HorNR8chgBTx3SyezESVrJrqa2trkYU gdoc_url=https://docs.google.com/document/d/1CdfzNo39ytA0HorNR8chgBTx3SyezESVrJrqa2trkYU/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_shop_30d

**分层**：ADS（应用数据层）
**主键**：`shop_id`（在指定分区 `grass_region` + `local_date` + `local_hour` 下唯一）
**分区**：`local_date`（日期）、`grass_region`（大区）、`local_hour`（小时）
**更新频率**：每日定时调度（按大区分区覆盖写入）
**访问频次**：7,222 次

---

## 业务描述

本表面向**搜推广告激励横幅（Reward Banner）** 业务场景，汇总各店铺在过去 **30 天滚动窗口**内的曝光量、订单量和 GMV 数据，供下游广告投放策略、店铺排名模型及业务报表使用。

**核心业务场景**：
- 激励横幅广告位（Reward Banner）的店铺维度投放效果评估；
- 近 30 天店铺维度 GMV / 订单 / 曝光表现追踪；
- 广告模型特征工程：为投放模型提供店铺历史表现特征。

**适合回答的问题**：
- 某大区某日各店铺近 30 天的激励横幅曝光量、成交订单量和 GMV 各是多少？
- 哪些店铺在激励横幅广告位的近 30 天 GMV 表现最优？
- 不同大区店铺在激励横幅广告位的近期转化效果对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据统计基准日期（即滚动窗口的结束日期，窗口为 `[local_date-29, local_date]`） |
| `grass_region` | string | 大区标识，用于隔离不同地区的数据分区（如 ID、TH、MY 等） |
| `local_hour` | int | 数据写入时的小时标识，通常用于标记批次时效；过滤时须指定 |

### 维度：店铺维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺唯一标识，本表最细粒度维度 |

### 指标：店铺近 30 天激励横幅广告表现

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_30d` | bigint | 近 30 天累计曝光次数，来源于上游 `imp_cnt` 字段的 SUM 汇总 |
| `order_cnt_30d` | bigint | 近 30 天累计成交订单数，来源于上游 `sold_cnt` 字段的 SUM 汇总 |
| `gmv_30d` | double | 近 30 天累计 GMV（成交金额），来源于上游 `gmv` 字段的 SUM 汇总 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将扫描所有大区分区，产生大量无效 IO；
- **`local_date`**：必须指定具体日期，该表为每日覆盖写入，通常取最新日期；
- **`local_hour`**：建议同时指定，防止读取到同一天内不同批次的重复数据；典型用法为取当日最新批次小时值。

```sql
-- 推荐写法示例
SELECT shop_id, imp_cnt_30d, order_cnt_30d, gmv_30d
FROM srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_shop_30d
WHERE grass_region = 'ID'
  AND local_date  = '2024-08-01'
  AND local_hour  = 10;
```

### 不可直接 SUM 的字段

| 字段 | 风险说明 |
|---|---|
| `imp_cnt_30d` | 已是 30 天滚动预聚合值；跨 `local_date` 分区累加会导致窗口重叠，数值虚高 |
| `order_cnt_30d` | 同上，跨日期分区累加无业务意义 |
| `gmv_30d` | 同上，跨日期分区累加会造成重复计算 |

> ⚠️ 本表所有指标字段均为**预聚合 30 天窗口值**，仅应在**单一 `local_date` + `local_hour` 分区**内按 `shop_id` 维度直接使用，**禁止跨分区叠加**。

### 时效性说明

- 本表为 **`*_30d` 滚动窗口表**，每次写入覆盖当前分区，窗口期固定为统计日期前推 29 天至当天（共 30 天）；
- 上游数据仅统计 `model_status IN (1, 2)` 的激励模型记录，不反映全量广告数据；
- 数据通常在每日固定时段写入，`local_hour` 用于区分批次，使用前确认已产出最新批次。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini` | 激励横幅广告模型明细宽表，提供店铺维度的曝光量（`imp_cnt`）、成交量（`sold_cnt`）、GMV（`gmv`）等原始指标；过滤条件：指定大区、近 30 天日期范围、`model_status IN (1, 2)` |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwm_sr_data_warehouse_tc_pb_reward_model_mini
    │  过滤：grass_region、近 30 天日期窗口、model_status IN (1,2)
    │  聚合：按 shop_id 汇总 imp_cnt、sold_cnt、gmv
    ▼
tmp_order_<grass_region>（Temporary View）
    │
    ▼
tmp_union_<grass_region>（Temporary View，透传中间层）
    │
    ▼
srdi_mart.ads_sr_data_warehouse_tc_pb_reward_banner_shop_30d
    PARTITION(grass_region, local_date, local_hour)
    INSERT OVERWRITE
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Statement 1 | CREATE TEMPORARY VIEW `tmp_order_<grass_region>` | 从上游 DWM 表读取近 30 天（`[local_date-29, local_date]`）指定大区、有效模型状态（1 或 2）的数据，按 `shop_id` 聚合曝光量、成交量、GMV |
| Statement 2 | CREATE TEMPORARY VIEW `tmp_union_<grass_region>` | 对 `tmp_order_<grass_region>` 做 `SELECT *` 透传，保留扩展多来源 UNION 的结构预留（当前单源） |
| Statement 3 | INSERT OVERWRITE | 从 `tmp_union_<grass_region>` 按 `shop_id` 二次聚合（兼容 UNION 多源场景），将 `imp_cnt_30d`、`order_cnt_30d`、`gmv_30d` 覆盖写入目标表对应分区 |

### 注意事项

- **单一 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险；
- **参数化分区**：SQL 使用 `${grass_region}`、`${local_date}`、`${local_hour}`、`${grass_region_without_quote}` 等运行时参数，调度时须确保参数正确传入，否则分区写入异常；
- **覆盖写入（INSERT OVERWRITE）**：每次调度会覆盖对应 `(grass_region, local_date, local_hour)` 分区，重跑历史分区是安全的；
- **model_status 过滤**：上游仅保留 `model_status IN (1, 2)` 的激励模型记录，若业务定义调整，需同步评估过滤逻辑的影响范围；
- **`tmp_union` 设计预留**：中间层 `tmp_union` 当前为单一来源透传，若后续需要合并多地区或多模型数据，可在此层扩展 UNION ALL，无需改动最终写入逻辑。

---

*文档生成时间：2026-05-17*