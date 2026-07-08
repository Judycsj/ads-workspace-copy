<!-- ads-workspace-gdoc-sync: gdoc_id=10fe_B9jOnjewUqUBM6foy4DE9tVLuLlxmtb96c_CiZg gdoc_url=https://docs.google.com/document/d/10fe_B9jOnjewUqUBM6foy4DE9tVLuLlxmtb96c_CiZg/edit -->

# mp_paidads.dwd_advertise_translog_event_di

**分层**：DWD（明细数据层）
**主键**：`deduct_unique_id`
**分区**：`tz_type`、`grass_region`、`grass_date`
**更新频率**：每日调度（覆盖写，`INSERT OVERWRITE`）
**引用频次**：0（末端 ADS 层输出表，未被其他候选表直接引用）

---

## 业务描述

本表是广告扣费交易日志的 DWD 明细层核心表，记录每一笔广告扣费事件的完整上下文信息，包括扣费金额、账户余额变化、广告主出价、竞价机制关键字段（二价广告 ID 与 eCPM 分）、流量来源、用户行为轨迹及广告 Credit 使用详情。上游原始日志经过 protobuf 扩展信息（`extinfo`）解码，并将关键子字段提升为独立列，大幅降低下游分析的解析成本。

本表适用于广告扣费核算、账户余额稽核、计价模式分析（CPC/CPM/CPS 等）、广告召回与竞价机制诊断等场景，是构建广告收入报表、ROAS 分析、Keyword 竞价分析等 ADS 层指标的重要数据基础。

各地区按本地时区参数化调度，`tz_type = 'local'` 分区存储按本地时间对齐的数据，确保各地区的日期切分语义一致。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区键。当前仅写入 `'local'`（按本地时区对齐）。查询时必须指定此字段过滤，避免全表扫描。 |
| `grass_region` | string | 地区编码分区键，如 `'MX'`、`'TH'`、`'ID'` 等，由调度参数 `${region}` 参数化注入。 |
| `grass_date` | date | 业务日期分区键，按本地时区的广告事件发生日期。 |

---

### 维度：主键与广告标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint | 来源于 `translog_tab` 的每日自增 ID，非全局唯一，仅在当日内保持唯一性。⚠️ 跨天查询时不可单独用于去重，需结合 `grass_date` 使用。 |
| `deduct_unique_id` | bigint | 扣费事件在扣费数据库中的唯一标识符，是本表的业务主键。 |
| `original_deduct_id` | bigint | 指向首笔扣费事件的 `deduct_unique_id`。CPS 广告存在补扣场景，后续补扣记录通过此字段关联至初始扣费记录。 |
| `ads_id` | bigint | 广告 ID，标识发生扣费的广告。 |
| `item_id` | bigint | 广告扣费关联的商品 ID。 |
| `shop_id` | bigint | 广告所属店铺 ID。 |
| `account_id` | bigint | 广告账户 ID。 |
| `acc_user_id` | bigint | 广告账户的用户 ID，通常用于标识广告主或账户持有者。 |
| `user_id` | bigint | 点击广告的用户 ID。CPM 扣费场景下，若 translog 中 `userid` 为空，则从 `cpm_event_details_str` 中解析填充。 |
| `track_unique_id` | string | 广告 Tracking 事件的唯一标识符，用于关联 Tracking 侧数据。 |
| `click_event_id` | string | 触发下单的商品点击事件 ID，用于归因链路追踪。 |
| `deduct_unique_id` | bigint | 同上，已列于本节，勿重复计算。 |

---

### 维度：账户与余额

| 字段 | 类型 | 说明 |
|------|------|------|
| `acc_before_balance` | bigint | 扣费或充值前的账户余额（单位：分/最小货币单位）。 |
| `acc_after_balance` | bigint | 扣费或充值后的账户余额（单位：分/最小货币单位）。 |
| `dai_before_balance` | bigint | 扣费或充值前的每日预算余额（单位：分/最小货币单位）。 |
| `dai_after_balance` | bigint | 扣费或充值后的每日预算余额（单位：分/最小货币单位）。 |
| `topup_sign` | string | 充值签名信息，由后端存储，用于充值操作校验。 |

---

### 维度：计价与竞价属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `operation` | int | 扣费操作类型枚举值，区分广告扣费、退款、补扣等操作类型。 |
| `pricing_type` | int | 广告计价模式枚举值，详见字段描述中的 `AdsPricingType`，如 `1=MANUAL_MODE_CPC`、`6=COST_PER_MILE`、`10=LIVE_STREAM_MAX_GMV` 等。 |
| `placement` | int | 广告位枚举值，参考 beeshop_ads.proto 定义。 |
| `entrance` | int | 广告入口枚举值。由 `decoded_extinfo.entrance` 优先填充，为空则取 CPM 扣费详情中的 `entrance`（`COALESCE` 逻辑）。详见字段描述中的 `AdsEntrance` 枚举。 |
| `sub_entrance` | int | 次级广告入口，是 `entrance` 的二级细分，主要应用于 DD 和搜索流量场景。 |
| `match_type` | int | 关键词匹配类型：`0=精确匹配`，`1=广泛匹配`。由 `decoded_extinfo.matchType` 解析。 |
| `recall_type` | int | 广告召回类型枚举值，由 `decoded_extinfo.recallType` 解析。 |
| `traffic_source` | int | 流量来源类型（如 org、roi1、roi2 等），区分自然流量与广告流量子类型。 |
| `status` | int | 广告状态枚举值。 |
| `display_video_id` | bigint | 已废弃字段（`deprecated`），保留用于兼容，不建议使用。⚠️ 已废弃，数据不可靠。 |

---

### 维度：搜索与页面上下文

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 广告竞价关键词。 |
| `user_query` | string | 触发广告扣费时用户的实际搜索词，由 `decoded_extinfo.query.keyword` 解析。 |
| `sort_by` | string | 前端页面排序方式字符串，如 `relevance`、`latest`、`top_sales`、`price` 等。 |
| `sort_type` | int | 排序方式枚举值，与 `sort_by` 语义一致，为数字编码形式，由 `decoded_extinfo.query.sorttype` 解析。⚠️ 与 `sort_by` 存在语义重叠，使用时建议统一口径。 |
| `page_type` | string | 流量事件归属的页面类型，如 `image_search`、`search`、`shop`、`me` 等。 |
| `page_section` | string | 流量事件归属的页面区域，如 `search`、`rcmd`、`you_may_also_like` 等。 |
| `search_scenario` | string | 搜索场景枚举字符串，如 `GLOBAL_SEARCH`、`BROWSE_IN_SHOP`，详见 `SEARCH_SCENARIO` 枚举。 |
| `search_entrance` | string | 搜索入口来源，记录入口的页面类型和区域，如 `homepage_search_bar`、`PDP_search_bar`。 |
| `search_mid` | string | 用户进入搜索结果页前的中间页面及区域，如 `SDP_history`、`SUP_suggested_shop`。无中间页时为 `null`。 |
| `search_session_id` | string | 搜索结果页的唯一搜索 ID，翻页会生成新的 ID。 |
| `target_type` | string | 流量事件对应的目标类型，如 `item` 等。 |
| `location` | int | 全局位置标识。 |
| `click_area` | int | 用户点击区域位置枚举值。 |
| `pdp_item_id` | bigint | 商品详情页的 `item_id`，由 `decoded_extinfo.query.itemid` 解析，用于 PDP 场景下的广告归因。 |
| `pdp_shop_id` | bigint | 商品详情页的 `shop_id`，由 `decoded_extinfo.query.shopid` 解析。 |
| `country` | string | 国家标识。 |

---

### 维度：设备与客户端

| 字段 | 类型 | 说明 |
|------|------|------|
| `device_id` | string | 用户设备 ID。 |
| `platform` | int | 用户平台类型枚举值，如 `2=IOS_APP`、`4=ANDROID_APP`、`5=PC_MALL` 等，详见 `TrackingPlatformType` 枚举。 |
| `rn_ver` | string | 前端框架 React Native 的版本号。 |
| `client_ip` | bigint | 用户客户端 IPv4 地址（以整型存储）。⚠️ 存储为整型，展示时需用 IP 转换函数（如 `inet_ntoa`）还原为点分十进制格式。 |
| `track_session_id` | string | 追踪用户在同一浏览/操作会话中行为链的唯一标识符。 |
| `raw_request_id` | string | 原始请求 ID，由 BFF（Backend For Frontend）生成，每次新请求生成一个。 |

---

### 维度：广告 AB 实验

| 字段 | 类型 | 说明 |
|------|------|------|
| `ab_sign` | string | A/B 测试组的字母数字标识，由 `decoded_extinfo.deductionInfo.algoName` 解析，用于广告算法实验分组标记。 |

---

### 维度：时间戳

| 字段 | 类型 | 说明 |
|------|------|------|
| `timestamp` | bigint | Track 服务接收到该事件的服务端时间戳（Unix 秒级时间戳）。 |
| `produce_ts` | bigint | 生产该条数据的时间戳（Unix 毫秒/微秒级，具体精度依上游日志定义）。 |
| `original_order_timestamp` | bigint | CPS 补扣场景下，首笔扣费的时间戳，用于追溯原始扣费时间。 |
| `click_time_daily_budget` | bigint | 点击事件发生时的每日预算值。 |

---

### 维度：扩展与 JSON 原始字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `decoded_extinfo` | string | 由 UDF `json_from_protobuf` 解码的 protobuf 扩展信息，JSON 格式，包含出价、credit、活动 ID 等详细信息。⚠️ 此字段为原始 JSON 字符串，子字段已被提升为独立列（如 `match_type`、`bid_price` 等），建议优先使用独立列；仅在需要访问未提升字段时才直接解析此字段。 |
| `algo_json_data` | string | 用于向算法侧传递字段的 JSON 数据，具体结构由算法团队定义。 |
| `common_json_data` | string | 公共 JSON 数据字段，通用扩展信息载体。 |
| `root_ads_data_str` | string | 请求或曝光/点击事件级别的 Tracking 公共数据，JSON 格式。⚠️ 为 JSON 字符串，需用 `get_json_object` 解析。 |
| `item_ads_data_str` | string | 商品（item）级别的 Tracking 数据，JSON 格式。⚠️ 为 JSON 字符串，需用 `get_json_object` 解析。 |
| `shop_ads_data_str` | string | 店铺（shop）级别的 Tracking 数据，JSON 格式。⚠️ 为 JSON 字符串，需用 `get_json_object` 解析。 |
| `cpm_event_details_str` | string | CPM 扣费详细信息原始字符串，包含曝光事件的 `user_id` 和 `entrance` 等字段，ETL 中通过 `LATERAL VIEW EXPLODE` 展开使用。⚠️ 为 JSON 数组字符串，直接使用需配合 `from_json` 展开。 |
| `imp_cost_details` | array\<struct\<event_ts:bigint, unique_id:bigint, user_id:bigint, request_id:string, batch_id:bigint, ads_id:bigint, price:bigint, adjusted_cost:bigint, credit_cost:bigint, balance_cost:bigint\>\> | CPM 扣费的明细结构体数组，包含每次曝光扣费的时间戳、请求 ID、价格及 Credit/余额分摊详情。⚠️ 为嵌套数组类型，聚合统计时需先 `EXPLODE` 展开后再汇总，不可直接对整列聚合。 |

---

### 指标：广告扣费金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `price` | bigint | 广告实际扣费金额（单位：分/最小货币单位），来源于广告实际扣费流程，是核心收入统计字段。 |
| `expect_deduct_price` | bigint | 期望扣费金额（单位：分/最小货币单位），由 `decoded_extinfo.expectDeductPrice` 解析，为预期扣费值，可能与 `price` 存在差异。⚠️ 与 `price` 含义不同，不可混用；分析实际收入应使用 `price`。 |
| `bid_price` | bigint | 广告主当前出价（单位：分/最小货币单位），由 `decoded_extinfo.deductionInfo.bidprice` 解析。⚠️ 为出价而非实际扣费价格，不反映实际广告成本。 |

---

### 指标：竞价机制

| 字段 | 类型 | 说明 |
|------|------|------|
| `second_ads_ecpm` | double | 排名次位广告的总得分（通常为质量分 × 出价），用于二价拍卖扣费计算。⚠️ 为预计算得分，不可直接 SUM 用于汇总分析，仅用于单条记录的竞价机制分析或审计。 |
| `second_ads_id` | bigint | 排名次位广告的 `ads_id`，用于日志记录及二价扣费定位。 |

---

### 指标：广告 Credit 扣费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_credits` | string | 广告 Credit 扣费详情 JSON，包含 `order_id`、`order_type`、扣费前后余额、`main_type`、`with_expiry`、`consumption_type` 等字段。⚠️ 为 JSON 字符串，需用 `get_json_object` 解析子字段。 |
| `deduction_info` | string | 扣费信息 JSON，包含竞价价格、下一名得分等详细扣费信息，由 `decoded_extinfo.deductionInfo` 提取。⚠️ 部分子字段（如 `bid_price`、`second_ads_ecpm`、`second_ads_id`、`ab_sign`）已提升为独立列，建议优先使用独立列。 |
| `paid_free_expiry_summary` | string | 不同扣款类型（付费/免费/到期）的金额分配列表，由 `decoded_extinfo.paidFreeExpirySummary` 提取。⚠️ 为 JSON/序列化字符串，需解析后才能按类型汇总金额。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询 **必须** 指定以下分区字段，否则将触发全表扫描，导致资源浪费和查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `WHERE tz_type = 'local'` | 当前虽只写入 `'local'`，但仍需显式指定以利用分区裁剪；未来若新增 `tz_type` 分区将导致数据重复计算。 |
| `grass_region` | `AND grass_region = 'TH'`（按需指定） | 跨地区全扫，IO 成本倍增，且结果混合多地区货币单位，口径错误。 |
| `grass_date` | `AND grass_date = '2026-04-21'` 或范围过滤 | 无日期过滤将全量扫描历史数据，严重影响性能。 |

**推荐查询模板：**
```sql
SELECT ...
FROM mp_paidads.dwd_advertise_translog_event_di
WHERE tz_type = 'local'
  AND grass_region = 'TH'
  AND grass_date = '2026-04-21'
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确做法 |
|------|----------|----------|
| `second_ads_ecpm` | 为预计算的竞价得分（质量分 × 出价），跨行 SUM 无业务意义 | 仅在单条记录维度做竞价分析；汇总时取 `AVG` 或配合 `ads_id` 做分组统计 |
| `imp_cost_details` | 嵌套数组类型，不可直接聚合 | 先 `LATERAL VIEW EXPLODE(imp_cost_details)` 展开后，再对 `price`/`credit_cost`/`balance_cost` 等子字段 SUM |
| `cpm_event_details_str` | JSON 数组字符串，不可直接聚合 | 使用 `from_json` + `EXPLODE` 展开后提取子字段 |
| `bid_price` | 为广告主出价，非实际扣费金额，直接 SUM 会虚高广告成本 | 分析实际广告支出应使用 `price` 字段 |
| `expect_deduct_price` | 为预期扣费而非实际扣费，SUM 结果与实际收入不一致 | 实际收入分析统一使用 `price` |
| `acc_before_balance` / `acc_after_balance` | 余额为状态量，直接 SUM 无意义（每条记录的余额是截面值） | 需取最新一条记录的余额值，不可跨行累加 |
| `dai_before_balance` / `dai_after_balance` | 同上，每日余额为状态截面量 | 同上，不可直接 SUM |
| `sort_type` | 枚举编码值，SUM/AVG 无业务意义 | 仅用于 `GROUP BY` 或 `WHERE` 过滤 |

### 时效性说明

本表为每日全量覆盖写（`INSERT OVERWRITE`），每个分区的数据在调度完成后即为当日最终口径。查询时建议使用 **T-1** 的 `grass_date` 分区（即昨日数据），确保调度已完成写入。

若需当日数据（T+0），请确认调度已成功执行，避免读取到未完成或部分写入的分区数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 广告扣费交易日志原始小时级 ODS 表，提供所有核心扣费字段和 `extinfo` protobuf 数据，是本表的唯一上游数据源 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ods_log_translog_event_hi__reg_s0_live
         │
         │  过滤条件：
         │  ① grass_date ∈ [${grass_date}, ${grass_date}+1)
         │  ② timestamp 对应的本地日期 ∈ [${grass_date}, ${grass_date}+1)
         │  ③ grass_region = upper('${region}')
         │
         ▼
  LATERAL VIEW EXPLODE(cpm_event_details_str)
  → 展开 CPM 扣费明细，补全 user_id 和 entrance
         │
         ▼
  临时视图：translog_event
  （字段清洗、类型转换）
         │
         │  UDF 解析：json_from_protobuf(extinfo)
         │  → decoded_extinfo（JSON 字符串）
         │
         │  get_json_object 提升子字段：
         │  match_type / recall_type / expect_deduct_price
         │  user_query / sort_type / pdp_item_id / pdp_shop_id
         │  ads_credits / deduction_info / paid_free_expiry_summary
         │  bid_price / second_ads_ecpm / second_ads_id / ab_sign
         │  topup_sign / entrance / pricing_type
         │
         ▼
  INSERT OVERWRITE
  dwd_advertise_translog_event_di__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)

  计算引擎：Hive（HQL）
  写入方式：INSERT OVERWRITE（全量覆盖写，按分区替换）
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `translog_event` | `ods_log_translog_event_hi__reg_s0_live` | 原始日志清洗视图。完成字段重命名、类型强转、`LATERAL VIEW EXPLODE` 展开 CPM 扣费明细（补全 `user_id` 和 `entrance`），并应用时间范围过滤和地区过滤。`decoded_extinfo` 在此通过 `json_from_protobuf` UDF 完成 protobuf 解码。 |

### 注意事项

1. **双重时间过滤机制**：ETL 同时对 `grass_date`（分区字段，读取效率）和 `timestamp`（事件实际时间，数据准确性）做范围过滤，两者共同确保写入分区的数据时间口径一致，避免跨日数据污染。查询时仅需过滤 `grass_date` 分区即可。

2. **CPM 扣费的 `user_id` 补全逻辑**：CPM 广告扣费场景下，`translog` 原始记录的 `userid` 可能为空，ETL 通过 `COALESCE(translog.userid, cpm_detail.user_id)` 从 `cpm_event_details_str` 展开结果中补全。分析 CPM 广告的用户归因时需注意此逻辑。

3. **`entrance` 字段的优先级**：最终写入的 `entrance` 为 `COALESCE(decoded_extinfo.entrance, cpm_detail.entrance)`，即优先取 `extinfo` 解析值，兜底使用 CPM 明细中的 `entrance`。

4. **CPS 补扣场景识别**：`original_deduct_id` 不为空时，表示该条记录为补扣事件，需关联首笔扣费（`deduct_unique_id = original_deduct_id`）才能完整还原扣费链路，去重统计时需注意避免重复计入广告成本。

5. **UDF 依赖**：ETL 依赖自定义 UDF `json_from_protobuf`（`com.shopee.deepdata.warehouse.hive.udf.TranslogExtinfoDecodeUDF`），该 UDF 完成 protobuf 二进制到 JSON 的解码。`decoded_extinfo` 字段的完整性依赖此 UDF 的正确运行。

6. **金额单位**：所有金额字段（`price`、`bid_price`、`acc_before_balance` 等）均以最小货币单位（分）存储，换算为主单位（元/美元等）时需除以对应精度系数，各地区精度系数可能不同。

7. **`display_video_id` 已废弃**：该字段在上游标注为 `deprecated`，数据不可信，不建议在新查询中使用。

---

*文档生成时间：2026-04-22*