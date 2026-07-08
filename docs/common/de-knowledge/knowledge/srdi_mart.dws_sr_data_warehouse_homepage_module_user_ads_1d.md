<!-- ads-workspace-gdoc-sync: gdoc_id=1XFhd8trzi2LPV6JJkpeRLfNSDHqL1QBkdrdShhbsi1U gdoc_url=https://docs.google.com/document/d/1XFhd8trzi2LPV6JJkpeRLfNSDHqL1QBkdrdShhbsi1U/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_module_user_ads_1d

**分层：** DWS（数据汇总层）
**主键：** `user_id` + `module` + `is_ads` + `grass_region` + `local_date`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 495 次

---

## 业务描述

本表记录 Shopee 首页各模块（Homepage Module）在 **用户 × 模块 × 是否广告** 粒度下的每日行为指标与电商转化指标，同时关联用户标签（购买类型、平台、版本号）。

**核心业务场景：**
- 评估首页各模块（Flash Sale、Campaign、Daily Discover、Shopee Live 等）对不同用户群的曝光、点击及转化效果；
- 对比广告流量（`is_ads=1`）与自然流量（`is_ads=0`）在各模块的效能差异；
- 分析首页整体用户停留时长、滚动深度、Homepage 页面浏览行为；
- 为搜推算法团队提供用户级别的首页互动特征数据。

**适合回答的问题：**
- 某大区某日首页各模块的 CTR、CVR、GMV 贡献如何？
- 广告 vs 自然流量的模块曝光和转化对比？
- 用户在首页的平均停留时长和滚动深度分布？
- 新用户区（New User Zone）的购买转化用户数？
- Shopee Live / Shopee Video 合并模块（`__LIVE_VIDEO_MERGE__`）的整体表现？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`MY`、`TH` 等；分区键，查询时必须指定 |
| `local_date` | date | 业务日期（本地时间）；分区键，查询时必须指定 |

### 维度：用户属性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，来源于 ETL 过滤条件 `user_id > 0`，排除匿名用户 |
| `user_purchase_type` | string | 用户购买类型标签，来自用户标签维度表（如新用户、老用户等） |
| `platform` | string | 用户使用平台（如 Android、iOS 等），取当日最新值 |
| `version_sign` | string | 用户 App 版本号（源字段 `app_version`），取当日最新值 |

### 维度：模块与流量类型

| 字段名 | 类型 | 说明 |
|---|---|---|
| `module` | string | 首页模块名称；枚举值包括 `Campaign`、`Flash Sale`、`Daily Discover`、`Shopee Live`、`Shopee Mall` 等具体模块，`__ALL__` 表示用户首页全模块汇总，`__LIVE_VIDEO_MERGE__` 表示 Shopee Live Merge + Shopee Video Merge + Shopee Video&Live Merge See More 的合并聚合 |
| `is_ads` | string | 是否广告流量；`1` 为广告，`0` 为自然流量，`__ALL__` 表示全量汇总（仅在 `module='__ALL__'` 行出现） |

### 指标：模块曝光与点击

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 模块内商品卡片曝光次数（区分广告/自然） |
| `click_cnt` | bigint | 模块内商品卡片点击次数（区分广告/自然） |
| `item_imp_cnt` | bigint | 模块内商品条目曝光次数（mini PPV 或 item 级别曝光） |
| `item_click_cnt` | bigint | 模块内商品条目点击次数 |
| `ppv_cnt` | bigint | 模块内商品详情页浏览次数（Product Page View） |

### 指标：转化与 GMV

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 模块带来的订单数（含归因，来源 organic 或 ads） |
| `gmv` | double | 模块带来的 GMV（USD），含广告/自然归因 |
| `pc2` | double | 模块带来的 PC2 GMV（USD），即付款确认后 GMV（源字段 `pc2_gmv`） |

### 指标：首页整体行为（仅 `module='__ALL__'` 行有意义）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `hp_imp_cnt` | bigint | 用户首页页面曝光次数（Homepage Page View 级别） |
| `hp_view_cnt` | bigint | 用户首页有效浏览次数 |
| `hp_duration` | double | 用户首页停留时长（单位：秒；ETL 中已将原始毫秒值除以 1000） |
| `hp_is_scrolldown` | bigint | 用户当日是否发生首页下滑行为；`1` 表示有下滑，`0` 表示无（ETL 中取 `max` 后 `>0` 则置 1） |
| `hp_scroll_depth` | bigint | 用户当日首页滚动深度，即有曝光（`imp_cnt>0`）的非 Others 模块数量（`count distinct module`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：`grass_region` 和 `local_date`，否则将触发全表扫描，影响性能。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

### 行粒度说明与聚合注意事项

- 每个用户在同一分区内存在**多行**，对应不同的 `module` 和 `is_ads` 组合，其中包含：
  - `module = '__ALL__'`、`is_ads = '__ALL__'`：用户当日首页全量汇总行；
  - `module = '__LIVE_VIDEO_MERGE__'`：Shopee Live Merge / Shopee Video Merge / Shopee Video&Live Merge See More 三个模块的合并行；
  - 各具体模块 + 广告/自然维度的明细行。
- **直接对同一用户的多行 SUM 会导致重复计算**，跨 `module` 维度汇总时请先过滤或使用 `__ALL__` 汇总行。
- `hp_duration`、`hp_imp_cnt`、`hp_view_cnt`、`hp_is_scrolldown`、`hp_scroll_depth` 仅在 `module = '__ALL__'` 行有实际数值，其余模块行均为 `0`，**不可对这些字段跨 module 求和**。
- `gmv`、`pc2`、`order_cnt` 为 double 类型，存在归因口径叠加，跨模块直接 SUM 会重复计算。
- `is_ads` 的 `__ALL__` 值仅存在于 `module = '__ALL__'` 汇总行，其他模块行中 `is_ads` 为 `'0'` 或 `'1'`（字符串）。
- `version_sign`（即 `app_version`）与 `platform`、`user_purchase_type` 均取自维度表当日快照，使用 `max()` 聚合，**不代表精确唯一值**。

### 时效性说明

- 表名后缀 `_1d` 表示按自然日汇总，每日全量覆盖写入（`INSERT OVERWRITE`）；
- 数据通常在 T+1 日产出，使用时注意业务日期与查询日期的差异；
- 不含累计（`_td`）或近 N 日窗口（`_nd`）语义，如需多日聚合需自行跨分区汇总。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` | 提供首页各模块的自然流量与广告流量的曝光、点击、PPV、订单、GMV、PC2 等指标（按 business_line = 'Homepage' 过滤） |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 提供用户维度标签，包括 platform、app_version、user_purchase_type |
| `${schema}.dwm_sr_data_warehouse_homepage_user_item` | 提供首页整体行为指标：hp_imp_cnt、hp_view_cnt、hp_duration、hp_is_scrolldown（按模块分组） |
| `${schema}.dwm_sr_data_warehouse_homepage_other_user` | 提供非主流模块的曝光、点击、订单、GMV 等指标（operation 维度展开） |
| `srdi_mart.dws_sr_data_warehouse_homepage_user_cardtype_ad_1d` | 提供 Daily Discover 模块含非 MP 商品的曝光、点击、PPV、订单、GMV、PC2 数据 |

---

## ETL 逻辑摘要

### 数据流

```
traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
  ├─ 自然流量分支 (is_ads=0)
  └─ 广告流量分支 (is_ads=1)
dwm_sr_data_warehouse_homepage_user_item          (hp 行为指标)
dwm_sr_data_warehouse_homepage_other_user         (其他模块指标)
dws_sr_data_warehouse_homepage_user_cardtype_ad_1d (Daily Discover)
         │
         ▼  UNION ALL → union_data（用户×模块×is_ads 汇总）
         │
         ├─ __ALL__ 行（全模块汇总 + hp 指标计算）
         ├─ 各模块明细行
         └─ __LIVE_VIDEO_MERGE__ 行（Live/Video 合并聚合）
         │
         ▼  LEFT JOIN dim_user（补充用户标签）
         │
         ▼  INSERT OVERWRITE dws_sr_data_warehouse_homepage_module_user_ads_1d
```

### 关键步骤

**Step 1 — Temporary View `dim_user`**
从 `srdi_mart.dim_sr_data_warehouse_user_label` 按 `grass_region` 和 `local_date` 过滤，对 `user_id` 分组，取 `platform`、`app_version`、`user_purchase_type` 的 `max()` 作为用户维度快照。

**Step 2 — Temporary View `union_data`**
将以下五个子查询通过 `UNION ALL` 合并，按 `(user_id, module, is_ads)` 聚合为中间结果：
1. **自然流量明细**：从 `dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` 提取 `is_ads=0` 的曝光、点击、PPV、订单、GMV、PC2；模块名统一映射到白名单枚举，过滤 `Others`；
2. **广告流量明细**：同上，提取 `is_ads=1` 的广告指标；
3. **首页行为数据**：从 `dwm_sr_data_warehouse_homepage_user_item` 提取 `hp_imp_cnt`、`hp_view_cnt`、`hp_duration`、`hp_is_scrolldown`（商品流量指标置 0）；
4. **其他模块数据**：从 `dwm_sr_data_warehouse_homepage_other_user` 提取 operation 维度的曝光、点击、订单、GMV；
5. **Daily Discover**：从 `dws_sr_data_warehouse_homepage_user_cardtype_ad_1d` 提取含非 MP 商品的 Daily Discover 全量指标。

**Step 3 — INSERT OVERWRITE 目标表**
从 `union_data` 展开三类输出行，与 `dim_user` LEFT JOIN 后写入目标表：
- `module = '__ALL__'`、`is_ads = '__ALL__'`：全模块汇总行，`hp_duration` 转换为秒（÷1000），`hp_scroll_depth` 计算有曝光的非 Others 模块数；
- 各具体 `(module, is_ads)` 明细行：hp 指标字段置 0；
- `module = '__LIVE_VIDEO_MERGE__'`：对 `Shopee Live Merge`、`Shopee Video Merge`、`Shopee Video&Live Merge See More` 三个模块按 `(user_id, is_ads)` 合并汇总，hp 字段置 0。

### 注意事项

- **单一 Writer**：本表仅有 1 个 ETL 文件，无 multi-writer 风险，但采用 `INSERT OVERWRITE` 按分区写入，重跑时会覆盖对应 `(grass_region, local_date)` 分区。
- **`hp_duration` 单位转换**：原始数据单位为毫秒，ETL 中已除以 1000 转换为秒，下游使用时无需再次转换。
- **模块白名单过滤**：`traffic_omni_oa` 来源的两个子查询使用 `HAVING module <> 'Others'` 过滤非白名单模块；`dwm_sr_data_warehouse_homepage_user_item` 来源的子查询无此过滤，存在 `Others` 进入 `union_data` 的可能，最终在 `__ALL__` 汇总行中 `hp_scroll_depth` 的计算已排除 `module = 'Others'`。
- **`is_ads` 类型**：字段在 DataMap 中为 `string`，ETL 中 `is_ads` 的值为整数 `0`/`1` 或字符串 `'__ALL__'`，查询时过滤条件需使用字符串：`is_ads = '0'`、`is_ads = '1'`。
- **`__LIVE_VIDEO_MERGE__` 行的 `is_ads`**：仅按 `(user_id, is_ads)` 分组，不含 `module`，该行的 `module` 固定为 `'__LIVE_VIDEO_MERGE__'`，与明细行存在数值叠加，跨行聚合时需注意去重。

---

*文档生成时间：2026-05-17*