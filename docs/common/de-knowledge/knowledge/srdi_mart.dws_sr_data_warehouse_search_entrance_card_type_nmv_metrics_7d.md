<!-- ads-workspace-gdoc-sync: gdoc_id=1CtzPxGuroC0sHQYIXYUAs6y33lTdb-c7ixRv2-Xg5zk gdoc_url=https://docs.google.com/document/d/1CtzPxGuroC0sHQYIXYUAs6y33lTdb-c7ixRv2-Xg5zk/edit -->

# srdi_mart.dws_sr_data_warehouse_search_entrance_card_type_nmv_metrics_7d

**分层：** dws_search
**主键：** grass_region, local_date, search_entrance, is_ads, card_type, sort_type
**分区：** grass_region, local_date
**更新频率：** 每日（按分区 INSERT OVERWRITE，覆盖当日分区）
**引用频次 / 访问频次：** 254

---

## 业务描述

本表为搜索域 DWS 层宽表，统计全球搜索（Global Search）场景下，过去 **7 天滑动窗口**内各搜索入口（`search_entrance`）、卡片类型（`card_type`）、是否广告（`is_ads`）、排序类型（`sort_type`）组合维度的 **NMV（商品交易总额）、净订单数、净下单 UU** 等核心电商成交指标。

数据来源覆盖主归因（`feature_detail`）及 source1、source2 多路归因链路，卡片粒度同时提供 `item`、`video`、`livestream` 细分及全量汇总（`__ALL__`）两套口径，维度组合通过 `CUBE` 运算预聚合，支持多维任意切片。

**核心业务场景：**

- 搜索 NMV 周趋势监控与归因分析
- 广告 vs. 自然流量成交对比
- 不同搜索入口（首页搜索框、PDP 内搜索、预填充搜索等）的变现效率评估
- 商品卡 / 视频卡 / 直播卡各卡片类型的 GMV 贡献分析
- 排序策略迭代对成交指标的影响评估

**适合回答的典型问题：**

- 最近 7 天，各搜索入口的 NMV 分布如何？
- 广告流量与自然流量的净订单数差异是多少？
- item 卡、video 卡、livestream 卡各自带来了多少 NMV？
- 特定地区（grass_region）下，不同排序类型的成交 UU 数趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，标识数据所属国家/地区市场，如 `SG`、`MY`、`TH` 等 |
| `local_date` | date | 数据日期分区，每日运行时写入当日日期；ETL 读取上游时覆盖 `[local_date-7, local_date]` 共 8 天窗口后聚合写入该分区 |

### 维度：搜索行为维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口，如 `home`、`pdp` 等；为空时置为 `NA`（原始值），CUBE 汇总行填充为 `__ALL__` |
| `card_type` | string | 卡片类型：`item`（商品卡）、`video`（视频卡）、`livestream`（直播卡）；跨卡汇总行填充为 `item+video+live`（item/video/live 三类合计）或 `__ALL__`（全量归因口径汇总）；由上游 `feature_detail` 字段按 `-` 分隔解析得到 |
| `is_ads` | string | 是否广告流量，`true` / `false`；原始值为 NULL 时默认为 `'false'`，CUBE 汇总行填充为 `__ALL__` |
| `sort_type` | string | 排序类型，标识搜索结果的排序策略；原始值为 NULL 时填充为 `'NULL'`，CUBE 汇总行填充为 `__ALL__` |

### 指标：成交核心指标（7 天窗口预聚合）

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 净商品交易总额（NMV，单位：USD），来自上游 `nmv` 字段，在 7 天窗口内按维度组合 SUM 聚合。**CUBE 汇总行已做预聚合，跨日或跨维度二次 SUM 时需注意口径重叠** |
| `net_order_cnt` | double | 净订单数，在 7 天窗口内按维度组合 SUM 聚合。**同上，CUBE 汇总行存在维度覆盖，直接 SUM 全表会导致重复计算** |
| `net_order_uu` | bigint | 净下单去重用户数（UU），在 7 天窗口内统计 `net_order_cnt > 0` 的 `user_id` 去重计数。**不可跨维度行二次 SUM，属于去重指标** |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段过滤（必须同时指定）**
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2025-01-01'
   ```
   - `grass_region` 和 `local_date` 均为分区字段，查询时必须显式指定，否则将触发全表扫描，读取所有地区和所有历史日期数据，产生严重性能问题。
   - `local_date` 单个分区已覆盖过去 7 天滑动窗口的聚合结果，**无需额外跨多个 `local_date` 分区求和**。

2. **维度汇总行过滤**
   - 表中存在 CUBE 产生的多级汇总行，`__ALL__`、`item+video+live` 均为预聚合占位值。查询细分指标时需过滤掉汇总行，例如：
     ```sql
     WHERE card_type NOT IN ('__ALL__', 'item+video+live')
       AND search_entrance != '__ALL__'
       AND is_ads != '__ALL__'
       AND sort_type != '__ALL__'
     ```
   - 如需使用汇总行，应明确指定对应维度值，避免混用细分行与汇总行。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `net_order_uu` | 去重 UU 指标，CUBE 各维度组合已分别去重，跨行 SUM 会导致重复计算 |
| `nmv` | CUBE 预聚合表，不同 `card_type` / `search_entrance` 等汇总行之间存在口径重叠，跨维度行 SUM 会导致重复计数 |
| `net_order_cnt` | 同 `nmv`，CUBE 汇总行之间数据已包含重叠，直接 SUM 全表结果不正确 |

### 时效性说明

- 本表为 **7 天滑动窗口**预聚合表（表名后缀 `_7d`），每个 `local_date` 分区的数据覆盖 `[local_date - 7, local_date]` 共 8 天的原始数据聚合结果。
- 通常 **T+1** 更新，即当日分区数据于次日产出，不提供实时或准实时数据。
- 若需逐日趋势，应按 `local_date` 逐分区查询，**不要跨多分区 SUM**（否则同一天的订单会被多次统计）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 搜索平台 NMV 明细宽表，提供用户级别的订单成交数据及搜索归因特征（主归因 `feature_detail`、`source1_feature_detail`、`source2_feature_detail` 三路），ETL 以 `reporting_business_line = 'Search'` 且 `reporting_module = 'Global Search'` 过滤后作为原始输入 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform_nmv
        │  (三路归因：feature_detail / source1 / source2)
        │  过滤：grass_region、local_date 近 7 天、user_id > 0
        │         reporting_business_line='Search', reporting_module='Global Search'
        ▼
 [Temp View] order_nmv_raw          ← UNION ALL 三路归因，解析 card_type / search_entrance / is_ads / sort_type
        │
        ├──► [Temp View] dwm_order_nmv_item_video_live  ← 只保留 item/video/livestream 卡，按用户+维度聚合
        │
        └──► [Temp View] dwm_order_nmv_all              ← 全量卡片（不限 card_type），按用户+维度聚合
                │
                ▼
        [Temp View] dws_order_nmv   ← CUBE 多维预聚合（含汇总行），两部分 UNION ALL：
                │                     ① item/video/live 细分 + 汇总（card_type='item+video+live'）
                │                     ② 全量口径（card_type='__ALL__'）
                ▼
srdi_mart.dws_sr_data_warehouse_search_entrance_card_type_nmv_metrics_7d
        (INSERT OVERWRITE PARTITION grass_region + local_date)
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `order_nmv_raw_{region}` | 从 DWD 层读取近 7 天数据，UNION ALL 合并主归因、source1、source2 三路，解析 `feature_detail` 按 `-` 分隔提取 `page_type`、`page_section`、`card_type`，标准化 `search_entrance`、`is_ads`、`sort_type` 空值处理 |
| Step 2 | `dwm_order_nmv_item_video_live_{region}` | 过滤 `page_type IN ('global_search', 'search_in_pdp', 'search_prefill')` 且 `page_section IS NULL` 且 `card_type IN ('item', 'video', 'livestream')`，按用户+搜索维度汇总 `net_order_cnt` 和 `nmv` |
| Step 3 | `dwm_order_nmv_all_{region}` | 全量数据（不限 page_type / card_type），按用户+搜索维度汇总 `net_order_cnt` 和 `nmv`，用于生成 `__ALL__` 卡片口径 |
| Step 4 | `dws_order_nmv_{region}` | ① 对 Step 2 结果做 `CUBE(search_entrance, is_ads, card_type, sort_type)` 多维聚合，汇总行维度值置为 `__ALL__`/`item+video+live`；② 对 Step 3 结果做 `CUBE(search_entrance, is_ads, sort_type)` 聚合并固定 `card_type='__ALL__'`；两部分 UNION ALL |
| Step 5 | `INSERT OVERWRITE` | 按 `grass_region` + `local_date` 分区覆盖写入目标表 |

### 注意事项

1. **单 Writer，无 multi-writer 风险**：该表仅由单个 ETL 文件写入，不存在多文件并发写同一分区的竞争问题。
2. **CUBE 汇总行重叠**：目标表中存在多级汇总行（`__ALL__`、`item+video+live`），下游查询务必根据业务口径明确过滤维度，避免重复聚合。
3. **三路归因 UNION ALL**：同一笔订单可能同时被主归因和 source1/source2 归因路径计入，导致 `order_nmv_raw` 层存在一单多行，这是搜索多路归因的业务设计，并非数据错误；聚合指标在此基础上累计，需了解该业务口径含义。
4. **参数化 Region**：SQL 使用 `${grass_region}` / `${grass_region_without_quote}` 模板变量，ETL 按 region 逐个调度执行，每次覆盖对应 region 分区。
5. **7 天窗口边界**：上游读取范围为 `DATE_SUB(${local_date}, 7)` 到 `${local_date}`（共 8 天），最终聚合后写入 `local_date` 单分区，不拆分到各天分区。

---

*文档生成时间：2026-05-17*