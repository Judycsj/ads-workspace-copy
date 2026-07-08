<!-- ads-workspace-gdoc-sync: gdoc_id=1PLddaTLMZESjXyNkeow0WYWU1NF2Fnw3PTpXMQG6PY8 gdoc_url=https://docs.google.com/document/d/1PLddaTLMZESjXyNkeow0WYWU1NF2Fnw3PTpXMQG6PY8/edit -->

# srdi_mart.dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d

**分层**：DWS（数据汇总层）
**主键**：`user_id` + `item_id` + `scenario` + `is_ads` + `antifraud_tag` + `local_date` + `grass_region`
**分区**：`grass_region`（站点区域）、`local_date`（本地日期）
**更新频率**：每日全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次**：188

---

## 业务描述

本表面向**内容电商（搜推）反欺诈场景**，以 **用户 × 商品 × 场景（视频/直播）× 是否广告 × 反欺诈标签** 为粒度，汇总各维度组合在指定日期下的**订单数与 GMV**。

数据涵盖 Video（短视频内容带货）和 Live（直播带货）两条内容链路，通过关联反欺诈系统打标结果，将订单划分为正常订单、刷单（Brushing）订单、滥用（Abuse）订单等类别，支持下游对内容流量质量的全面评估。

**典型业务场景：**
- 内容搜推模型训练样本清洗：过滤刷单 / 滥用订单后生成高质量训练数据
- 内容带货 GMV 归因分析：按广告 / 自然流量拆分计算 GMV 贡献
- 反欺诈效果评估：统计各反欺诈标签下的订单量与 GMV 占比
- 用户 × 商品级别的内容电商行为分析

**适合回答的问题：**
- 某日某站点下，被标记为刷单的内容订单 GMV 占总 GMV 的比例是多少？
- 视频带货与直播带货的订单量及 GMV 如何对比？
- 广告流量与自然流量在用户 × 商品维度的成交数量分布？
- 某用户在某商品上通过内容渠道产生的订单是否涉及欺诈行为？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，例如 `SG`、`MY`、`TH` 等，用于物理分区隔离 |
| `local_date` | date | 订单统计本地日期（基于站点本地时区 `tz_type='local'`），格式 `YYYY-MM-DD` |

### 维度：用户与商品标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 买家用户 ID；视频链路来源于 `user_id`，直播链路来源于 `order_buyer_id` |
| `item_id` | bigint | 订单关联商品 ID（`order_item_id`） |

### 维度：内容场景与流量类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario` | string | 内容场景类型：`Video`（短视频带货）或 `Live`（直播带货） |
| `is_ads` | string | 是否广告流量：`'true'` 表示广告，`'false'` 表示自然流量 |

### 维度：反欺诈标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `antifraud_tag` | int | 反欺诈标签，来源于反欺诈系统 `szci_antifraud.dws_ob_online_s1_di`；`0` = Brushing（刷单），`1` = Abuse（滥用）；若订单未命中反欺诈规则则填充默认值 `-1`（正常订单） |

### 指标：订单与成交金额

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 维度组合下的订单数汇总；视频链路使用分摊权重 `video_order_fraction`，直播链路使用 `ls_order_fraction`，二者均为分摊值（非整数），不可直接与整单口径数据对比 |
| `gmv` | double | 维度组合下的 GMV 汇总（单位：USD），来源于 `gmv_usd` 字段求和 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区过滤**：查询时**必须同时指定** `grass_region` 和 `local_date`，避免全表扫描，例如：
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2025-01-01'
   ```
2. **多日期查询**：如需跨日期聚合，使用 `local_date BETWEEN ... AND ...` 并确保 `grass_region` 已指定。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_cnt` | 采用订单分摊权重（`video_order_fraction` / `ls_order_fraction`），跨维度直接 SUM 可能导致双重计算；与订单整数口径数据对比时需注意口径差异 |
| `gmv` | 同上，为分摊 GMV，跨场景 / 跨 `antifraud_tag` SUM 时需理解分摊逻辑 |

> **注意**：`antifraud_tag = -1` 表示未命中反欺诈规则的订单，并非欺诈，统计"正常订单"时应过滤 `antifraud_tag = -1`；统计"全部订单"时需包含该值。

### 时效性说明

- 本表为 **1d（T+1 日级别）** 表，数据通常在次日产出。
- ETL 每次写入时，上游数据窗口为 **`[local_date - 14, local_date]`**（滑动 15 天窗口），用于关联可能延迟到达的反欺诈标签；最终写入目标表时按 `local_date` 分区聚合，**每个分区为当日的最终口径数据**。
- 历史分区数据在对应日期重跑时会被 INSERT OVERWRITE 覆盖。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_content_oa.dwd_video_order_omni_local_content_direct_final_detail_di` | 视频内容带货订单明细，提供用户、商品、订单、广告标识、订单分摊数、GMV 等字段；过滤条件：`business_id in ('1003', '1019')`（内容搜推相关业务线）、本地时区、指定站点 |
| `mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di` | 直播内容带货订单明细，提供买家、商品、订单、广告标识、订单分摊数、GMV 等字段；过滤条件：`order_cal_type = 'direct'`、本地时区、`is_content_directly_related = 1` |
| `szci_antifraud.dws_ob_online_s1_di` | 反欺诈系统订单打标结果，提供 `order_id` 对应的 `antifraud_tag`（0=刷单，1=滥用） |

---

## ETL 逻辑摘要

### 数据流

```
mp_content_oa.dwd_video_order_omni_local_content_direct_final_detail_di  ─┐
                                                                            ├──► user_item_view (UNION ALL)
mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di            ─┘
                                                                                      │
szci_antifraud.dws_ob_online_s1_di ──► order_antifraud_tag_view                      │
                                              │                                       │
                                              └─────── LEFT JOIN on order_id ─────────┘
                                                                                      │
                                                                                      ▼
                        srdi_mart.dws_sr_data_warehouse_content_antifraud_user_item_level_order_metrics_1d
                                          (INSERT OVERWRITE, partition by grass_region + local_date)
```

### 关键步骤

**Step 1 — 创建临时视图 `user_item_{region}`**

- 从视频订单明细表读取 Video 场景数据，过滤 `business_id in ('1003', '1019')`，取 15 天滑动窗口（`[local_date-14, local_date]`），本地时区；将布尔型 `is_ads` 转换为字符串 `'true'`/`'false'`；订单量使用 `video_order_fraction`（分摊值）。
- 从直播订单明细表读取 Live 场景数据，过滤 `order_cal_type='direct'`、`is_content_directly_related=1`、本地时区，同样取 15 天滑动窗口；`is_ads` 原为字符串类型，直接使用；订单量使用 `ls_order_fraction`（分摊值）。
- 两路数据通过 `UNION ALL` 合并，共享字段：`local_date`、`user_id`、`item_id`、`scenario`、`order_id`、`is_ads`、`order_cnt`、`gmv`。

**Step 2 — 创建临时视图 `order_antifraud_tag_{region}`**

- 从反欺诈系统读取同样 15 天窗口内的订单打标结果，按 `(order_id, tag)` 去重（GROUP BY），产出 `antifraud_tag` 字段（0=Brushing，1=Abuse）。
- 注意：同一 `order_id` 可能存在多个 `antifraud_tag` 值，GROUP BY 保留所有组合。

**Step 3 — INSERT OVERWRITE 写入目标表**

- 将 Step 1 结果与 Step 2 结果按 `order_id` 进行 LEFT JOIN，未匹配到反欺诈标签的订单使用 `COALESCE(antifraud_tag, -1)` 填充为 `-1`（正常）。
- 按 `(user_id, item_id, scenario, is_ads, antifraud_tag, local_date)` 进行 GROUP BY，对 `order_cnt` 和 `gmv` 分别求 SUM。
- 以 `grass_region` 和 `local_date` 为分区，INSERT OVERWRITE 写入目标表，覆盖当次调度对应的分区数据。

### 注意事项

1. **单 Writer**：该表仅有 1 个 ETL 文件写入，不存在多 Writer 并发冲突风险。
2. **分区覆写范围**：每次调度对固定 `grass_region` 和单日 `local_date` 执行 INSERT OVERWRITE，历史分区不受影响，但同一分区重跑时数据会被全量替换。
3. **上游滑动窗口与目标表日期对应**：上游拉取 15 天数据是为了等待反欺诈标签延迟补录，最终写入时仍按订单发生的 `grass_date`（即 `local_date`）分区存储，不会导致数据膨胀到 15 个分区。
4. **`antifraud_tag` 多值风险**：反欺诈临时视图按 `(order_id, tag)` 去重，若同一订单被打上多个标签（如同时为 Brushing 和 Abuse），LEFT JOIN 后会产生多行，导致 `order_cnt` 和 `gmv` 被重复计入，下游使用时需关注该场景。
5. **`is_ads` 类型差异**：视频链路的 `is_ads` 原为 Boolean 类型，ETL 中已显式转换为字符串；直播链路的 `is_ads` 原始即为字符串，两路 UNION ALL 后类型一致，但需注意源表字段变更风险。

---

*文档生成时间：2026-05-17*