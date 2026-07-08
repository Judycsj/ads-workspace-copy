<!-- ads-workspace-gdoc-sync: gdoc_id=1RRDI04zbVz03EMgsBBCmTEiGKxaQx8gh1mWLH5D52xU gdoc_url=https://docs.google.com/document/d/1RRDI04zbVz03EMgsBBCmTEiGKxaQx8gh1mWLH5D52xU/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_feature_location_level_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `exp_type` + `is_ads` + `location` + `exp_group_id` + `target_type` + `scenario_tag`
**分区：** `grass_region`（站点大区）/ `local_date`（业务日期）/ `exp_type`（实验类型，当前固定为 `traffic`）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 917

---

## 业务描述

本表为**搜推平台实验（A/B Test）特征位置级别**的日粒度汇总宽表，服务于算法实验效果评估场景。

核心业务场景：
- 以**实验分组（exp_group_id）× 流量位置（location）× 是否广告（is_ads）× 目标类型（target_type）× 场景标签（scenario_tag）** 为细粒度维度，统计曝光、点击、全域曝光/点击、加购、PPV、订单及 GMV 等全链路指标。
- 支持多来源归因：行为事件的 `feature_detail` 及其上游来源（source1、source2）均被展开计算，以覆盖跨场景的归因链路，但最终写入表时 `feature_detail` 字段置空（NULL），仅保留位置维度聚合结果。
- 通过 `scenario_exp_sum` 自定义 UDAF 对用户级数据去重，输出精确的 UU（去重用户数）指标，同时满足 ATC 窗口归因（当日/3日内）需求。

**适合回答的问题：**
- 某实验分组在某站点某日的曝光量、点击量、订单量、GMV 是多少？
- 各实验组在不同广告位（is_ads）或位置（location）下的 UU 转化漏斗表现如何？
- 加购后当日/3日内的订单转化与 GMV 归因情况？
- 全域曝光/点击（omni）与普通曝光/点击的差异分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 `SG`、`MY`、`TH` 等），分区过滤必填 |
| `local_date` | date | 业务本地日期，分区过滤必填 |
| `exp_type` | string | 实验类型，当前 ETL 固定写入 `traffic` |

---

### 维度：实验与流量标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | 实验分组 ID，来源于 `exp_group_ids` 数组展开 |
| `scenario_tag` | string | 算法场景标签，取 `algo_tag` 中以 `DA_` 开头的标签（展开自数组），通过 UDAF 展开 |
| `is_ads` | string | 是否广告流量；`'true'`/`'false'`；聚合维度中使用 `'__ALL__'` 表示不区分 |
| `location` | int | 展示位置编号，≥200 的位置统一归并为 200 |
| `target_type` | string | 推荐目标类型（如商品、店铺等）；聚合维度中使用 `'__ALL__'` 表示不区分 |
| `feature_detail` | string | 特征来源明细；本表 ETL 中固定写入 `NULL`，位置层面不区分 feature |

---

### 指标：曝光与点击（去重用户数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 曝光去重用户数（普通曝光），由 `scenario_exp_sum` UDAF 计算 |
| `click_uu` | bigint | 点击去重用户数，由 `scenario_exp_sum` UDAF 计算 |
| `omni_imp_uu` | bigint | 全域曝光去重用户数，由 `scenario_exp_sum` UDAF 计算 |
| `omni_click_uu` | bigint | 全域点击去重用户数，由 `scenario_exp_sum` UDAF 计算 |

---

### 指标：曝光与点击（事件计数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 普通曝光次数，对应 `operation = 'impression'` 的 `operation_cnt` 汇总 |
| `click_cnt` | bigint | 普通点击次数，对应 `operation = 'click'` 的 `operation_cnt` 汇总 |
| `omni_imp_cnt` | bigint | 全域曝光次数，对应 `operation = 'omni_impression'` 的 `operation_cnt` 汇总 |
| `omni_click_cnt` | bigint | 全域点击次数，对应 `operation = 'omni_click'` 的 `operation_cnt` 汇总 |

---

### 指标：商品详情页浏览（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页浏览次数（含回退行为），对应 `operation = 'ppv'` 的 `operation_cnt` 汇总 |
| `ppv_cnt_exclude_isback` | bigint | 排除回退（is_back=true）的 PPV 次数，即有效 PPV |
| `ppv_exclude_isback_uu` | bigint | 排除回退的 PPV 去重用户数，由 `scenario_exp_sum` UDAF 计算 |

---

### 指标：加购

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数，对应 `operation = 'cart'` 的 `operation_cnt` 汇总 |
| `atc_uu` | bigint | 加购去重用户数（ATC UU），由 `scenario_exp_sum` UDAF 计算 |

---

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单次数，对应 `operation = 'order'` 的 `operation_cnt` 汇总（含归因分配故为 double）|
| `order_uu` | bigint | 下单去重用户数，由 `scenario_exp_sum` UDAF 计算 |
| `gmv` | double | 下单 GMV（本地货币），对应 `operation = 'order'` 的 `place_order_gmv` 汇总 |

---

### 指标：ATC 窗口归因订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购当日（window_day=1）内产生的订单数 |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内（window_day 1~4）产生的订单数 |
| `atc_same_day_gmv` | double | 加购当日（window_day=1）内产生的 GMV |
| `atc_within_3day_gmv` | double | 加购后 3 日内（window_day 1~4）产生的 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须指定，否则触发全量分区扫描，严重影响性能。
- **`local_date`**：分区字段，必须指定具体日期或日期范围，避免跨分区全扫。
- **`exp_type`**：分区字段，当前所有数据均为 `'traffic'`，建议显式指定 `WHERE exp_type = 'traffic'`。

### 不可直接 SUM 的字段

以下字段为 **UDAF 去重计算结果**，跨分组直接 SUM 会导致重复计算，**不可通过 SUM 跨维度上卷**：

| 字段 | 原因 |
|---|---|
| `imp_uu` | 去重用户数，跨 exp_group_id / location / scenario_tag 不可加和 |
| `click_uu` | 同上 |
| `omni_imp_uu` | 同上 |
| `omni_click_uu` | 同上 |
| `ppv_exclude_isback_uu` | 同上 |
| `atc_uu` | 同上 |
| `order_uu` | 同上 |

以下字段为**带归因权重的浮点累计值**，跨分组 SUM 需注意归因逻辑是否一致：

| 字段 | 原因 |
|---|---|
| `order_cnt` | double 类型，含归因权重，跨维度 SUM 需谨慎 |
| `gmv` | 含归因权重，跨维度 SUM 需谨慎 |
| `atc_same_day_order_cnt` | ATC 窗口归因，跨维度 SUM 需谨慎 |
| `atc_within_3day_order_cnt` | 同上 |
| `atc_same_day_gmv` | 同上 |
| `atc_within_3day_gmv` | 同上 |

### 维度聚合说明

- `is_ads = '__ALL__'` 和 `target_type = '__ALL__'` 是 ETL 通过 `GROUPING SETS` 预聚合写入的跨维度汇总行，查询时需按需筛选，避免重复计数。
- `feature_detail` 字段在本表中固定为 `NULL`，若需要 feature_detail 粒度分析请查阅其他 DWS 表。
- `location >= 200` 的位置在 ETL 中已统一归并为 `200`，查询结果中 `location = 200` 表示所有高位置编号的合并值。

### 时效性说明

- 本表为 **T+1 日更新**，每日产出前一天数据，不含实时或准实时数据。
- 后缀 `_1d` 表示单日粒度聚合，不含滚动窗口累计。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心行为明细表，提供用户行为事件（impression/click/ppv/cart/order/omni_impression/omni_click）、特征标签、实验分组、位置信息及 GMV 等原始数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │  （按 grass_region、local_date 过滤，仅保留目标 operation 类型及有实验分组的行）
    ▼
dwd_derived_scenario（临时视图）
    │  · 用户 ID 统一化（登录用户取 user_id，匿名用户取 -CRC32(device_id)）
    │  · location 截断（≥200 归为 200）
    │  · algo_tag 解析为 scenario_tags 数组（过滤 DA_ 前缀标签）
    │  · 同时处理 source1、source2 归因链路字段
    ▼
base_table（临时视图）
    │  · 三路 UNION ALL：主 feature_detail + source1_feature_detail + source2_feature_detail
    │  · 每路过滤有效 scenario_tags（≥1 个 DA_ 标签）
    │  · 按 (user_id, is_ads, location, exp_group_ids, target_type, scenario_tags) 分组
    │  · 聚合各 operation 类型的 cnt 及 GMV，含 ATC 窗口归因
    ▼
user_metric_row → user_metric（临时视图）
    │  · 将各指标打包为 named_struct（user_data）
    │  · 通过 GROUPING SETS 生成多粒度聚合：
    │    (user_id, target_type, location)
    │    (user_id, is_ads, target_type, location)
    │    (user_id, is_ads, location)
    │    (user_id, location)
    │  · 每个用户按分组收集 user_data_list
    ▼
mask_user_metric（临时视图）
    │  · 调用 scenario_exp_sum(user_id, user_data_list) 自定义 UDAF
    │  · 输出按 (is_ads, target_type, location) 汇总的 mask_user_metrics 数组
    │  · NULL 维度替换为 '__ALL__'
    ▼
metric_explode（临时视图）
    │  · LATERAL VIEW EXPLODE(mask_user_metrics) 展开各实验组 × 场景标签的指标行
    ▼
INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_platform_exp_feature_location_level_metrics_1d
    PARTITION (grass_region=?, local_date=?, exp_type='traffic')
    · feature_detail 固定写 NULL
    · REPARTITION(200) 控制输出文件数
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Step 1 | Temporary View | `dwd_derived_scenario`：从 DWD 层过滤并标准化原始行为数据，处理用户 ID、位置截断、scenario_tag 解析及三路归因字段 |
| Step 2 | Temporary View | `base_table`：三路 UNION ALL 展开主/source1/source2 归因路径，按用户×维度聚合所有指标（含 ATC 窗口归因） |
| Step 3 | Temporary View | `user_metric_row`：将各指标打包为 `named_struct`，为 UDAF 输入准备 |
| Step 4 | Temporary View | `user_metric`：通过 `GROUPING SETS` 构造多维度预聚合，并按分组 `collect_list` 用户数据 |
| Step 5 | Temporary View | `mask_user_metric`：调用 `scenario_exp_sum` UDAF 完成跨用户去重计算，输出聚合后的指标数组 |
| Step 6 | Temporary View | `metric_explode`：`LATERAL VIEW EXPLODE` 展开每个 (is_ads, target_type, location) 组合下所有 exp_group_id × scenario_tag 的指标行 |
| Step 7 | INSERT OVERWRITE | 写入目标表，分区固定为 `exp_type='traffic'`，`feature_detail` 置 NULL，启用 `REPARTITION(200)` |

### 注意事项

1. **单 Writer**：本表仅有 1 个 ETL 文件，不存在 multi-writer 并发冲突风险。
2. **INSERT OVERWRITE 分区替换**：每次运行覆盖指定 `(grass_region, local_date, exp_type)` 分区，重跑安全，但须确保同一分区不被并发任务同时写入。
3. **GROUPING SETS 多粒度行**：`user_metric` 视图通过 GROUPING SETS 产生多粒度汇总行（含 NULL 占位维度），下游 mask 阶段将 NULL 替换为 `'__ALL__'`，查询时须注意同一 location 下可能存在多行聚合粒度不同的数据，应按需过滤 `is_ads` 和 `target_type` 维度值。
4. **scenario_exp_sum UDAF**：为内部自定义聚合函数，实现用户级去重并按实验组×场景标签展开，UU 类指标均依赖此函数，不可在此表上二次 SUM 上卷。
5. **归因三路展开**：source1 和 source2 的行为事件会被重复计入对应来源的 location/target_type 维度，使用时需明确分析口径是否涵盖归因链路。
6. **feature_detail 过滤**：ETL 排除了 `bottom_bar-tab`、`phone_notifications-push_notification` 等特定特征，以及 `global_search-item`、`search_in_pdp-item`，查询结果不包含上述流量。
7. **location 截断**：所有 location ≥ 200 的坑位统一归并为 200，分析高坑位时结果为合并值。

---

*文档生成时间：2026-05-17*