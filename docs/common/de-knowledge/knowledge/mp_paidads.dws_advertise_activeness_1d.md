<!-- ads-workspace-gdoc-sync: gdoc_id=13jqaNo72-vTwgdsEQGa_gyauHDYwlaFKX2tAUdtjs8E gdoc_url=https://docs.google.com/document/d/13jqaNo72-vTwgdsEQGa_gyauHDYwlaFKX2tAUdtjs8E/edit -->

# mp_paidads.dws_advertise_activeness_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `shop_id` + `user_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1 调度）
**引用频次**：9 次（候选表范围内）

---

## 业务描述

本表记录各广告（`ads_id`）在不同投放模式下**首次生效**的日期，是广告活跃度分析的基础宽表。核心价值在于沉淀两类关键词广告的最早激活时间：手动模式关键词广告（placement=0）的 `first_mm_kw_ads_active_date` 与简单模式关键词广告（placement=4）的 `first_sm_kw_ads_active_date`，为下游广告运营分析、卖家生命周期建模、广告起量评估等场景提供标准化的时间基准字段。

本表按地区与本地日期分区存储，各地区依本地时区参数化调度，每日覆盖写入（INSERT OVERWRITE），确保当日分区数据的幂等性与准确性。下游可结合 `grass_date` 分区高效获取特定日期的广告激活快照，支撑广告主首单分析、广告类型渗透率统计等业务指标的计算。

适用场景包括但不限于：广告首次激活日期的标签化打宽、按 `shop_id` / `user_id` 维度统计广告激活分布、以及与其他 DWS/ADS 层表 JOIN 补充广告启动时间维度。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。当前写入值固定为 `'local'`，表示各地区按本地时区对齐日期。查询时须显式指定 `tz_type = 'local'` 以避免全表扫描。 |
| `grass_region` | string | 地区分区，取值为大写国家/地区代码（如 `'MX'`、`'BR'`），由调度参数 `${region}` 参数化写入，覆盖所有已上线地区。 |
| `grass_date` | date | 日期分区，对应数据产出日期（本地时区）。来源于调度参数 `${grass_date}`。⚠️ 该字段为每日全量覆盖写入，使用时须指定具体分区日期，避免跨分区全扫。 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，广告投放的唯一标识。与 `shop_id`、`user_id` 共同构成本表主键。 |
| `shop_id` | bigint | 店铺 ID，广告所属店铺的唯一标识。 |
| `user_id` | bigint | 卖家用户 ID，来源于上游 `seller_id` 字段。 |

### 指标：广告首次激活日期

| 字段 | 类型 | 说明 |
|------|------|------|
| `first_mm_kw_ads_active_date` | date | 手动模式关键词广告（placement=0）的最早生效日期。通过对上游维表中满足 `is_ads_active = 1` 且 `placement = 0` 的记录取 `MIN(grass_date)` 计算得出。⚠️ 该字段为按 `ads_id` + `shop_id` + `user_id` 聚合后的最小值，不代表单条记录的原始日期，跨分区聚合时应再次取 MIN，不可直接 SUM。 |
| `first_sm_kw_ads_active_date` | date | 简单模式关键词广告（placement=4）的最早生效日期。通过对满足 `is_ads_active = 1` 且 `placement = 4` 的记录取 `MIN(grass_date)` 计算得出。⚠️ 同上，跨分区聚合时应再次取 MIN，不可直接 SUM。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，造成资源浪费甚至查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区（当前实际只有 `local`，但未来可能扩展），产生冗余扫描 |
| `grass_region` | `grass_region = '<目标地区大写代码>'`，如 `grass_region = 'MX'` | 扫描全部地区分区，数据量成倍放大 |
| `grass_date` | `grass_date = '<目标日期>'` | 扫描全量历史分区，极易导致查询超时或资源超限 |

**推荐查询模板：**
```sql
SELECT *
FROM mp_paidads.dws_advertise_activeness_1d
WHERE tz_type      = 'local'
  AND grass_region = 'MX'
  AND grass_date   = '2026-04-21';
```

### 不可直接 SUM 的字段

| 字段 | 正确聚合方式 | 说明 |
|------|-------------|------|
| `first_mm_kw_ads_active_date` | `MIN(first_mm_kw_ads_active_date)` | 已为按主键聚合的最早日期，跨记录合并时应取 MIN，直接 SUM 无业务意义且结果错误 |
| `first_sm_kw_ads_active_date` | `MIN(first_sm_kw_ads_active_date)` | 同上 |

### 时效性说明

本表采用每日 **INSERT OVERWRITE** 方式写入当日分区，分区内数据为当日活跃广告的全量快照。

- **查最新状态**：取 `grass_date = CURRENT_DATE - 1`（T+1 产出，当日调度完成后可用）。
- **查历史首次激活日期**：`first_mm_kw_ads_active_date` / `first_sm_kw_ads_active_date` 字段记录的是截至该分区日期时，该广告在上游维表中所有历史记录的最早激活日期，**并非仅当日数据**。若需获取某广告的"历史最早"激活日期，取最新分区即可，无需跨多个 `grass_date` 分区再次聚合。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__${region}_s0_live` | 广告维度表，提供 `ads_id`、`shop_id`、`seller_id`、`placement`、`is_ads_active`、`grass_date` 等核心字段，是本表唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise__${region}_s0_live
  │
  │  过滤条件：
  │    grass_date = '${grass_date}'
  │    is_ads_active = 1
  │
  │  字段派生（CASE WHEN）：
  │    placement=0  → first_mm_kw_ads_active_date = grass_date
  │    placement=4  → first_sm_kw_ads_active_date = grass_date
  │    placement=1000 → first_boost_kw_ads_active_date（源码存在但未写出）
  │
  │  GROUP BY (ads_id, shop_id, seller_id)
  │    MIN(first_mm_kw_ads_active_date)
  │    MIN(first_sm_kw_ads_active_date)
  │
  ▼
dws_advertise_activeness_1d__${region}_s0_live
  PARTITION (tz_type='local', grass_region=upper('${region}'), grass_date='${grass_date}')
  [INSERT OVERWRITE，Hive SQL，每日调度]
```

### 注意事项

1. **`first_boost_kw_ads_active_date` 字段缺失**：ETL 子查询中已计算 `placement = 1000` 对应的 `first_boost_kw_ads_active_date`，但最终 SELECT 及 DDL 字段列表中均未输出该字段，当前表结构不包含此列。下游若有 Boost 模式分析需求，需回溯上游维表自行计算。

2. **INSERT OVERWRITE 覆盖语义**：每次调度对当日分区执行全量覆盖写入，单分区内无重复风险；但**不会回填历史分区**，历史分区一旦产出即固化。

3. **`NULL` 值含义**：当某广告在目标日期从未以特定 placement 类型激活时，对应的 `first_mm_kw_ads_active_date` 或 `first_sm_kw_ads_active_date` 为 `NULL`。下游 JOIN 或过滤时需注意 NULL 处理，避免误丢数据。

4. **地区参数化调度**：`grass_region` 与时区均由调度参数 `${region}`、`${grass_date}` 动态注入，本表覆盖所有已上线地区，各地区按本地时区对齐日期边界，文档中出现的具体地区代码仅为模板示例。

5. **`is_ads_active = 1` 过滤**：仅统计当日处于激活状态的广告，非激活广告不会在当日分区留存记录。若广告在历史某日激活、后续停止，其激活日期记录将保留在历史分区，但不会出现在停止后的最新分区中。

---

*文档生成时间：2026-04-22*