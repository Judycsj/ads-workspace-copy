<!-- ads-workspace-gdoc-sync: gdoc_id=1FFwtFGZiedcU3-4zdlEByKExiv4o8yg3oUGbiZYvXvw gdoc_url=https://docs.google.com/document/d/1FFwtFGZiedcU3-4zdlEByKExiv4o8yg3oUGbiZYvXvw/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_abtest_category_type_metrics_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `exp_type` + `exp_group_id` + `category_type` + `feature_group` + `target_type` + `sort_type` + `is_ads`
**分区：** `grass_region`（站点/地区）、`local_date`（业务日期）、`exp_type`（实验类型）
**更新频率：** 每日（T+1）
**访问频次：** 5,443 次

---

## 业务描述

本表是搜推平台（Search & Recommendation，SR）A/B 实验效果评估的核心 ADS 层汇总表，以**天**为粒度，聚合各实验组在不同商品类目、业务场景、投放类型等维度下的曝光、点击、浏览、加购及成交核心指标，并提供经过 99.5% 分位截尾处理的 GMV / 订单量稳健统计指标。

**核心业务场景：**
- AB 实验分组效果的多维归因分析（实验组 × 类目 × 场景 × 投放类型 × 是否广告）
- 搜索（Global Search）、推荐（Daily Discover、YMAL、Cart 等多 DA 场景）算法迭代的实验评估
- 稳健 GMV 指标计算（去除极端高 GMV 订单的偏差影响）

**适合回答的问题：**
- 某实验组在特定类目下，点击率、加购率、GMV 相比对照组是否有显著提升？
- 特定场景（如 Global Search）的实验组在不同 target_type 下各有多少去重用户产生了购买行为？
- 广告流量（`is_ads = true`）与自然流量（`is_ads = false`）在实验期间的成交表现差异？
- 99.5% 截尾后，各实验组的稳健 GMV 和订单量是否与原始指标存在显著差异（异常值影响评估）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/国家地区标识，如 `ID`、`MY`、`TH` 等，每次查询必须指定 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`，每次查询必须指定 |
| `exp_type` | string | 实验分流方式，区分三种计算口径：`assign_log_join`（基于搜索分流日志，仅 Search 场景）、`dim_join` / `assign_log_join_all_scene`（基于维度表关联，覆盖搜索+推荐多场景）、`traffic`（基于流量明细，使用 `exp_group_ids` 直接关联，覆盖搜索+推荐多场景，UU 为精确去重） |

### 维度：实验与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | 实验分组 ID，对应 A/B 实验的对照组或实验组编号 |
| `feature_group` | string | 业务场景标识，如 `dpm module Global Search business line Search`、`DA_Daily Discover`、`DA_You May Also Like` 等；`assign_log_join` 口径固定为 `dpm module Global Search business line Search`，其他口径来自 `scenario_tag` |
| `target_type` | string | 算法策略类型（如排序目标），`NA` 表示未匹配，`__ALL__` 表示全场景汇总 |
| `sort_type` | string | 排序类型；`assign_log_join` 口径按实际排序类型分组，`dim_join` 和 `traffic` 口径固定输出 `__ALL__` |
| `is_ads` | string | 是否广告流量，取值 `true`/`false`/`__ALL__`（`__ALL__` 表示广告+自然流量合并汇总） |

### 维度：商品类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `category_type` | string | 商品类目标签，来源于 `dim_sr_data_warehouse_item` 的 `category_tag`；未命中类目的商品统一归为 `low gmv` |

### 指标：曝光行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 商品曝光次数（impression 事件聚合） |
| `imp_uu` | bigint | 产生曝光行为的去重用户数（`imp_cnt > 0` 的用户计数） |

### 指标：点击行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 商品点击次数 |
| `click_uu` | bigint | 产生点击行为的去重用户数（`click_cnt > 0` 的用户计数） |

### 指标：商品详情页浏览

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页（PDP）浏览次数；`traffic` 口径中已过滤 `is_back = true` 的回退浏览 |
| `ppv_uu` | bigint | 产生 PDP 浏览的去重用户数（`ppv_cnt > 0` 的用户计数） |

### 指标：加购行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 产生加购行为的去重用户数（`cart_cnt > 0` 的用户计数） |

### 指标：订单与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 原始下单件数（operation_cnt 聚合） |
| `order_uu` | double | 产生下单行为的去重用户数（`order_cnt > 0` 的用户计数） |
| `order_cnt_995_v2` | double | 99.5% 截尾后的订单件数；当单笔订单 GMV 超过对应 `category_tag` + `is_ads` 的 99.5% 分位阈值时，该笔订单不计入 |
| `gmv` | double | 原始 GMV（place_order_gmv 聚合，单位与货币同站点） |
| `gmv_995_v2` | double | 99.5% 截尾后的 GMV；超过阈值的订单 GMV 替换为阈值上限值（`gmv_995pct`），用于减少极端高价单对实验评估的偏差 |
| `pc2_gmv` | double | PC2 口径 GMV（归因至二级来源的 GMV） |
| `pc2_gmv_995_v2` | double | 99.5% 截尾后的 PC2 GMV，同 `gmv_995_v2` 处理逻辑 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全量扫描所有站点分区，查询性能极差。
- **`local_date`**：必须指定，本表为每日快照，建议精确到单日或使用日期范围。
- **`exp_type`**：强烈建议指定，三种口径（`assign_log_join`、`dim_join`/`assign_log_join_all_scene`、`traffic`）的**分母定义、场景覆盖范围、指标计算方法均不同**，混合汇总无实际业务意义。

```sql
-- 推荐写法示例
WHERE grass_region = 'ID'
  AND local_date = '2025-05-16'
  AND exp_type = 'traffic'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu` | 去重用户数，跨行直接 SUM 会重复计算同一用户 |
| `gmv_995_v2`、`pc2_gmv_995_v2`、`order_cnt_995_v2` | 截尾预聚合指标，不同维度组合的截尾阈值来自各自分组的分位数，跨组 SUM 无法还原正确的截尾结果 |
| `order_cnt`、`order_uu`、`gmv`、`pc2_gmv` | 当 `is_ads = '__ALL__'` 与明细行（`true`/`false`）共存时，直接 SUM 会重复计数；需按 `is_ads` 明细值过滤后聚合 |
| `sort_type` 相关聚合 | `dim_join` 和 `traffic` 口径的 `sort_type` 固定为 `__ALL__`，不可与 `assign_log_join` 口径混合对 `sort_type` 做 GROUP BY 分析 |

### `__ALL__` 汇总行说明

- `target_type = '__ALL__'`、`is_ads = '__ALL__'`、`sort_type = '__ALL__'`、`feature_group = '__ALL__'` 均为预计算的各维度汇总行，已包含在表内。
- 使用明细维度分析时，需过滤掉 `__ALL__` 行，反之亦然，避免重复。

### 时效性说明

- 本表后缀 `_1d`，为**每日批量更新**，通常于 T+1 上午完成写入，不提供实时/小时级数据。
- 各 `exp_type` 分区由独立 ETL 任务分别写入，存在先后完成时间差，同一 `local_date` 下不同 `exp_type` 分区的数据就绪时间可能不一致。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 实验用户分组映射，提供 `user_id → exp_group_id` 关系；不同 ETL 按 `is_assignment_log`、`is_search_whitelist`、`is_dim_join`、`is_rcmd_whitelist` 等标志过滤不同口径的实验用户 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验组白名单过滤（`is_rcmd_whitelist = 1`），用于 `traffic` 口径的有效实验组筛选 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品类目维度表，提供 `item_id → category_tag` 映射 |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 各类目 × is_ads 组合的 GMV 99.5% 分位阈值（`gmv_995pct`、`pc2_gmv_995pct`），用于截尾处理 |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 用户-商品级别的曝光、点击、PDP 浏览、加购 DWS 汇总（`assign_log_join` 和 `dim_join` 口径流量指标来源） |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 用户-商品操作明细（`traffic` 口径流量指标来源），包含 `exp_group_ids` 字段，支持直接 explode 关联实验组 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 订单明细 DWD 层，包含多路归因字段（reporting/source1/source2）及 `place_order_gmv`、`pc2_gmv`、`operation_cnt`，三种口径的订单指标均来源于此 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group / abtest_group
        │ 实验分组关系
        ▼
[用户-实验组映射]
        │
        ├── INNER JOIN ──────────────────────────────────────────┐
        │                                                        │
dws/dwm 平台行为明细                                        dwd 订单明细
  (曝光/点击/ppv/加购)                                    (place_order_gmv/pc2_gmv)
        │ CUBE 多维预聚合                                        │ 多路归因展开 + CUBE
        ▼                                                        ▼
   exp_metrics（曝光/点击等实验组聚合）       dws_order_exp（订单/GMV 实验组聚合）
                                                    │
                              dim_category_gmv_outlier（99.5% 分位截尾）
                                                    │
        └──────────── FULL OUTER JOIN ────────────────┘
                              │
              INSERT OVERWRITE → 目标表（按 exp_type 分区）
```

### 关键步骤

#### ETL 1：`assign_log_join` 口径（仅 Search 场景）

1. **`user_exp_mapping`**：从 `dim_sr_data_warehouse_abtest_user_group` 中按 `is_assignment_log = 1 AND is_search_whitelist = 1` 筛选搜索场景实验用户。
2. **`dim_item`**：加载当日商品类目维度。
3. **`dws_platform`**：从 `dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` 过滤 `scenario_tags` 含 `dpm module Global Search business line Search` 的记录，LEFT JOIN 类目维度，按 `user_id × category_tag × target_type × sort_type × is_ads` 聚合曝光/点击/ppv/加购。
4. **`dws_platform_cube`**：对 `target_type`、`sort_type`、`is_ads` 执行 CUBE 多维展开，生成含 `__ALL__` 汇总行的中间结果。
5. **`exp_metrics`**：INNER JOIN 实验用户映射，按 `exp_group_id` 维度聚合，计算各实验组的行为指标及 UU 数。
6. **`gmv_outlier`**：读取 99.5% GMV 截尾阈值（按 `feature_group = 'dpm module Global Search business line Search'` 过滤）。
7. **`dws_order`**：从 `dwd_sr_data_warehouse_platform` 读取订单记录，按多路归因规则（reporting/source1/source2）确定 `target_type` 和 `sort_type`，LEFT JOIN 类目维度，按 `user_id × category_tag × target_type × sort_type × is_ads × order_id × item_id` 聚合。
8. **`dws_order_cube`**：对 `target_type`、`sort_type`、`is_ads` 执行 CUBE 展开。
9. **`dws_order_outlier`**：LEFT JOIN GMV 截尾阈值，计算 `order_cnt_995`、`gmv_995_overwrite`、`pc2_gmv_995_overwrite`。
10. **`dws_order_exp`**：INNER JOIN 实验用户映射，按 `exp_group_id` 维度聚合，计算订单 UU 及截尾指标。
11. **INSERT OVERWRITE**：`exp_metrics` FULL OUTER JOIN `dws_order_exp`，写入 `exp_type = 'assign_log_join'` 分区，`feature_group` 固定为 `'dpm module Global Search business line Search'`，`sort_type` 保留实际值。

#### ETL 2：`dim_join` / `assign_log_join_all_scene` 口径（搜索 + 多推荐场景）

1. **`user_exp_mapping`**：UNION ALL 两路用户集合：`is_dim_join = 1 AND is_rcmd_whitelist = 1`（标记 `exp_type = 'dim_join'`）和 `is_assignment_log = 1 AND is_search_whitelist = 1`（标记 `exp_type = 'assign_log_join_all_scene'`）。
2. **`dws_platform`**：UNION ALL 三路数据：① 按 `target_type` 明细展开的多场景曝光行为；② 使用 `dedup_scenario_tags` 展开的 `target_type = '__ALL__'` 数据；③ `is_direct = true` 的直达流量（`target_type = '__ALL__'`，`scenario_tags = ['__ALL__']`）。
3. **`dws_platform_cube`**：按 `scenario_tag`（LATERAL VIEW EXPLODE）× `target_type` × CUBE(`is_ads`) 聚合。
4. **`exp_metrics`**：INNER JOIN 实验用户（含 `exp_type` 字段），聚合至 `exp_group_id × scenario_tag × target_type × is_ads × exp_type` 粒度，UU 指标使用 `sum(if(cnt > 0, 1, null))` 近似计算。
5. **订单侧**：订单明细通过 `build_scenario_tags` UDF 展开多路归因场景标签，LATERAL VIEW EXPLODE 后进行 CUBE 聚合，再 LEFT JOIN GMV 截尾阈值。
6. **INSERT OVERWRITE**：写入 `exp_type`（动态分区，来自 `COALESCE(a.exp_type, b.exp_type)`），`sort_type` 固定输出 `'__ALL__'`，`feature_group` 取 `scenario_tag`。

#### ETL 3：`traffic` 口径（基于流量明细，精确去重 UU）

1. **`exp_filter`**：从 `dim_sr_data_warehouse_abtest_group` 获取 `is_rcmd_whitelist = 1` 的有效实验组列表（不需要 user 级别关联，仅作最终 JOIN 过滤）。
2. **`dws_platform`**：从 `dwm_sr_data_warehouse_platform_user_item`（行为明细层）读取，UNION ALL 五路数据：reporting/source1/source2 各 `target_type` 明细、`target_type = '__ALL__'` 合并、`scenario_tags = ['__ALL__']` 全量。行为明细已携带 `exp_group_ids` 数组。
3. **`dws_platform_cube`**：按 `scenario_tag × target_type × CUBE(is_ads)` 聚合，保留 `exp_group_ids` 数组。
4. **`exp_explode`**：LATERAL VIEW EXPLODE `exp_group_ids`，将每条记录展开为多个实验组记录。
5. **`exp_metrics`**（CACHE TABLE）：INNER JOIN `exp_filter` 白名单，使用 `count(distinct if(..., user_id, null))` **精确去重**计算 UU，与其他口径的近似计算有所不同。
6. **订单侧**（CACHE TABLE）：`dwd_order` 从 `dwd_sr_data_warehouse_platform` 读取，保留 `exp_group_ids`，通过 `dwd_order_source` 展开多路归因，CUBE 聚合后 LATERAL VIEW EXPLODE `exp_group_ids`，INNER JOIN `exp_filter`，LEFT JOIN GMV 截尾阈值，直接在 `cache table dws_order_exp` 中完成截尾计算。
7. **INSERT OVERWRITE**：写入 `exp_type = 'traffic'` 分区，`sort_type` 固定输出 `'__ALL__'`，`feature_group` 取 `scenario_tag`。

### 注意事项

- **Multi-writer 风险**：本表由 3 个独立 ETL 文件分别写入不同 `exp_type` 分区，采用 `INSERT OVERWRITE ... PARTITION(exp_type = ...)` 静态或动态写入，各文件之间互不干扰，但调度上需保证串行或分区隔离执行，避免同一分区被并发覆盖。
- **`exp_type = 'dim_join'` 与 `'assign_log_join_all_scene'` 同属 ETL 2**：两者由同一 SQL 文件在 `exp_type` 动态分区下同时写入，数据产出时间一致，逻辑上是同一 pipeline 的两个输出分区。
- **UU 计算口径差异**：`assign_log_join` 和 `dim_join`/`assign_log_join_all_scene` 口径的 UU 指标使用 `sum(if(cnt > 0, 1, null))` 近似去重（user 级已预聚合），而 `traffic` 口径使用 `count(distinct user_id)` 精确去重，同一实验组不同口径的 UU 数存在合理差异，不可直接对比。
- **GMV 截尾阈值匹配逻辑**：`assign_log_join` 口径按 `feature_group` 固定值过滤截尾阈值表；`dim_join` 和 `traffic` 口径按 `scenario_tag` 动态 JOIN 截尾阈值的 `feature_group` 字段，未匹配的场景不做截尾（GMV 保留原始值）。
- **`category_type = 'low gmv'`**：表示商品未命中类目维度表，属于兜底值，分析时需酌情处理。

---

*文档生成时间：2026-05-17*