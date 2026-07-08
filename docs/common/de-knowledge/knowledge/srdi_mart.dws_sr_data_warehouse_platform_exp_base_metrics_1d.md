<!-- ads-workspace-gdoc-sync: gdoc_id=1f1R6vmKqXtnaPMWSxoCpnXkJ3FNQ29XUTdHJxFdNmxI gdoc_url=https://docs.google.com/document/d/1f1R6vmKqXtnaPMWSxoCpnXkJ3FNQ29XUTdHJxFdNmxI/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d

**分层**：DWS（数据汇总层）
**主键**：`grass_region` + `local_date` + `exp_type` + `exp_group_id` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `target_type`
**分区**：`grass_region`（地区）/ `local_date`（业务日期）/ `exp_type`（实验类型，枚举值：`traffic` / `assign_log_join` / `dim_join`）
**更新频率**：每日 T+1 全量覆盖写入（INSERT OVERWRITE），三个 exp_type 分区由三个独立 ETL 文件并行写入
**引用频次 / 访问频次**：1729

---

## 业务描述

本表是搜推（Search & Recommendation）数仓平台的 **A/B 实验基础指标汇总表**，以「实验分组 × 平台 × 广告标记 × 特征维度 × 场景标签 × 目标类型」为粒度，存储每个实验桶在各业务场景下的核心漏斗指标（曝光 → 点击 → 商品详情页访问 → 加购 → 下单 → GMV），支持搜索、推荐、首页、私域等多个业务线的实验效果评估。

**核心业务场景**：
- A/B 实验效果评估：对比不同实验分组的点击率（CTR）、转化率（CVR）、GMV 等核心指标；
- 广告负载（Ads Load）分析：计算广告曝光占比，支持自然流量与广告流量的分层分析；
- 多归因口径支持：通过三种 `exp_type` 提供基于流量日志（`traffic`）、分配日志关联（`assign_log_join`）、维度关联（`dim_join`）三套实验人群圈定口径的独立指标；
- 统计显著性检验支持：提供 `squared_*` 字段（方差估计）用于 Delta Method 等统计检验；
- Omni 渠道分析：提供全渠道曝光（`omni_imp_cnt`）和全渠道点击（`omni_click_cnt`）。

**适合回答的问题**：
- 某实验分组在指定地区、指定日期内的曝光量、点击量、GMV 是多少？
- 各实验桶之间的点击率、成交转化率差异是否显著？
- 广告流量占整体流量的比例（Ads Load）如何？
- 搜索/推荐/首页各场景下实验指标的差异对比？
- 加购后当日/3日内的转化效果如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识，如 `SG`、`MY` 等，所有查询必须指定此分区 |
| `local_date` | date | 业务日期（本地日期），格式 `YYYY-MM-DD`，所有查询必须指定此分区 |
| `exp_type` | string | 实验人群圈定口径类型：`traffic`（流量日志实验桶过滤）、`assign_log_join`（分配日志关联）、`dim_join`（维度表关联） |

### 维度：实验与特征维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_group` / `dim_sr_data_warehouse_abtest_user_group`；`__ALL__` 维度下该字段为汇总值 |
| `platform` | string | 平台标识（如 iOS / Android / Web 等）；`__ALL__` 表示全平台汇总；原始为 NULL 时填充为 `'NULL'` |
| `is_ads` | string | 是否广告流量：`'true'`（广告）、`'false'`（自然流量）、`'__ALL__'`（全量汇总） |
| `feature_detail` | string | 特征维度标识，标识具体的推荐/搜索特征路径（如 `a-b-item`）；`'__ALL__'` 表示全特征汇总；同一条记录可能对应主特征、source1 或 source2 归因 |
| `scenario_tag` | string | 场景标签，标识业务线与场景（如 `DA_*` 系列、Search、Rcmd、Homepage、Private Domain 等）；`'__ALL__'` 表示全场景汇总 |
| `target_type` | string | 目标类型，从 `feature_detail` 按 `-` 分割提取（第3段或第2段），如 `item`；`'__ALL__'` 表示全类型汇总 |

### 指标：曝光与点击漏斗（全量 + 登录用户）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 总曝光次数（含未登录用户） |
| `imp_login_cnt` | bigint | 登录用户曝光次数（`traffic` 口径下为登录用户部分；`assign_log_join`/`dim_join` 口径下因数据源仅含登录用户，与 `imp_cnt` 相等） |
| `imp_uu` | bigint | 有曝光行为的登录用户数（去重 UU） |
| `click_cnt` | bigint | 总点击次数 |
| `click_login_cnt` | bigint | 登录用户点击次数 |
| `click_uu` | bigint | 有点击行为的登录用户数（去重 UU） |
| `ppv_cnt` | bigint | 商品详情页（PPV）访问总次数 |
| `ppv_login_cnt` | bigint | 登录用户 PPV 次数 |
| `ppv_uu` | bigint | 有 PPV 行为的登录用户数（去重 UU） |
| `ppv_cnt_exclude_isback` | bigint | 排除回退行为（is_back=true）后的 PPV 次数 |
| `ppv_exclude_isback_login_cnt` | bigint | 登录用户排除回退后的 PPV 次数 |

### 指标：商品粒度曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | 商品（target_type='item'）曝光次数 |
| `item_imp_login_cnt` | bigint | 登录用户商品曝光次数 |
| `item_imp_uu` | bigint | 有商品曝光行为的登录用户数（去重 UU） |
| `item_click_cnt` | bigint | 商品点击次数 |
| `item_click_login_cnt` | bigint | 登录用户商品点击次数 |
| `item_click_uu` | bigint | 有商品点击行为的登录用户数（去重 UU） |

### 指标：加购与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购（加入购物车）总次数 |
| `cart_login_cnt` | bigint | 登录用户加购次数 |
| `cart_uu` | bigint | 有加购行为的登录用户数（去重 UU） |
| `order_cnt` | double | 下单总次数（double 类型，来源于 dwm 层 order_cnt 累加） |
| `order_login_cnt` | double | 登录用户下单次数 |
| `order_uu` | bigint | 有下单行为的登录用户数（去重 UU） |

### 指标：ATC（加购后）转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购当日成交订单数 |
| `atc_same_day_order_login_cnt` | double | 登录用户加购当日成交订单数 |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内成交订单数 |
| `atc_within_3day_order_login_cnt` | double | 登录用户加购后 3 日内成交订单数 |

### 指标：GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 总成交金额（GMV） |
| `gmv_login` | double | 登录用户成交金额 |
| `atc_same_day_order_gmv` | double | 加购当日成交 GMV（ETL 中来源字段为 `atc_same_day_gmv`） |
| `atc_same_day_gmv_login` | double | 登录用户加购当日成交 GMV |
| `atc_within_3day_gmv` | double | 加购后 3 日内成交 GMV |
| `atc_within_3day_gmv_login` | double | 登录用户加购后 3 日内成交 GMV |
| `pc2_gmv` | double | PC2 归因口径成交 GMV |
| `pc2_gmv_login` | double | 登录用户 PC2 归因口径成交 GMV |

### 指标：全渠道（Omni Channel）

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_imp_cnt` | bigint | 全渠道曝光次数；仅 `assign_log_join` 和 `dim_join` 口径有值，`traffic` 口径固定为 NULL |
| `omni_click_cnt` | bigint | 全渠道点击次数；仅 `assign_log_join` 和 `dim_join` 口径有值，`traffic` 口径固定为 NULL |

### 指标：广告负载

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_load` | double | 广告负载率：`is_ads='true'` 时为 1，`is_ads='false'` 时为 0，`is_ads='__ALL__'` 时为 `ads_imp_cnt / all_imp_cnt`（广告曝光数/总曝光数）；**派生字段，不可直接 SUM** |

### 指标：方差估计（用于统计检验）

| 字段 | 类型 | 说明 |
|---|---|---|
| `squared_imp_cnt` | double | 曝光次数的平方（`power(imp_cnt, 2)`），用于 Delta Method 方差估计；**不可直接 SUM 作业务指标** |
| `squared_click_cnt` | double | 点击次数的平方，用于统计检验；**不可直接 SUM 作业务指标** |
| `squared_order_cnt` | double | 下单次数的平方，用于统计检验；**不可直接 SUM 作业务指标** |
| `squared_ppv_cnt_exclude_isback` | double | 排除回退后 PPV 次数的平方，用于统计检验；**不可直接 SUM 作业务指标** |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段均需指定**，缺失任一分区将触发全表扫描：
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2024-01-01'
     AND exp_type = 'traffic'   -- 或 'assign_log_join' / 'dim_join'
   ```
2. **`exp_type` 三个分区语义不同、数据独立**，不可跨 `exp_type` 聚合，否则会三重计数：
   - `traffic`：基于流量日志中的实验桶 ID，包含登录+未登录用户；
   - `assign_log_join`：基于实验分配日志（`is_assignment_log=1`）关联，仅含登录用户，含 omni 及 squared 指标；
   - `dim_join`：基于维度表（`is_dim_join=1`）关联，仅含登录用户，含 omni 及 squared 指标。
3. **`exp_group_id` 必须与业务实验对应**，避免混入无关实验桶数据。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ads_load` | 派生比率字段（广告曝光/总曝光），直接 SUM 无意义，需重新计算分子分母比值 |
| `imp_uu` / `click_uu` / `ppv_uu` / `cart_uu` / `order_uu` / `item_imp_uu` / `item_click_uu` | 去重 UU 指标，跨维度 SUM 会重复计算同一用户 |
| `squared_imp_cnt` / `squared_click_cnt` / `squared_order_cnt` / `squared_ppv_cnt_exclude_isback` | 方差估计中间值，仅用于统计检验公式，不是业务可加指标 |

### 维度聚合注意事项

- 表中包含 **预聚合的汇总维度**：`feature_detail='__ALL__'`、`scenario_tag='__ALL__'`、`platform='__ALL__'`、`is_ads='__ALL__'`、`target_type='__ALL__'`，使用时需明确是否需要汇总维度，否则与明细维度叠加会导致数据重复。
- `feature_detail` 存在多归因场景（主特征、source1、source2），一条原始行为记录可能同时出现在多个 `feature_detail` 下，跨 `feature_detail` 累加时需注意重复计数风险。

### 时效性说明

- 本表为 **日粒度表**（`_1d` 后缀），数据为 T+1 更新，不含实时数据。
- 不存在近 N 天窗口预聚合，如需多日汇总请自行按 `local_date` 范围过滤后聚合（注意 UU 类指标不可跨日 SUM）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心行为明细宽表，提供用户在各平台的曝光、点击、PPV、加购、下单、GMV 等操作级数据，三个 ETL 文件均以此为基础数据源 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验分组白名单维度表，用于 `traffic` 口径过滤有效实验分组（`is_rcmd_whitelist=1`） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户-实验分组关联维度表，用于 `assign_log_join`（`is_assignment_log=1`）和 `dim_join`（`is_dim_join=1`）口径的用户实验归因关联 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │
        ▼
  [按 grass_region/local_date 过滤行为数据]
        │
        ├─► [traffic 口径]  按 exp_group_id 关联 dim_abtest_group 白名单过滤
        │                    → GROUPING SETS 多维预聚合 (Cube)
        │                    → 计算 UU / login_cnt / ads_load
        │                    → INSERT OVERWRITE exp_type='traffic'
        │
        ├─► [assign_log_join 口径]  按 user_id 关联 dim_abtest_user_group (is_assignment_log=1)
        │                            → GROUPING SETS 多维预聚合
        │                            → 计算 squared_* / omni_* / ads_load
        │                            → exp_sum UDAF 按实验桶聚合
        │                            → INSERT OVERWRITE exp_type='assign_log_join'
        │
        └─► [dim_join 口径]  按 user_id 关联 dim_abtest_user_group (is_dim_join=1)
                              → GROUPING SETS 多维预聚合
                              → 计算 squared_* / omni_* / ads_load
                              → exp_sum UDAF 按实验桶聚合
                              → INSERT OVERWRITE exp_type='dim_join'
```

### 关键步骤

**ETL 文件 1（exp_type = 'traffic'）**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `exp_filter` | 从实验分组维度表取当日白名单实验桶列表（`is_rcmd_whitelist=1`） |
| 2 | `dwm_table` | 从 dwm 层读取行为数据，按用户+特征+实验桶列表聚合，同时处理主特征/source1/source2 三路 scenario_tags 过滤（保留 DA_\* 及指定业务线场景） |
| 3 | `explode_table` | 将 `exp_group_ids` 数组展开为单行（EXPLODE） |
| 4 | `base_table`（CACHED） | INNER JOIN 白名单 `exp_filter`，过滤非白名单实验桶，结果缓存到内存/磁盘 |
| 5 | `raw_data` | UNION ALL 三路归因（主特征、source1、source2），要求 scenario_tags 非空且特征非空 |
| 6 | `dws_all_tag` / `dws_tag` | 构建全场景汇总（`__ALL__`）和按场景联合标签的预聚合视图 |
| 7 | `filter_tag_data` | 解析 `target_type`（从 feature_detail 按 `-` 分割取第3或第2段） |
| 8 | `cube_table` | GROUPING SETS 多维 Cube 预聚合（feature_detail × is_ads × platform × target_type × scenario_tag），UNION ALL 三组：明细特征、全特征汇总、场景联合标签汇总 |
| 9 | `metric_table` | 在 Cube 结果上聚合计算 UU 指标（登录用户去重）、login_cnt 指标，NULL 维度替换为 `'__ALL__'` |
| 10 | `benchmark_w_cube_ads_load_temp` + `res` | 窗口函数计算 `ads_imp_cnt`/`all_imp_cnt`，派生 `ads_load` |
| 11 | INSERT OVERWRITE | 写入分区 `exp_type='traffic'`，`omni_*` 和 `squared_*` 字段填充 NULL |

**ETL 文件 2（exp_type = 'assign_log_join'）**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `user_exp` | 从用户实验分组表（`is_assignment_log=1`，`is_rcmd_whitelist=1`）收集每个 user_id 的实验桶列表 |
| 2 | `base_table`（CACHED） | 从 dwm 层读取行为数据，仅保留登录用户（`user_id > 0`），包含 `omni_impression`/`omni_click` 操作，scenario_tags 过滤排除 Page 和 mapping group 类标签 |
| 3 | `raw_data` | UNION ALL 三路归因特征，应用 DA_\* 等场景过滤 |
| 4-7 | `dws_all_tag` / `dws_tag` / `filter_tag_data` / `cube_table` | 与文件 1 逻辑相同，额外包含 `omni_imp_cnt`/`omni_click_cnt` |
| 8 | `squared_data` | 计算 UU 标记位及 `power(*,2)` 方差估计字段 |
| 9 | `map_data` | 将所有指标打包为 array（metrics 向量） |
| 10 | `explode_metric_table` | 使用自定义 UDAF `exp_sum` JOIN `user_exp`，按实验桶汇总 metrics 向量 |
| 11 | `metric_table` | LATERAL VIEW EXPLODE 展开 exp_metrics，解包各实验桶指标 |
| 12 | `benchmark_w_cube_ads_load_temp` + `res` | 计算 `ads_load` |
| 13 | INSERT OVERWRITE | 写入分区 `exp_type='assign_log_join'`，`*_login_cnt` 字段直接等于对应 `*_cnt`（因来源仅登录用户） |

**ETL 文件 3（exp_type = 'dim_join'）**

与文件 2 逻辑基本一致，差异仅在用户实验分组过滤条件为 `is_dim_join=1`（而非 `is_assignment_log=1`），写入分区 `exp_type='dim_join'`。

### 注意事项

1. **Multi-writer 并发写入**：三个 ETL 文件各自使用 `INSERT OVERWRITE` 写入不同 `exp_type` 分区，物理上写入同一张表的不同分区目录，需确保三个任务不写入同一分区（当前设计通过 `exp_type` 分区隔离，无冲突风险）。
2. **`traffic` 口径 omni/squared 字段为 NULL**：`exp_type='traffic'` 的分区中，`omni_imp_cnt`、`omni_click_cnt`、`squared_*` 四个字段固定写入 NULL，下游使用前需判断口径。
3. **`assign_log_join` / `dim_join` 口径的 `*_login_cnt` 字段**：由于基础数据源过滤了 `user_id > 0`，这两个口径的 `*_login_cnt` 字段值与对应 `*_cnt` 字段完全相同（直接 alias），无额外过滤逻辑。
4. **`exp_sum` 为自定义 UDAF**：`assign_log_join` 和 `dim_join` 口径使用自定义聚合函数 `exp_sum(exp_group_ids, metrics)` 将 user 维度指标按实验桶分配汇总，该函数不在标准 Spark SQL 内置函数范围内，依赖平台特定 UDF 注册。
5. **GROUPING SETS 产生汇总维度行**：Cube 预聚合会产生 `feature_detail`/`platform`/`is_ads` 为 NULL 的汇总行，ETL 最终 SELECT 时将 NULL 替换为 `'__ALL__'`，下游查询时需注意区分明细维度与汇总维度，避免重复计算。
6. **`base_table` 缓存策略差异**：`traffic` 口径使用 `MEMORY_AND_DISK_SER`，`assign_log_join`/`dim_join` 使用 `DISK_ONLY`，反映数据量差异（后两者仅含登录用户）。

---

*文档生成时间：2026-05-17*