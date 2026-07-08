<!-- ads-workspace-gdoc-sync: gdoc_id=1ES-i2lJHzMs0b5bhtAUV-UeUpl5-Op3Itx-gIfG63ho gdoc_url=https://docs.google.com/document/d/1ES-i2lJHzMs0b5bhtAUV-UeUpl5-Op3Itx-gIfG63ho/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_card_level_diversity_nd

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `num_day` + `scene_type` + `card_type` + `is_ads`
**分区：** `grass_region`（地区）/ `local_date`（统计截止日期）/ `num_day`（滑动窗口天数）
**更新频率：** 每日调度，按分区覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 2406

---

## 业务描述

本表为搜推数据仓库平台（SR Data Warehouse Platform）中，**场景 × 卡片类型** 粒度的 **内容多样性（Diversity）汇总宽表**，统计周期为最近 N 天滑动窗口（`*_nd`）。

核心业务场景：

- 衡量各搜推场景（Search、DD、YMAL、PP、Platform、S&R、RCMD）下不同卡片类型（item+mixfeed、video 等）的曝光、点击、下单规模及对应 UU 数；
- 通过 `*_llm_cat_cnt` 系列指标，反映用户在各场景/卡片维度下接触到的 **LLM 语义类目（cluster）数量之和**，用于评估平台内容多样性；
- 支持广告 vs 非广告（`is_ads`）的对比分析；
- 适合回答的典型问题：
  - "过去 7/14/30 天，Search 场景下 item+mixfeed 卡片的曝光 UU 及 LLM 语义类目覆盖量是多少？"
  - "各场景广告流量的点击量及类目多样性对比如何？"
  - "Platform 整体 vs RCMD 子场景的订单量及订单类目分布差异？"

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，如 `SG`、`MY` 等，对应 Shopee 各站点 |
| `local_date` | date | 统计截止日期（滑动窗口最后一天） |
| `num_day` | int | 滑动窗口天数，值 = `date_offset + 1`，例如 7、14、30 |

### 维度：场景与卡片类型

| 字段名 | 类型 | 说明 |
|---|---|---|
| `scene_type` | string | 场景类型。原子场景：`Search`（全局/图片搜索）、`DD`（Daily Discover 首页）、`YMAL`（You May Also Like 推荐）、`PP`（Post Purchase 推荐）、`Others`；聚合场景：`Platform`（全平台）、`S&R`（Search & Recommend，含 DD/PP/Search/YMAL）、`RCMD`（推荐，含 DD/PP/YMAL） |
| `card_type` | string | 卡片类型。`item + mixfeed`（商品卡/混合信息流卡）、`video`（视频卡）、`item + mixfeed + video`（商品+视频合并）、`item + mixfeed + video - no dedup`（DD/PP 场景下视频 cluster 加前缀 `v#` 不去重版本）、`others`（其他类型）、`__ALL__`（所有类型汇总） |
| `is_ads` | string | 是否广告流量，`true` / `false` / `__ALL__`（含 CUBE 汇总行） |

### 指标：曝光、点击、下单总量

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 窗口期内曝光总次数（`omni_scenario_imp_cnt` 求和） |
| `click_cnt` | bigint | 窗口期内点击总次数（`omni_scenario_click_cnt` 求和） |
| `order_cnt` | double | 窗口期内下单总量（`order_cnt` 求和）。**注意：** 当 `scene_type` 为聚合场景（Platform / S&R / RCMD）或 `card_type` 为 `__ALL__` 时，因 source1/source2 归因路径差异存在已知重复计算风险，详见查询注意事项 |

### 指标：曝光、点击、下单 UU 数

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 窗口期内有曝光行为的去重用户数（`omni_scenario_imp_cnt > 0` 的用户数之和） |
| `click_uu` | bigint | 窗口期内有点击行为的去重用户数（`omni_scenario_click_cnt > 0` 的用户数之和） |
| `order_uu` | bigint | 窗口期内有下单行为的去重用户数（`order_cnt > 0` 的用户数之和） |

### 指标：LLM 语义类目多样性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_llm_cat_cnt` | bigint | 窗口期内各用户曝光触达的 LLM 语义类目（`item_llm_cluster_id`）去重数之和，用于衡量曝光内容多样性 |
| `click_llm_cat_cnt` | bigint | 窗口期内各用户点击触达的 LLM 语义类目去重数之和，用于衡量点击内容多样性 |
| `order_llm_cat_cnt` | bigint | 窗口期内各用户下单触达的 LLM 语义类目去重数之和，用于衡量下单内容多样性 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部指定**，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-07'
    AND num_day = 7
  ```
- `num_day` 枚举值由上游调度参数 `date_offset` 决定，常见取值为 7、14、30，查询前需确认目标分区已存在。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`order_uu` | 已为预聚合去重 UU 数，跨 `scene_type` / `card_type` / `is_ads` 维度叠加会导致重复计数，**不可跨维度 SUM** |
| `imp_llm_cat_cnt`、`click_llm_cat_cnt`、`order_llm_cat_cnt` | 为各用户去重类目数之和（per-user distinct count 的累加），跨维度 SUM 无业务意义 |
| `order_cnt`（聚合 scene_type / `__ALL__` card_type） | 当 `scene_type ∈ {Platform, S&R, RCMD}` 或 `card_type = __ALL__` 时，因 source1/source2 归因链路存在差异，`order_cnt` 已知存在轻微重复计算（>25% 时对 Platform + `__ALL__` 组合有特殊处理逻辑），直接使用须知晓偏差 |

### 时效性说明

- 表名后缀 `_nd` 表示 **最近 N 天滑动窗口**，`local_date` 为窗口截止日，`num_day` 为窗口长度。
- 每日 T+1 调度覆盖写入，当日数据通常次日可用。
- 同一 `grass_region` + `local_date` 下可能存在多个 `num_day` 分区，代表不同统计周期，需按需筛选。

### 场景类型说明

- `scene_type = 'Platform'` 与 `card_type = '__ALL__'` 的组合来自 `user_item_raw`（未经 source1/source2 union），其余聚合场景（S&R、RCMD）来自 `user_cluster_agg` 中间视图，两者口径不同，**不可直接横向对比 `order_cnt`**。
- `card_type = 'item + mixfeed + video - no dedup'` 仅覆盖 DD 和 PP 场景，视频类目 ID 加 `v#` 前缀以区分 item 类目，适用于不去重场景下的多样性度量，使用时须注意范围限制。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 主要数据源，提供用户-商品粒度的曝光/点击/下单行为、场景标签、卡片类型及 LLM 类目 ID，包含 source1/source2 归因链路字段 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │
        ▼
user_item_raw           （原始字段解析：卡片类型、场景类型、source1/source2 归因）
        │
        ▼
user_item_processed     （标准化 card_type 枚举值）
        │
        ▼
user_item_union         （UNION source1/source2 order 归因行，扩展订单归因覆盖）
        │
        ▼
user_cluster_agg        （按 user × is_ads × cluster × card_type × scene_type 聚合，
                          含 __ALL__ / item+mixfeed+video / no-dedup 等多种 card_type 汇总）
        │
        ├── user_item_raw ─────────────────────────────────────────────────┐
        │   （仅用于 Platform + __ALL__ 场景，绕过 source1/source2 重复计算） │
        ▼                                                                  │
cubed_data              （CUBE(is_ads) 展开，生成 Platform/S&R/RCMD/原子场景行）◄─┘
        │
        ▼
dws_sr_data_warehouse_platform_scenario_card_level_diversity_nd
（按 scene_type × card_type × is_ads 聚合，计算 UU / llm_cat_cnt / cnt 指标）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `user_item_raw` | 从 DWM 层过滤有效行（`user_id > 0`、`item_id > 0`、行为量 > 0），解析 `feature_detail` 提取原始 `target_type`，将 `scenario_tags` 映射为 Search/DD/YMAL/PP/Others 场景，同时处理 source1/source2 归因字段 |
| Step 2 | `user_item_processed` | 将原始 `target_type` 标准化为 `card_type`（`item + mixfeed` / `video` / `others` / null） |
| Step 3 | `user_item_union` | 三路 UNION：① 原始行；② source1 与原始 scene+card 不同的 order 行（仅计 order，imp/click 补 0）；③ source2 与原始及 source1 均不同的 order 行；目的是将订单归因补充至多个场景/卡片维度 |
| Step 4 | `user_cluster_agg` | 四路 UNION，按 user×is_ads×cluster×scene 维度聚合：① `__ALL__` card_type；② 细粒度 card_type（item+mixfeed、video）；③ `item+mixfeed+video` 合并；④ DD/PP 专属 `no-dedup` 版本（视频 cluster 加 `v#` 前缀） |
| Step 5 | `cubed_data` | 五路 UNION，对 `is_ads` 使用 `CUBE` 生成全量/广告/非广告三种汇总；按场景拆分为 Platform（来自 `user_item_raw`）、各细粒度场景、S&R、RCMD，每行同时计算 per-user LLM cluster 去重数 |
| Step 6 | INSERT OVERWRITE | 按 `scene_type × card_type × is_ads` 分组，将 per-user 指标汇总为全局 `cnt`/`uu`/`llm_cat_cnt` 指标，写入目标分区 |

### 注意事项

1. **order_cnt 重复计算风险（已知 Known Issue）**：当聚合场景（Platform / S&R / RCMD）或 `card_type = __ALL__` 时，若同一订单的 source1/source2 场景或卡片类型与原始不同但同属同一聚合分组，`order_cnt` 可能被重复计入。BI 侧评估偏差可接受，ETL 保持与 BI 口径一致。**对 `scene_type = Platform` + `card_type = __ALL__` 组合，ETL 特殊处理（使用 `user_item_raw` 而非 union 后的视图）以控制偏差在 25% 以内**。
2. **单 writer 单文件**：`multi_writer = false`，ETL 由单个 SQL 文件的 6 个 statement 顺序执行，无并发写入冲突。
3. **分区覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION (grass_region, local_date, num_day)` 动态分区覆盖，重跑安全，但需确保同一调度批次内 `grass_region` / `local_date` / `date_offset` 参数一致。
4. **`num_day` 计算**：`num_day = date_offset + 1`，即若 `date_offset = 6` 则 `num_day = 7`，代表最近 7 天窗口。
5. **`item_llm_cluster_id` 为 null 时**：`no-dedup` 版本中 null cluster 保持 null（不加前缀），其 LLM 多样性统计结果需谨慎解读。

---

*文档生成时间：2026-05-17*