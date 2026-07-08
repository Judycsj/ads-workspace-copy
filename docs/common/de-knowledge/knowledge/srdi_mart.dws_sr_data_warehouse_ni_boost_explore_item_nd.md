<!-- ads-workspace-gdoc-sync: gdoc_id=1YPu5Le3ApENlmZ7IDtlCcxqEjHUV4BcCIv_ssHsmp4A gdoc_url=https://docs.google.com/document/d/1YPu5Le3ApENlmZ7IDtlCcxqEjHUV4BcCIv_ssHsmp4A/edit -->

# srdi_mart.dws_sr_data_warehouse_ni_boost_explore_item_nd

**分层：** DWS（数据汇总层）
**主键：** `exp_tag` + `item_id`（分区内唯一）
**分区：** `grass_region`（大区）/ `regional_date`（业务日期）
**更新频率：** 每日一次（T+1，覆盖写当日分区）
**访问频次：** 4,483 次

---

## 业务描述

本表面向**搜推数仓 NI Boost 探索频道**，以商品（`item_id`）× 实验标签（`exp_tag`）为粒度，记录近 90 天内新品在探索频道（Explore）的**累计曝光、点击、下单及全平台曝光**数据。

核心业务场景：
- 追踪 NI Boost 实验组新品在探索频道的流量分配与转化表现；
- 计算新品从创建到当日的滚动累计指标（非单日快照，而是历史累加）；
- 支持新品冷启动、Boost 策略评估及 AB 实验分析。

适合回答的问题示例：
- 某大区某实验标签下，新品自上线以来在探索频道累计获得了多少曝光/点击/订单？
- 新品全平台曝光趋势如何？
- 距创建 90 天内的新品流量分布情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`TH` 等，用于多区域数据隔离 |
| `regional_date` | date | 业务日期，即数据所属日期（每日更新） |

### 维度：商品与实验标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，与 `exp_tag` 共同构成分区内唯一粒度 |
| `exp_tag` | string | 实验标签，标识商品所属 NI Boost 实验分组（格式以 `T` 开头，如 `T1`） |
| `create_time` | bigint | 商品创建时间戳（Unix 秒级），取历史记录中的最大值（`max`），用于判断商品新鲜度 |

### 指标：流量与转化累计指标（近 90 天滚动累加）

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_imp_cnt` | bigint | 商品在**全平台**的累计曝光次数（来源：`dws_sr_data_warehouse_ni_boost_offline_common_1d` 全渠道 `sum(imp_cnt)`） |
| `explore_imp_cnt` | bigint | 商品在**探索频道**的累计曝光次数 |
| `explore_click_cnt` | bigint | 商品在**探索频道**的累计点击次数 |
| `explore_order_cnt` | double | 商品在**探索频道**的累计下单数（来源字段类型为 double，可能含小数权重） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定** `grass_region` 和 `regional_date` 分区过滤，避免全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND regional_date = '2024-06-01'
  ```
- 若需查询特定实验组，需同时过滤 `exp_tag`（如 `exp_tag = 'T1'`）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `explore_imp_cnt` | **已为滚动累计值**，跨日期 SUM 会导致重复计算 |
| `explore_click_cnt` | 同上，跨日期不可 SUM |
| `explore_order_cnt` | 同上，跨日期不可 SUM；且类型为 double，直接聚合需注意精度 |
| `platform_imp_cnt` | 同上，跨日期不可 SUM |
| `create_time` | 经 `max()` 聚合写入，仅为标记时间戳，不具备加法语义 |

> ⚠️ 本表指标为**历史累计值（截至 `regional_date`）**，跨多个 `regional_date` 聚合时请仅取**最新一天**的分区进行分析，切勿跨分区 SUM。

### 时效性说明

- 表名含 `_nd`，表示**N 天滚动累计**语义（本表窗口为近 **90 天**）；
- 每日 T+1 覆盖写入当日分区；
- ETL 以昨日已有数据（`regional_date = today - 1`）加上今日增量合并，超过 90 天的老数据在合并时自动剔除，不再写入新分区，具有**自动老化**机制。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_item` | 获取近 90 天内新品列表及商品创建时间戳（`item_create_timestamp`） |
| `srdi_mart.dws_sr_data_warehouse_ni_boost_explore_item_nd` | 读取昨日分区的历史累计数据（自关联滚动叠加） |
| `srdi_mart.dws_sr_data_warehouse_ni_boost_offline_common_1d` | 获取当日探索频道分实验标签的曝光/点击/下单，以及全平台商品曝光数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_item（新品过滤）
        ↓
all_new_item（近90天新品 × exp_tag）
        ↓
today_data（新品 + 今日探索指标 + 今日全平台曝光）
        ↓
                                  before_data（昨日累计分区）
                                        ↓
                    UNION ALL 合并历史 + 今日 → GROUP BY 累加
                                        ↓
        INSERT OVERWRITE 当日分区（grass_region, regional_date）
```

### 关键步骤

1. **`all_new_item`（Temporary View）**
   从 `dim_sr_data_warehouse_item` 筛选当前大区、当日快照中**创建时间距今不超过 90 天**的商品，并通过 `lateral view explode(array('T1'))` 展开实验标签，生成新品候选集。

2. **`before_data`（Temporary View）**
   读取本表**昨日分区**的历史累计数据，同时过滤掉创建时间距今超过 90 天的过期商品，减轻存储压力。

3. **`today_data_raw`（Temporary View）**
   从 `dws_sr_data_warehouse_ni_boost_offline_common_1d` 提取当日、当前大区、`exp_tag LIKE 'T%'` 的探索频道曝光/点击/下单数据。

4. **`today_data`（Temporary View）**
   以 `all_new_item` 为基础，LEFT JOIN 全平台商品曝光（按 `item_id` 聚合）和今日探索指标，形成今日完整新品指标行。

5. **INSERT OVERWRITE（最终写入）**
   将 `before_data`（昨日历史）与 `today_data`（今日增量）UNION ALL 后，按 `(exp_tag, item_id)` 分组，执行 `max(create_time)`、`sum(platform_imp_cnt/explore_imp_cnt/explore_click_cnt/explore_order_cnt)`，**覆盖写入**当日分区。

### 注意事项

- **自关联写入风险：** ETL 同时读取本表昨日分区并写入今日分区，需确保调度严格按日期顺序执行，避免读写分区交叉；
- **单 Writer：** `multi_writer = false`，单文件写入，无并发冲突风险；
- **90 天老化机制：** `before_data` 读取时显式过滤 `datediff <= 90`，超期数据不会被带入新分区，属于设计内行为；
- **`exp_tag` 生成逻辑：** `all_new_item` 中通过 `explode(array('T1'))` 写死当前仅展开 `T1` 标签，若后续新增实验标签需同步修改此处逻辑；
- **`explore_order_cnt` 类型为 double：** 在聚合时请注意浮点精度问题，避免直接用于精确整数对账。

---

*文档生成时间：2026-05-17*