<!-- ads-workspace-gdoc-sync: gdoc_id=1KrK4PkQoiNDkV0hLM_DqdKJ3nYTm1RhcJsfXJFuPXDQ gdoc_url=https://docs.google.com/document/d/1KrK4PkQoiNDkV0hLM_DqdKJ3nYTm1RhcJsfXJFuPXDQ/edit -->

# mp_paidads.ads_category_performance_1d

**分层**：ADS（应用数据服务层）
**主键**：`grass_region` + `grass_date` + `tz_type` + 类目体系（global_be / fe_display / kpi_category）+ 层级（level1 / level2 / level3）+ 对应类目 ID
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1，各地区按本地时区参数化调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表以**类目**为核心维度，汇总各地区每日付费广告的核心绩效指标，覆盖三套类目体系（全球后端类目 `global_be`、前端展示类目 `fe_display`、KPI 考核类目 `kpi_category`）下三个层级（L1 / L2 / L3）的广告曝光、点击、花费、订单及 GMV 数据。每一行对应某一类目体系下某一层级某个类目节点在当日的广告绩效汇总，同一类目节点在不同体系中均独立成行，互不重叠。

本表适用于以下场景：按类目维度分析广告投放效率（ROI、CTR）、对比不同类目体系下的广告表现、跨地区横向对比类目广告绩效以及 KPI 类目口径的广告达成追踪。由于同时提供本地货币与 USD 双币种指标，亦可支持多币种报表和跨地区统一口径分析。

本表为 ADS 层末端宽表，直接服务于 BI 看板、数据产品及运营分析报表，是付费广告按类目分析的**唯一口径表**。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，区分本地时区（`local`）与 UTC 时区（`utc`）。各地区按本地时区参数化调度。⚠️ 查询时必须指定该分区，否则将导致数据重复计算（同一天数据出现两条）。 |
| `grass_region` | string | 国家/地区分区，存储值为大写国家代码（如 `MX`、`BR`）。⚠️ 查询时必须指定该分区，否则触发全表扫描。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`，表示广告数据所属自然日。⚠️ 查询时必须指定该分区，否则触发全表扫描。 |

---

### 维度：类目体系与层级

> **设计说明**：本表采用"宽稀疏"设计。每一行只属于三套类目体系之一（global_be / fe_display / kpi_category）下的一个层级（L1 / L2 / L3），其余类目字段均为 `NULL`。查询时须通过 IS NOT NULL 或具体 ID 过滤锁定所需类目体系和层级，避免重复统计。

#### 全局后端类目（global_be_category）

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_global_be_category_id` | bigint | 一级全球后端类目 ID。当本行归属于 L1 global_be 类目时有值，否则为 NULL。 |
| `level1_global_be_category` | string | 一级全球后端类目名称。 |
| `level2_global_be_category_id` | bigint | 二级全球后端类目 ID。当本行归属于 L2 global_be 类目时有值，否则为 NULL。 |
| `level2_global_be_category` | string | 二级全球后端类目名称。 |
| `level3_global_be_category_id` | bigint | 三级全球后端类目 ID。当本行归属于 L3 global_be 类目时有值，否则为 NULL。 |
| `level3_global_be_category` | string | 三级全球后端类目名称。 |

#### 前端展示类目（fe_display_category）

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_fe_display_category_id` | bigint | 一级前端展示类目 ID。当本行归属于 L1 fe_display 类目时有值，否则为 NULL。⚠️ 上游通过 LATERAL VIEW OUTER EXPLODE 展开 list 字段，一条广告记录可能对应多个 fe_display 类目，聚合时需注意去重或口径一致。 |
| `level1_fe_display_category` | string | 一级前端展示类目名称。 |
| `level2_fe_display_category_id` | bigint | 二级前端展示类目 ID。同上，通过 EXPLODE 展开，存在一对多关系。⚠️ 同上。 |
| `level2_fe_display_category` | string | 二级前端展示类目名称。 |
| `level3_fe_display_category_id` | bigint | 三级前端展示类目 ID。同上，通过 EXPLODE 展开，存在一对多关系。⚠️ 同上。 |
| `level3_fe_display_category` | string | 三级前端展示类目名称。 |

#### KPI 考核类目（kpi_category）

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_kpi_category_id` | bigint | 一级 KPI 考核类目 ID。当本行归属于 L1 kpi_category 时有值，否则为 NULL。⚠️ 上游通过 LATERAL VIEW OUTER EXPLODE 展开，存在一对多关系，聚合时需注意口径一致。 |
| `level1_kpi_category` | string | 一级 KPI 考核类目名称。 |
| `level2_kpi_category_id` | bigint | 二级 KPI 考核类目 ID。同上。⚠️ 同上。 |
| `level2_kpi_category` | string | 二级 KPI 考核类目名称。 |
| `level3_kpi_category_id` | bigint | 三级 KPI 考核类目 ID。同上。⚠️ 同上。 |
| `level3_kpi_category` | string | 三级 KPI 考核类目名称。 |

---

### 指标：广告绩效（本地货币 & USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `category_ads_impression_cnt_1d` | bigint | 当日该类目下广告总曝光次数（L1/L2/L3 各层级汇总）。 |
| `category_ads_click_cnt_1d` | bigint | 当日该类目下广告总点击次数（L1/L2/L3 各层级汇总）。 |
| `category_ads_expenditure_amt_1d` | double | 当日该类目下广告花费金额，本地货币。 |
| `category_ads_expenditure_amt_usd_1d` | double | 当日该类目下广告花费金额，USD。 |
| `category_ads_order_cnt_1d` | bigint | 当日该类目下广告带来的精准归因订单数（直接归因，non-broad）。 |
| `category_ads_gmv_amt_1d` | double | 当日该类目下广告精准归因 GMV，本地货币。 |
| `category_ads_gmv_amt_usd_1d` | double | 当日该类目下广告精准归因 GMV，USD。 |
| `category_ads_broad_order_cnt_1d` | bigint | 当日该类目下广告宽泛归因（broad match）订单数。⚠️ 与 `category_ads_order_cnt_1d` 归因口径不同，两者不可相加，需根据业务口径选其一使用。 |
| `category_ads_broad_gmv_amt_1d` | double | 当日该类目下广告宽泛归因 GMV，本地货币。⚠️ 归因口径与精准 GMV 不同，不可与 `category_ads_gmv_amt_1d` 混合求和。 |
| `category_ads_broad_gmv_amt_usd_1d` | double | 当日该类目下广告宽泛归因 GMV，USD。⚠️ 同上。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全分区扫描，产生巨大计算资源消耗，并导致数据重复（`tz_type` 遗漏时同一天数据被重复计入）：

| 过滤字段 | 推荐写法示例 | 遗漏后果 |
|----------|------------|----------|
| `tz_type` | `tz_type = 'local'`（推荐使用本地时区口径） | 同一日期数据被 local 和 utc 各算一次，所有指标翻倍 |
| `grass_region` | `grass_region = 'BR'` | 全地区数据混合，无法对应单一市场 |
| `grass_date` | `grass_date = '2026-04-21'` 或 `grass_date BETWEEN ... AND ...` | 全量历史数据扫描，极高资源消耗 |

此外，由于本表采用"宽稀疏"多类目体系 UNION ALL 设计，**必须通过类目 ID IS NOT NULL 过滤**来锁定所需类目体系和层级，例如：

```sql
-- 查询 L2 global_be 类目维度广告花费
WHERE tz_type = 'local'
  AND grass_region = 'BR'
  AND grass_date = '2026-04-21'
  AND level2_global_be_category_id IS NOT NULL
```

若不加类目 IS NOT NULL 过滤，则同一类目下的广告数据会被 global_be、fe_display、kpi_category 三套体系各计一次，**指标严重重复**。

---

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确处理方式 |
|------|----------|------------|
| `category_ads_broad_order_cnt_1d` | 宽泛归因订单与精准归因订单口径不同，不可与 `category_ads_order_cnt_1d` 混合相加 | 根据业务归因口径选择其中一个，不可混用 |
| `category_ads_broad_gmv_amt_1d` | 宽泛归因 GMV，不可与精准归因 GMV 相加 | 同上，按口径选用其一 |
| `category_ads_broad_gmv_amt_usd_1d` | 同上（USD 版本） | 同上 |
| 所有指标字段（跨类目体系） | 未过滤类目体系时，同一广告数据被三套体系各贡献一次 | 查询前必须通过类目 ID IS NOT NULL 明确体系和层级，见上节 |
| CTR / ROI 等派生比率 | 本表未直接存储比率字段，如需计算 CTR，须用 `category_ads_click_cnt_1d / category_ads_impression_cnt_1d` 手动计算，不可跨行直接 AVG | 用分子除以分母，在聚合后计算 |

---

### 时效性说明

本表按日分区，每日 T+1 调度写入前一日数据。查询当日数据时，建议取 `grass_date = CURRENT_DATE - 1` 分区，确保数据已完整写入。当天（T+0）分区可能尚未产出或数据不完整，不建议直接使用。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告主/商品级广告明细宽表，提供各层级类目归属字段（list 格式）及广告花费、点击、曝光、订单、GMV 等原始指标；本表所有指标均由此表按类目维度聚合而来 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
        │
        ├─── [直接 GROUP BY level1/2/3_global_be_category] ──► global_be_category (temp view)
        │         (3 段 UNION ALL，分别对应 L1 / L2 / L3)
        │
        ├─── [LATERAL VIEW OUTER EXPLODE(levelN_fe_display_category_list)
        │     + GROUP BY] ──────────────────────────────────► fe_display_category (temp view)
        │         (3 段 UNION ALL，分别对应 L1 / L2 / L3)
        │
        └─── [LATERAL VIEW OUTER EXPLODE(levelN_kpi_category_list)
              + GROUP BY] ──────────────────────────────────► kpi_category (temp view)
                    (3 段 UNION ALL，分别对应 L1 / L2 / L3)
                          │
                          ▼
              global_be_category
              UNION ALL
              fe_display_category
              UNION ALL
              kpi_category
                          │
                          ▼
    INSERT OVERWRITE PARTITION(tz_type, grass_region, grass_date)
    mp_paidads.ads_category_performance_1d__reg_s0_live
```

**调度引擎**：Spark SQL（Studio 任务，task_code: `data_paidadsmart.studio_2850871`）
**写入方式**：`INSERT OVERWRITE` 分区覆盖写，按 `${region}` + `${grass_date}` 参数化调度，各地区独立执行

---

### 关键 CTE 说明

| 临时视图（Temp View） | 来源表 | 作用 |
|-----------------------|--------|------|
| `global_be_category` | `ads_advertise_mkt_1d__reg_s0_live` | 按全球后端类目（L1 / L2 / L3）分别 GROUP BY 聚合广告指标，3 段 UNION ALL 合并；global_be 类目字段直接读取，无 EXPLODE 展开 |
| `fe_display_category` | `ads_advertise_mkt_1d__reg_s0_live` | 使用 `LATERAL VIEW OUTER EXPLODE` 展开上游 list 类型的前端展示类目字段（L1 / L2 / L3），再 GROUP BY 聚合；3 段 UNION ALL 合并 |
| `kpi_category` | `ads_advertise_mkt_1d__reg_s0_live` | 使用 `LATERAL VIEW OUTER EXPLODE` 展开上游 list 类型的 KPI 类目字段（L1 / L2 / L3），再 GROUP BY 聚合；3 段 UNION ALL 合并 |

---

### 注意事项

1. **宽稀疏行设计**：最终写入表共由 9 段 SELECT（3 体系 × 3 层级）UNION ALL 而成。每行只有一套类目体系下的一个层级字段非 NULL，其余类目字段全为 NULL。**直接对整张表无条件聚合指标将导致同一广告数据被计算 9 次**，务必在 WHERE 中过滤体系和层级。

2. **EXPLODE 导致的行扩散**：`fe_display_category` 和 `kpi_category` 两组临时视图使用了 `LATERAL VIEW OUTER EXPLODE` 展开 list 字段，即一条广告记录可能被展开成多行（对应多个类目），因此同一笔花费/订单/GMV 可能出现在多个类目行中。**这是设计预期行为**，表达一条广告归属多个类目的业务含义，但跨类目汇总时不可简单相加。

3. **global_be 类目非 list 字段**：`global_be_category` 临时视图中直接使用结构体字段（`level1_global_be_category.level1_global_be_category_id` 形式），并非 EXPLODE 展开，说明上游 global_be 类目字段为标量，不存在一对多展开问题。

4. **分区参数化**：ETL SQL 中出现的具体地区代码和日期均为调度模板的参数占位符 `${region}` / `${grass_date}`，本表通过多地区参数化调度覆盖所有上线地区，各地区按本地时区独立产出数据。

5. **数据延迟**：依赖上游 `ads_advertise_mkt_1d__reg_s0_live` 表完整产出后才能调度，实际可用时间视上游延迟而定，建议在数据平台确认上游 SLA 后再配置下游消费时间。

---

*文档生成时间：2026-04-22*