<!-- ads-workspace-gdoc-sync: gdoc_id=1kuvURzPiP7iaUF10QASq-LW5BtRXwVDDnIAiQyydDTU gdoc_url=https://docs.google.com/document/d/1kuvURzPiP7iaUF10QASq-LW5BtRXwVDDnIAiQyydDTU/edit -->

# srdi_mart.dwd_sr_data_warehouse_game_ads_unify_full_link_log_1h

**分层:** DWD（数据明细层）
**主键:** `regional_date`, `regional_hour`, `country`, `request_id`, `session_id`, `ads_id`
**分区:** `regional_date`（日期分区）, `regional_hour`（小时分区），运行时按 `country`（大区）三级分区写入
**更新频率:** 每小时一次（1h 级别调度）
**引用频次 / 访问频次:** 10

---

## 业务描述

本表为游戏广告全链路日志的统一明细宽表，属于 SRDI 搜推数仓 DWD 层。每行记录代表一次广告请求中某条广告候选的完整全链路快照，涵盖召回、精排、出价、扣费等各阶段的扩展信息。

**核心业务场景：**
- 游戏类目广告全链路分析，包括召回阶段（`ads_recall_ext`）、信息扩展（`ads_info_ext`）、竞价阶段（`ads_bid_ext`）、扣费阶段（`ads_deduct_ext`）的逐条追踪。
- 广告主（`shop_id`）、广告计划（`ads_id`）、商品（`item_id`）、视频（`video_id`）等维度的投放效果明细分析。
- 用户（`user_id`）维度的广告曝光与行为路径还原。

**适合回答的问题：**
- 某广告计划在某小时内各大区的完整全链路曝光记录是什么？
- 不同卡片类型（`card_type`）或商品类型（`item_type`）下的预排价分布如何？
- 某次请求（`request_id`）中各广告候选的出价与扣费详情是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据所属日期分区，格式 `yyyy-MM-dd`，对应业务日志产生日期（大区本地时间） |
| `regional_hour` | string | 数据所属小时分区，格式 `HH`（00-23），对应业务日志产生小时（大区本地时间） |
| `country` | string | 大区/国家分区，标识数据归属的地理大区，由 ETL 调度参数 `${grass_region}` 注入 |

### 维度：请求与会话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 广告请求唯一标识，用于全链路追踪同一次广告请求 |
| `session_id` | string | 用户会话标识，用于关联同一会话内的多次请求行为 |

### 维度：用户与广告主信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识 |
| `shop_id` | bigint | 广告主店铺唯一标识 |

### 维度：广告与商品信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_id` | bigint | 广告计划唯一标识 |
| `ads_entrance` | bigint | 广告入口类型，来源于 `biz_info.ads_entrance`，标识广告曝光的业务入口场景 |
| `item_id` | bigint | 广告关联商品唯一标识 |
| `video_id` | string | 广告关联视频唯一标识 |
| `card_type` | string | 广告卡片类型，标识广告素材的展示形态（如竖版视频、横版图片等） |
| `item_type` | string | 商品类型，标识广告所推广商品的品类属性 |

### 指标：价格与出价

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_price_v2` | bigint | 商品价格（v2 版本），来源于 `d.price_v2`，单位通常为分，具体口径以上游定义为准 |
| `prerank_bid` | bigint | 预排阶段出价，来源于 `d.ads_info.prerank_bid`，反映广告在精排前的竞价值 |

### 指标：全链路扩展信息（Protobuf 序列化字段）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_recall_ext` | string | 召回阶段全链路扩展信息，由 `d.ads_info.recall_ext` 经 `base64_to_protobuf('RecallFullLinkExt', ...)` 解析得到，包含召回策略、召回源等信息 |
| `ads_info_ext` | string | 广告信息扩展字段，由 `d.ads_info.info_ext` 经 `base64_to_protobuf('RecallFullLinkExt', ...)` 解析得到，包含广告候选的附加信息 |
| `ads_bid_ext` | string | 竞价阶段全链路扩展信息，由 `d.bidding_info.bid_ext` 经 `base64_to_protobuf('AdBidFullLinkExt', ...)` 解析得到，包含出价策略、竞价过程等信息 |
| `ads_deduct_ext` | string | 扣费阶段全链路扩展信息，由 `d.deduction_info.deduct_ext` 经 `base64_to_protobuf('DeductFullLinkExt', ...)` 解析得到，包含实际扣费金额、扣费规则等信息 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `regional_date` 和 `regional_hour`**，避免全表扫描，例如：
  ```sql
  WHERE regional_date = '2024-01-01'
    AND regional_hour = '10'
    AND country = 'SG'
  ```
- **建议同时指定 `country`** 分区，缩小扫描范围；若需跨大区汇总，请在 SQL 中枚举所有目标大区值。

### 不可直接 SUM 的字段

- `prerank_bid`、`item_price_v2`：为单条广告候选的价格/出价值，跨行 SUM 无业务意义，需结合具体分析场景决定聚合方式（如 AVG、分位数）。
- `ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext`：为 Protobuf 序列化后的 JSON/字符串结构，不可直接聚合，需先通过 `get_json_object` 或相应解析函数提取内部字段后再使用。
- `request_id`、`session_id`：如需统计去重 UV/请求数，须使用 `COUNT(DISTINCT ...)` 而非 `COUNT` 或 `SUM`。

### 时效性说明

- 本表为 **1 小时级别小时表**，每小时调度一次，数据通常有 **1 小时左右的延迟**。
- 写入方式为 `INSERT OVERWRITE` 按分区覆盖，同一 `(regional_date, regional_hour, country)` 分区重跑后数据会被全量覆盖，查询时无需去重。
- 历史分区数据稳定，不存在追加写入问题；实时性要求高的场景请查看上游 ODS 实时表。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_game_ads` | 游戏广告全链路日志 ODS 原始表，包含 `data` 数组（每个元素为一条广告候选的完整信息）、`biz_info`、`request_id`、`session_id`、`user_id` 等字段，按 `regional_date`、`regional_hour`、`country` 分区过滤后 `LATERAL VIEW EXPLODE` 展开 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_game_ads
    └─ 按 (regional_date, regional_hour, country) 分区过滤
    └─ LATERAL VIEW EXPLODE(data) 展开广告候选数组
    └─ Protobuf 字段解析（base64_to_protobuf）
    └─ temporary view: unify_fll_game_ads_parse_${grass_region_without_quote}
    └─ INSERT OVERWRITE srdi_mart.dwd_sr_data_warehouse_game_ads_unify_full_link_log_1h
           partition (regional_date, regional_hour, country)
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Statement 1 | CREATE TEMPORARY VIEW | 创建 `unify_fll_game_ads_parse_${grass_region_without_quote}`，从 ODS 表按分区过滤，使用 `LATERAL VIEW EXPLODE(t.data)` 将广告候选数组展开为行，并对 `recall_ext`、`info_ext`、`bid_ext`、`deduct_ext` 四个 Base64 编码字段分别调用 `base64_to_protobuf` 自定义函数解析为可读结构 |
| Statement 2 | INSERT OVERWRITE | 从 Statement 1 创建的 Temporary View 读取全量数据，以 `INSERT OVERWRITE ... PARTITION(regional_date, regional_hour, country)` 静态分区方式覆盖写入目标表 |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件，无 multi-writer 风险；但每次调度按大区（`country`）独立提交，不同大区分区之间互不干扰。
- **静态分区写入**：分区值 `regional_date`、`regional_hour`、`country` 均由调度参数注入，写入时为静态分区，重跑某分区会完整覆盖该分区数据，具有幂等性。
- **数组展开**：ODS 表 `data` 字段为数组类型，经 `LATERAL VIEW EXPLODE` 展开后行数会显著放大，查询目标表时若需还原请求维度聚合，须以 `request_id` 为 GROUP BY 键。
- **Protobuf 解析函数依赖**：`base64_to_protobuf` 为平台自定义 UDF，仅在 Spark 执行环境中可用；直接在其他引擎（如 Presto/Trino）查询目标表中已解析的字符串结果时，需确认格式（JSON 字符串）后再进行解析。
- **参数化大区**：ETL 中 `${grass_region}` 与 `${grass_region_without_quote}` 为同一大区的两种格式（带引号/不带引号），仅影响 SQL 拼接，不影响业务语义。

---

*文档生成时间：2026-05-17*