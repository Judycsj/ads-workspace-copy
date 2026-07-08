<!-- ads-workspace-gdoc-sync: gdoc_id=1kTrS0POnfGg3EqgCHF6bTk6bNIrjZt3QMfMmXdquBCc gdoc_url=https://docs.google.com/document/d/1kTrS0POnfGg3EqgCHF6bTk6bNIrjZt3QMfMmXdquBCc/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_state_level_nmv_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `state` + `platform` + `is_ads` + `scenario_tag` + `feature_detail` + `target_type` + `local_date`（分区内唯一）
**分区：** `exp_type` / `grass_region` / `local_date`（三级分区）
**更新频率：** 每日（T+1）
**访问频次：** 260 次

---

## 业务描述

本表是搜推数仓（SRDI）平台维度下，结合 **A/B 实验分组（exp_group）** 与 **用户地理州/省（state）** 的 NMV 日粒度汇总宽表。

**核心业务场景：**
- 按 A/B 实验组拆分，统计不同实验组在各州/省、平台、广告类型、推荐场景下的 NMV 表现；
- 支持搜索、推荐、首页等多种流量场景（`scenario_tag`）的 GMV 归因分析；
- 支持按 `feature_detail`（功能入口）和 `target_type`（落地页类型）细分的实验效果评估；
- 当前仅写入 `exp_type = 'dim_join'` 分区，即通过维度关联方式构建的实验统计口径。

**适合回答的典型问题：**
1. 某实验组在巴西圣保罗州的 NMV 和下单 UV 是多少？
2. 在全站汇总维度下，各推荐场景（scenario_tag）实验组间 NMV 差异如何？
3. iOS/Android 平台在越南各大区的实验组 NMV 对比？
4. 广告流量与自然流量在各实验组中的 NMV 占比分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验口径类型；当前固定写入值为 `dim_join`（维度关联口径） |
| `grass_region` | string | 国家/地区标识，如 `BR`（巴西）、`VN`（越南）等 |
| `local_date` | date | 本地化业务日期（数据所属自然日） |

### 维度：实验与功能标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，由 `exp_sum` UDF 展开 |
| `feature_detail` | string | 功能入口细节标识（如页面-场景-类型串），`__ALL__` 表示全站汇总 |
| `target_type` | string | 落地页/目标类型，从 `feature_detail` 按 `-` 分隔符解析（优先取第3段，否则取第2段）；`__ALL__` 表示全站汇总 |
| `scenario_tag` | string | 推荐/搜索场景标签，如 DPM 模块标识、DA 算法标签等；`__ALL__` 表示跨场景汇总 |

### 维度：用户与流量属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `state` | string | 用户所在州/省；BR 优先取最近收货地址州，其次取注册州，否则归为 `others`；VN 优先取默认收货省份，依次回退至最近收货省份、注册省份，否则为 `Unknown` |
| `platform` | string | 用户使用的客户端平台（如 `iOS`、`Android`），`__ALL__` 表示全平台汇总 |
| `is_ads` | string | 是否广告流量，`true`/`false`；`__ALL__` 表示广告与自然流量合计 |

### 指标：交易表现

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净成交金额（NMV），单位与上游一致，为该实验组在对应维度组合下的加总值 |
| `net_order_cnt` | double | 净订单数，即退款后的有效订单数量汇总 |
| `net_order_uu` | bigint | 产生净订单的去重用户数（UV）；由 `exp_sum` UDF 按实验组拆分后聚合，**不可直接跨实验组 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

1. **必须同时指定三个分区字段**，否则将触发全表扫描：
   ```sql
   WHERE exp_type = 'dim_join'
     AND grass_region = 'BR'          -- 按需替换为目标国家
     AND local_date = '2025-01-01'    -- 按需替换为目标日期
   ```
2. `exp_type` 当前唯一有效值为 `'dim_join'`，必须显式指定；
3. `grass_region` 与 `local_date` 为必填过滤条件，跨区域/日期汇总需在应用层处理。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `net_order_uu` | 去重 UV 指标，已由 `exp_sum` UDF 按实验组拆分，**跨实验组或跨维度不可直接加总** |
| `nmv` / `net_order_cnt` | 表中存在 `grouping sets` 预聚合的多粒度行（含 `__ALL__` 汇总行），与明细行并存；直接 SUM 会导致重复计算 |

### 维度汇总行说明

- `feature_detail = '__ALL__'`、`target_type = '__ALL__'`、`scenario_tag = '__ALL__'` 均表示该维度的跨值汇总行；
- `platform = '__ALL__'`、`is_ads = '__ALL__'` 同理；
- 查询时需明确过滤，避免混入汇总行，或仅选取特定粒度的行进行分析。

### 时效性说明

- 本表为 **T+1 每日全量覆写**（`INSERT OVERWRITE`），数据通常在次日产出；
- ETL 读取上游数据的时间窗口为 `local_date` 当天往前 **7 天**（含当天），实验组映射也在此窗口内做关联；
- 每次执行按 `grass_region` 粒度运行，各区域互相独立。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 原始平台 NMV 明细数据，包含用户、平台、广告标识、feature_detail、净订单等核心指标 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户与实验组 ID 的映射关系 |
| `traffic.dwd_register_di__reg_live` | 巴西用户注册州信息，用于构建 BR 用户州映射 |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 巴西买家最近收货地址州，优先级高于注册州 |
| `mp_user.dim_user__reg_s0_live` | 越南用户维度表，提供默认收货地址省份 |
| `vnbi_mkt.dim_user__address` | 越南用户最近收货省份 |
| `mp_user.dwd_register_ent_di__vn_s0_live` | 越南用户注册省份 |
| `vnbi_mkt.shopee_vn_bi_team__vietnam_region_map_details` | 越南省份与大区（major_region）映射字典 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
dwd_sr_data_warehouse_platform_nmv        ──┤
                                            ├─► 用户-实验组关联 + 维度展开 ──► grouping sets 预聚合
BR/VN 用户州映射（多表关联）               ──┘      ──► exp_sum UDF 实验组拆分 ──► INSERT OVERWRITE 目标表
```

### 关键步骤

1. **构建实验用户快照（`user_exp`）**
   从 A/B 实验分组表读取近 8 天（`local_date - 7` 至 `local_date`）的有效分组用户，聚合为 `user_id → collect_list(exp_group_ids)`。

2. **构建用户州映射（`user_state_mapping`）**
   - **BR**：先取注册州，再用最近 30 天内最新一笔订单的收货州覆盖；均归一化为 `Sao Paulo`、`Rio de Janeiro`、`others` 三类。
   - **VN**：优先取用户默认收货地址省份，其次取最近收货省份，最后取注册省份，并通过字典表映射为大区（`major_region`）；无匹配时为 `Unknown`。
   - 合并 BR 与 VN 结果形成统一 `user_state_mapping` 视图。

3. **构建 DPM 维度数据（`dwd_raw` → `concat_data`）**
   从 NMV 明细表读取近 8 天数据，按 DPM 维度体系（业务线、模块、报告对象、功能组、算法标签、页面类型）拼接场景标签字符串，并拆分为数组 `scenario_tags`（含 source1、source2 两个归因路径）。

4. **缓存基础宽表（`base_table`）**
   将 NMV 明细与用户州映射 LEFT JOIN，并对场景标签数组做过滤（仅保留 DA 相关标签及指定 DPM 模块标签）。以 `MEMORY_AND_DISK_SER` 缓存，供后续多次使用。

5. **多归因路径展开（`raw_data`）**
   对 `feature_detail`、`source1_feature_detail`、`source2_feature_detail` 三条归因路径分别 UNION ALL，去重逻辑为：source1 不等于 feature_detail 时才纳入，source2 同时不等于 source1 和 feature_detail 时才纳入。

6. **解析 `target_type`（`filter_tag_data`）**
   从 `feature_detail` 按 `-` 拆分，优先取第 3 段，否则取第 2 段作为 `target_type`。

7. **预聚合（`cube_table`）**
   通过三段 UNION ALL 覆盖不同粒度的 `grouping sets`：
   - 含 `feature_detail` + `scenario_tag`（从场景标签数组 EXPLODE）的明细粒度组合；
   - 无 `feature_detail` 的全站汇总（`__ALL__`）；
   - 无 `feature_detail` 但含 `scenario_tag` 的跨场景汇总。
   所有组合在 `is_ads` 和 `platform` 两个维度上做完全 cube（有值 / `__ALL__`）。

8. **计算 net_order_uu（`uu_data`）**
   对每行判断 `net_order_cnt > 0 AND user_id > 0`，生成 `net_order_uu` 标志位（0/1）。

9. **实验组拆分（`metric_table` → `explode_metric_table`）**
   将用户级指标打包为数组 `metrics`，与实验用户快照 INNER JOIN 后，通过 `exp_sum` UDF 按实验组 ID 汇总，最终 EXPLODE 得到每个实验组的指标行。

10. **写入目标表**
    `INSERT OVERWRITE` 写入 `exp_type = 'dim_join'`、`grass_region = ${grass_region}` 分区，按 `local_date` 动态分区覆盖。

### 注意事项

- **单 Writer，按区域串行/并行执行**：本表仅有 1 个 ETL 文件，无多写风险；但每次调度以 `grass_region` 为参数单独运行，不同区域写入不同分区，互不干扰。
- **`INSERT OVERWRITE` 分区覆盖**：目标分区 `(exp_type, grass_region, local_date)` 每次执行全量覆写，重跑历史日期需注意幂等性。
- **`exp_sum` 为自定义 UDF**：该 UDF 封装了按实验组 ID 汇总的逻辑，输出结果已完成实验组维度的指标拆分，下游不得再跨 `exp_group_id` 做二次 SUM。
- **`base_table` 缓存**：使用 `MEMORY_AND_DISK_SER` 策略缓存宽表，若 Spark 资源不足可能溢写到磁盘，需关注执行时资源配置。
- **近 8 天滚动窗口**：上游 NMV 明细与实验分组均取 `[local_date - 7, local_date]`，非单日快照，历史补数时需注意时间窗口覆盖范围。
- **BR 订单收货州取最新一条**：通过 `ROW_NUMBER() OVER (ORDER BY create_datetime DESC)` 取 `order_dt = 1`，仅反映用户近 30 天内最新订单的收货州，非历史全量。

---

*文档生成时间：2026-05-17*