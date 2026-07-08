<!-- ads-workspace-gdoc-sync: gdoc_id=1jIi-66OtV7GtwREAdc-j2OaugWuR-yq3KnN9Bd6zrto gdoc_url=https://docs.google.com/document/d/1jIi-66OtV7GtwREAdc-j2OaugWuR-yq3KnN9Bd6zrto/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_srp_shop_recall_metrics_1d

**分层：** dws_search
**主键：** experiment_id + exp_group_id + card_type + shop_card_type + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次：** 706

---

## 业务描述

本表为搜索结果页（SRP）**店铺召回类型 A/B 实验**的天级汇总宽表，面向搜索推荐数据仓库体系（SRDI）的实验效果评估场景。

**核心业务场景：**
- 按实验组（experiment_id + exp_group_id）对比不同搜索策略在店铺卡片召回维度下的用户行为与商业化表现；
- 按卡片类型（`card_type`：主搜结果卡 vs. 店铺卡）与店铺卡细分类型（`shop_card_type`：广告/自然/品牌广告/店铺广告/全部/无店铺卡）拆解实验指标；
- 衡量曝光、点击、成交、GMV 及广告收入在不同实验分组和召回路径下的差异。

**适合回答的问题：**
- 某实验组下，店铺广告卡（shop_ads）与自然店铺卡（org）的 CTR、CVR 对比如何？
- 新召回策略对 Brand Ads 的广告消耗（ads_rev）是否有显著提升？
- 各实验分组的下单用户数（order_uu）和 GMV 在主搜卡与店铺卡之间的分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `'SG'`、`'MY'` 等 |
| `local_date` | date | 数据日期（本地时区），格式 `yyyy-MM-dd` |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID；固定仅覆盖实验号 11548、23605、18853、197181、200522、202945 |
| `exp_group_id` | bigint | 实验分组 ID，标识对照组或各实验组 |

### 维度：卡片类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 卡片大类。`main_cards`：主搜结果卡（商品/视频/直播）；`shop_cards`：店铺卡；`__ALL__`：全卡片聚合 |
| `shop_card_type` | string | 店铺卡细分类型。枚举值：`ads`（广告店铺卡）、`org`（自然店铺卡）、`shop_ads`（Shop Ads 召回）、`brand_ads`（Brand Ads 召回）、`all_shop_cards`（所有含店铺卡会话）、`non_shop_card`（不含店铺卡会话）、`__ALL__`（全聚合） |

### 指标：曝光行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；来自 `dwd_sr_data_warehouse_search` 中 `operation='impression'` 的 `operation_cnt` 汇总 |
| `imp_uu` | bigint | 曝光用户数（去重）；`imp_cnt > 0` 的 user_id 去重计数，**不可直接跨行 SUM** |

### 指标：点击行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 点击次数；来自 `dwd_sr_data_warehouse_search` 中 `operation='click'` 的 `operation_cnt` 汇总 |
| `click_uu` | bigint | 点击用户数（去重）；`click_cnt > 0` 的 user_id 去重计数，**不可直接跨行 SUM** |

### 指标：成交行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单笔数；来自 `dwd_sr_data_warehouse_search` 中 `operation='order'` 的 `operation_cnt` 汇总，包含跨 source 归因链路 |
| `order_uu` | bigint | 下单用户数（去重）；`order_cnt > 0` 的 user_id 去重计数，**不可直接跨行 SUM** |
| `gmv` | double | 成交 GMV（单位：本地货币），来自 `place_order_gmv` 字段汇总 |

### 指标：商业化收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_rev` | double | 广告消耗金额（单位：USD）；来自 `mp_paidads.dwd_advertise_performance_di__reg_s0_live` 的 `expenditure_amt_usd`，仅统计搜索入口（entrance=1 主搜、entrance=5 店铺卡）下 Shop Ads 与 Brand Ads 的消耗 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：每次查询必须指定，否则将全表扫描所有站点分区，代价极高。
- **`local_date`**：每次查询必须指定日期或日期范围，本表为天级分区表，不含跨天滚动窗口。
- 示例：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu` | 跨行（不同 card_type / shop_card_type / experiment 维度）的去重用户数不可加总，会导致重复计算 |
| `click_uu` | 同上，去重用户数 |
| `order_uu` | 同上，去重用户数 |
| `ads_rev`（跨 shop_card_type 聚合时）| `shop_card_type = '__ALL__'` 的值已被 broadcast 展开到 `ads`、`all_shop_cards` 等细分维度，若同时与细分值一起 SUM 会产生重复计算 |

### 维度值注意事项

- `shop_card_type = '__ALL__'` 及 `card_type = '__ALL__'` 是预聚合的全量行，已包含子分类之和，**不要与子分类行混合 SUM**。
- 本表实验范围固定为 6 个实验 ID（11548、23605、18853、197181、200522、202945），不适用于其他实验的分析。
- `card_type = NULL` 不存在（最终 INSERT 中通过 COALESCE 保证非空）。

### 时效性说明

- 本表为 **T+1** 天级表，每日调度完成后覆写当日分区，通常在次日业务时间可用。
- 无跨天滚动窗口（`_nd`/`_td`）逻辑，如需多日聚合需在查询层自行对 `local_date` 范围求和（注意 `*_uu` 字段不可跨天 SUM）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取实验用户分组映射（experiment_id、exp_group_id、user_id），过滤 assignment log 有效记录 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细事件表，提供曝光、点击、下单等 operation 记录及会话、归因链路信息 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告消耗明细（expenditure_amt_usd），用于计算各维度广告收入 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表，关联 ads_id 获取 main_product_type（Shop Ads / Brand Ads） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group
        │  (实验用户分组)
        ▼
user_exp_mapping  ──────────────────────────────────────────┐
                                                            │ INNER JOIN
dwd_sr_data_warehouse_search                                │
        │  (搜索行为事件)                                    │
        ├──► dws_session          (会话级店铺卡特征)          │
        │         │                                          │
        │         ▼                                          │
        │    dws_session_cube     (店铺卡类型多维展开)        │
        │         │                                          │
        ├──► dws_omni_order       (会话×用户×卡片 行为汇总)   │
        │         │ LEFT JOIN dws_session_cube               │
        │         ▼                                          │
        │    dws_omni_order_res   (GROUPING SETS 聚合)       │
        │         │ INNER JOIN user_exp_mapping              │
        │         ▼                                          │
        │    omni_exp             (实验组行为指标)  ──────────┤
        │                                                    │ FULL OUTER JOIN
dwd_advertise_performance_di + dim_advertise                 │
        │  (广告消耗)                                         │
        ├──► dws_ads_performance  (ads_rev 按 card/shop 分)  │
        │         │                                          │
        ├──► dws_ads_performance_broadcast (广告收入维度广播) │
        │         │                                          │
        ├──► dws_ads_res          (GROUPING SETS 聚合)       │
        │         │ INNER JOIN user_exp_mapping              │
        │         ▼                                          │
        │    dws_ads_exp          (实验组广告收入)  ──────────┤
        │                                                    │
        └──────────────────────────────────────────────────►▼
                    INSERT OVERWRITE 目标分区
```

### 关键步骤

1. **`user_exp_mapping`**：从实验用户分组维表中筛选指定站点、日期、有 assignment log 的实验用户，覆盖 6 个固定实验 ID。

2. **`dws_session`**：从搜索行为明细中，按 `search_session_id` 聚合每个会话的店铺卡是否曝光（`with_shop_card`）、是否为广告（`shop_is_ads`）及召回类型（`shop_recall_type`）。过滤条件：`user_id > 0`，`page_section IS NULL`，`page_type IN ('global_search', 'search_in_pdp', 'search_prefill')`。

3. **`dws_session_cube`**：对 `dws_session` 做 UNION ALL 多路展开，生成四类 `shop_card_type` 维度标签（ads/org、shop_ads/brand_ads、all_shop_cards/non_shop_card、`__ALL__`），形成会话到多维标签的宽表，供后续 JOIN 使用。

4. **`dws_omni_order`**：从搜索行为明细中抽取曝光、点击、下单事件，支持多跳归因（source1、source2），按 `(search_session_id, user_id, card_type)` 聚合得到 `imp_cnt`、`click_cnt`、`order_cnt`、`gmv`。

5. **`dws_omni_order_res`**：将 `dws_omni_order` LEFT JOIN `dws_session_cube`，引入 `shop_card_type` 维度，再经 `GROUPING SETS((user_id, card_type, shop_card_type), (user_id, shop_card_type))` 二次聚合，生成含 `__ALL__` 的预聚合行。

6. **`omni_exp`**：将 `dws_omni_order_res` INNER JOIN `user_exp_mapping`，按 `(experiment_id, exp_group_id, card_type, shop_card_type)` 聚合，计算各实验分组的行为指标（含去重 UU）。

7. **`dim_ads`**：从广告维度表中取最新 placement 的 `main_product_type`（Shop Ads / Brand Ads），用于分类广告消耗。

8. **`dws_search_req_item`**：从搜索曝光明细中按 `(item_id, request_id)` 取 `search_session_id`，用于主搜广告消耗与搜索会话的关联。

9. **`dws_ads_performance`**：店铺卡广告消耗（entrance=5）按 main_product_type GROUPING SETS 聚合；主搜广告消耗（entrance=1）通过 request_id → search_session_id → shop_card_type 链路关联，两路 UNION ALL 合并。

10. **`dws_ads_performance_broadcast`**：将 `shop_card_type='__ALL__'` 的广告收入通过 LATERAL VIEW EXPLODE 广播复制到 `ads` 和 `all_shop_cards` 细分维度，保证口径对齐。

11. **`dws_ads_res`**：对广播后的广告收入按 `GROUPING SETS` 二次聚合，生成含 `__ALL__` 的预聚合行。

12. **`dws_ads_exp`**：将 `dws_ads_res` INNER JOIN `user_exp_mapping`，按实验分组聚合广告收入。

13. **`INSERT OVERWRITE`（最终写入）**：将 `dws_ads_exp`（广告收入维度）与 `omni_exp`（行为指标维度）按 `(experiment_id, exp_group_id, shop_card_type, card_type)` 做 **FULL OUTER JOIN**，通过 COALESCE 对齐维度键后写入目标表分区。

### 注意事项

- **单 Writer**：本表为 `multi_writer: false`，仅有一个 ETL 文件负责写入，不存在并发写入同一分区的风险。
- **分区写入策略**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)`，每次按站点和日期全量覆写，历史分区不受影响。
- **FULL OUTER JOIN 空值处理**：最终 INSERT 中广告收入（`dws_ads_exp`）与行为指标（`omni_exp`）存在维度不完全一致的情况，通过 COALESCE 保证维度字段非空，但 `ads_rev`、`gmv` 等指标字段在另一侧为空时保持 NULL，下游使用时需注意 NULL 处理。
- **广告收入双重计算风险**：`shop_card_type='__ALL__'` 的 ads_rev 经 broadcast 展开后被计入 `ads` 和 `all_shop_cards` 行，与 `__ALL__` 行本身存在重叠，跨 shop_card_type 聚合时须排除 `__ALL__` 行或选定单一 shop_card_type 切片。
- **实验范围固定**：ETL 中硬编码了 6 个实验 ID，表中不包含其他实验的数据，切勿用于范围外实验的分析。
- **时区**：广告数据使用 `tz_type = 'local'` 过滤，与搜索行为数据的 `local_date` 口径一致。

---

*文档生成时间：2026-05-17*