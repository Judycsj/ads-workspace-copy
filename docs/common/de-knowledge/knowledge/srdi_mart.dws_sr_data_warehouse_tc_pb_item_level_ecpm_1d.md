<!-- ads-workspace-gdoc-sync: gdoc_id=15uE2cKoXe2O0_D8CkGXNsJbsmdNAEB6WIHVU55H35Uw gdoc_url=https://docs.google.com/document/d/15uE2cKoXe2O0_D8CkGXNsJbsmdNAEB6WIHVU55H35Uw/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_item_level_ecpm_1d

**分层：** DWS（数据汇总层）
**主键：** `item_id`（在分区 `grass_region` + `regional_date` 内唯一）
**分区：** `grass_region`（区域）、`regional_date`（业务日期）
**更新频率：** 每日一次（T+1 覆盖写入）
**访问频次：** 29,007 次

---

## 业务描述

本表用于存储**搜推广告（ROI2）场景下，各商品（item）在不同入口渠道的 eCPM 分层标签**。

核心业务场景：
- 针对搜索（Search）、每日发现（Daily Discover）、猜你喜欢（You May Also Like）三个广告入口，分别计算每个商品当日的平均 eCPM（单位：美元），并与当日全渠道 eCPM 的分位数阈值对比，为商品打上 eCPM 分层标签（0.1 ～ 1.0，代表所处分位数区间）。
- 分层标签以 `map<入口名, [分位数分层值, eCPM美元值]>` 的结构存储，方便下游快速获取商品在各渠道的 eCPM 竞争力水位。

**适合回答的问题：**
- 某商品在搜索/每日发现/猜你喜欢入口的 eCPM 处于市场什么分位水平？
- 某区域某日哪些商品 eCPM 处于 Top 10%（分层标签 = 1.0）？
- 商品在不同广告入口的 eCPM 竞争力横向对比分析。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识，如 `SG`、`MY` 等，与业务大区对应；每次写入覆盖对应分区 |
| `regional_date` | date | 业务日期（数据归属日期），格式 `yyyy-MM-dd` |

### 维度：商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，为分区内主键 |

### 指标：商品 eCPM 分层标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `ecpm_tag` | map\<string, array\<double\>\> | 商品在各广告入口的 eCPM 标签，key 为入口名称（`Search` / `Daily Discover` / `You May Also Like`），value 为长度为 2 的数组：`[ecpm_tier_tag, ecpm_usd]`。其中 `ecpm_tier_tag` 为 eCPM 分位数分层标签（0.1/0.2/.../1.0，代表所处分位区间上界），`ecpm_usd` 为该商品在该入口当日平均 eCPM 的美元值（已除以汇率换算） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪必须同时指定 `grass_region` 和 `regional_date`**，否则将触发全量分区扫描，导致查询性能严重下降并可能引发资源超限。示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-06-01'
  ```

### 不可直接聚合的字段

- **`ecpm_tag`** 是预聚合的复合结构字段（map + array），存储了分位数分层标签和均值 eCPM，**不可直接 SUM / AVG**。
  - 若需提取具体入口的 eCPM 值，需使用 `ecpm_tag['Search'][1]` 取对应美元值，`ecpm_tag['Search'][0]` 取分层标签。
  - 分层标签（`ecpm_tier_tag`）是基于当日全渠道分位数阈值计算的**有序分箱值**，跨日或跨区域的标签值不可直接加总比较，仅作为同日同区域内的相对排名参考。
  - eCPM 美元值（`ecpm_usd`）为分区内 `avg(ecpm)` 再除以汇率，**不可跨行 SUM 后再除汇率**，否则结果有误。

### 时效性说明

- 本表为 `*_1d` 日粒度汇总表，每日 T+1 覆盖写入，查询时应使用最新业务日期分区。
- 数据依赖当日汇率表（`dim_exchange_rate__reg_s0_live`），若汇率数据延迟，则 eCPM 美元值可能偏差。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_roi2_ads_search_log` | 搜推 ROI2 广告曝光日志，提供商品维度的 eCPM 及入口信息，作为 eCPM 计算的基础事实数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供当日区域汇率，用于将 eCPM 从本地货币换算为美元 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_roi2_ads_search_log
        │  （过滤 ROI2 类型、入口、有效 eCPM）
        ▼
dim_exchange_rate__reg_s0_live ──► [Step 1] 商品 × 入口 均值 eCPM（USD）
                                          │
                                          ▼
                                  [Step 2] 各入口全局分位数阈值（P10~P90）
                                          │
                                          ▼
                                  [Step 3] 商品 × 入口 eCPM 分层打标
                                          │
                                          ▼
                                  [Step 4] 聚合为 map 结构
                                          │
                                          ▼
        dws_sr_data_warehouse_tc_pb_item_level_ecpm_1d（分区覆盖写入）
```

### 关键步骤

| 步骤 | 临时视图 | 逻辑说明 |
|---|---|---|
| Step 1 | `exchange_rate_<region>` | 从汇率维表取当日指定区域汇率，供后续换算使用 |
| Step 2 | `ecpm_label_step1_<region>` | 从 ROI2 广告日志过滤有效记录（`roi_item_type IN ('SIMPLE_ROI2','TARGET_ROI2')`，`entrance IN (1,3,4)`，`ecpm > 0`），按 `item_id × 入口` 计算 `avg(ecpm) / exchange_rate` 得到美元 eCPM |
| Step 3 | `ecpm_label_step2_<region>` | 按入口分组，对美元 eCPM 计算 P10~P90 共 9 个分位数阈值（使用 `APPROX_PERCENTILE`），作为分层边界 |
| Step 4 | `ecpm_label_<region>` | 将 Step 2 结果与 Step 3 分位阈值 JOIN，对每条商品×入口记录打上 eCPM 分层标签（0.1/0.2/.../1.0），再按 `item_id` 聚合，使用 `map_from_entries(collect_list(struct(入口名, array(分层值, eCPM美元值))))` 构造 map 结构 |
| Final | 目标表写入 | `INSERT OVERWRITE` 按 `grass_region` + `regional_date` 分区覆盖写入，仅写 `item_id` 和 `ecpm_tag` 两列 |

### 注意事项

- **单 Writer 覆盖写入**：本表仅有 1 个 ETL 文件，无 multi-writer 风险；每次执行以 `INSERT OVERWRITE` 完整替换目标分区，幂等性良好。
- **分区参数化**：SQL 中 `${grass_region}`、`${regional_date}`、`${grass_region_without_quote}` 均为运行时注入参数，临时视图名称带区域后缀，支持并发区域任务隔离，但需确保参数正确传入。
- **分位数近似计算**：Step 3 使用 `APPROX_PERCENTILE`（近似分位数），结果为近似值，不保证精确分位；不同日期、不同数据量下分位阈值可能存在细微波动。
- **`entrance` 枚举覆盖**：仅处理 `entrance IN (1,3,4)`，分别对应 Search、Daily Discover、You May Also Like，其他入口不纳入计算；若商品仅在部分入口有记录，`ecpm_tag` 中仅包含对应 key，不存在的入口不会有空 key 占位。
- **汇率关联方式**：以 `ON 1=1` 广播关联汇率，汇率表需保证当日区域数据唯一，否则 JOIN 结果可能膨胀，导致均值计算偏差。

---

*文档生成时间：2026-05-17*