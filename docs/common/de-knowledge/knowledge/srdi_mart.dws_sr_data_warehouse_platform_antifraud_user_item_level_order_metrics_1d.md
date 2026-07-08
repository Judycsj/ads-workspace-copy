<!-- ads-workspace-gdoc-sync: gdoc_id=10SZ4p0AoAGiHt3_ogcO5IFrmX82P0YRvq0OMKRKfCjE gdoc_url=https://docs.google.com/document/d/10SZ4p0AoAGiHt3_ogcO5IFrmX82P0YRvq0OMKRKfCjE/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_antifraud_user_item_level_order_metrics_1d

**分层**：DWS（数据汇总层）
**主键**：`user_id` + `item_id` + `scenario` + `scenario_tags` + `is_ads` + `antifraud_tag` + `local_date` + `grass_region`
**分区**：`grass_region`（大区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1 全量覆写，保留最近 15 天滚动窗口数据，即当日及前 14 天）
**引用频次 / 访问频次**：300

---

## 业务描述

本表在**搜索与推荐（SR）平台**的订单数据基础上，关联**反欺诈（Antifraud）标签**，按 **用户 × 商品 × 场景** 粒度聚合订单数量与 GMV，是搜推业务下反欺诈分析的核心汇总层宽表。

**核心业务场景**：

- 识别刷单（Brushing）、滥用（Abuse）等欺诈行为对搜推各渠道订单及 GMV 的影响
- 对比正常订单与欺诈订单在不同场景（搜索、推荐、店铺等）下的分布差异
- 为广告与自然流量的反欺诈效果评估提供数据支撑
- 支持按用户、商品维度的欺诈风险画像分析

**适合回答的问题示例**：

- 某大区昨日各场景下，被标记为刷单的订单数与 GMV 占比是多少？
- 广告流量（is_ads=true）中欺诈订单的 GMV 损失规模？
- 特定商品在推荐场景下，不同反欺诈标签的订单量分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `MY`、`TH`、`ID` 等；分区过滤必填字段 |
| `local_date` | date | 业务本地日期；数据范围为写入日期前推 14 天至当日（滚动 15 天窗口） |

### 维度：用户与商品

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 下单用户 ID |
| `item_id` | bigint | 被购买商品 ID |

### 维度：渠道与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario` | string | 搜推场景分类，枚举值：`Search`（全局搜索）、`Daily Discover`（每日发现）、`You May Also Like`（猜你喜欢）、`Post Purchase`（购后推荐）、`Shop`（店铺）、`Other`（其他） |
| `scenario_tags` | array\<string\> | 场景细分标签数组，来源于 `algo_tag` 及 `Global Search` 标识的组合，已去除空串元素 |
| `is_ads` | string | 是否广告流量，取值 `'true'` 或 `'false'`（字符串类型） |

### 维度：反欺诈标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `antifraud_tag` | int | 反欺诈标签：`0` = 刷单（Brushing），`1` = 滥用/薅羊毛（Abuse），`-1` = 未命中任何反欺诈标签（正常订单） |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 在该用户 × 商品 × 场景 × 反欺诈标签粒度下的订单数量汇总，由上游 `operation_cnt` 累加而来 |
| `gmv` | double | 在该用户 × 商品 × 场景 × 反欺诈标签粒度下的成交金额（GMV）汇总，由上游 `place_order_gmv` 累加而来 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响查询性能及成本
- **`local_date`**：强烈建议指定，数据保留最近 15 天（含当日），超出范围的历史日期不存在

```sql
-- 典型过滤写法示例
WHERE grass_region = 'MY'
  AND local_date = '2025-05-16'
```

### 不可直接 SUM 的字段

- `order_cnt` 与 `gmv` 在当前表粒度下已按 **用户 × 商品 × 场景 × 反欺诈标签** 聚合，可在此基础上进一步 `SUM`；但**跨 `local_date` 累加时需注意 15 天滚动窗口已含多日数据，避免重复统计同一日期**
- `scenario_tags` 为数组类型，不可直接聚合，需使用 `explode` 或数组函数展开后分析

### 时效性说明

- 本表为 **`_1d` 日级表**，每日 T+1 调度更新
- 每次写入以 `INSERT OVERWRITE PARTITION` 方式覆写，单次写入范围为**当日及前 14 天共 15 个分区**
- 查询最新数据请使用 `local_date = date_add(current_date(), -1)`（即昨日）

### 其他注意事项

- `is_ads` 字段类型为 **string**（非 boolean），过滤时须使用字符串比较：`is_ads = 'true'`
- `antifraud_tag = -1` 表示该订单在反欺诈系统中**未被标记**，属于正常或未被检测到的订单，非异常数据缺失

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推平台明细层订单数据，提供用户、商品、场景、广告标识、订单数量、GMV 等核心字段 |
| `szci_antifraud.dws_ob_online_s1_di` | 反欺诈系统订单标签表，提供订单级欺诈标签（刷单 / 滥用），按 `order_id` 与主表进行 LEFT JOIN |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
        │  过滤指定大区、近15天、operation='order'
        │  构建场景分类 scenario、场景标签 scenario_tags、is_ads
        ▼
  [临时视图] user_item_sr_{grass_region}
        │
        │  LEFT JOIN on order_id
        │
szci_antifraud.dws_ob_online_s1_di
        │  过滤指定大区、近15天
        │  去重取 antifraud_tag
        ▼
  [临时视图] order_antifraud_tag_{grass_region}
        │
        │  GROUP BY 用户×商品×场景×is_ads×antifraud_tag×日期
        │  SUM(order_cnt)、SUM(gmv)
        ▼
srdi_mart.dws_sr_data_warehouse_platform_antifraud_user_item_level_order_metrics_1d
  (INSERT OVERWRITE PARTITION)
```

### 关键步骤

**Step 1 — 临时视图 `user_item_sr_{grass_region}`**

从 `srdi_mart.dwd_sr_data_warehouse_platform` 读取指定大区近 15 天的下单（`operation = 'order'`）明细，执行以下处理：
- 使用多层 `CASE WHEN` 将 `reporting_business_line`、`reporting_module`、`reporting_object` 映射为 6 类 `scenario` 枚举值
- 将 `Global Search` 标识与 `algo_tag` 拼接后 split，并通过 `array_remove` 去除空串，生成 `scenario_tags` 数组
- 将 boolean 类型的 `is_ads` 转换为字符串 `'true'` / `'false'`
- 保留 `order_id` 用于后续 JOIN

**Step 2 — 临时视图 `order_antifraud_tag_{grass_region}`**

从 `szci_antifraud.dws_ob_online_s1_di` 读取同大区近 15 天反欺诈标签，按 `(order_id, tag)` 去重，输出 `antifraud_tag`（0=刷单，1=滥用）

**Step 3 — INSERT OVERWRITE 写目标表**

将 Step 1 与 Step 2 的结果按 `order_id` 进行 LEFT JOIN，对未命中反欺诈标签的订单使用 `COALESCE(antifraud_tag, -1)` 赋默认值 `-1`，最终按 `(user_id, item_id, scenario, scenario_tags, is_ads, antifraud_tag, local_date)` 分组聚合 `SUM(order_cnt)`、`SUM(gmv)`，写入目标表的 `(grass_region, local_date)` 分区

### 注意事项

- **单 Writer 无并发冲突**：ETL 仅有 1 个 source block，无 multi-writer 风险
- **分区覆写范围**：每次调度以动态分区方式覆写近 15 天数据（`local_date between date_add(date(${local_date}), -14) and date(${local_date})`），历史分区会被重写，下游不应在调度窗口内并发读取该表
- **反欺诈关联非强制**：采用 LEFT JOIN，未打标的订单保留 `antifraud_tag = -1`，不会丢失正常订单数据
- **scenario_tags 为数组**：若后续有写入 Hive/SparkSQL 的对比需求，注意 `array<string>` 类型在不同引擎的兼容性

---

*文档生成时间：2026-05-17*