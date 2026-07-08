<!-- ads-workspace-gdoc-sync: gdoc_id=1pXbx-spPG7iMkt6AoBYUs4G1tQ-V0wRqdHiiQBvgeqQ gdoc_url=https://docs.google.com/document/d/1pXbx-spPG7iMkt6AoBYUs4G1tQ-V0wRqdHiiQBvgeqQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_card_type_core_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `experiment_id` + `exp_group_id` + `layer_id` + `scene_id` + `card_type` + `is_ads` + `search_entrance`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次/访问频次：** 1424

---

## 业务描述

本表为搜索 A/B 实验核心指标汇总宽表，以「实验组 × 入口 × 卡片类型」为分析粒度，沉淀每日搜索 A/B 实验的曝光、点击、加购、成交、搜索量等核心指标，用于实验效果分析与归因。

**核心业务场景：**
- 搜索 A/B 实验上线后，按实验组拆分对比各项核心指标（曝光 UV、点击率、成交 GMV 等）；
- 按搜索入口（如直播搜索、视频搜索、普通搜索）或卡片类型（商品、视频、直播）下钻分析实验效果；
- 评估广告与自然流量在不同实验分组下的行为差异；
- 计算搜索成功率（直接成功 / 广义成功）以评估搜索相关性质量。

**适合回答的问题举例：**
- 某实验组相比对照组，商品卡片的点击率是否有显著提升？
- 内容搜索入口（`all_content_search`）在各实验组的 GMV 表现如何？
- 实验上线后直接搜索成功量是否有变化？
- 广告流量与自然流量在不同实验组的加购 UV 差异如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 ID、TH、VN 等），分区键，每次查询必须指定 |
| `local_date` | date | 业务日期（本地时区），分区键，每次查询必须指定 |

### 维度：实验层级信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来源于实验白名单维度表 |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID，来源于实验白名单维度表 |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID（如对照组、实验组） |
| `exp_group_name` | string | 实验分组名称 |

### 维度：流量特征

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口。原始值来自 SRP 行为日志，经标准化处理：值为 `null`/空串时填充为 `NA`；`live_search`/`video_search`/`content_mix_search` 被归并为 `all_content_search`，同时保留原始粒度行；跨入口汇总行填充为 `__ALL__` |
| `card_type` | string | 卡片类型。由 `page_section` 与 `target_type` 推断：`item`（商品卡）、`video`（视频卡）、`livestream`（直播卡）或 `Other`；跨类型汇总行填充为 `__ALL__` |
| `is_ads` | string | 是否广告流量（`true`/`false`）；原始为 null 时填充为 `false`；跨广告/自然汇总行填充为 `__ALL__` |

### 指标：实验人群规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_uu` | bigint | 实验分组总 UV（命中分流日志且在搜索白名单内的去重用户数），与卡片类型、入口无关，按 `exp_group_id` 唯一 |
| `search_uu` | bigint | 搜索 UV（实验分组内有搜索浏览行为的去重用户数，`view_cnt > 0`），仅在 `card_type = '__ALL__'` 且 `is_ads = '__ALL__'` 时有值，其余行为 NULL |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光总次数（仅统计 `card_type` 为 `item`/`video`/`livestream` 的曝光量） |
| `imp_uu` | bigint | 曝光 UV（有曝光行为的去重用户数） |
| `click_cnt` | bigint | 点击总次数 |
| `click_uu` | bigint | 点击 UV（有点击行为的去重用户数） |
| `ppv_cnt` | bigint | 商品详情页浏览总次数（Product Page View） |
| `ppv_uu` | bigint | 商品详情页浏览 UV |

### 指标：加购与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购总次数 |
| `cart_uu` | bigint | 加购 UV（有加购行为的去重用户数） |
| `order_cnt` | double | 下单总次数（继承上游 double 类型，含小数，聚合时注意精度） |
| `order_uu` | bigint | 下单 UV（有下单行为的去重用户数） |
| `gmv` | double | 成交 GMV（主要货币口径） |
| `pc2_gmv` | double | PC2 口径 GMV（另一种 GMV 统计口径，具体定义以上游 SRP benchmark 表为准） |

### 指标：搜索量与搜索成功量

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_volume` | bigint | 搜索量，以 `(device_id, keyword)` 组合去重计数（`view_cnt > 0` 的搜索词次数）；仅在 `card_type = '__ALL__'` 且 `is_ads = '__ALL__'` 时有值 |
| `direct_search_success_volume` | bigint | 直接搜索成功量：用户在搜索 item/video/livestream 且有点击行为的 `(device_id, keyword)` 去重数；仅在 `card_type = '__ALL__'` 且 `is_ads = '__ALL__'` 时有值 |
| `broad_search_success_volume` | bigint | 广义搜索成功量：点击范围扩展至 shop、creator、curated_search、live_stream_floating_preview 等更多卡型的 `(device_id, keyword)` 去重数；仅在 `card_type = '__ALL__'` 且 `is_ads = '__ALL__'` 时有值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 均为分区字段，查询时**必须同时指定**，否则触发全表扫描。
- 示例：`WHERE grass_region = 'ID' AND local_date = '2024-01-01'`

### 聚合时的注意事项

| 字段 | 风险 | 正确处理方式 |
|---|---|---|
| `exp_group_uu` | 预聚合字段，按 `exp_group_id` 粒度唯一，跨 `card_type`/`is_ads`/`search_entrance` 行均相同，不可直接 SUM | 按 `exp_group_id` 取任意一行（`MAX` 或 `FIRST`） |
| `search_uu` | 去重 UV，只在 `card_type='__ALL__'` 且 `is_ads='__ALL__'` 的行有值，不可跨维度 SUM | 仅在特定维度组合下使用 |
| `search_volume` / `direct_search_success_volume` / `broad_search_success_volume` | 去重词次数，仅在 `card_type='__ALL__'` 且 `is_ads='__ALL__'` 的行有值 | 仅在特定维度组合下使用 |
| `imp_uu` / `click_uu` / `ppv_uu` / `cart_uu` / `order_uu` | 预聚合去重 UV，跨维度相加会重复计数 | 不可跨维度 SUM；需回溯明细或使用对应 `cnt` 字段估算 |
| `order_cnt` | 类型为 double，直接 SUM 存在浮点精度问题 | 使用 `ROUND` 或 `CAST` 处理 |
| `gmv` / `pc2_gmv` | double 浮点类型，大规模 SUM 有精度损失风险 | 汇报时建议保留 2 位小数 |

### 维度汇总行说明

- `card_type = '__ALL__'`：跨所有卡片类型汇总行
- `is_ads = '__ALL__'`：跨广告与自然流量汇总行
- `search_entrance = '__ALL__'`：跨所有搜索入口汇总行
- 搜索量/搜索 UV/搜索成功量仅挂载在 `card_type='__ALL__' AND is_ads='__ALL__'` 的行上，避免重复计算

### 时效性说明

- 本表为 **T+1** 天级快照表（`_1d` 后缀），每个分区代表一个自然日的全量汇总数据；不包含实时或准实时数据。
- 每次写入目标分区使用 `INSERT OVERWRITE`，同一分区数据会被完整替换，无需担心重复写入。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_search_scene_layer_whitelist` | 获取搜索实验场景与层 ID 白名单，用于过滤合规的 scene_id 和 layer_id |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 获取实验组维度信息（scene/layer/experiment/group 名称），仅取搜索白名单内的实验 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户-实验组分流映射关系，基于分流日志且在搜索白名单内 |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 搜索 SRP 用户行为基准宽表，提供用户级别的关键词粒度曝光、点击、加购、成交等行为明细 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_search_scene_layer_whitelist
    └─► dim_whitelist_scene / dim_whitelist_layer（白名单过滤）

dim_sr_data_warehouse_abtest_group ──────────────────────────────────► dim_exp（实验组维度）
dim_sr_data_warehouse_abtest_user_group ─────────────────────────────► user_exp_mapping（用户分组映射）
                                                                            │
dws_sr_data_warehouse_search_srp_user_benchmark_1d                         │
    └─► dwm_search_user_keyword_raw（行为明细过滤）                          │
           └─► dws_search_feature（用户×关键词×卡型汇总）                    │
                  ├─► search_entrance_flatten（搜索入口展开/归并）            │
                  │       ├─► dws_entrance（用户级 GROUPING SETS 聚合）──JOIN─┤
                  │       │       └─► dws_main_metrics（实验组级主指标）      │
                  │       └─► dwm_search_volume ─► dws_search_volume ───JOIN─┤
                  │                                                           │
                  └─► dws_search_uu ──────────────────────────────────────JOIN┘
                                                                            │
                                                  dim_exp ─────────────────JOIN
                                                  dws_exp_uu ──────────────JOIN
                                                                            ▼
                                    目标表：dws_sr_data_warehouse_search_abtest_entrance_card_type_core_metrics_1d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `dim_whitelist_scene` | 从白名单维度表去重获取合规 scene_id |
| 2 | `dim_whitelist_layer` | 从白名单维度表去重获取合规 layer_id |
| 3 | `dim_exp` | 读取当日实验组维度信息，过滤 `is_search_whitelist=1` |
| 4 | `user_exp_mapping` | 读取当日用户-实验组分流映射，过滤分流日志且搜索白名单内的记录 |
| 5 | `dws_exp_uu` | 对 `user_exp_mapping` 按 `exp_group_id` 统计实验组总 UV |
| 6 | `dwm_search_user_keyword_raw` | 从 SRP benchmark 表抽取 global_search/search_in_pdp/search_prefill 三种页面类型的用户行为明细（user_id > 0） |
| 7 | `dws_search_feature` | 按用户×设备×关键词×卡片类型×is_ads×搜索入口聚合行为指标，同时计算 search_cnt、direct_search_success_cnt、broad_search_success_cnt |
| 8 | `search_entrance_flatten` | 将 `dws_search_feature` 与内容搜索入口归并行（`all_content_search`/`not_content_search`）UNION ALL，实现入口多粒度分析 |
| 9 | `dws_entrance` | 使用 GROUPING SETS 对用户级别在 card_type × is_ads × search_entrance 维度组合上聚合，生成多粒度汇总行（含 `__ALL__` 占位行） |
| 10 | `dws_main_metrics` | 将 `dws_entrance` JOIN `user_exp_mapping`，按实验组×卡片类型×is_ads×搜索入口聚合核心指标及各类 UV |
| 11 | `dwm_search_volume` | 基于 `dws_search_feature` 和 `search_entrance_flatten`，统计 (device_id, keyword) 去重搜索量及成功量 |
| 12 | `dws_search_volume` | 将 `dwm_search_volume` JOIN `user_exp_mapping`，汇总到实验组级搜索量指标 |
| 13 | `dws_search_uu` | 统计实验组内有搜索浏览行为的去重用户数（search_uu） |
| 14 | **INSERT OVERWRITE** | 将 `dws_main_metrics` 与 `dim_exp`、`dws_exp_uu`、`dws_search_volume`、`dws_search_uu` 多路 LEFT JOIN，写入目标表目标分区 |

### 注意事项

- **`search_volume` / `search_uu` 字段的 JOIN 条件限制**：在最终 INSERT 阶段，`dws_search_volume` 和 `dws_search_uu` 只在 `a.card_type = '__ALL__' AND a.is_ads = '__ALL__'` 时关联，其他维度组合的行该字段为 NULL，这是设计行为，避免重复计算去重指标。
- **GROUPING SETS 产生多行**：`dws_entrance` 步骤通过 GROUPING SETS 生成多种维度组合（含全量汇总行），最终表中同一实验组会存在多条 `card_type`/`is_ads`/`search_entrance` 不同组合的行，分析时需明确选择所需维度组合，避免重复聚合。
- **单文件单写入**：本表为 single-writer，无多文件并发写入风险，`INSERT OVERWRITE PARTITION` 保证每次运行同分区数据幂等替换。
- **`dim_whitelist_scene` / `dim_whitelist_layer` 视图在最终 INSERT 中未直接使用**：白名单过滤已通过 `dim_exp`（`is_search_whitelist=1`）在实验维度层面实现，两个白名单视图为保留预处理结构，实际过滤逻辑以 `dim_exp` 的 `is_search_whitelist` 字段为准。
- **`order_cnt` 为 double 类型**：继承自上游，使用时需注意浮点精度，不建议与 bigint 类型字段直接混合比较。

---

*文档生成时间：2026-05-17*