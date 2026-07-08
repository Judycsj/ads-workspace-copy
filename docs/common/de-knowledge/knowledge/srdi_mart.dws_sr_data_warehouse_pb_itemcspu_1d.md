<!-- ads-workspace-gdoc-sync: gdoc_id=1udhXW--j9V4ETmP_URrtAZGsqQ43nsntXU_tOXEJieE gdoc_url=https://docs.google.com/document/d/1udhXW--j9V4ETmP_URrtAZGsqQ43nsntXU_tOXEJieE/edit -->

# srdi_mart.dws_sr_data_warehouse_pb_itemcspu_1d

**分层：** DWS（数据汇总层）
**主键：** `cspu_id` + `item_id` + `mapping_general` + `grass_region` + `local_date`
**分区：** `grass_region`（站点/区域），`local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**访问频次：** 133 次

---

## 业务描述

本表是搜推（Search & Recommendation）数仓中以 **CSPU × Item × 渠道场景** 为粒度的日汇总宽表，记录各 CSPU（标准商品单元）下 Item 在不同业务场景（搜索/推荐）中的曝光、点击、成单等核心行为指标。

**核心业务场景：**
- 搜索（Search）：Global Search 频道下 Item 的流量与转化数据；
- 推荐（RCMD）：包含"You May Also Like"、"Daily Discover"、"Post Purchase"等推荐场景下 Item 的流量与转化数据；
- 支持区分广告流量（`is_ads=true`）与自然流量（`org_*` 前缀指标）。

**适合回答的问题：**
- 某个 CSPU 下各 Item 在搜索/推荐渠道的每日曝光、点击、成单表现如何？
- 剔除广告后，Item 的自然流量（曝光/点击/成单）表现如何？
- 不同站点（grass_region）同一 CSPU 的 Item 流量对比分析；
- 搜推各渠道对 CSPU 维度商品的贡献度分析。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 SG、MY 等，用于多站点分区隔离 |
| `local_date` | date | 业务日期（本地时间），数据覆盖粒度为自然日 |

### 维度：商品与场景标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 标准商品单元 ID（CSPU），商品归一化后的标准 ID |
| `item_id` | bigint | 商品 Item ID，CSPU 下的具体 SKU/商品 |
| `mapping_general` | string | 业务场景分类，取值为 `RCMD`（推荐）或 `Search`（搜索），用于下游表自关联，不可为 NULL 或空字符串 |

### 指标：全量流量指标（含广告）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（含广告），来自上游 `imp_cnt` 汇总 |
| `click_cnt` | bigint | 点击次数（含广告），来自上游 `click_cnt` 汇总 |
| `order_cnt` | double | 成单数（含广告），来自上游 `order_cnt` 汇总 |

### 指标：自然流量指标（排除广告）

| 字段 | 类型 | 说明 |
|---|---|---|
| `org_imp_cnt` | bigint | 自然曝光次数，排除广告流量（`is_ads='true'` 时计为 0）|
| `org_click_cnt` | bigint | 自然点击次数，排除广告流量（`is_ads='true'` 时计为 0）|
| `org_order_cnt` | double | 自然成单数，排除广告流量（`is_ads='true'` 时计为 0）|

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`** 两个分区字段，否则将触发全表扫描，严重影响查询性能并产生非预期结果：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- `mapping_general` 仅有 `'RCMD'` 和 `'Search'` 两个合法值，下游关联时务必明确指定，避免交叉笛卡尔积。

### 不可直接 SUM 的字段

- 本表已在 CSPU × Item × `mapping_general` 维度进行预聚合，若跨 `mapping_general` 汇总（如将 RCMD 与 Search 合并），需注意**同一 Item 在两个场景下均会出现**（维表在 ETL 中通过 `explode` 复制），直接 SUM 将导致 Item 指标重复计算。
- `order_cnt` 和 `org_order_cnt` 为 `double` 类型，汇总时注意精度损失风险。
- CSPU 维度汇总 `imp_cnt`/`click_cnt`/`order_cnt` 时，需以 `cspu_id + mapping_general` 为 GROUP BY 键，避免 Item 级别重复。

### 时效性说明

- 本表为 **每日快照表**（`_1d` 后缀），每次按分区 INSERT OVERWRITE，仅保存当日数据，不累计历史。
- 若需分析连续多日趋势，需在查询中枚举或范围过滤 `local_date`。
- 数据通常在次日产出，反映前一个自然日的业务数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | CSPU 与 Item 的关联维表，提供 `cspu_id` ↔ `item_id` 映射关系；通过 `explode` 按 `mapping_general` 维度复制 |
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 搜推全渠道行为明细表，提供 Item 粒度的曝光、点击、成单事件及广告标识，用于汇总各场景流量指标 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf  ──► all_cspu_item (维度复制，RCMD+Search)
                                                                          │
dwm_sr_data_warehouse_tc_ab_all_cards ──► imp_click (场景聚合，含/排广告)  │
                                                          │               │
                                                          └──── LEFT JOIN ──►  dws_sr_data_warehouse_pb_itemcspu_1d
```

### 关键步骤

**Step 1 — 构建 CSPU-Item 维度视图（`all_cspu_item`）**
- 从 CSPU 关联维表按 `grass_region` 和 `local_date` 过滤，获取 `cspu_id` ↔ `item_id` 去重映射；
- 使用 `lateral view explode(array('RCMD','Search'))` 将每条记录复制为两行，分别对应两个业务场景，`mapping_general` 不允许为 NULL 或空字符串，保障下游自关联语义正确。

**Step 2 — 构建 Item 流量指标视图（`imp_click`）**
- 从行为明细表按 `grass_region`、`local_date` 及 `operation`（`omni_impression`、`omni_click`、`order`）过滤；
- 通过 CASE WHEN 将 `reporting_business_line`/`reporting_module`/`reporting_object` 组合映射为 `mapping_general`（`Search` 或 `RCMD`）；
- 按 `item_id + mapping_general` 分组，分别汇总全量指标（`imp_cnt`、`click_cnt`、`order_cnt`）和自然流量指标（`org_*`，通过 `if(is_ads='true', 0, x)` 过滤广告）。

**Step 3 — INSERT OVERWRITE 写目标分区**
- 以 Step 1 的 CSPU-Item 维度视图为主表，LEFT JOIN Step 2 的 Item 流量视图（关联键：`item_id + mapping_general`）；
- 保留所有 CSPU-Item-场景组合，流量指标不存在时为 NULL；
- 按 `grass_region` 和 `local_date` 分区覆写目标表。

### 注意事项

- **单一写入（non-multi-writer）**：本表仅有一个 ETL 文件写入，无多文件并发写入风险。
- **分区覆写风险**：INSERT OVERWRITE 按单个 `grass_region + local_date` 分区执行，重跑时仅覆盖当前分区，不影响其他分区历史数据。
- **维度爆炸导致的数据量翻倍**：ETL 中使用 `explode` 将每个 CSPU-Item 对复制为两条（RCMD/Search），下游使用时需注意行数为实际商品数的 2 倍。
- **LEFT JOIN 导致指标为 NULL**：若某 CSPU-Item 组合在当日无行为数据，流量指标字段将为 NULL，下游统计时需做 COALESCE 处理。
- **`mapping_general` 过滤数据量压缩**：行为明细表过滤条件较严格，仅保留指定渠道和模块组合，未覆盖渠道的 Item 行为数据不纳入统计。

---

*文档生成时间：2026-05-17*