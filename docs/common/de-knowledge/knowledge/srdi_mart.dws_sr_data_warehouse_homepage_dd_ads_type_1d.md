<!-- ads-workspace-gdoc-sync: gdoc_id=1FinmEQdAGJ__XsXIBI88ww8uPrvwsL3VGGtjOTST5Zo gdoc_url=https://docs.google.com/document/d/1FinmEQdAGJ__XsXIBI88ww8uPrvwsL3VGGtjOTST5Zo/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_dd_ads_type_1d

**分层**: DWS（数据汇总层）
**主键**: `reporting_business_line`, `reporting_module`, `reporting_object`, `platform`, `location`, `is_ads`, `ads_id`, `main_product_type`, `product_type`, `sub_product_type`, `grass_region`, `local_date`
**分区**: `grass_region`（大区）, `local_date`（本地日期）
**更新频率**: 每日一次（T+1）
**访问频次**: 20 次

---

## 业务描述

本表汇总首页（Homepage）**每日发现（Daily Discover）**模块下，按广告类型维度细分的曝光、点击、商品浏览（PPV）、下单及 GMV 等核心指标。数据同时融合了**入口层（Omni Entry）**与**商品层（Omni Item）**两条行为链路，并关联广告维表补全广告产品类型信息。

**核心业务场景**：
- 首页 Daily Discover 模块的广告投放效果分析（按广告 ID、广告产品类型分层评估）
- 广告与自然流量（`is_ads`）的流量与转化对比
- 跨平台（PC/Mobile 等）和地理大区的广告效果横向比较
- 流量漏斗分析：入口曝光 → 入口点击 → 商品曝光 → 商品点击 → PPV → 下单 → GMV

**适合回答的问题**：
- 某大区某日 Daily Discover 模块广告的曝光量、点击率是多少？
- 不同广告产品类型（`main_product_type` / `product_type`）的 GMV 贡献如何？
- 广告位置（`location`）排名对点击与转化有何影响？
- 剔除回退行为后（`ppv_cnt_exclude_isback`）的真实 PDV 访问量是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、MY、TH 等；每次查询必须指定 |
| `local_date` | date | 本地日期（按用户所在时区），格式 `yyyy-MM-dd` |

### 维度：上报口径标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `reporting_business_line` | string | 上报业务线，固定为 `Homepage` |
| `reporting_module` | string | 上报模块，固定为 `Daily Discover` |
| `reporting_object` | string | 上报对象，对应 Omni Item 链路中的 object；Omni Entry 链路的 object 字段同名映射 |
| `platform` | string | 用户访问平台，如 `android`、`ios`、`pc` 等 |

### 维度：流量位置与广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `location` | bigint | 广告/内容在列表中的位置，`-1` 表示无位置信息，超过 250 的位置统一截断为 `250` |
| `is_ads` | string | 是否为广告流量标识，`1` 表示广告，`0` 或空表示自然流量 |
| `ads_id` | bigint | 广告 ID；无广告时填充为 `-1` 或 `0` |

### 维度：广告产品类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `main_product_type` | string | 广告主产品类型，关联广告维表获取；无法匹配时默认为 `others` |
| `product_type` | string | 广告产品类型（二级），关联广告维表获取；无法匹配时默认为 `others` |
| `sub_product_type` | string | 广告产品子类型（三级），关联广告维表获取；无法匹配时默认为 `others` |

### 指标：入口层曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_entry_impr_cnt` | bigint | 入口层曝光次数（Omni Entry Impression），来源于场景事件日志，operation = `impression` |
| `omni_entry_click_cnt` | bigint | 入口层点击次数（Omni Entry Click），来源于场景事件日志，operation = `click` |

### 指标：商品层曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `omni_item_impr_cnt` | bigint | 商品层曝光次数（Omni Item Impression），operation = `omni_impression` |
| `omni_item_click_cnt` | bigint | 商品层点击次数（Omni Item Click），operation = `omni_click` |

### 指标：商品详情页访问

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页访问次数（Product Page View），含回退行为 |
| `ppv_cnt_exclude_isback` | bigint | 剔除回退（is_back = true）后的商品详情页访问次数，更能反映主动浏览意愿 |

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单量，来源于 `srdi_mart.dwd_sr_data_warehouse_platform`，operation = `order` |
| `gmv` | double | 成交金额（USD），来源于 `place_order_gmv` 字段 |
| `pc2_gmv` | double | PC2 口径 GMV（USD），为不同归因口径下的成交金额，与 `gmv` 计算口径不同 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须指定，否则将触发全分区扫描，严重影响性能。
- **`local_date`**：分区字段，建议同时指定，以限定查询到具体日期范围。

```sql
-- 标准过滤示例
WHERE grass_region = 'ID'
  AND local_date = '2024-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `gmv` / `pc2_gmv` | 已在 ETL 中按分组聚合，跨分组直接 SUM 会产生双计；多来源（source0/source1/source2）UNION ALL 后再 SUM，需确认分析口径 |
| `order_cnt` | 类型为 double，由多条来源 UNION ALL 汇总而来，跨广告 ID 或产品类型横向累加时需确认去重逻辑 |
| `ppv_cnt` / `ppv_cnt_exclude_isback` | 来源于 Omni Item 链路，跨 `ads_id = -1`（自然流量）和有效广告 ID 的维度叠加 SUM 可能产生重叠 |

### 时效性说明

- 本表为 **每日快照表（`_1d` 后缀）**，T+1 产出，当日数据通常在次日早间写入完成。
- 不含历史累计逻辑，每个 `local_date` 分区仅覆盖当日行为数据。
- 本表使用 `INSERT OVERWRITE PARTITION` 写入，每次调度会覆盖对应 `grass_region` + `local_date` 分区，无增量追加风险。

### 其他注意事项

- `location` 值为 `-1` 表示无位置信息，`250` 表示位置 ≥ 250 的截断值，聚合分析时需关注这两个特殊值是否需要过滤。
- `ads_id = -1` 或 `0` 表示非广告或无广告 ID，分析广告效果时应过滤这部分数据。
- `is_ads` 字段为 string 类型，过滤时注意使用字符串比较：`is_ads = '1'`。
- `omni_entry_*` 与 `omni_item_*` 来自不同数据链路，同一行记录中两组指标互斥（其中一组必为 0），整体求和时可直接 SUM 但需理解这一设计。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，提供广告 ID 对应的 `main_product_type`、`product_type`、`sub_product_type`、`placement` 等属性；按 `grass_region` 和 `grass_date` 过滤，取最新 placement 的一条记录（ROW_NUMBER 去重） |
| `traffic_omni_oa.dwd_scenario_event_log_di__reg_sensitive_live` | 入口层（Omni Entry）原始事件日志，提供首页 Daily Discover 模块的曝光（impression）和点击（click）行为 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 商品层（Omni Item）平台行为宽表，提供商品曝光、点击、PPV、下单及 GMV 数据，支持 source0/source1/source2 三种归因路径 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise__reg_s0_live
        │
        ▼ (CACHE: dim_ads_<region>)
        │  加盐去重广告维表
        │
        ├─────────────────────────────────┐
        ▼                                 ▼
traffic_omni_oa                   srdi_mart.dwd_sr_data_warehouse_platform
dwd_scenario_event_log            (source0 / source1 / source2 UNION ALL)
        │                                 │
        ▼ LEFT JOIN dim_ads               ▼ LEFT JOIN dim_ads
omni_entry_all_type_imp_click     omni_item_all_type_imp_click_order
        │                                 │
        └──────────────┬──────────────────┘
                       ▼ UNION ALL
              GROUP BY 维度聚合
                       │
                       ▼
   srdi_mart.dws_sr_data_warehouse_homepage_dd_ads_type_1d
         (INSERT OVERWRITE PARTITION)
```

### 关键步骤

**Step 1 — CACHE 广告维表（dim_ads_\<region\>）**
- 从 `mp_paidads.dim_advertise__reg_s0_live` 按 `grass_region` 和 `grass_date` 过滤，保留 `tz_type = 'local'` 数据。
- 使用 `ROW_NUMBER() OVER (PARTITION BY ads_id ORDER BY placement DESC)` 对同一 `ads_id` 取唯一记录（取 placement 最大的一条）。
- 对 `ads_id` 为 `NULL/-1/0` 的情况采用**加盐策略**（拼接随机数后缀 `_0~19`），用于后续 LEFT JOIN 时避免数据倾斜。
- 将结果 CACHE 到 `MEMORY_AND_DISK_SER` 以复用。

**Step 2 — 临时视图 omni_entry_all_type_imp_click_\<region\>（入口层行为汇总）**
- 从场景事件日志读取 Homepage / Daily Discover 的 `impression` 和 `click` 事件，过滤 `user_id > 0` 的有效用户。
- `location` 超过 250 截断为 250，NULL 填充为 -1。
- `ads_id` NULL 填充为 -1，同样应用加盐策略后 LEFT JOIN 广告维表补全产品类型。
- 按 business_line、module、object、platform、location、is_ads、ads_id、产品类型分组，统计曝光和点击次数。

**Step 3 — 临时视图 omni_item_all_type_imp_click_order_\<region\>（商品层行为汇总）**
- 从 `srdi_mart.dwd_sr_data_warehouse_platform` 通过 **三路 UNION ALL** 读取数据：
  - **source0**：使用主路径字段（`reporting_business_line`、`reporting_module` 等）
  - **source1**：使用 `source1_*` 前缀字段（支持第一归因来源路径）
  - **source2**：使用 `source2_*` 前缀字段（支持第二归因来源路径）
- 三路均过滤 Homepage / Daily Discover，操作类型包含 `omni_impression`、`omni_click`、`ppv`、`order`。
- 同样对 `ads_id` 加盐后 LEFT JOIN 广告维表，按维度分组聚合商品曝光、点击、PPV（含/不含回退）、订单量、GMV 及 PC2 GMV。

**Step 4 — INSERT OVERWRITE 写入目标表**
- 将 Step 2（入口层）和 Step 3（商品层）的结果 UNION ALL 合并：
  - 入口层记录中 `omni_item_*`、`ppv_*`、`order_cnt`、`gmv`、`pc2_gmv` 填充为 0。
  - 商品层记录中 `omni_entry_impr_cnt`、`omni_entry_click_cnt` 填充为 0。
- 对合并结果按全部维度字段（reporting_business_line、reporting_module、reporting_object、platform、location、is_ads、ads_id、main_product_type、product_type、sub_product_type）执行最终 GROUP BY SUM 聚合。
- 以 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 写入目标表。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，不存在多 Writer 并发冲突风险。
- **分区覆盖写**：每次调度使用 `INSERT OVERWRITE PARTITION`，同一 `grass_region + local_date` 分区的历史数据会被完全覆盖，重跑安全。
- **加盐 JOIN 防倾斜**：`ads_id` 为 -1 或 0 时（即无广告流量）数据量通常极大，ETL 通过 `CONCAT(ads_id, '_', FLOOR(RAND() * 20))` 拆分为 20 个桶与维表 JOIN，最终聚合时仍可还原到正确的 `ads_id = -1`。分析时不要依赖 `salted_ads_id` 字段（该字段不写入目标表）。
- **三路 UNION ALL 潜在重复**：`dwd_sr_data_warehouse_platform` 的 source0/source1/source2 三路归因可能对同一笔订单产生多条记录，这是业务多归因设计；在计算转化率或去重指标时需注意口径对齐，避免重复计数。
- **广告维表时效**：`dim_advertise__reg_s0_live` 按 `grass_date` 过滤，使用的是当日广告配置快照，广告属性变化不会追溯历史分区。

---

*文档生成时间：2026-05-17*