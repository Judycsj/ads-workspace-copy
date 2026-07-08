<!-- ads-workspace-gdoc-sync: gdoc_id=1DvrVGLJS5Xl-WycfCAgwMIwfeg055qL0Uk8sqLmtQxE gdoc_url=https://docs.google.com/document/d/1DvrVGLJS5Xl-WycfCAgwMIwfeg055qL0Uk8sqLmtQxE/edit -->

# srdi_mart.dws_sr_data_warehouse_search_srp_performance_1d

**分层**：dws_search（数据仓库服务层 - 搜索域）
**主键**：grass_region + local_date + platform + search_entrance + location_type + is_ads + feature
**分区**：grass_region（地区）、local_date（业务日期）
**更新频率**：每日全量覆写（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次**：672

---

## 业务描述

本表为搜索结果页（SRP）性能指标汇总宽表，以**日粒度**聚合各站点的 SRP 曝光、点击、加购、下单、GMV 等核心电商漏斗指标，并按平台、搜索入口、位置类型、是否广告、搜索特征标签（feature）多维度切分。

**核心业务场景**：
- 搜索 SRP 页面各类卡片/模块（自然结果、广告、LLM DeepThinking 卡片等）的曝光与转化效率分析；
- 不同搜索入口（首页搜索、PDP 内搜索、预填充搜索等）的流量与 GMV 贡献对比；
- 广告与自然结果的漏斗指标拆分；
- 多平台（iOS/Android/Web 等）搜索性能趋势监控。

**适合回答的问题**：
- 某站点某日各搜索特征（feature）的曝光量、点击率、加购率、成交率分别是多少？
- 广告位与自然位的 GMV 贡献差异如何？
- 搜索入口（search_entrance）维度下，哪个入口的 pc2_gmv 最高？
- LLM DeepThinking 卡片相比普通商品卡片的转化表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 SG、MY、TH 等，所有查询必须指定 |
| `local_date` | date | 业务日期（本地时区），所有查询必须指定 |

### 维度：搜索上下文与流量切分

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 用户访问平台，如 iOS、Android、PC 等；原始为 NULL 时填充为 `'NA'` |
| `search_entrance` | string | 搜索入口类型，如首页搜索、PDP 内搜索等；原始为空字符串或 NULL 时填充为 `'NA'` |
| `location_type` | string | SRP 页面内的位置/版位类型，区分顶部、底部等布局区域 |
| `is_ads` | string | 是否广告流量，`'true'` 表示广告，`'false'` 表示自然结果；原始为 NULL 时填充为 `'false'` |
| `feature` | string | 搜索结果页特征标签，由 feature_tag 映射得到；当 feature_tag 为 `'item'` 时，根据是否开启 LLM DeepThinking 进一步细分为 `'deepthinking_card'` 或 `'item'`，其余取 feature_tag 原值 |

### 指标：曝光与点击漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果页曝光次数，仅在特征标签 operation 包含 `'impression'` 时汇总 |
| `click_cnt` | bigint | 搜索结果页点击次数，仅在特征标签 operation 包含 `'click'` 时汇总 |
| `ppv_cnt` | bigint | 商品详情页浏览次数（Post-click PDP View），仅在 operation 包含 `'click'` 时汇总 |

### 指标：加购与成交漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数，仅在 operation 包含 `'click'` 时汇总 |
| `order_cnt` | double | 下单订单数，仅在特征标签 operation 包含 `'order'` 时汇总 |
| `gmv` | double | 成交金额（GMV），仅在 operation 包含 `'order'` 时汇总，单位与上游一致 |
| `pc2_gmv` | double | PC2 口径 GMV（二次确认支付 GMV 或特定归因口径 GMV），仅在 operation 包含 `'order'` 时汇总 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定两个分区字段**，否则将触发全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 若需跨多日分析，建议使用 `local_date BETWEEN '...' AND '...'` 显式限定范围。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gmv` / `pc2_gmv` | 按 feature 维度分别汇总，跨 feature 直接 SUM 会导致重复计算（同一订单可能对应多个 feature） |
| `order_cnt` | 同上，不同 feature 的 order 归因规则由 operation 标签控制，跨维度聚合需谨慎 |
| `imp_cnt` / `click_cnt` 等 | 不同 feature 的 operation 覆盖范围不同（部分 feature 仅统计 click 不统计 impression），跨 feature SUM 无业务含义 |

> ⚠️ 点击率（CTR）= click_cnt / imp_cnt、加购率、转化率等**比率指标**均需在查询层自行计算，不可对比率直接聚合。

### 时效性说明

- 本表为 `_1d` 日粒度表，T+1 产出，反映前一自然日的完整数据。
- 数据按 `(grass_region, local_date)` 分区 INSERT OVERWRITE，每次执行覆盖对应分区，不存在增量追加逻辑。
- 查询当日数据时需确认 ETL 已完成调度，建议在查询前校验分区是否存在。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 提供用户级别的 SRP 搜索行为基础指标（曝光、点击、加购、下单、GMV 等），按指定 local_date 和 grass_region 过滤，仅取 global_search / search_in_pdp / search_prefill 三类页面且 user_id > 0 的记录 |
| `srdi_mart.dim_sr_data_warehouse_search_feature_tags_mapping_v2` | 搜索特征标签映射维表，定义 page_type / page_section / target_type / search_entrance / search_mid 组合到 feature_tag 及其适用 operation（impression / click / order）的映射规则，过滤 feature_type = 'srp_performance' |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_search_srp_user_benchmark_1d  ──┐
                                                        ├──► dws_user_keyword (temp view)
dim_sr_data_warehouse_search_feature_tags_mapping_v2 ──┤
                                                        ├──► dim_search_feature_mapping (temp view)
                                                        │
                                                        └──► INNER JOIN ──► dws_search_with_feature (temp view)
                                                                                    │
                                                                                    ▼
                                              dws_sr_data_warehouse_search_srp_performance_1d
                                              （INSERT OVERWRITE，按 grass_region + local_date 分区）
```

### 关键步骤

**Step 1：构建特征标签映射视图（`dim_search_feature_mapping`）**
从维表 `dim_sr_data_warehouse_search_feature_tags_mapping_v2` 读取 `srp_performance` 类型的映射规则，按页面维度聚合 operation 集合（COLLECT_SET）和 feature_tag，并预解析 `in` 语法的 search_mid / search_entrance 列表，供后续 JOIN 使用。

**Step 2：构建用户行为汇总视图（`dws_user_keyword`）**
从上游基准表按分区（local_date、grass_region）过滤，限定页面类型为 global_search / search_in_pdp / search_prefill，排除匿名用户（user_id > 0），对 NULL/空值维度字段做默认填充（platform→'NA'，search_entrance→'NA'，is_ads→'false' 等），然后按全部维度聚合各项指标的 SUM。

**Step 3：关联特征标签并按 operation 分配指标（`dws_search_with_feature`）**
将 Step 2 的行为数据与 Step 1 的特征映射做 INNER JOIN，JOIN 条件同时支持精确匹配和通配（page_section/target_type/search_entrance/search_mid 字段为空时视为全匹配）。各指标仅在对应 operation 存在于 feature 的 operation 集合时才计入（例如 gmv 仅在 operation 包含 'order' 时 SUM，click_cnt 仅在包含 'click' 时 SUM）。同时对 `feature` 字段做二次派生：feature_tag='item' 且 is_llm_deepthinking=TRUE 映射为 `'deepthinking_card'`，否则保留 `'item'`。

**Step 4：写入目标表**
将 Step 3 的结果通过 `INSERT OVERWRITE TABLE ... PARTITION(grass_region=..., local_date=...)` 写入目标表，按站点和日期分区全量覆盖。

### 注意事项

- **非 multi-writer**：本表仅有单一 ETL 文件写入，不存在多文件并发写同一分区的风险。
- **INNER JOIN 过滤风险**：Step 3 使用 INNER JOIN，若维表 `dim_sr_data_warehouse_search_feature_tags_mapping_v2` 未覆盖某 page_type/page_section/target_type 组合，对应行为数据将被静默丢弃，需关注维表维护完整性。
- **分区覆写语义**：每次调度仅覆盖当次参数对应的 `(grass_region, local_date)` 分区，历史分区不受影响，但重跑同一分区时会完整替换。
- **feature 字段语义变更风险**：`deepthinking_card` 分支依赖上游字段 `is_llm_deepthinking`，若上游未回填历史数据，历史分区中该 feature 将不存在，跨时间对比需注意。
- **指标 NULL 处理**：各指标字段使用条件 SUM（`SUM(IF(...),..., null)`），当 feature 对应 operation 不匹配时该指标为 NULL 而非 0，下游聚合时需注意 NULL 与 0 的区分。

---

*文档生成时间：2026-05-17*