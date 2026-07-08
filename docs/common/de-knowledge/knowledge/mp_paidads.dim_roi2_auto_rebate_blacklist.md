<!-- ads-workspace-gdoc-sync: gdoc_id=1VG5-2GjmBrTapTs4iZ4buTisoNvemUIpBumlFe1814o gdoc_url=https://docs.google.com/document/d/1VG5-2GjmBrTapTs4iZ4buTisoNvemUIpBumlFe1814o/edit -->

# mp_paidads.dim_roi2_auto_rebate_blacklist

**分层**：DIM（维度层）
**主键**：`shop_id`
**分区**：`grass_region` / `grass_date`
**更新频率**：每日调度（T+1，覆盖前一业务日数据）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表为 ROI 自动返利（Auto Rebate）功能的店铺黑名单维表，记录被打上 `1P_SIP` 标签的店铺信息。当某店铺满足特定条件（即被平台标记为 SIP 一方店铺）时，将被纳入黑名单，从而在自动返利计算逻辑中被排除或作特殊处理，确保返利策略不被滥用或误发。

本表的核心价值在于为下游 ROI 自动返利相关报表与调度任务提供可靠的店铺黑名单过滤依据。下游任务在执行返利资格判断、返利金额计算等逻辑时，通过关联本表来剔除不符合条件的店铺，保障返利发放的准确性与合规性。

各地区通过参数化调度（`${region}`、`${BIZ_YESTERDAY}`）独立写入各自分区，各地区按本地时区参数化调度，全量覆盖所有运营地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识，大写字母，如 `MY`、`TH`、`VN` 等；按地区分区存储，查询时必须指定以避免全表扫描 |
| `grass_date` | date | 业务日期分区，对应 ETL 调度的前一业务日（`BIZ_YESTERDAY`）；查询时必须指定具体日期 |

### 维度：主键与黑名单属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，来源为 `mp_seller.dim_seller_tag_entity__reg_live` 中的 `entity_id`，为本表的业务主键 |
| `blacklist_date` | date | 店铺被纳入黑名单的日期，取自标签记录的 `create_datetime` 截断到日期精度，反映该店铺最早被打上 `1P_SIP` 标签的时间 ⚠️ 该字段为标签创建日期，不等于当前分区的 `grass_date`，使用时需注意区分"黑名单生效日"与"数据分区日" |

---

## 查询使用须知

**必须包含的过滤条件**

每次查询必须同时指定 `grass_region` 和 `grass_date` 两个分区字段，否则将触发全表全分区扫描，导致查询性能严重下降并产生不必要的计算成本。推荐写法：

```sql
WHERE grass_region = 'MY'
  AND grass_date = '2026-04-21'
```

`grass_region` 取值为大写地区代码，需与业务地区保持一致；`grass_date` 一般取最新业务日（T-1）。

**不可直接 SUM 的字段**

本表为纯维度/黑名单表，不包含度量类字段，无需聚合计算。通常以 `shop_id` 作为过滤键与事实表 JOIN 使用，而非直接聚合。

**时效性说明**

本表每日 T+1 写入，分区 `grass_date` 对应前一业务日数据。若需获取最新黑名单状态，应使用最新的 `grass_date` 分区；历史分区保留各日期快照，可用于追溯某一日期的黑名单状态。注意：`blacklist_date` 早于 `grass_date` 的记录表示该店铺为历史老黑名单，在标签有效（`is_valid=1`）的前提下仍会出现在当日分区中。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_seller.dim_seller_tag_entity__reg_live` | 店铺标签明细表；通过筛选 `tag_name = '1P_SIP'`、`entity_type = 'ENTITY_TYPE_SHOP'`、`is_valid = 1` 获取当日有效的 SIP 黑名单店铺及其标签创建时间 |

---

## ETL 逻辑摘要

### 数据流

```
mp_seller.dim_seller_tag_entity__reg_live
    │
    │  过滤条件：
    │    grass_region = UPPER('${region}')
    │    grass_date   = date('${BIZ_YESTERDAY}')
    │    is_valid     = 1
    │    entity_type  = 'ENTITY_TYPE_SHOP'
    │    tag_name     = '1P_SIP'
    │
    ▼
  字段映射：
    entity_id        → shop_id
    date(create_datetime) → blacklist_date
    UPPER('${region}')   → grass_region  [分区]
    date('${BIZ_YESTERDAY}') → grass_date [分区]
    │
    ▼
mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live
（INSERT OVERWRITE，按 grass_region / grass_date 分区写入）
```

### 注意事项

1. **黑名单判定标准**：上游仅过滤 `tag_name = '1P_SIP'` 且 `is_valid = 1` 的有效标签记录，标签失效（`is_valid = 0`）的店铺不会出现在本表中，即本表始终反映当日有效黑名单。
2. **覆写语义**：ETL 采用 `INSERT OVERWRITE` 按分区写入，每次调度仅覆盖当日分区（`grass_date = BIZ_YESTERDAY`），历史分区不受影响，支持按日期追溯。
3. **`blacklist_date` 与 `grass_date` 的区别**：`blacklist_date` 是店铺标签的创建日期（即最早入黑名单的时间），`grass_date` 是数据写入的业务分区日期，两者可能相差较大，下游关联时切勿混淆。
4. **参数化调度**：`${region}` 和 `${BIZ_YESTERDAY}` 为调度模板参数，由平台在各地区、各日期独立注入，表结构本身不限定地区范围。

---

*文档生成时间：2026-04-22*