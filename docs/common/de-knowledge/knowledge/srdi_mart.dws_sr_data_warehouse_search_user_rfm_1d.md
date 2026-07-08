<!-- ads-workspace-gdoc-sync: gdoc_id=1n-dAZKTHuAwxbtA61FLNST4FgalB75Ic45qF7hPTHU0 gdoc_url=https://docs.google.com/document/d/1n-dAZKTHuAwxbtA61FLNST4FgalB75Ic45qF7hPTHU0/edit -->

# srdi_mart.dws_sr_data_warehouse_search_user_rfm_1d

**分层：** dws_search
**主键：** user_id
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 1253

---

## 业务描述

本表为搜索域用户 RFM（Recency / Frequency / Monetary Value）画像宽表，以天为粒度，记录每个用户在过去 90 天内通过搜索场景（全局搜索、PDP 内搜索）产生下单行为的 R / F / M 原始值及其分级标签，同时保留逐日明细的订单历史快照。

**核心业务场景：**
- 搜索用户价值分层：依据 R / F / M 三维度将用户分为 High / Medium / Low 三级，支持精细化运营和搜索策略差异化投放。
- 用户活跃度与消费能力评估：结合近期购买时间（Recency）、历史购买频次（Frequency）与累计 GMV（Monetary Value）综合评价用户质量。
- 跨地区对比分析：已内置 ID（印度尼西亚）与 BR（巴西）两套分级阈值，支持多站点运营对比。

**适合回答的问题：**
- 某地区高价值搜索用户（RFM 均为 High）的规模及趋势？
- 某用户最近一次通过搜索下单距今多少天？其历史搜索购买频次和 GMV 分别是多少？
- 搜索场景下，各 RFM 分级用户的分布比例如何随时间变化？
- 某日期某地区，哪些用户处于"流失风险"区间（Recency 等级 Low）？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `ID`（印度尼西亚）、`BR`（巴西）；ETL 按地区独立写入对应分区 |
| `local_date` | date | 数据日期（本地时区），表示当日 RFM 快照日期；每个分区对应一天的全量计算结果 |

### 维度：用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识，与 `grass_region` + `local_date` 共同确定一行记录 |

### 指标：搜索下单历史明细

| 字段 | 类型 | 说明 |
|---|---|---|
| `place_order_history` | array\<struct\<local_date:date, order_cnt:double, gmv:double\>\> | 用户在快照日期前 90 天内通过搜索场景（全局搜索 / PDP 内搜索）每日下单明细数组，按 `local_date` 升序排列；每个元素包含：日期（`local_date`）、当日订单数（`order_cnt`）、当日 GMV（`gmv`） |

### 指标：RFM 评分与分级

| 字段 | 类型 | 说明 |
|---|---|---|
| `rfm` | struct\<recency:int, recency_type:string, frequency:double, frequency_type:string, monetary_value:double, monetary_value_type:string\> | 用户 RFM 复合结构，包含六个子字段：<br>• `recency`（int）：距快照日期最近一次搜索下单的天数，无购买记录时默认为 90<br>• `recency_type`（string）：Recency 分级，取值 `High` / `Medium` / `Low`，按地区阈值划分<br>• `frequency`（double）：过去 90 天内搜索下单总笔数，无购买记录时默认为 0<br>• `frequency_type`（string）：Frequency 分级，取值 `High` / `Medium` / `Low`，按地区阈值划分<br>• `monetary_value`（double）：过去 90 天内搜索下单累计 GMV，无购买记录时默认为 0<br>• `monetary_value_type`（string）：Monetary Value 分级，取值 `High` / `Medium` / `Low`，按地区阈值划分 |

> **各地区 RFM 分级阈值参考：**
>
> | 维度 | ID 高 | ID 中 | ID 低 | BR 高 | BR 中 | BR 低 |
> |---|---|---|---|---|---|---|
> | Recency（天） | ≤7 | 8–30 | 31–90 | ≤12 | 13–50 | 51–90 |
> | Frequency（笔） | >30 | 12–30 | ≤12 | >7 | 2–7 | ≤2 |
> | Monetary Value | >140 | 60–140 | ≤60 | >90 | 25–90 | ≤25 |

---

## 查询使用须知

**必须包含的过滤条件：**
- 查询时**必须同时指定 `grass_region` 和 `local_date`** 两个分区字段，否则将触发全表扫描，消耗大量资源。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

**不可直接 SUM / AVG 的字段：**
- `rfm.recency`：为天数原始值，跨用户求和无业务意义；如需汇总，应使用 `AVG` 或分布统计，且需注意无购买用户默认值 90 的干扰。
- `rfm.recency_type` / `rfm.frequency_type` / `rfm.monetary_value_type`：分级标签字段，不可数值聚合，应使用 `COUNT` + `GROUP BY` 统计分布。
- `place_order_history`：数组结构，不可直接 SUM；如需展开，使用 `LATERAL VIEW EXPLODE` 或 `INLINE` 函数后再聚合。
- `rfm.frequency` 和 `rfm.monetary_value` 已是 90 天窗口内的预聚合值，跨分区（跨天）直接相加会产生重复计数，**不可跨 `local_date` SUM**。

**时效性说明：**
- 表为 **日快照表**（`_1d` 后缀），每日全量覆盖写入当日分区（`INSERT OVERWRITE PARTITION`）。
- 每个分区反映的是截至 `local_date` 前 90 天滚动窗口内的用户行为汇总，**非累计全量**。
- 存在两套 ETL 文件：常规调度文件（日期窗口为 `[local_date-90, local_date-1]`）和手动回刷文件（日期窗口为 `[local_date-90, local_date]`，含当日数据）。两者写入同一物理分区，手动回刷时会覆盖常规调度结果，注意区分数据口径。
- 目前仅覆盖 `ID` 和 `BR` 两个地区，其他地区的 `recency_type` / `frequency_type` / `monetary_value_type` 字段将返回 `NULL`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索行为明细宽表，过滤 `operation = 'order'` 及搜索场景（`feature_detail IN ('global_search-item', 'search_in_pdp-item')`），提取用户每日下单数量（`operation_cnt`）和下单 GMV（`place_order_gmv`），作为 RFM 计算的原始数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │
    │ 过滤：operation='order'，搜索场景 feature_detail，90天滚动窗口
    ▼
[Temporary View] user_order_history / user_search_order_history
    │ 按 user_id + local_date 聚合 order_cnt / gmv
    │ collect_list 后 array_sort 生成有序订单历史数组
    ▼
[Temporary View] user_rfm_updated / user_rfm
    │ 计算 recency（最近下单距今天数）、frequency（总订单数）、monetary_value（总 GMV）
    │ 无购买记录时 recency 默认 90，frequency / monetary_value 默认 0
    ▼
INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_search_user_rfm_1d
    PARTITION (grass_region, local_date)
    附加 recency_type / frequency_type / monetary_value_type 分级标签（按地区阈值 CASE WHEN）
```

### 关键步骤

| 步骤 | 说明 |
|---|---|
| **Statement 1 — 构建订单历史 Temporary View** | 从 `dwd_sr_data_warehouse_platform` 过滤搜索下单行为，按 `user_id + local_date` 汇总 `order_cnt` 和 `gmv`，再按 `user_id` 用 `collect_list + array_sort` 生成按日期升序排列的订单历史数组 `place_order_history` |
| **Statement 2 — 计算 RFM 原始值 Temporary View** | 基于订单历史数组计算：`recency` = 快照日期与最后一次下单日期之差（`datediff`）；`frequency` = 数组内所有 `order_cnt` 累加（`aggregate`）；`monetary_value` = 数组内所有 `gmv` 累加；三项均使用 `coalesce` 处理无购买用户的 NULL 情况 |
| **Statement 3 — INSERT OVERWRITE 写目标表** | 在 RFM 原始值基础上，通过多层 `CASE WHEN` 按地区（ID / BR）分别为 `recency`、`frequency`、`monetary_value` 打上 High / Medium / Low 分级标签，以 `INSERT OVERWRITE PARTITION` 方式写入目标表 |

### 注意事项

- **Multi-writer 风险：** 本表由两个独立 ETL 文件共同写入，均使用 `INSERT OVERWRITE PARTITION`。常规调度文件的 90 天窗口为 `[local_date-90, local_date-1]`（不含当日），手动回刷文件窗口为 `[local_date-90, local_date]`（含当日）。两者覆盖同一分区，并发执行或顺序不当时存在数据被覆盖的风险，生产环境应确保同一分区同一时刻只有一个 writer。
- **数据口径差异：** 手动回刷文件（manual）在计算 `recency` / `frequency` / `monetary_value` 时会过滤掉 `local_date` 当日的记录（`filter(place_order_history, x -> x.local_date < ${local_date})`），但 `place_order_history` 数组中仍包含当日数据，与常规文件存在细微口径差异，需注意区分。
- **地区覆盖限制：** 分级标签（`*_type`）仅对 ID 和 BR 两个地区有 CASE 分支，其他地区值为 `NULL`，查询时应注意过滤或判空。
- **分区写入模式：** 每次调度以 `INSERT OVERWRITE PARTITION` 全量覆盖当日分区，不支持增量追加；历史分区数据不会被重刷（除手动触发 manual ETL 外）。

---

*文档生成时间：2026-05-17*