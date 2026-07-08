<!-- ads-workspace-gdoc-sync: gdoc_id=1J4sKQXfxszRTNXHV-Ok1bhAa1jPRALAOgfwP7GHxKtI gdoc_url=https://docs.google.com/document/d/1J4sKQXfxszRTNXHV-Ok1bhAa1jPRALAOgfwP7GHxKtI/edit -->

# srdi_mart.dwd_sr_data_warehouse_paidads_search_live_unify_full_link_log_1h

**分层：** DWD（明细数据层）
**主键：** `request_id` + `session_id` + `ads_id` + `item_id`（联合唯一标识一次广告曝光明细）
**分区：** `regional_date`（日期）+ `regional_hour`（小时）+ `country`（地区）
**更新频率：** 每小时覆盖写（INSERT OVERWRITE），T+0 准实时
**引用频次 / 访问频次：** 0

---

## 业务描述

本表是**搜索直播付费广告（Paid Ads）全链路日志**的小时级明细宽表，记录用户在搜索场景下触达直播付费广告的完整投放链路信息，覆盖召回、排序出价、扣费等核心阶段的全链路扩展字段。

**核心业务场景：**
- 搜索直播广告投放效果的逐小时精细化分析；
- 广告全链路（召回 → 预排序出价 → 扣费）的端到端归因与问题排查；
- 商品、店铺、视频维度下的广告投放明细下钻；
- 多地区（`country`）广告流量的分区隔离查询。

**适合回答的问题举例：**
- 某小时内某地区搜索直播广告的广告位（`ads_entrance`）流量分布如何？
- 某广告（`ads_id`）在特定时段的预排序出价（`prerank_bid`）和实际扣费（`ads_deduct_ext`）情况？
- 某商品（`item_id`）/ 店铺（`shop_id`）在搜索直播广告中的投放明细？
- 广告召回扩展信息（`ads_recall_ext`）和排序扩展信息（`ads_info_ext`）的对比分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `regional_date` | date | 数据所属日期（地区时间），分区键，格式 `yyyy-MM-dd` |
| `regional_hour` | string | 数据所属小时（地区时间），分区键，格式 `HH`（00~23） |
| `country` | string | 地区/国家代码，分区键，对应投放地区（如 `SG`、`ID` 等） |

### 维度：请求与会话标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `request_id` | string | 搜索请求唯一标识，标识一次搜索检索请求 |
| `session_id` | string | 用户会话唯一标识，标识一次连续会话 |
| `user_id` | bigint | 用户唯一 ID |

### 维度：广告基础信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告计划唯一 ID |
| `ads_entrance` | bigint | 广告入口/广告位标识，来源于 `biz_info.ads_entrance`，标识广告展示的入口类型 |
| `card_type` | string | 广告卡片类型，标识展示的广告卡片形式 |

### 维度：商品与店铺信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品唯一 ID |
| `item_type` | string | 商品类型，标识商品的业务类型分类 |
| `item_price_v2` | bigint | 商品价格（v2 版本），单位通常为最小货币单位（如分），来源于 `price_v2` |
| `shop_id` | bigint | 店铺唯一 ID |
| `video_id` | string | 直播/视频唯一 ID，关联对应的直播间或视频内容 |

### 维度：全链路扩展信息（Protobuf 序列化字段）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_recall_ext` | string | 广告召回阶段全链路扩展信息，由 `d.ads_info.recall_ext` Base64 解码后反序列化为 `RecallFullLinkExt` Protobuf 结构 |
| `ads_info_ext` | string | 广告信息/排序阶段全链路扩展信息，由 `d.ads_info.info_ext` Base64 解码后反序列化为 `RecallFullLinkExt` Protobuf 结构 |
| `ads_bid_ext` | string | 广告出价阶段全链路扩展信息，由 `d.bidding_info.bid_ext` Base64 解码后反序列化为 `AdBidFullLinkExt` Protobuf 结构 |
| `ads_deduct_ext` | string | 广告扣费阶段全链路扩展信息，由 `d.deduction_info.deduct_ext` Base64 解码后反序列化为 `DeductFullLinkExt` Protobuf 结构 |

### 指标：出价与价格

| 字段 | 类型 | 说明 |
|------|------|------|
| `prerank_bid` | bigint | 预排序阶段出价金额，来源于 `d.ads_info.prerank_bid`，单位通常为最小货币单位（如分） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `regional_date`、`regional_hour`、`country` 三个分区字段**，否则将触发全表扫描，影响查询性能及资源消耗：
  ```sql
  WHERE regional_date = '2025-05-18'
    AND regional_hour = '10'
    AND country = 'SG'
  ```
- 本表为**小时级分区表**，每次查询建议限定具体小时范围，跨多小时查询需枚举或使用范围过滤。
- 若需多地区汇总，`country` 可使用 `IN` 列表，但仍须显式列出所有目标地区以利用分区裁剪。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `prerank_bid` | 为单次请求的出价金额，跨广告/请求直接求和无实际业务意义，需结合业务口径使用 |
| `item_price_v2` | 为商品单价，不可直接累加作为营收类指标 |
| `ads_recall_ext` / `ads_info_ext` / `ads_bid_ext` / `ads_deduct_ext` | Protobuf 序列化字符串，须先解析结构化子字段后再进行聚合计算，不可直接 SUM/COUNT 原始值用于指标统计 |

### 时效性说明

- 本表为**小时级准实时表**，每小时触发一次 INSERT OVERWRITE，覆盖对应 `(regional_date, regional_hour, country)` 分区。
- 当前小时数据在任务完成前不可用，存在一定延迟（取决于上游 ODS 表就绪时间及调度延迟）。
- 不含累计（`*_td`）或近 N 天（`*_nd`）窗口聚合，仅保留单小时原始明细。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_rt.ods_fll_paidads_search_live` | 搜索直播付费广告全链路原始日志 ODS 表，提供请求级 + 广告明细级（`data` 数组）的原始数据，是本表的唯一上游数据源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_paidads_search_live
    │  按 (regional_date, regional_hour, country) 分区过滤
    │  LATERAL VIEW EXPLODE(t.data)  →  展开广告明细数组
    │  base64_to_protobuf()          →  解析全链路扩展字段
    ▼
temporary view: unify_fll_paidads_search_live_parse_<region>
    │
    ▼
INSERT OVERWRITE srdi_mart.dwd_sr_data_warehouse_paidads_search_live_unify_full_link_log_1h
    partition (regional_date, regional_hour, country)
```

### 关键步骤

**Step 1 — 创建临时视图（Spark SQL Statement 1）**

从 ODS 表 `srdi_rt.ods_fll_paidads_search_live` 按当前调度的 `regional_date`、`regional_hour`、`country` 过滤数据，使用 `LATERAL VIEW EXPLODE(t.data)` 将一条请求记录中的多条广告明细（`data` 数组）展开为行级明细，并对以下扩展字段执行 `base64_to_protobuf()` 函数解码：

| 原始字段 | Protobuf Schema | 目标字段 |
|----------|----------------|---------|
| `d.ads_info.recall_ext` | `RecallFullLinkExt` | `ads_recall_ext` |
| `d.ads_info.info_ext` | `RecallFullLinkExt` | `ads_info_ext` |
| `d.bidding_info.bid_ext` | `AdBidFullLinkExt` | `ads_bid_ext` |
| `d.deduction_info.deduct_ext` | `DeductFullLinkExt` | `ads_deduct_ext` |

结果写入临时视图 `unify_fll_paidads_search_live_parse_<region>`。

**Step 2 — 写入目标表（Spark SQL Statement 2）**

从上述临时视图读取全量字段，执行 `INSERT OVERWRITE` 写入目标表对应分区 `(regional_date, regional_hour, country)`，完成小时级全量覆盖刷新。

### 注意事项

- **单一 ETL 文件写入**：本表仅有 1 个 ETL 源文件，无 multi-writer 问题，分区写入逻辑清晰。
- **动态分区参数**：`regional_date`、`regional_hour`、`country`（`grass_region`）均为调度参数动态传入，每次任务仅处理并覆盖一个具体分区，不同地区之间分区隔离。
- **数组展开放大效应**：`LATERAL VIEW EXPLODE(t.data)` 会将每条请求中的多条广告明细展开，输出行数 ≥ 输入行数，统计请求数时应使用 `COUNT(DISTINCT request_id)` 而非 `COUNT(*)`。
- **Protobuf 扩展字段**：`ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext` 为 Protobuf 反序列化后的结构化字符串，下游使用时需根据对应 Protobuf Schema 进一步解析子字段，不可直接作为普通字符串处理。
- **INSERT OVERWRITE 幂等性**：任务重跑时会完整覆盖对应分区，具备幂等写入能力，但重跑期间对应分区数据短暂不可用。

---

*文档生成时间：2026-05-18*