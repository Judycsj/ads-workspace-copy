<!-- ads-workspace-gdoc-sync: gdoc_id=14nQ29nmiEzfL5IfbvbX_PY91tsDVh_2cVCvDGA5b0tg gdoc_url=https://docs.google.com/document/d/14nQ29nmiEzfL5IfbvbX_PY91tsDVh_2cVCvDGA5b0tg/edit -->

# srdi_mart.dim_sr_data_warehouse_vsku_replace_vitem_metrics_hf

**分层：** dim（维度层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `vitem_id` + `exp_tag` + `version_date`
**分区：** `grass_region` / `regional_date` / `regional_hour`
**更新频率：** 小时级（每小时覆盖写入对应分区）
**引用频次 / 访问频次：** 5085

---

## 业务描述

本表面向**搜推数仓 vSKU 替换 vItem 的 A/B 实验效果监控**场景，以 vItem 维度汇总实验组与对照组在多个时间窗口（当前 N 天、近 3 天、近 7 天）的曝光、点击及 CTR 指标，并关联来自推荐系统的 vItem 固有质量特征（CTR / CR / CTCVR 等）。

**核心业务场景：**
- 监控 vSKU → vItem 替换策略在各实验分组（`exp_tag = T*` 为实验组，`exp_tag = C*` 为对照组）下的点击率变化趋势；
- 对比实验组与对照组在 3 天、7 天和 N 天滚动窗口内的曝光/点击量，评估策略上线效果；
- 结合 vItem 在推荐场景中的历史质量指标，为策略调优提供多维参考。

**适合回答的问题：**
- 某区域某小时，实验组 vItem 的近 7 天 CTR 是否优于对照组？
- 特定 vItem 在不同实验策略下的曝光及点击量趋势如何？
- vItem 自身的推荐侧历史 CTR/CVR 与实验侧 CTR 是否一致？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `ID`、`MY` 等，查询时必须指定 |
| `regional_date` | date | 数据所属本地日期，格式 `yyyy-MM-dd` |
| `regional_hour` | int | 数据所属本地小时（0–23） |

---

### 维度：vItem 基础维度

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID，vSKU 替换策略的目标 vItem |
| `exp_tag` | string | 实验分组标签；`T*` 表示实验组（当前枚举为 `T4`），`C1` 表示对照组 |
| `version_date` | string | vItem 首次出现于本表的日期版本，格式 `yyyyMMdd`；首次写入时取当前 `regional_date` |

---

### 指标：实验组 N 天滚动窗口指标（nd window）

> `nd` 表示从 `dws_sr_data_warehouse_vsku_replace_vitem_hourly_nd` 取得的滚动 N 天累计值，具体窗口长度由上游 DWS 定义。

| 字段名 | 类型 | 说明 |
|---|---|---|
| `exp_imp_cnt_nd` | bigint | 实验组 vItem 在 N 天窗口内的累计曝光次数 |
| `exp_click_cnt_nd` | bigint | 实验组 vItem 在 N 天窗口内的累计点击次数 |
| `exp_ctr_nd` | double | 实验组 N 天 CTR，计算公式：`exp_click_cnt_nd / exp_imp_cnt_nd`；曝光为 0 时为 NULL |

---

### 指标：对照组 N 天滚动窗口指标（nd window）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `control_imp_cnt_nd` | bigint | 对照组（`exp_tag = C1`）vItem 在 N 天窗口内的累计曝光次数 |
| `control_click_cnt_nd` | bigint | 对照组 vItem 在 N 天窗口内的累计点击次数 |
| `control_ctr_nd` | double | 对照组 N 天 CTR，计算公式：`control_click_cnt_nd / control_imp_cnt_nd`；曝光为 0 时为 NULL |

---

### 指标：实验组近 3 天 / 近 7 天指标（realtime 窗口）

> 来源于 paimon 实时表，`3d` = `regional_date` 起往前 2 天（含当天共 3 天），`7d` = 往前 6 天（含当天共 7 天）。

| 字段名 | 类型 | 说明 |
|---|---|---|
| `exp_imp_cnt_3d` | bigint | 实验组 vItem 近 3 天累计曝光次数 |
| `exp_click_cnt_3d` | bigint | 实验组 vItem 近 3 天累计点击次数 |
| `exp_ctr_3d` | double | 实验组近 3 天 CTR，计算公式：`exp_click_cnt_3d / exp_imp_cnt_3d`；曝光为 0 时为 NULL |
| `exp_imp_cnt_7d` | bigint | 实验组 vItem 近 7 天累计曝光次数 |
| `exp_click_cnt_7d` | bigint | 实验组 vItem 近 7 天累计点击次数 |
| `exp_ctr_7d` | double | 实验组近 7 天 CTR，计算公式：`exp_click_cnt_7d / exp_imp_cnt_7d`；曝光为 0 时为 NULL |

---

### 指标：对照组近 3 天 / 近 7 天指标（realtime 窗口）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `control_imp_cnt_3d` | bigint | 对照组 vItem 近 3 天累计曝光次数 |
| `control_click_cnt_3d` | bigint | 对照组 vItem 近 3 天累计点击次数 |
| `control_ctr_3d` | double | 对照组近 3 天 CTR，计算公式：`control_click_cnt_3d / control_imp_cnt_3d`；曝光为 0 时为 NULL |
| `control_imp_cnt_7d` | bigint | 对照组 vItem 近 7 天累计曝光次数 |
| `control_click_cnt_7d` | bigint | 对照组 vItem 近 7 天累计点击次数 |
| `control_ctr_7d` | double | 对照组近 7 天 CTR，计算公式：`control_click_cnt_7d / control_imp_cnt_7d`；曝光为 0 时为 NULL |

---

### 指标：vItem 推荐侧历史质量特征（7 天）

> 来源于推荐系统特征表，反映 vItem 在推荐场景中的历史表现，与实验分组无关，按 vItem 维度关联。

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vitem_imp_7d_rcmd` | bigint | vItem 在推荐场景近 7 天曝光次数 |
| `vitem_click_7d_rcmd` | bigint | vItem 在推荐场景近 7 天点击次数 |
| `vitem_ctr_7d_rcmd` | double | vItem 在推荐场景近 7 天 CTR（来源字段 `ctr7`） |
| `vitem_cr_7d_rcmd` | double | vItem 在推荐场景近 7 天转化率 CR（来源字段 `cr7`） |
| `vitem_ctcvr_7d_rcmd` | double | vItem 在推荐场景近 7 天 CTCVR（来源字段 `ctcvr7`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **三个分区字段均须指定**，否则将触发全表扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2024-06-01'
    AND regional_hour = 10
  ```
- 若需要分析近 7 天趋势，需显式列举 `regional_date` 范围，并注意不同小时分区的数据口径一致性。

### 不可直接 SUM 的字段

以下字段为**预计算比率**，跨分区/跨 vItem 聚合时**禁止直接 SUM**，应重新用分子/分母字段计算：

| 字段 | 原因 |
|---|---|
| `exp_ctr_nd` | 比率字段，`= exp_click_cnt_nd / exp_imp_cnt_nd` |
| `control_ctr_nd` | 比率字段，`= control_click_cnt_nd / control_imp_cnt_nd` |
| `exp_ctr_3d` | 比率字段，`= exp_click_cnt_3d / exp_imp_cnt_3d` |
| `exp_ctr_7d` | 比率字段，`= exp_click_cnt_7d / exp_imp_cnt_7d` |
| `control_ctr_3d` | 比率字段，`= control_click_cnt_3d / control_imp_cnt_3d` |
| `control_ctr_7d` | 比率字段，`= control_click_cnt_7d / control_imp_cnt_7d` |
| `vitem_ctr_7d_rcmd` | 推荐系统预聚合比率，非本表原始累计值 |
| `vitem_cr_7d_rcmd` | 推荐系统预聚合比率 |
| `vitem_ctcvr_7d_rcmd` | 推荐系统预聚合比率 |

> **注意**：当曝光量为 0 时，CTR 字段值为 NULL（ETL 中为整数除 0，Spark 默认返回 NULL），下游使用时需做 NULL 保护。

### 时效性说明

- 本表为**小时级分区表**（`regional_hour` 粒度），每小时执行一次 INSERT OVERWRITE，覆盖当前小时分区；
- `exp_imp_cnt_nd` / `exp_click_cnt_nd` 等 `_nd` 字段基于上游 DWS 小时表的**滚动 N 天**窗口，具体窗口天数由 `dws_sr_data_warehouse_vsku_replace_vitem_hourly_nd` 定义；
- `_3d` / `_7d` 字段来源于 paimon 实时表，数据新鲜度接近准实时，但窗口为**自然日边界**（date_sub 计算），并非精确滚动小时窗口；
- `vitem_*_rcmd` 字段依赖 `dws_fp_rcmd_item_feature` 的**最新可用分区**（取 `< regional_date` 的最大 `dt`），存在最多 1 天的数据滞后；
- `version_date` 字段通过自关联历史分区做累计快照（FULL OUTER JOIN），保证历史存在但当前无数据的 vItem 不丢失。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | 获取当前小时参与实验的 vItem 全量列表（维度基础） |
| `srdi_mart.dim_sr_data_warehouse_vsku_replace_vitem_metrics_hf`（自关联） | 读取上一个可用小时分区，用于累计快照维护（保留历史 vItem 不丢失） |
| `srdi_mart.dws_sr_data_warehouse_vsku_replace_vitem_hourly_nd` | 提供实验组和对照组的 N 天滚动窗口曝光/点击指标 |
| `paimon.srdi_mart.dws_sr_data_warehouse_vsku_replace_vitem_realtime_1d` | 提供近 7 天（含近 3 天）实验组和对照组的实时曝光/点击明细，用于计算 3d/7d 指标 |
| `srdi_mart.dws_fp_rcmd_item_feature` | 提供 vItem 在推荐场景的历史质量特征（CTR / CR / CTCVR / 曝光 / 点击） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_vsku_model_mapping_hf  ──┐
                                                ├─► accumulated_vitem（累计 vItem 快照）
dim_sr_data_warehouse_vsku_replace_vitem_metrics_hf（自关联上一分区）──┘
                                                │
dws_sr_data_warehouse_vsku_replace_vitem_hourly_nd ──► exp_metrics（nd window）
                                                       control_metrics（nd window）
                                                │
paimon.dws_sr_data_warehouse_vsku_replace_vitem_realtime_1d ──► exp_3d_metrics / control_3d_metrics
                                                │
dws_fp_rcmd_item_feature ──► item_feature（推荐质量特征）
                                                │
                                                ▼
              INSERT OVERWRITE dim_sr_data_warehouse_vsku_replace_vitem_metrics_hf
```

### 关键步骤

1. **`vitem_list`（Temporary View）**：从 vSKU 模型映射表中获取当前小时有效的 vItem 列表，通过 `lateral view explode(array('T4'))` 按实验策略数量复制行，为每个 vItem 生成对应实验标签。

2. **`last_partition` 变量**：查询目标表自身，在近 7 天分区中找到严格小于当前 `regional_date_regional_hour` 的最新分区，作为历史基准。

3. **`last_vitem`（Temporary View）**：从上一步找到的历史分区中读取已存在的 `(exp_tag, vitem_id, version_date)` 三元组，用于延续历史 vItem 记录。

4. **`accumulated_vitem`（Temporary View）**：对 `last_vitem`（历史）和 `vitem_list`（当前）做 FULL OUTER JOIN，实现累计快照，保证新增和历史 vItem 均被保留；`version_date` 取历史值，历史无记录时取当前日期。

5. **`nd_metrics`（Temporary View）**：从 N 天滚动 DWS 表获取当前分区的曝光/点击明细。

6. **`exp_metrics` / `control_metrics`（Temporary View）**：分别对实验组（`exp_tag like 'T%'`）和对照组（`exp_tag = 'C1'`）按 `(vitem_id, exp_tag, version_date)` / `vitem_id` 聚合 nd 窗口指标。

7. **`realtime_metrics`（Temporary View）**：从 paimon 实时表读取近 7 天（`regional_date between date_sub(regional_date,6) and regional_date`）的明细数据。

8. **`exp_3d_metrics` / `control_3d_metrics`（Temporary View）**：基于 realtime_metrics，通过条件聚合分别计算实验组和对照组的 3 天/7 天窗口指标。

9. **`item_feature`（Temporary View）**：从推荐特征表读取 vItem 的 CTR/CR/CTCVR 等历史质量指标，使用 `max_pt` 函数取 `< regional_date` 的最新分区，避免使用未来数据。

10. **`INSERT OVERWRITE`（目标写入）**：以 `accumulated_vitem` 为驱动表，依次 LEFT JOIN 各指标 view，计算 CTR 比率字段，覆盖写入目标表当前 `(grass_region, regional_date, regional_hour)` 分区。

### 注意事项

- **单 Writer**：本表仅一个 ETL 文件写入，无多写风险，但自关联历史分区时若上游分区缺失（如首次运行或历史分区空洞），`last_partition` 变量可能为空，导致 `last_vitem` 返回空集，此时 `version_date` 将全部回退为当前日期，需关注冷启动场景。
- **CTR 除零保护**：ETL 中 CTR 计算未做显式除零保护（如 `nullif`），当分母为 0 时 Spark 返回 NULL；下游消费时应使用 `coalesce(exp_ctr_nd, 0)` 或同等方式处理。
- **实验策略扩展**：`exp_tag` 当前通过 `explode(array('T4'))` 硬编码，若实验组增加（如新增 T5），需同步修改 ETL 脚本。
- **paimon 表依赖**：`realtime_metrics` 来源于 paimon 实时表，与普通 Hive 表读取方式不同，需确保 paimon catalog 配置正确。
- **推荐特征滞后**：`item_feature` 使用 `< regional_date` 的最大分区，在当天首个小时运行时可能使用前一天数据，属于设计预期行为。

---

*文档生成时间：2026-05-17*