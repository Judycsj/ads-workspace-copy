<!-- ads-workspace-gdoc-sync: gdoc_id=1ZAZMhIkmZ-_G9OWv9JC5LzIWNcpYMCGLqNzSIwCDVd0 gdoc_url=https://docs.google.com/document/d/1ZAZMhIkmZ-_G9OWv9JC5LzIWNcpYMCGLqNzSIwCDVd0/edit -->

# srdi_mart.dwd_sr_data_warehouse_paidads_union_unify_full_link_log_1h

**分层：** DWD（明细数据层）
**主键：** `request_id` + `session_id` + `user_id` + `ads_id` + `item_id`（联合唯一，逻辑主键）
**分区：** `regional_date`（日期）+ `regional_hour`（小时）+ `country`（地区/国家）
**更新频率：** 每小时更新（1h 粒度 INSERT OVERWRITE）
**引用频次 / 访问频次：** 3

---

## 业务描述

本表为搜推广告域（PaidAds）**全链路日志明细宽表**，以小时为粒度存储付费广告在搜索 / 推荐统一全链路（Unified Full-Link Log）中的曝光与竞价明细数据。

核心业务场景：
- **付费广告全链路追踪**：将一次广告请求从召回（Recall）、粗排（Pre-rank）、竞价（Bid）到扣费（Deduct）的关键信息汇聚到单条记录，支持全链路归因分析。
- **广告流量来源拆解**：通过 `traffic_source` 区分搜索、推荐等不同流量来源，配合 `ads_entrance` 分析不同广告入口的投放效果。
- **商品与店铺维度分析**：关联 `item_id`、`shop_id`、`video_id` 等维度，支持商品/店铺级广告效果评估。
- **多地区广告数据隔离**：通过 `country` 分区实现多地区（Grass Region）数据物理隔离，便于分地区统计分析。

适合回答的问题：
- 某小时内各流量来源的广告请求量分布？
- 指定广告位（`ads_entrance`）的竞价价格（`prerank_bid`）和扣费信息分布？
- 特定商品或店铺在某时段内的广告曝光明细？
- 召回、竞价、扣费各环节扩展信息（Protobuf 解析后）的字段级分析？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `regional_date` | date | 数据日期分区，格式 `yyyy-MM-dd`，对应广告日志产生的本地日期 |
| `regional_hour` | string | 数据小时分区，格式 `HH`（如 `00`~`23`），对应广告日志产生的本地小时 |
| `country` | string | 地区/国家分区，对应 Grass Region，用于多地区数据隔离 |

### 维度：请求与用户标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 广告请求唯一标识，用于全链路日志串联与归因 |
| `session_id` | string | 用户会话标识，关联同一会话内的多次广告请求 |
| `user_id` | bigint | 用户唯一标识 |

### 维度：广告标识与入口

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_id` | bigint | 广告计划/广告位唯一标识 |
| `ads_entrance` | bigint | 广告入口标识，来源于 `biz_info.ads_entrance`，标识广告展示的业务入口类型 |
| `traffic_source` | string | 流量来源标识，区分搜索、推荐等不同广告流量渠道 |

### 维度：商品与内容标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 广告关联的商品唯一标识 |
| `shop_id` | bigint | 广告关联的店铺唯一标识 |
| `video_id` | string | 广告关联的视频唯一标识（如适用） |
| `card_type` | string | 广告卡片类型，标识广告的展示形式 |
| `item_type` | string | 商品类型，标识广告商品的类目属性 |

### 指标：价格与竞价

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_price_v2` | bigint | 商品价格 V2 版本，来源于 `data[].price_v2`，单位以业务约定为准（通常为分）；**不可直接 SUM 作为收入汇总** |
| `prerank_bid` | bigint | 粗排阶段出价，来源于 `ads_info.prerank_bid`，用于分析广告粗排竞价分布；**不可直接 SUM** |

### 指标：全链路扩展信息（Protobuf 解析）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_recall_ext` | string | 召回全链路扩展信息，由 `recall_ext` 字段经 `base64_to_protobuf('RecallFullLinkExt', ...)` 解析，存储召回阶段的扩展特征（JSON/Protobuf 字符串） |
| `ads_info_ext` | string | 广告信息全链路扩展信息，由 `info_ext` 字段经 `base64_to_protobuf('RecallFullLinkExt', ...)` 解析，存储广告附加信息（JSON/Protobuf 字符串） |
| `ads_bid_ext` | string | 竞价全链路扩展信息，由 `bidding_info.bid_ext` 经 `base64_to_protobuf('AdBidFullLinkExt', ...)` 解析，存储竞价阶段的扩展特征（JSON/Protobuf 字符串） |
| `ads_deduct_ext` | string | 扣费全链路扩展信息，由 `deduction_info.deduct_ext` 经 `base64_to_protobuf('DeductFullLinkExt', ...)` 解析，存储扣费阶段的扩展特征（JSON/Protobuf 字符串） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `regional_date` 和 `regional_hour` 分区**，避免全表扫描：
  ```sql
  WHERE regional_date = '2024-06-01'
    AND regional_hour = '10'
    AND country = 'SG'   -- 如只需特定地区，建议同时过滤
  ```
- `country` 为第三分区键，跨地区查询时注意 IO 放大，建议按需过滤。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_price_v2` | 商品价格，为商品属性维度值，不代表收入流水，直接 SUM 无业务意义 |
| `prerank_bid` | 粗排出价，为单次请求竞价快照值，跨请求 SUM 无意义，应使用 AVG/分位数分析分布 |
| `ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext` | Protobuf 解析后的 JSON/字符串字段，需使用 `get_json_object` 等函数提取子字段后再聚合，不可直接聚合 |

### 时效性说明

- 本表为**小时级准实时表**，每小时产出一次，延迟约为数据产生后 1～2 小时内可查（依调度时延而定）。
- 查询时请使用**完整分区**（`regional_date` + `regional_hour`）定位数据；跨小时汇总需显式枚举或使用日期范围。
- 数据以 `INSERT OVERWRITE` 方式按分区写入，同一分区数据具有幂等性，重跑不会产生重复。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_rt.ods_fll_paidads_union` | 付费广告统一全链路原始日志 ODS 表，包含嵌套结构体数组 `data[]`，本表通过 `LATERAL VIEW EXPLODE` 展开后清洗写入 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_paidads_union
    │  按 regional_date / regional_hour / country 过滤
    │  LATERAL VIEW EXPLODE(data) 展开广告明细数组
    │  base64_to_protobuf 解析各扩展字段
    ▼
temporary view: unify_fll_paidads_union_parse_<region>
    │  直接 SELECT 输出所有清洗字段
    ▼
srdi_mart.dwd_sr_data_warehouse_paidads_union_unify_full_link_log_1h
    （INSERT OVERWRITE，按 regional_date / regional_hour / country 分区写入）
```

### 关键步骤

1. **Statement 1 — 创建临时视图 `unify_fll_paidads_union_parse_<region>`**
   - 从 ODS 表 `srdi_rt.ods_fll_paidads_union` 读取指定日期、小时、地区分区数据。
   - 使用 `LATERAL VIEW EXPLODE(t.data) d AS d` 将嵌套的广告明细数组展平为行级记录。
   - 提取业务字段：`ads_entrance` 来自 `biz_info.ads_entrance`；`prerank_bid` 来自 `d.ads_info.prerank_bid`。
   - 对召回、广告信息、竞价、扣费四类扩展字段分别调用 `base64_to_protobuf` UDF 将 Base64 编码的 Protobuf 二进制解析为可读字符串（类型映射：`RecallFullLinkExt`、`AdBidFullLinkExt`、`DeductFullLinkExt`）。

2. **Statement 2 — INSERT OVERWRITE 写目标表**
   - 读取临时视图中的全部 17 个非分区字段，以 `INSERT OVERWRITE ... PARTITION(regional_date, regional_hour, country)` 静态分区写入目标表。
   - 分区值通过调度参数 `${regional_date}`、`${regional_hour}`、`${grass_region}` 在运行时注入。

### 注意事项

- **单 writer，无并发写冲突风险**：本表仅有 1 个 ETL 文件，不存在 multi-writer 场景。
- **静态分区写入**：`country` 分区值由调度参数 `${grass_region}` 在运行时静态绑定，每次调度只写入单一地区分区，多地区数据由调度系统并行触发不同参数的任务实例产出。
- **UDF 依赖**：`base64_to_protobuf` 为自定义 UDF，若 Protobuf Schema 版本变更（`RecallFullLinkExt`、`AdBidFullLinkExt`、`DeductFullLinkExt`），扩展字段解析结果可能变化，需关注 Schema 兼容性。
- **数组展开行膨胀**：`LATERAL VIEW EXPLODE(t.data)` 会将一条请求记录按广告数量展开为多行，下游使用时若需请求级聚合，须以 `request_id` 去重或 GROUP BY，避免重复计数。
- **参数化表名**：临时视图名含 `${grass_region_without_quote}` 参数后缀，确保多地区并发任务的临时视图相互隔离，不会产生命名冲突。

---

*文档生成时间：2026-05-17*