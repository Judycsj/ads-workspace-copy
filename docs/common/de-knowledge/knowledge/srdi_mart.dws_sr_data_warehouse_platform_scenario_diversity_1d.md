<!-- ads-workspace-gdoc-sync: gdoc_id=1UbtbDNheVQMq5wpgARvOTQRiBt6cn-pwl-jDtlP12Ew gdoc_url=https://docs.google.com/document/d/1UbtbDNheVQMq5wpgARvOTQRiBt6cn-pwl-jDtlP12Ew/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_diversity_1d

**分层：** DWS（数据汇总层）
**主键：** `platform` + `login_type` + `feature_detail` + `scenario_tag` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 11,888 次

---

## 业务描述

本表用于衡量搜索与推荐（SR）场景下，各平台、各流量入口（feature）、各场景标签（scenario）维度的**商品类目多样性**。多样性指标基于信息熵原理（Shannon Entropy）计算，反映曝光（impression）与购买浏览（ppv）流量在全球后台一级、二级、三级类目上的分布离散程度。

**核心业务场景：**
- 评估搜推结果的类目覆盖广度，识别流量是否过度集中于少数类目
- 按平台、登录状态、流量入口、场景标签多维度拆分多样性表现
- 支持结合基准行（`feature_detail = '__ALL__'` / `scenario_tag = '__ALL__'`）进行横向对比
- 辅助算法团队优化推荐策略，提升商品多样性

**适合回答的问题：**
- 某平台某入口下，曝光商品在 L1/L2/L3 类目上的多样性熵值是多少？
- 登录 vs 非登录用户在不同场景下的类目多样性是否有差异？
- 某场景标签的 ppv 多样性趋势如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `SG`、`MY` 等；同时作为过滤条件与分区键 |
| `local_date` | date | 业务日期（本地时间），格式 `yyyy-MM-dd` |

### 维度：平台与入口标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 平台标识，如 `android`、`ios`、`pc` 等 |
| `login_type` | string | 登录状态，取值 `login`（user_id > 0）或 `nonlogin` |
| `feature_detail` | string | 流量入口明细标识；`__ALL__` 表示全入口汇总行；若商品来自多个来源入口（source1、source2），会为每个来源入口单独展开一行 |
| `scenario_tag` | string | 场景标签，由上游 scenario_tags 数组展开得到单个标签；`__ALL__` 表示全场景汇总行 |

### 指标：曝光与购买浏览的类目多样性熵值

| 字段 | 类型 | 说明 |
|---|---|---|
| `l1_imp_diversity` | double | 基于全球后台一级类目的曝光类目多样性熵值。计算公式：`Abs(Σ (p_i × ln(p_i)))`，其中 `p_i = 该 L1 类目曝光数 / 当前维度总曝光数`，值越大表示类目分布越分散 |
| `l2_imp_diversity` | double | 基于全球后台二级类目的曝光类目多样性熵值，计算逻辑同 `l1_imp_diversity` |
| `l3_imp_diversity` | double | 基于全球后台三级类目的曝光类目多样性熵值，计算逻辑同 `l1_imp_diversity` |
| `l1_ppv_diversity` | double | 基于全球后台一级类目的购买浏览（ppv）类目多样性熵值。计算公式：`Abs(Σ (p_i × ln(p_i)))`，其中 `p_i = 该 L1 类目 ppv 数 / 当前维度总 ppv 数` |
| `l2_ppv_diversity` | double | 基于全球后台二级类目的购买浏览类目多样性熵值，计算逻辑同 `l1_ppv_diversity` |
| `l3_ppv_diversity` | double | 基于全球后台三级类目的购买浏览类目多样性熵值，计算逻辑同 `l1_ppv_diversity` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，避免全分区扫描（该字段是第一级分区键）。
- **`local_date`**：必须指定，避免跨日期全量扫描；若需查多天，显式枚举日期范围。
- 推荐写法示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

以下字段均为**预聚合熵值（Shannon Entropy）**，不具备加法可加性，**禁止直接 SUM 跨行汇总**：

| 字段 | 原因 |
|---|---|
| `l1_imp_diversity` | 信息熵，非线性计算，跨维度直接相加无业务意义 |
| `l2_imp_diversity` | 同上 |
| `l3_imp_diversity` | 同上 |
| `l1_ppv_diversity` | 同上 |
| `l2_ppv_diversity` | 同上 |
| `l3_ppv_diversity` | 同上 |

> 如需汇总更高维度的多样性，须回溯至上游明细表重新计算熵值。

### 汇总行说明

- `feature_detail = '__ALL__'` 表示不区分入口的全量汇总行，可直接用于全平台入口整体分析。
- `scenario_tag = '__ALL__'` 表示不区分场景标签的全量汇总行。
- 两者可同时为 `'__ALL__'`，代表全入口 × 全场景的最高聚合层。
- 查询明细维度时需过滤掉汇总行，避免重复计算：`WHERE feature_detail != '__ALL__' AND scenario_tag != '__ALL__'`。

### 时效性说明

- 本表为 **天粒度（_1d）** 汇总表，每天产出前一日数据（T+1）。
- 每次写入为 `INSERT OVERWRITE` 分区，同一 `(grass_region, local_date)` 分区的数据会被完整覆盖重刷。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 提供商品级曝光（impression）和购买浏览（ppv）明细，包含 platform、user_id、feature_detail、source1/source2 入口信息及 scenario_tags 数组 |
| `srdi_mart.dim_sr_data_warehouse_item` | 提供商品维度信息，包含 L1/L2/L3 全球后台类目 ID（`level1/2/3_global_be_category_id`），用于将商品映射到类目层级 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │  按 grass_region + local_date 过滤，按商品+入口+场景聚合
        ▼
base_table（缓存）
        │
        ├── 展开 scenario_tags / source1_scenario_tags / source2_scenario_tags
        │   同时展开多入口 feature_detail（source1、source2 去重）
        ▼
feature_tag_data（各入口×各 scenario_tag 的曝光/ppv）
        │
        ├── 叠加 __ALL__ 汇总行（全入口 + 全场景）
        ▼
benchmark_union_data
        │  left join dim_sr_data_warehouse_item 挂载 L1/L2/L3 类目
        ▼
benchmark_data_cache（缓存）
        │
        ├── 按类目层级分别聚合：L1 / L2 / L3 曝光与 ppv
        │   并 join feature 层总量（feature_impr / feature_ppv）
        ▼
union_table（L1、L2、L3 行 UNION ALL，稀疏存储，缓存）
        │
        │  计算各类目占比 p_i = cat_imp / feature_impr
        │  熵值 = Abs(Σ p_i × ln(p_i))
        ▼
INSERT OVERWRITE dws_sr_data_warehouse_platform_scenario_diversity_1d
partition(grass_region, local_date)
```

### 关键步骤

1. **`base_table`（CACHE）**：从 `dwm_sr_data_warehouse_platform_user_item` 过滤指定大区和日期，按 platform / item_id / login_type / feature_detail / source1_feature_detail / source2_feature_detail / scenario_tags 等聚合曝光与 ppv 量。同时预计算 `union_scenario_tags`（三路场景标签的并集）。

2. **`feature_tag_data`（TEMP VIEW）**：通过 `LATERAL VIEW EXPLODE` 将 scenario_tags 数组展开为单行，分三路 UNION ALL：
   - 主入口（feature_detail）× scenario_tags
   - source1 入口（source1_feature_detail，与主入口不同时）× source1_scenario_tags（imp_cnt 置 0）
   - source2 入口（source2_feature_detail，与主、source1 入口均不同时）× source2_scenario_tags（imp_cnt 置 0）

3. **`item_data`（TEMP VIEW）**：从 `dim_sr_data_warehouse_item` 提取 item_id → L1/L2/L3 类目映射。

4. **`benchmark_union_data`（TEMP VIEW）**：三路 UNION ALL 构造完整维度行：
   - 全入口全场景汇总行（`__ALL__` × `__ALL__`）
   - 全入口 × 各 scenario_tag（使用 union_scenario_tags 展开）
   - 各 feature_detail × 各 scenario_tag

5. **`benchmark_data_cache`（CACHE）**：将 benchmark_union_data left join item_data，挂载类目信息后聚合至 platform / login_type / feature_detail / scenario_tag / L1/L2/L3 类目粒度。

6. **`feature_level_impress`（CACHE）**：在 benchmark_data_cache 基础上，去掉类目维度，聚合得到每个 (platform, login_type, feature_detail, scenario_tag) 的总曝光量 `feature_impr` 和总 ppv 量 `feature_ppv`，作为熵值计算的分母。

7. **L1/L2/L3 类目聚合视图**（各两步）：分别按 L1/L2/L3 类目聚合得到 `cat_imp_l{n}` / `cat_ppv_l{n}`，再 left join `feature_level_impress` 补充总量（`feature_impr`、`feature_ppv`），生成 `cat_level_l1/l2/l3` 视图。

8. **`union_table`（CACHE）**：将 L1、L2、L3 三个层级的数据 UNION ALL 合并，采用稀疏存储（各层级只填充本层类目字段，其余置 null）。

9. **INSERT OVERWRITE（最终写入）**：对 union_table 先按 feature_detail / scenario_tag / 三级类目 GROUP BY 汇总各类目层级量，再外层按 feature_detail / scenario_tag / platform / login_type GROUP BY，通过 `Abs(Sum(p_i × ln(p_i)))` 计算 L1/L2/L3 的曝光和 ppv 信息熵，写入目标分区。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，无多写竞争风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 策略，同一分区重跑会完整覆盖，幂等性好。
- **大量中间缓存**：ETL 使用多个 `CACHE TABLE ... MEMORY_AND_DISK_SER`，对 Spark executor 内存要求较高，大大区（如 `ID`）运行时需关注资源配置。
- **source1 / source2 的 ppv 仅计入，imp 置 0**：多来源入口场景下，source1 和 source2 的 imp 不做分配（置 0），ppv 则全量计入对应来源入口的统计，使用时需注意 `l{n}_imp_diversity` 对多来源场景可能低估。
- **熵值为 0 的边界情况**：当某 (feature_detail, scenario_tag) 下所有曝光/ppv 集中于单一类目时，熵值为 0；`feature_impr` 或 `feature_ppv` 为 0 时存在除零风险，上游若有零流量行需注意数据质量。
- **`${fields_placeholder}` / `${groupby_placeholder}`**：最终 INSERT SQL 使用模板参数，实际执行时由调度框架注入 platform / login_type 等维度字段，阅读 SQL 时需结合模板参数理解完整字段列表。

---

*文档生成时间：2026-05-17*