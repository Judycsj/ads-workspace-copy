<!-- ads-workspace-gdoc-sync: gdoc_id=1e4Bu2C7GmFKx7VAwM9pSha7FuBVmuI3jiu3LTknmccQ gdoc_url=https://docs.google.com/document/d/1e4Bu2C7GmFKx7VAwM9pSha7FuBVmuI3jiu3LTknmccQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_keyword_query_cat_count_1d

**分层：** dws_search
**主键：** `keyword` + `cat_id` + `level` + `country` + `dt` + `operation`
**分区：** `country`（站点/草地区域）、`dt`（本地日期）、`operation`（操作类型：click / impression）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 351

---

## 业务描述

本表为 SRDI 搜推数仓**搜索关键词 × 类目** 维度的日粒度汇总表，统计在全局搜索场景下，用户对特定关键词搜索所带来的商品**点击量**和**曝光量**，并按商品所属的全局后台类目（1～5 级）进行聚合。

**核心业务场景：**
- 分析某关键词在各类目层级下的搜索点击 / 曝光分布，识别关键词与类目的关联强度；
- 评估搜索流量在类目维度的渗透情况，支持搜索优化和类目运营；
- 辅助判断关键词是否被用户用于跨类目搜索，为搜索算法调优提供数据依据。

**适合回答的典型问题：**
- "关键词 X 在某天的点击量 / 曝光量主要集中在哪些类目？"
- "某一级 / 二级类目在搜索侧的流量贡献关键词是哪些？"
- "某站点某天的搜索关键词，各类目层级的点击 vs 曝光对比情况如何？"

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `country` | string | 站点 / 草地区域（grass_region），如 SG、MY、TH 等，与 ETL 参数 `${grass_region}` 对应 |
| `dt` | varchar(10) | 数据业务日期（本地日期），格式 `YYYY-MM-DD` |
| `operation` | string | 操作类型，取值为 `click`（点击）或 `impression`（曝光） |

### 维度：搜索关键词与类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词，已做小写化（LOWER）和去首尾空格（TRIM）处理 |
| `cat_id` | bigint | 全局后台类目 ID（global_be_category_id），对应商品在各层级的类目，缺失时以 0 填充 |
| `level` | int | 类目层级，取值范围 1～5，代表类目树中的第几级 |
| `is_global_cat` | boolean | 是否为全局类目，当前 ETL 中固定写入 `true` |

### 指标：搜索行为计数

| 字段 | 类型 | 说明 |
|---|---|---|
| `count` | bigint | 在指定关键词下、命中该类目商品的操作次数（点击或曝光），来源为 `SUM(operation_cnt)` 经类目 JOIN 后再次 `SUM` 聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`country`**：必须指定，否则将全量扫描所有站点分区，造成不必要的资源消耗。
- **`dt`**：必须指定单日期或明确的日期范围；本表为日粒度，每次 INSERT OVERWRITE 覆盖对应分区。
- **`operation`**：根据业务需要选择 `click` 或 `impression`；若需同时汇总两种操作，需在查询侧显式 UNION 或过滤后聚合，**不可直接对全分区 SUM**（点击与曝光语义不同，混合累加无意义）。

### 不可直接 SUM 的注意事项

- **`count` 跨 `level` 直接 SUM 会重复计算**：同一商品在 level 1～5 均有记录，若不按 `level` 过滤或去重，对 `count` 直接求和将导致同一商品的行为被多次计入。查询时须指定具体 `level` 或明确聚合层级。
- **`count` 跨 `operation` 直接 SUM 无业务意义**：点击量与曝光量量纲不同，应分开分析或计算点击率（CTR = click_count / impression_count）。
- **`is_global_cat`**：当前恒为 `true`，不具备过滤区分价值，无需依赖该字段做业务逻辑判断。
- **`cat_id = 0`**：表示该层级类目 ID 缺失（COALESCE 填充），统计时如需排除无效类目，应加 `AND cat_id != 0`。

### 时效性说明

- 本表为 **T+1 日粒度**数据，当日数据通常在次日 ETL 完成后可用。
- 仅覆盖 **`page_type = 'global_search'`、非广告（`is_ads = false`）、`target_type = 'item'`、`sort_type = 'relevancy'`** 的搜索行为，其他搜索场景不在本表统计范围内。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_item` | 获取商品的 1～5 级全局后台类目 ID，作为类目维度主要来源 |
| `mp_item.dim_dp_item__reg_s0_live` | 补充在 `dim_sr_data_warehouse_item` 中未覆盖的商品类目信息（LEFT JOIN 后取 NULL 侧补全） |
| `srdi_mart.dwd_sr_data_warehouse_search` | 获取搜索行为明细，包含关键词、商品 ID、操作类型及操作次数 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search
        │
        ▼
[clk_imp_counts] ── 按关键词+商品+操作聚合
        │
        ├─────────────────────────────────────────────┐
        │                                             │
        ▼                                             ▼
srdi_mart.dim_sr_data_warehouse_item         mp_item.dim_dp_item__reg_s0_live
  （主要类目来源）                             （补充未覆盖商品类目）
        │                                             │
        └──────────────── UNION ALL ──────────────────┘
                                │
                                ▼
                       [item_cats] ── 商品→各层级类目展开（INLINE STRUCT）
                                │
                                ▼
              clk_imp_counts JOIN item_cats（on item_id）
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              click 聚合            impression 聚合
                    │                       │
                    └──────── UNION ALL ────┘
                                │
                                ▼
  srdi_mart.dws_sr_data_warehouse_search_keyword_query_cat_count_1d
```

### 关键步骤

**Step 1 — Temporary View `item_cats`（商品类目展开）**

从 `srdi_mart.dim_sr_data_warehouse_item` 中取当天当站点商品的 1～5 级全局后台类目，使用 `INLINE(ARRAY(STRUCT(...)))` 将多级类目纵向展开为 `(item_id, category_id, level)` 行格式；对缺失类目 ID 用 `COALESCE(..., 0)` 填充。同时通过 `mp_item.dim_dp_item__reg_s0_live` LEFT JOIN 补充 `dim_sr_data_warehouse_item` 中不存在的商品（即维度表漏录商品），两部分 UNION ALL 合并。

**Step 2 — Temporary View `clk_imp_counts`（搜索行为聚合）**

从 `srdi_mart.dwd_sr_data_warehouse_search` 中筛选：
- `page_type = 'global_search'`
- `is_ads = false`（非广告）
- `target_type = 'item'`
- `sort_type = 'relevancy'`
- `operation IN ('click', 'impression')`
- `keyword IS NOT NULL`

对关键词做 `TRIM(LOWER(...))` 标准化，按 `(keyword, item_id, operation)` 分组 SUM `operation_cnt`，得到每个关键词下各商品的点击 / 曝光汇总。

**Step 3 — INSERT OVERWRITE 写目标表**

将 `clk_imp_counts` 与 `item_cats` 按 `item_id` JOIN，分别对 `click` 和 `impression` 按 `(keyword, level, category_id)` 聚合 SUM count，`is_global_cat` 固定为 `true`，两部分 UNION ALL 后写入目标表，按 `(country, dt, operation)` 分区覆盖。

### 注意事项

- **单 Writer，无多写风险**：本表仅由 1 个 ETL 文件写入，不存在多 Writer 并发覆盖问题。
- **`cat_id = 0` 的数据行存在**：类目 ID 缺失时 COALESCE 填充为 0，查询时如需过滤无效类目需显式排除。
- **`is_global_cat` 恒为 true**：当前 ETL 写死该字段，无动态计算逻辑，后续如有业务变更需关注该字段是否被赋予实际区分意义。
- **商品类目双源补全**：`item_cats` 视图通过 UNION ALL 合并主维度表与备用商品表，确保维度覆盖率，但两表数据同一商品不会重复（LEFT JOIN 取 NULL 侧）。
- **INSERT OVERWRITE 分区覆盖**：每次执行将覆盖对应 `(country, dt, operation)` 分区，重跑历史分区安全，但需确保 ETL 参数 `${grass_region}` 和 `${local_date}` 传入正确。

---

*文档生成时间：2026-05-17*