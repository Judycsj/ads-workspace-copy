<!-- ads-workspace-gdoc-sync: gdoc_id=1O5CXEbpV31BmIUkIo2p9qD5wauQFtDwvAyCFTko4aWA gdoc_url=https://docs.google.com/document/d/1O5CXEbpV31BmIUkIo2p9qD5wauQFtDwvAyCFTko4aWA/edit -->

# srdi_mart.ads_sr_data_warehouse_ni_boost_exp_performance_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date` + `exp_tag`
**分区**：`grass_region`（地区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1）
**访问频次**：1,462 次

---

## 业务描述

本表用于追踪**搜推数仓 NI Boost 实验**的每日绩效表现，属于 A/B 实验效果评估报表表。

**核心业务场景**：

- 对首页（Homepage > Daily Discover）与推荐（Rcmd > User Scenario）场景下的 NI Boost 策略实验（含 T1/C1 分组）进行效果度量。
- 涵盖 ID、VN、PH、TH、MY 五个市场，按实验分组（对照组 / 实验组）输出曝光用户数、订单量、GMV。
- 归因逻辑兼顾直接曝光成交及 source1/source2 归因链路的订单，避免重复计算。

**适合回答的问题**：

- NI Boost 实验各组（T1/C1）在某日某地区的曝光 UV、订单量、GMV 分别是多少？
- 实验组（T1）与对照组（C1）的转化率、人均 GMV 差异如何？
- 各地区 NI Boost 实验效果横向对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区键，取值范围：ID、VN、PH、TH、MY |
| `local_date` | date | 业务日期分区键，格式 YYYY-MM-DD |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_tag` | string | 实验分组标签。`T1`：实验组（各地区对应特定 exp_group_id）；`C1`：对照组（exp_group_id = 378802）。基于 A/B 实验 assignment log 打标 |

### 指标：曝光与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uv` | bigint | 发生曝光（imp_cnt > 0）的去重用户数（RCMD 场景下，与实验分组 inner join 后统计） |
| `order_cnt` | double | 归因订单量之和；含直接归因及 source1/source2 归因链路订单（去重逻辑见 ETL 注意事项） |
| `gmv` | double | 归因 GMV 之和（单位与源表一致）；含 source1/source2 归因链路 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时务必同时指定 `grass_region` 和 `local_date`，否则将触发全分区扫描，产生大量无效 I/O：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uv` | 去重用户数（COUNT DISTINCT），跨分区/跨地区/跨日期不可直接累加，重复用户会被重复计数 |
| `order_cnt` | 已含 source 归因链路叠加逻辑，跨分组直接 SUM 可能导致语义混淆；如需汇总需明确归因口径 |
| `gmv` | 同 `order_cnt`，跨分组汇总需确认归因链路一致性 |

### 时效性说明

- 本表为 **`_1d`** 后缀日表，每日覆盖写入（`INSERT OVERWRITE`），反映 `local_date` 当天的实验数据。
- 数据通常在次日（T+1）更新完成，不适用于实时/准实时场景。
- 表内仅保留已分配实验分组（`is_assignment_log = 1`）的用户，未命中实验的用户不计入。

### 其他注意事项

- 当前实验分组硬编码于 ETL SQL 中（exp_group_id 白名单 + 地区匹配），如实验扩组或新增地区，需同步更新 ETL。
- `exp_tag` 仅有 `T1` / `C1` 两个有效值；未命中白名单的 exp_group_id 对应 `exp_tag = NULL`，在 GROUP BY 时会产生 NULL 行，查询时建议过滤 `WHERE exp_tag IS NOT NULL`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 提供用户粒度的曝光（omni_impression）与订单（order）行为数据，包含 imp_cnt、order_cnt、gmv 及归因链路字段（source1/source2） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供用户实验分组信息，通过 assignment log（is_assignment_log = 1）过滤，按地区和 exp_group_id 白名单打标 T1/C1 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_tc_ab_all_cards
        │
        ▼
[Step 1] traffic_data_raw       ← 过滤 order/omni_impression，按用户+归因维度聚合
        │
        ▼
[Step 2] sr_data_raw_step1      ← 过滤 RCMD 场景（Homepage/Daily Discover 或 Rcmd/User Scenario），打标 mapping_general
        │
        ▼
[Step 3] sr_data_raw_step2      ← UNION ALL 展开三路归因（直接归因 + source1 + source2），去重防止订单重复计数
        │
dim_sr_data_warehouse_abtest_user_group
        │
        ▼
[Step 4] user_exp               ← 过滤 assignment log，按地区白名单打标 T1/C1
        │
        ▼（INNER JOIN on user_id）
[Step 5] INSERT OVERWRITE       → ads_sr_data_warehouse_ni_boost_exp_performance_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Statement 1 | `traffic_data_raw` | 从 `dwm_sr_data_warehouse_tc_ab_all_cards` 读取当日当地区数据，operation 归一化（order/others），按用户+全量归因维度 SUM 聚合 |
| Statement 2 | `sr_data_raw_step1` | 在 `traffic_data_raw` 基础上，过滤保留至少一路归因属于 RCMD 场景的记录，生成 `mapping_general`、`source1_mapping_general`、`source2_mapping_general` 三个映射标签 |
| Statement 3 | `sr_data_raw_step2` | UNION ALL 三路：① 直接归因 RCMD 的所有记录（含曝光和订单）；② source1 归因 RCMD 的订单记录（且 source1 与直接归因不同，防重）；③ source2 归因 RCMD 的订单记录（且 source2 与直接归因、source1 均不同，防重） |
| Statement 4 | `user_exp` | 从 `dim_sr_data_warehouse_abtest_user_group` 读取当日 assignment log，按地区匹配 exp_group_id 白名单，打标 `exp_tag`（T1/C1） |
| Statement 5 | `INSERT OVERWRITE` | 将 `sr_data_raw_step2` 与 `user_exp` 按 `user_id` INNER JOIN，GROUP BY `exp_tag`，聚合输出 `imp_uv`（COUNT DISTINCT）、`order_cnt`（SUM）、`gmv`（SUM），覆盖写入目标分区 |

### 注意事项

- **单一写入**：本表仅有 1 个 ETL 文件，无多文件并发写入（multi_writer = false），分区安全。
- **INNER JOIN 影响覆盖范围**：`sr_data_raw_step2` 与 `user_exp` 采用 INNER JOIN，仅命中实验分组的用户才会计入，未分配实验的用户行为不进入本表，统计口径相对收窄。
- **归因防重逻辑**：source1 和 source2 的订单归因通过 `source1_mapping_general != mapping_general` 及 `source2_mapping_general != source1_mapping_general` 条件防止重复计算，但该防重仅基于 mapping_general 映射标签，非精确 session 级去重，极端情况下可能存在一定的口径偏差。
- **实验分组硬编码**：exp_group_id 白名单及地区映射关系固化在 SQL 中，实验变更时需同步修改 ETL 逻辑。
- **覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION`，每次运行会覆盖对应 `grass_region` + `local_date` 分区，重跑历史分区是安全的。

---

*文档生成时间：2026-05-17*