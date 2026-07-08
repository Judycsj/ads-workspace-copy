<!-- ads-workspace-gdoc-sync: gdoc_id=1MC2I89VV1Iyvxb01cVN0NqlPGNN_jxZT0_kVwfuglog gdoc_url=https://docs.google.com/document/d/1MC2I89VV1Iyvxb01cVN0NqlPGNN_jxZT0_kVwfuglog/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_srp_layout_instant_filter_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `experiment_id` + `exp_group_id` + `use_instant_filter_type` + `layout_type` + `card_type`
**分区：** `grass_region`（站点）, `local_date`（业务日期）
**更新频率：** 每日覆盖写（INSERT OVERWRITE），T+1 产出
**引用频次 / 访问频次：** 346

---

## 业务描述

本表面向**搜索结果页（SRP）即时配送筛选器（Instant Filter）A/B 实验**的日级效果分析，核心目标是评估 SRP 布局类型（`layout_type`）与即时筛选器使用与否（`use_instant_filter_type`）对搜索漏斗各核心指标的影响。

**核心业务场景：**
- 统计指定 A/B 实验（experiment_id=148401）各实验组在不同布局类型、筛选器使用状态下的搜索、曝光、点击、成单、GMV、广告收入等全链路指标。
- 评估即时筛选器（instant_delivery / fast_delivery）的采用率、零结果页（no results）率及对搜索成功率的影响。
- 分析店铺卡片布局（layout_type='3'）下的商品填充率（`shop_item_fill_rate`）与店铺曝光情况。
- 提供实验组维度的全平台 GMV 与 Global Search GMV 对照，用于实验收益归因。
- 衡量平均预计送达时间（avg_edt）在不同实验组及筛选器使用状态下的差异。

**适合回答的问题：**
- 某实验组在使用 / 未使用即时筛选器时，搜索成功率、成单率、GMV 有何差异？
- 不同 SRP 布局（layout_type）下，即时筛选器的点击率和曝光情况如何？
- 实验组 vs 对照组的 Global Search GMV、平台 GMV 变化幅度？
- 店铺卡片布局下商品填充率是否满足要求（shop_item_fill_rate）？
- 筛选器导致的零结果页（no results）对各实验组的影响程度？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域分区，如 `TH`、`ID`、`MY` 等，对应各国家站点 |
| `local_date` | date | 业务日期（本地时区），数据统计口径的日期分区 |

### 维度：实验与分组维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，当前 ETL 固定聚合实验 ID = 148401（SRP 布局即时筛选器实验） |
| `exp_group_id` | bigint | 实验分组 ID，区分对照组与各实验组 |

### 维度：切片维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `use_instant_filter_type` | string | 是否使用即时配送筛选器。`'true'`=使用（即 search_filter_string 中包含 instant_delivery 或 fast_delivery），`'false'`=未使用，`'__ALL__'`=全量（CUBE 汇总维） |
| `layout_type` | string | SRP 页面布局类型，来自 dwd 层 layout_type 字段，`NULL` 时默认为 `'2'`；`'3'` 表示店铺卡片布局；`'__ALL__'`=全量汇总维 |
| `card_type` | string | 搜索结果卡片类型，取自 target_type，如 `item`、`shop`、`video`、`livestream` 等；`'__ALL__'`=全量汇总维 |

### 指标：实验组基础规模指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `group_uu` | bigint | 实验组独立用户数（UV），仅在 `use_instant_filter_type='__ALL__'` 且 `layout_type='__ALL__'` 且 `card_type='__ALL__'` 行有值，其余行为 NULL |

### 指标：搜索行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu` | bigint | 发起搜索（operation=view）的独立用户数，仅在全量汇总维度行（三维均为 `__ALL__`）有值 |
| `search_volume` | bigint | 搜索次数（以 user_id + device_id + keyword 三元组去重计），仅在全量汇总行有值 |
| `instant_filter_uu` | bigint | 点击（使用）即时筛选器的独立用户数，仅在全量汇总行有值 |
| `instant_filter_using_cnt` | bigint | 即时筛选器被点击的总次数（operation=click 且 filter_name 为即时配送相关），仅在全量汇总行有值 |
| `instant_filter_imp_uu` | bigint | 即时筛选器曝光的独立用户数（shortcut bar 中 filter_button 曝光），仅在全量汇总行有值 |
| `instant_filter_imp_cnt` | bigint | 即时筛选器曝光总次数，仅在全量汇总行有值 |

### 指标：搜索成功与零结果指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_search_success_volume` | bigint | 直接搜索成功量，定义为 page_section=NULL 且 target_type 为 item/video/livestream 的点击去重（user_id, device_id, keyword）数 |
| `broad_search_success_volume` | bigint | 广义搜索成功量，包含直接搜索成功及店铺/达人相关点击的去重搜索次数 |
| `no_results_cnt` | bigint | 零结果页面曝光次数（impression 行数），仅在全量汇总行有值 |
| `no_results_volume` | bigint | 零结果去重搜索次数（以 user_id + device_id + keyword 三元组计），仅在全量汇总行有值 |
| `instant_filter_no_results_cnt` | bigint | 由即时筛选器导致的零结果曝光次数（target_type=try_diff_address 或 no_recall_with_filter 含即时筛选），仅在全量汇总行有值 |
| `instant_filter_no_results_volume` | bigint | 由即时筛选器导致的零结果去重搜索次数，仅在全量汇总行有值 |

### 指标：曝光、点击、成单漏斗指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果卡片总曝光次数（operation_cnt 求和） |
| `imp_uu` | bigint | 搜索结果卡片曝光独立用户数 |
| `click_cnt` | bigint | 搜索结果卡片总点击次数（operation_cnt 求和） |
| `click_uu` | bigint | 搜索结果卡片点击独立用户数 |
| `order_cnt` | double | 搜索归因订单数（operation_cnt 求和，含 source1/source2 归因链路） |
| `order_uu` | bigint | 搜索归因下单独立用户数 |
| `gmv` | double | 搜索归因 GMV（place_order_gmv 求和，含 source1/source2 归因链路），单位与 place_order_gmv 一致 |

### 指标：广告收入与预计送达时间

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_rev` | double | 搜索广告收入（expenditure_amt_usd），通过 request_id + item_id 与广告曝光表关联后汇总 |
| `avg_edt` | double | 平均预计送达时间（edtmax_in_days 均值），通过订单与 EDT 订单信息表关联计算；**不可直接 SUM** |

### 指标：店铺布局专属指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_search_volume` | bigint | 店铺卡片布局（layout_type='3'）下的搜索量（去重搜索 session 数），非 layout_type='3' 时为 NULL |
| `empty_shop_imp_cnt` | bigint | 店铺卡片（layout_type='3' 且 card_type='shop'）中商品槽未填满（shop_layout_item_list 数量 < 3）的曝光次数，非对应维度时为 NULL |
| `shop_item_fill_rate` | double | 店铺卡片商品填充率，计算公式为 item 卡曝光数 / (shop 卡曝光数 × 3)，仅 layout_type='3' 时有值；**不可直接 SUM** |

### 指标：平台全局对照指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_search_order_cnt` | double | 全局搜索渠道归因订单数（reporting_business_line='Search' 且 reporting_module='Global Search'），仅在全量汇总行有值 |
| `global_search_gmv` | double | 全局搜索渠道归因 GMV，仅在全量汇总行有值 |
| `platform_order_cnt` | double | 实验组用户全平台订单数（不限搜索渠道），仅在全量汇总行有值 |
| `platform_gmv` | double | 实验组用户全平台 GMV，仅在全量汇总行有值 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段过滤**：查询时必须同时指定 `grass_region` 和 `local_date`，避免全表扫描。

   ```sql
   WHERE grass_region = 'TH'
     AND local_date = '2024-01-01'
   ```

2. **维度过滤说明**：表中包含 CUBE 展开后的多维汇总行。若只需要全量合计，应过滤：
   ```sql
   AND use_instant_filter_type = '__ALL__'
   AND layout_type = '__ALL__'
   AND card_type = '__ALL__'
   ```
   若需要按某个维度细分，则对应字段不过滤 `'__ALL__'`，并注意其他维度是否也要汇总或细分。

3. **实验组全量口径**：`group_uu`、`search_uu`、`search_volume`、`instant_filter_*`、`no_results_*`、`global_search_*`、`platform_*` 等指标仅在三个切片维度均为 `'__ALL__'` 时填充，其他行为 NULL，因此计算实验整体漏斗时应限定全量汇总行。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `avg_edt` | 均值型指标，跨行 SUM 无意义，需重新从明细层聚合或使用加权平均 |
| `shop_item_fill_rate` | 比率型指标（item 曝光 / shop 曝光×3），不可 SUM，跨分组比较须回溯分子分母 |
| `order_cnt`、`gmv`、`platform_order_cnt`、`platform_gmv`、`global_search_order_cnt`、`global_search_gmv` | 类型为 double，存在跨 CUBE 维度重复计算风险；跨多个维度汇总时须确认聚合粒度 |

### 时效性说明

- 本表为 `*_1d` 日级表，每日 T+1 产出，覆盖上一个自然日数据。
- `avg_edt` 依赖 `sls_mart.dwd_edt_order_info_df_*`，该表取最新分区（`MAX(grass_date)`），存在轻微延迟风险，若 EDT 表尚未产出当日数据，则 avg_edt 可能为 NULL 或使用前一日数据。
- 广告收入数据来源 `mp_paidads.dwd_advertise_performance_di__reg_s0_live`，为当日实时累计口径，与搜索事件日期对齐。

### 其他注意事项

- `experiment_id` 当前 ETL 固定关联实验 ID = **148401**，如需查询其他实验请注意此表数据范围受限。
- `layout_type` 原始值为 NULL 时已被统一默认填充为 `'2'`。
- CUBE 展开后同一 `(experiment_id, exp_group_id)` 组合下存在多行（不同 use_instant_filter_type × layout_type × card_type 组合），聚合时须小心避免重复计数。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取实验用户分配日志，构建 user_id → experiment_id + exp_group_id 映射 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为事件明细，提供搜索量、曝光、点击、成单、筛选器使用、布局类型等核心字段 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台全域订单明细，用于计算 global_search_gmv / platform_gmv 等对照指标 |
| `sls_mart.dwd_edt_order_info_df_${grass_region}` | 订单预计送达时间（EDT）明细，用于关联计算平均 EDT |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告消耗明细，提供各 request_id + item_id 的广告收入（USD） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group
        │
        ▼
user_exp_mapping（实验用户映射）
        │
        ├──────────────────────────────────────────────────────────────────────────┐
        │                                                                          │
        ▼                                                                          │
dwd_sr_data_warehouse_search                                          dwd_sr_data_warehouse_platform
        │                                                                          │
        ├── dws_search_volume（搜索量 UV）                                          │
        ├── dws_instant_filter_click_imp（筛选器点击/曝光）                         │
        ├── dws_no_results_metrics（零结果指标）                                    │
        ├── dwd_direct_broad_search_volume → dws_direct_broad_search_volume         │
        ├── dwd_click_imp_order_metrics → dws_click_imp_order_other_metrics        │
        │       └── dws_shop_item_fill_rate（填充率）                               │
        │       └── dwm_avg_edt_dim → dwm_avg_edt_join ←── dwd_edt_order_info     │
        │               └── dws_avg_edt（平均EDT）                                 │
        └── dwm_ads_revenue_link ←── dwd_ads_revenue（mp_paidads）                 │
                └── dwm_ads_revenue → dws_ads_revenue（广告收入）                  │
                                                                                   │
                                                                global_search_and_platform_metrics
                                                                                   │
                                                                                   ▼
dws_main_metrics（FULL JOIN 汇总各指标子集）
        │
        └── LEFT JOIN exp_group_uu / dws_search_volume / dws_instant_filter_click_imp
                    / dws_no_results_metrics / dws_shop_item_fill_rate
                    / global_search_and_platform_metrics
                        │
                        ▼
        INSERT OVERWRITE → 目标表
```

### 关键步骤

1. **`user_exp_mapping`**：从 `dim_sr_data_warehouse_abtest_user_group` 过滤 `is_assignment_log=1` 且 `experiment_id=148401`，产出当日实验用户 → 实验组映射。

2. **`exp_group_uu`**：基于 `user_exp_mapping` 统计各实验组 `group_uu`（实验组总 UV）。

3. **`dws_search_volume`**：JOIN 实验用户映射，统计全量搜索 UV（`search_uu`）和搜索次数（`search_volume`），口径限定 `page_type IN ('global_search','search_in_pdp','search_prefill')` 且 `page_section IS NULL` 且 `operation='view'`。

4. **`dws_instant_filter_click_imp`**：分别统计即时筛选器点击（`action_filter` 操作）和曝光（shortcut_bar 中 filter_button impression）的 UV 和 Count，仅计 filter_name 为 instant_delivery 或 fast_delivery 的筛选器。

5. **`dws_no_results_metrics`**：统计零结果页各指标，区分全量零结果（`no_results_cnt/volume`）和由即时筛选器导致的零结果（`instant_filter_no_results_cnt/volume`）。

6. **`dwd_direct_broad_search_volume` → `dws_direct_broad_search_volume`**：提取搜索结果点击事件，用 `CUBE(use_instant_filter_type, layout_type)` 多维聚合，计算直接成功搜索量（item/video/livestream 点击）和广义成功搜索量（含店铺/达人点击）。

7. **`dwd_click_imp_order_metrics`**：`UNION ALL` 三段：主 source（direct click/impression/order）+ source1 归因订单 + source2 归因订单，产出含 use_instant_filter_type / layout_type / card_type 的曝光点击成单明细。

8. **`dws_click_imp_order_other_metrics`**：以 `CUBE(use_instant_filter_type, layout_type, card_type)` 对上述明细进行三维聚合，产出 imp_cnt/uu、click_cnt/uu、order_cnt/uu、gmv、shop_search_volume、empty_shop_imp_cnt。

9. **`dws_shop_item_fill_rate`**：从 `dws_click_imp_order_other_metrics` 过滤 `layout_type='3'`，计算 shop_item_fill_rate = item 曝光数 / (shop 曝光数 × 3)。

10. **`dwd_edt_order_info` → `dwm_avg_edt_dim` → `dwm_avg_edt_join` → `dws_avg_edt`**：通过 GROUPING SETS 对订单按 (use_instant_filter_type, layout_type) 多维展开，JOIN EDT 订单信息表后聚合 `AVG(edtmax_in_days)` 得到各维度平均 EDT。

11. **`dwm_ads_revenue_link` → `dwd_ads_revenue` → `dwm_ads_revenue` → `dws_ads_revenue`**：将广告消耗（按 raw_request_id + item_id 关联）映射到搜索 use_instant_filter_type / layout_type 维度，以 GROUPING SETS 多维聚合广告收入。

12. **`global_search_and_platform_metrics`**：从平台订单表 JOIN 实验用户，按 reporting_business_line/module 区分 Global Search 和全平台口径，计算 global_search_order_cnt / global_search_gmv / platform_order_cnt / platform_gmv。

13. **`dws_main_metrics`**：将 `dws_click_imp_order_other_metrics`（主指标）与 `dws_direct_broad_search_volume`、`dws_avg_edt`、`dws_ads_revenue` 进行 FULL JOIN，以 COALESCE 对齐维度键，形成完整指标宽表。

14. **最终 INSERT OVERWRITE**：将 `dws_main_metrics` 与 `exp_group_uu`、`dws_search_volume`、`dws_instant_filter_click_imp`、`dws_no_results_metrics`、`dws_shop_item_fill_rate`、`global_search_and_platform_metrics` 以 LEFT JOIN 方式补充剩余指标，仅在 `use_instant_filter_type='__ALL__' AND layout_type='__ALL__' AND card_type='__ALL__'` 条件下注入全量汇总类指标，写入目标表对应分区。

### 注意事项

- **单 Writer 单分区写入**：`multi_writer=false`，每次运行按 `(grass_region, local_date)` 参数化覆盖写单个分区，无并发写入冲突风险。
- **CUBE 多维展开**：`dws_click_imp_order_other_metrics`（3 维 CUBE）和 `dws_direct_broad_search_volume`（2 维 CUBE）产生大量汇总行，`'__ALL__'` 为 GROUPING 占位标识，查询时务必明确维度过滤以避免重复计算。
- **指标稀疏性**：`group_uu`、`search_uu`、`search_volume` 等实验组级全量指标仅在三维均为 `'__ALL__'` 行填充，其余 CUBE 展开行对应字段为 NULL，属正常设计。
- **EDT 数据延迟风险**：`dwd_edt_order_info_df_*` 取 `MAX(grass_date)` 最新分区，若该表未及时产出当日数据，`avg_edt` 将使用最近可用分区数据，存在日期错配风险。
- **广告收入关联质量**：`dwm_ads_revenue_link` 注释说明 request_id + item_id 在两表中须为唯一对，若上游存在重复，可能导致广告收入重复计算。
- **layout_type NULL 默认值**：原始 layout_type 为 NULL 时统一填充为 `'2'`，分析时 `'2'` 包含了原始无布局类型数据。

---

*文档生成时间：2026-05-17*