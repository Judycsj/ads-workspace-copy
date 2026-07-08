<!-- ads-workspace-gdoc-sync: gdoc_id=1XZ2bmBUoee6cCgFRxjKS7Ue07a2Ge38NTp4C57M4uYo gdoc_url=https://docs.google.com/document/d/1XZ2bmBUoee6cCgFRxjKS7Ue07a2Ge38NTp4C57M4uYo/edit -->

# srdi_mart.dws_sr_data_warehouse_image_search_exp_level_metrics_1d

**分层：** dws_search
**主键：** exp_group_id + search_entrance + image_source + is_ads + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日一次（T+1）
**访问频次：** 524

---

## 业务描述

本表为图搜（以图搜物）功能的**实验组级别日粒度聚合宽表**，记录各实验组（exp_group_id）在不同搜索入口（search_entrance）、图片来源（image_source）和广告标识（is_ads）维度组合下的用户规模、曝光、点击、加购、下单及 GMV 等核心业务指标。

表中数据通过 GROUPING SETS 多维上卷方式生成，维度字段中 `__ALL__` 表示该维度上的全量汇总，支持灵活的多维交叉分析。

**核心业务场景：**
- A/B 实验效果评估：按实验组对比图搜各阶段转化漏斗（曝光→浏览→加购→下单）
- 图搜入口效能分析：评估不同搜索入口（首页、搜索结果页、商场等）的图搜表现
- 图片来源质量分析：按 image_source（用户上传、截图等）分析搜索质量与转化差异
- 广告与自然流量对比：通过 is_ads 区分广告与非广告图搜结果的效果差异
- 图搜相关性与位置分析：追踪 top1 图搜相似度、点击位置、加购位置等用户行为指标

**适合回答的问题：**
- 实验组 X 与对照组在图搜 DAU、加购率、GMV 上的差异是什么？
- 哪个搜索入口带来了最多的图搜有效转化用户（eff_trans_uu）？
- 图搜无结果量（non_result_volume）在各实验组的变化趋势如何？
- 广告图搜结果与自然图搜结果的 PPV 转化率对比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/站点标识，如 ID、TH、VN 等，用于多站点数据隔离 |
| `local_date` | date | 业务日期（本地时区），每日分区键 |

### 维度：实验与流量分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验组 ID；所有实验组汇总时该字段为全量聚合标识 |
| `search_entrance` | string | 图搜触发的搜索入口，如 `HOME`、`SEARCH_RESULT`、`MALL`、`PRESEARCH`、`NSRP`、`RCMD_SEARCH_RESULT` 等；跨入口汇总时值为 `__ALL__` |
| `image_source` | string | 图片来源类型（如用户拍照、截图等）；跨来源汇总时值为 `__ALL__`；已过滤 `{%` 开头的脏数据 |
| `is_ads` | string | 是否广告流量，取值为 `'true'`、`'false'` 或 `'__ALL__'`（汇总）；源字段为 boolean，ETL 中转换为字符串 |

### 指标：用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `dau` | bigint | 图搜日活用户数：当日 image_search_pv > 0 的去重用户数 |
| `camera_uu` | bigint | 点击图搜入口按钮的去重用户数（image_search_button_click_cnt > 0） |
| `landing_rate_dau` | bigint | 落地页 DAU：在指定主流入口（HOME、SEARCH_RESULT、MALL、PRESEARCH、NSRP、RCMD_SEARCH_RESULT 等）发起图搜的去重用户数，用于计算落地率分母 |

### 指标：曝光与浏览

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 图搜商品曝光总次数（image_search_item_imp_cnt 汇总） |
| `imp_uu` | bigint | 图搜商品曝光去重用户数（image_search_item_imp_cnt > 0 的用户数） |
| `ppv_cnt` | bigint | 商品详情页（PDP）浏览总次数（pdp_pv 汇总） |
| `ppv_uu` | bigint | 浏览 PDP 的去重用户数（pdp_pv > 0 的用户数） |

### 指标：加购与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | double | 加购物车总次数（cart_cnt 汇总） |
| `cart_uu` | bigint | 加购物车去重用户数（cart_cnt > 0 的用户数） |
| `order_cnt` | double | 下单总次数（order_cnt 汇总） |
| `order_uu` | bigint | 下单去重用户数（order_cnt > 0 的用户数） |
| `gmv` | double | 成交金额总量（GMV，order_cnt 对应的 gmv 汇总） |
| `eff_trans_uu` | bigint | 有效转化去重用户数：图搜后发生点击商品、收藏或加购任一行为的用户数（image_search_item_click_cnt > 0 OR pdp_like_button_click_cnt > 0 OR cart_cnt > 0） |

### 指标：搜索质量与行为位置

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_top1_similarity` | double | 图搜 Top1 结果平均相似度：sum(top1_similarity_sum) / sum(top1_item_impression_cnt)；反映图搜召回质量 |
| `avg_click_location` | double | 平均点击位置：sum(click_location_sum) / sum(image_search_item_click_cnt)；反映用户倾向点击的结果排位 |
| `avg_atc_location` | double | 平均加购位置：sum(atc_location_sum) / sum(cart_cnt)；反映用户倾向加购的结果排位（ETL 中字段名为 avg_cart_location） |
| `query_cnt` | bigint | 图搜查询请求总次数 |
| `image_search_result_volume` | bigint | 图搜有结果的查询次数 |
| `image_search_non_result_volume` | bigint | 图搜无结果的查询次数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定：** 查询时务必在 `WHERE` 子句中同时指定 `grass_region` 和 `local_date`，避免全表扫描。

```sql
WHERE grass_region = 'ID'
  AND local_date = '2025-01-01'
```

- 若需多日汇总，使用 `local_date BETWEEN '2025-01-01' AND '2025-01-07'`，但注意以下不可直接 SUM 的字段限制。

### 维度过滤注意事项

- 表中同时存在明细维度行和汇总行（值为 `__ALL__`），直接聚合时需过滤，避免重复统计。例如：
  - 仅分析某入口：`AND search_entrance != '__ALL__'`
  - 仅看全量汇总：`AND search_entrance = '__ALL__' AND image_source = '__ALL__'`
- `is_ads = '__ALL__'` 表示广告与非广告合并汇总，避免与 `true`/`false` 行同时 SUM。

### 不可直接 SUM 的字段

以下字段为预计算比率或加权均值，**跨行 SUM 无意义，跨日/跨组聚合须回溯原始分子分母**：

| 字段 | 原因 |
|---|---|
| `avg_top1_similarity` | 加权均值，= sum(top1_similarity_sum) / sum(top1_item_impression_cnt) |
| `avg_click_location` | 加权均值，= sum(click_location_sum) / sum(image_search_item_click_cnt) |
| `avg_atc_location` | 加权均值，= sum(atc_location_sum) / sum(cart_cnt) |

以下字段为去重用户数（UV），**跨日 SUM 会导致用户重复计算**：

`dau`、`camera_uu`、`landing_rate_dau`、`imp_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`eff_trans_uu`

### 时效性说明

- 本表为日粒度表（`_1d` 后缀），T+1 更新，当天数据于次日产出。
- 不含近 N 天滚动窗口，如需多日趋势分析需在查询层手动聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_exp_metrics_1d` | 图搜用户级别实验指标明细表，提供按用户粒度的各项行为计数及金额数据，作为本表聚合的唯一数据源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_exp_metrics_1d
    └─► [GROUPING SETS 多维上卷 + UNION ALL]
         └─► Temporary View: image_search_aggregated_${grass_region_without_quote}
              └─► INSERT OVERWRITE
                   └─► srdi_mart.dws_sr_data_warehouse_image_search_exp_level_metrics_1d
```

### 关键步骤

**Step 1 — 创建中间聚合 Temporary View（`image_search_aggregated_*`）**

通过三段 UNION ALL 对上游用户级明细表按不同维度组合进行 GROUPING SETS 聚合，生成多维汇总结果：

| 分段 | search_entrance | image_source | 分组维度 |
|---|---|---|---|
| 分段 1 | 实际值 | `__ALL__` | GROUPING SETS: (exp_group_id, search_entrance, is_ads) 和 (exp_group_id, search_entrance) |
| 分段 2 | `__ALL__` | 实际值 | GROUPING SETS: (exp_group_id, image_source, is_ads) 和 (exp_group_id, image_source)；额外过滤 `image_source not like '{%'` |
| 分段 3 | `__ALL__` | `__ALL__` | GROUPING SETS: (exp_group_id, is_ads) 和 (exp_group_id) |

每段中：
- UV 类指标（dau、camera_uu 等）通过 `COUNT(DISTINCT IF(条件, user_id, NULL))` 计算
- 累加指标（imp_cnt、cart_cnt、gmv 等）通过 `SUM` 计算
- 均值指标（avg_top1_similarity、avg_click_location、avg_cart_location）通过分子 SUM / 分母 SUM 计算

**Step 2 — INSERT OVERWRITE 写目标表**

从 Temporary View 读取数据，写入目标表对应分区。主要处理：
- `is_ads` 字段从 boolean 转换为字符串：`true → 'true'`，`false → 'false'`，`NULL → '__ALL__'`
- 按 `grass_region` 和 `local_date` 分区覆盖写入（INSERT OVERWRITE）

### 注意事项

- **单文件单写入：** 本表为单 ETL 文件写入（`multi_writer: false`），无多文件并发写入风险。
- **分区覆盖：** 每次执行为 INSERT OVERWRITE 指定分区，同一分区重跑幂等，不影响其他分区。
- **脏数据过滤：** 分段 2 中对 `image_source like '{%'` 的记录做了过滤，`__ALL__` 汇总分段（分段 1、3）未做此过滤，因此 `image_search_result_volume` 等汇总指标在 `image_source = '__ALL__'` 与按 image_source 明细行加总时可能存在轻微口径差异。
- **NULL 维度处理：** 上游表中 `image_source` 和 `search_entrance` 可能存在 NULL 和空值，ETL 注释说明正是因此采用多段 UNION ALL 而非单一大 GROUPING SETS，以规避 NULL 分组合并问题。
- **`avg_atc_location` 字段映射：** DataMap 中字段名为 `avg_atc_location`，ETL SQL 中对应别名为 `avg_cart_location`，两者为同一字段。

---

*文档生成时间：2026-05-17*