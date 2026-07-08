<!-- ads-workspace-gdoc-sync: gdoc_id=1mseB2N8VdQxPV0Zy-ULBxmjdm1wwE4WfVpxA3KixDLw gdoc_url=https://docs.google.com/document/d/1mseB2N8VdQxPV0Zy-ULBxmjdm1wwE4WfVpxA3KixDLw/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_user_exp_level_benchmark_1d

**分层：** DWS（数据仓库服务层）
**主键：** `user_id` + `exp_group_id` + `device_id` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `grass_region` + `local_date`
**分区：** `grass_region`（站点大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE PARTITION`）
**访问频次：** 716 次

---

## 业务描述

本表是搜推（Search & Recommendation）数据仓库平台的**实验分组（A/B Test）用户级行为基准宽表**，以「用户 × 实验组 × 设备 × 平台 × 是否广告 × 特征细分 × 场景标签」为粒度，沉淀每日各实验分组内用户的完整漏斗行为指标。

**核心业务场景：**

1. **A/B 实验效果评估**：通过 `exp_group_id` 快速切分对照/实验组，对曝光、点击、加购、下单、GMV 等核心指标进行组间对比，支撑搜索/推荐策略迭代的效果验证。
2. **场景归因分析**：基于 `feature_detail`（功能模块细分）和 `scenario_tag`（以 `DA_` 开头的场景标签）的多路归因复算，准确统计同一订单在多场景触达下的归因贡献，避免重复计数或遗漏。
3. **全渠道流量分析**：通过 `omni_imp_cnt`/`omni_click_cnt` 等全链路指标，结合 `platform` 维度，分析跨平台流量效率。
4. **广告与自然流量拆分**：通过 `is_ads` 标识，支持广告流量与自然推荐流量的独立分析。

**适合回答的典型问题：**

- 某实验组在 iOS App 上相比对照组的 CTR、CVR 提升了多少？
- 推荐场景 `DA_XXX` 下，各实验分组的加购当日/3日 GMV 贡献如何？
- 特定功能模块（`feature_detail`）在不同平台上的曝光和点击分布？
- 全渠道曝光（`omni_imp_cnt`）与站内曝光（`imp_cnt`）的比例关系？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 站点大区，如 `SG`、`MY`、`TH` 等，按大区分区写入 |
| `local_date` | date | 业务日期（本地日期），数据所属的自然日，格式为 `yyyy-MM-dd` |

### 维度：实验与用户标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户唯一标识；未登录场景可能为空或特殊值 |
| `device_id` | string | 设备唯一标识，与 `user_id` 共同构成用户粒度 |
| `exp_group_id` | int | A/B 实验分组 ID，仅保留在推荐搜索白名单（`is_rcmd_search_whitelist=1`）中的分组 |

### 维度：流量属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform` | string | 访问平台，枚举值：`ios_app`、`android_app`、`pc_web`、`ios_web`、`android_web`、`other` |
| `is_ads` | boolean | 是否为广告流量；`true` 表示广告，`false` 表示自然推荐/搜索流量 |

### 维度：场景与功能模块

| 字段 | 类型 | 说明 |
|------|------|------|
| `feature_detail` | string | 功能模块细分标识，格式如 `xxx-yyy-item`；`__ALL__` 表示所有功能模块的汇总行；经过多路归因复算（含 `source1`/`source2` 来源），可用于场景级漏斗分析 |
| `scenario_tag` | string | 场景标签，仅保留以 `DA_` 开头的场景（动态场景）；`__ALL__` 表示所有场景的汇总行；同一订单在多场景下的归因通过 EXPLODE 展开，保证去重准确性 |

### 指标：流量漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_cnt` | bigint | 站内曝光次数；仅统计 `feature_detail`/`scenario_tag` 对应来源的主曝光，`source1`/`source2` 归因行中该字段为 0 |
| `item_imp_cnt` | bigint | 商品级曝光次数；仅当 `feature_detail` 末段（`-` 分隔后第2或第3段）为 `item` 时计入 |
| `click_cnt` | bigint | 站内点击次数；同 `imp_cnt`，`source1`/`source2` 归因行中为 0 |
| `item_click_cnt` | bigint | 商品级点击次数；判断条件同 `item_imp_cnt` |
| `view_cnt` | bigint | 浏览（详情页访问）次数 |
| `ppv_cnt` | bigint | 页面浏览量（Page View）次数，含回退页面 |
| `ppv_cnt_exclude_isback` | bigint | 排除回退行为（`is_back=true`）后的页面浏览量 |
| `omni_imp_cnt` | bigint | 全渠道曝光次数（含站外等跨渠道触达） |
| `omni_click_cnt` | bigint | 全渠道点击次数 |

### 指标：转化与交易

| 字段 | 类型 | 说明 |
|------|------|------|
| `cart_cnt` | bigint | 加购次数（Add to Cart） |
| `order_cnt` | double | 下单笔数（归因后） |
| `gmv` | double | 下单 GMV（归因后，单位与源表一致） |
| `pc2_gmv` | double | PC2 口径 GMV（特定业务口径下的 GMV，与 `gmv` 计算规则不同，具体口径以源表 `dwm` 层定义为准） |
| `atc_same_day_order_cnt` | double | 加购当日成单笔数（ATC 后当天内转化） |
| `atc_same_day_gmv` | double | 加购当日成单 GMV |
| `atc_within_3day_order_cnt` | double | 加购 3 日内成单笔数（ATC 后 3 天内转化） |
| `atc_within_3day_gmv` | double | 加购 3 日内成单 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须同时指定** `grass_region` 和 `local_date`，缺少任一分区条件均会导致全表扫描，严重影响查询性能：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 本表仅包含当日（`local_date`）快照数据，无历史累计字段；跨天分析需手动 UNION 或按日聚合。

### 不可直接 SUM 的字段

本表的粒度为「用户 × 实验组 × 设备 × 平台 × 是否广告 × 功能模块 × 场景标签」，直接跨维度 SUM 时须注意以下风险：

| 字段 | 风险说明 |
|------|---------|
| `order_cnt`、`gmv`、`atc_same_day_gmv` 等转化指标 | 同一笔订单在多个 `scenario_tag` 或 `feature_detail` 中均有归因行（EXPLODE 展开），跨场景/功能模块 SUM 会**重复计数**；需在 `scenario_tag = '__ALL__'` 且 `feature_detail = '__ALL__'` 的行上汇总，或按业务口径去重 |
| `imp_cnt`、`click_cnt` | `source1`/`source2` 归因行中流量指标置为 0，直接 SUM 不重复；但跨 `scenario_tag` 汇总时仍需选择 `__ALL__` 行避免多 EXPLODE 展开行叠加 |
| `user_id` 去重计数 | 该表非用户粒度唯一，同一 `user_id` 可出现在多个 `exp_group_id`、`feature_detail`、`scenario_tag` 中，`COUNT(DISTINCT user_id)` 需配合合理的维度过滤 |

**推荐汇总用法：** 若需全量汇总（不按场景/功能模块细分），优先筛选 `scenario_tag = '__ALL__' AND feature_detail = '__ALL__'` 的行，该行已完成去重聚合。

### 时效性说明

- 本表为 **天级快照表**（`_1d` 后缀），每日调度完成后覆盖写入当日分区，通常在 T+1 的业务时间内可用。
- 无实时或小时粒度数据，不适合实时监控场景。
- `atc_within_3day_*` 指标依赖上游 3 日归因窗口，若上游数据有延迟，近期分区的该指标可能不完整。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 核心宽表，提供用户级商品行为明细（曝光、点击、加购、订单、GMV 等），包含实验组 ID 数组、场景标签数组、`source1`/`source2` 归因链路字段 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验分组维表，用于过滤出推荐搜索白名单实验组（`is_rcmd_search_whitelist = 1`），确保结果仅包含有效实验分组 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │ (按 grass_region + local_date 过滤，operation 行为类型过滤，仅保留有实验组的记录)
        ▼
   [base_table]  ← CACHE（内存+磁盘序列化）
        │
        ├─── 场景标签维度展开 + 订单多路归因（source / source1 / source2）
        │         ▼
        │   [feature_tag_data]（feature_detail × scenario_tag 粒度，DA_ 场景归因行）
        │
        └─── 全汇总维度补全（__ALL__ 占位）
                  ▼
        [feature_tag_data_cube]（含 __ALL__×__ALL__、__ALL__×scenario、feature×scenario 三路 UNION ALL）
                  │
                  ▼
        [exp_group_data]（EXPLODE exp_group_ids → exp_group_id，展开为单值）
                  │
                  │ INNER JOIN dim_sr_data_warehouse_abtest_group（白名单过滤）
                  ▼
  INSERT OVERWRITE dws_sr_data_warehouse_platform_user_exp_level_benchmark_1d
                  (PARTITION grass_region + local_date)
```

### 关键步骤

**Step 1｜exp_filter（Temporary View）**
从实验分组维表读取当日白名单实验组（`is_rcmd_search_whitelist = 1`），用于最终 INNER JOIN 过滤。

**Step 2｜base_table（CACHE TABLE）**
从 `dwm` 层宽表读取当日指定大区数据，过滤有效行为类型（`impression`/`click`/`view`/`ppv`/`cart`/`order`/`omni_impression`/`omni_click`）及有实验组的记录（`size(exp_group_ids) > 0`）。按用户、实验组数组、设备、平台、广告标识、`feature_detail`（含 `source1`/`source2`）、`DA_` 场景标签数组（含 `source1`/`source2`）聚合所有指标，结果缓存以供后续多次引用。

**Step 3｜feature_tag_data（Temporary View）**
对 `base_table` 进行三路 `UNION ALL`，实现订单在 `feature_detail` 维度上的多路归因复算：
- **主路**：EXPLODE `scenario_tags_da`，保留全部指标；
- **source1 归因路**：EXPLODE `source1_scenario_tags_da`，仅当 `source1_feature_detail` 不为空且与主 `feature_detail` 不同时纳入，流量类指标置 0，仅计转化指标；
- **source2 归因路**：逻辑同 source1，额外排除与 `source1_feature_detail` 重复的情况。

**Step 4｜feature_tag_data_cube（Temporary View）**
在 `feature_tag_data` 和 `base_table` 基础上，通过三路 `UNION ALL` 生成维度组合完整的 CUBE：
- **全汇总行**：`feature_detail = '__ALL__'`，`scenario_tag = '__ALL__'`，从 `base_table` 直接聚合；
- **场景汇总行**：`feature_detail = '__ALL__'`，指定 `scenario_tag`，对 `source1`/`source2` 场景标签进行 `array_union` 去重后 EXPLODE；
- **功能×场景行**：指定 `feature_detail` 和 `scenario_tag`，来自 `feature_tag_data` 的再次聚合。

**Step 5｜exp_group_data（Temporary View）**
对 `feature_tag_data_cube` 中的 `exp_group_ids` 数组进行 EXPLODE，将多实验组数组字段展开为逐行单个 `exp_group_id`。

**Step 6｜INSERT OVERWRITE（目标写入）**
将 `exp_group_data` 与白名单 `exp_filter` 进行 INNER JOIN，过滤掉非白名单实验组，按维度字段聚合所有指标后，覆盖写入目标分区。

### 注意事项

1. **场景归因去重风险**：`feature_tag_data` 通过三路 UNION ALL 展开多归因路径，最终聚合前若直接跨 `feature_detail` 或 `scenario_tag` SUM 转化指标，会导致同一笔订单被多次计算。`__ALL__` 维度行已在 ETL 内完成去重，**下游应优先使用 `__ALL__` 行汇总，而非对明细行直接 SUM**。
2. **`source1`/`source2` 归因行流量指标为 0**：`imp_cnt`、`click_cnt`、`item_imp_cnt`、`item_click_cnt`、`view_cnt` 在 source1/source2 路径中固定为 0，这是设计行为（流量归因无多路），SUM 不会虚增流量，但须理解语义。
3. **`DA_` 场景过滤**：ETL 中对 `scenario_tags` 使用 `filter(... like 'DA_%')` 过滤，非 `DA_` 前缀的场景标签不会出现在本表中。
4. **CACHE 依赖**：`base_table` 使用 `MEMORY_AND_DISK_SER` 缓存，后续多个 Temporary View 均依赖该缓存；若 Spark 资源不足导致缓存被逐出，可能影响执行性能但不影响正确性。
5. **单 Writer，单文件写入**：本表为单 ETL 文件、单 Spark Job 写入，无 multi-writer 并发冲突风险，按分区覆盖写入，历史分区不受影响。
6. **实验组白名单过滤**：最终 INNER JOIN `exp_filter` 确保只有 `is_rcmd_search_whitelist = 1` 的实验组数据进入目标表，查询时无需额外过滤实验组有效性。

---

*文档生成时间：2026-05-17*