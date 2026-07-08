<!-- ads-workspace-gdoc-sync: gdoc_id=1qXNppz-CQGhOxGLEtPPFIlyzA1jXveV6QKFL4h_Qim8 gdoc_url=https://docs.google.com/document/d/1qXNppz-CQGhOxGLEtPPFIlyzA1jXveV6QKFL4h_Qim8/edit -->

# mp_paidads.ads_simple_roi2_npb_item_hi

**分层**：ADS（应用数据层）
**主键**：`item_id`
**分区**：`tz_type` / `grass_region` / `grass_date` / `h`
**更新频率**：小时级（每小时覆盖写入）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表为**新品竞价（NPB）商品小时级 ROI 简单评估宽表**，以商品（`item_id`）为粒度，记录每个商品自上架以来截至当前调度小时的累计订单数、订单生产速率，以及近期曝光/点击汇总数据。核心价值在于为付费广告投放的 ROI 快速评估提供商品维度的小时级数据支撑，支持对新品投放效果进行高频监控与实时决策。

本表覆盖各地区市场，各地区按本地时区参数化调度，确保 `grass_date` 与 `h` 均以本地时区为准。商品订单统计口径为：商品上架时间起至调度时刻，**20 天内**产生的有效订单（含实时订单与离线订单拼接）；曝光与点击数来自近 10 天的预聚合数据。

典型使用场景包括：① 广告优化引擎评估新品当前 ROI 是否达标；② 实时看板监控各商品订单增速（`platform_order_avg`）；③ 下游 ADS 层拼接广告主的出价与预算数据，进行 ROI 决策。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定值为 `'local'`，表示日期与小时均以各地区本地时区为准。查询时**必须**指定此字段以避免全分区扫描 |
| `grass_region` | string | 地区编码（如 `MY`、`TH`、`VN` 等），各地区独立调度写入 |
| `grass_date` | date | 业务日期（本地时区），格式 `YYYY-MM-DD` |
| `h` | tinyint | 业务小时（本地时区，0–23），与 `grass_date` 共同确定数据快照时刻 |

---

### 维度：主键与商品属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，主键（pk@item_id）；来源于商品维表，`status = 1` 的有效在售商品 |
| `create_datetime` | string | 商品上架时间（本地时区，字符串格式）；是计算订单时效窗口（20天）与 `create_day_cnt` 的基准时间。⚠️ 为字符串类型，按时间过滤时须显式转换，避免隐式比较错误 |
| `create_timestamp` | bigint | 商品上架时间的 Unix 时间戳（秒级），与 `create_datetime` 一一对应，可直接用于时间差计算 |

---

### 指标：订单累计与速率

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_order_acc` | bigint | 商品上架后 20 天内、截至当前调度时刻的累计去重订单数（`count(distinct order_id)`），订单状态包含有效状态码（1,2,4,6–16） |
| `create_day_cnt` | double | 从商品上架时刻到当前调度时刻的天数（精确到小数点后4位），计算公式：`(当前调度时刻 unix_timestamp - create_datetime unix_timestamp) / 86400`。⚠️ 为派生计算值，不可直接 SUM；若需跨商品汇总，应重新基于时间戳差值计算 |
| `platform_order_avg` | double | 商品平均每天产生的订单数，计算公式：`platform_order_acc / create_day_cnt`。⚠️ 为预计算比率，不可直接 SUM；多商品汇总时应用 `SUM(platform_order_acc) / SUM(create_day_cnt)` 重新计算 |

---

### 指标：平台大盘曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_impression_acc` | bigint | 商品近 10 天的平台累计曝光次数，来源于 `dws_item_simple_roi2_npb_created_nd`，原字段为 `platform_impression_cnt_10d`；若上游无数据则补 0。⚠️ 统计口径为近 10 天滚动窗口，非商品全生命周期累计，与 `platform_order_acc` 的 20 天窗口不对齐，两者不可混合计算 ROI 比率 |
| `platform_click_acc` | bigint | 商品近 10 天的平台累计点击次数，来源同上，原字段为 `platform_click_cnt_10d`；若上游无数据则补 0。⚠️ 同 `platform_impression_acc`，为近 10 天滚动窗口，口径说明同上 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下分区字段，否则将触发全表扫描，造成大量资源浪费：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `'local'` 一个值，但不指定会导致分区裁剪失效 |
| `grass_region` | `grass_region = 'XX'` | 按目标地区指定，避免跨地区全量扫描 |
| `grass_date` | `grass_date = '2026-04-22'` | 指定目标业务日期；查询最新快照时取最新分区日期 |
| `h` | `h = 最新小时值` | 每小时覆盖写入，同一 `grass_date` 下存在多个小时分区；若需当天最新数据，应取 `max(h)` 所对应分区 |

> ⚠️ 遗漏 `grass_date` 或 `h` 将导致读取当天所有小时的重复快照数据，造成指标严重重复计算。

---

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `create_day_cnt` | 预计算的时间跨度（天数），各商品值独立，直接 SUM 无业务含义 | 跨商品分析时，用 `(unix_timestamp(当前时刻) - unix_timestamp(create_datetime)) / 86400` 重新计算 |
| `platform_order_avg` | 预计算比率（订单数/天数），直接 SUM 会产生错误的平均值 | 多商品汇总时用 `SUM(platform_order_acc) / SUM(create_day_cnt)` 重新计算 |
| `platform_impression_acc` | 统计窗口为近 10 天滚动，与订单 20 天窗口不对齐 | 与 `platform_order_acc` 混合使用时需注意口径差异，不可直接相除计算 CTR-to-Order 类指标 |
| `platform_click_acc` | 同 `platform_impression_acc` | 同上 |

---

### 时效性说明

- 本表为**小时级快照表**，每小时覆盖写入当前小时分区（`grass_date` + `h`）。
- 查询当天最新数据时，应先确认 `max(h)` 分区已产出，再以该分区值过滤，例如：
  ```sql
  WHERE tz_type = 'local'
    AND grass_region = 'MY'
    AND grass_date = current_date()
    AND h = (SELECT max(h) FROM ads_simple_roi2_npb_item_hi__reg_s0_live
             WHERE tz_type = 'local' AND grass_region = 'MY' AND grass_date = current_date())
  ```
- 订单数据由**实时订单（近 5 天）+ 离线订单（`ads_simple_roi2_npb_item_last_order_di`）**拼接而成，实时部分存在一定的数据延迟，历史区间依赖离线 T-1 快照，最新当日数据以实时为准。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_item.rt_dim_item__reg_s0_live` | 商品维表，提供 `item_id`、`create_datetime`、`create_timestamp` 等商品基础属性；过滤 `status = 1` 的在售商品，并限制上架时间在调度时刻前 20 天内 |
| `mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live` | 实时订单明细表，提供近 5 天内的实时订单数据（`order_id`、`item_id`、`create_datetime`），过滤有效订单状态码 |
| `mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp` | 离线历史订单快照表，补充 5 天以前的订单数据，与实时订单 `UNION ALL` 形成完整订单集合 |
| `mp_paidads.dws_item_simple_roi2_npb_created_nd__reg_s0_live` | 商品近 10 天曝光/点击预聚合 DWS 表，提供 `platform_impression_cnt_10d` 和 `platform_click_cnt_10d` |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.rt_dim_item__reg_s0_live
  (status=1, 上架时间在调度时刻20天内)
            │
            │ item 基础信息
            ▼
     ┌─────────────┐          mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live
     │  item_order  │◄─────── (实时订单, 近5天, 有效状态码)
     │     CTE      │         UNION ALL
     │              │◄─────── mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp
     └──────┬───────┘         (离线历史订单快照)
            │ item_id + 订单聚合指标
            │
            ▼
     ┌─────────────┐          mp_paidads.dws_item_simple_roi2_npb_created_nd__reg_s0_live
     │   item_imp  │◄─────── (近10天曝光/点击预聚合)
     │     CTE      │
     └──────┬───────┘
            │ item_id + 曝光/点击指标
            │
     LEFT JOIN on item_id
            │
            ▼
ads_simple_roi2_npb_item_hi__reg_s0_live
  (INSERT OVERWRITE, 分区: tz_type/grass_region/grass_date/h)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `item_order` | `mp_item.rt_dim_item__reg_s0_live` + `mp_order.rt_dwd_order_item_all_ent_rf__reg_s0_live` + `mp_paidads.ads_simple_roi2_npb_item_last_order_di__reg_s0_temp` | 以商品为粒度，左关联实时+离线订单（20天窗口内），聚合计算 `platform_order_acc`（累计订单数）、`create_day_cnt`（上架天数）、`platform_order_avg`（日均订单速率） |
| `item_imp` | `mp_paidads.dws_item_simple_roi2_npb_created_nd__reg_s0_live` | 拉取当日指定地区的商品近 10 天曝光/点击预聚合数据 |

### 注意事项

1. **订单窗口口径**：订单时效限制为商品上架后 **20 天内**（`UNIX_TIMESTAMP(o.create_datetime) <= UNIX_TIMESTAMP(item.create_datetime) + 1728000`），超出窗口的订单不计入 `platform_order_acc`，需注意与其他订单口径的差异。

2. **实时与离线订单拼接**：订单数据由两段拼接而成——实时表覆盖近 5 天（`date(create_datetime) >= date_sub(调度时刻_local, 5)`），离线表覆盖更早历史。两段存在一定的时间重叠风险，已由 `count(distinct order_id)` 去重保障。

3. **曝光/点击与订单窗口不一致**：`platform_impression_acc` 和 `platform_click_acc` 统计窗口为近 **10 天**，而 `platform_order_acc` 为 **20 天**，两者直接相除计算 ROI 类比率时口径不对齐，需在业务层额外处理。

4. **覆盖写入**：采用 `INSERT OVERWRITE` 按分区覆盖写入，每小时完整刷新当前小时分区数据，同一 `(grass_date, h)` 分区的历史数据会被完全替换，不存在追加重复问题。

5. **参数化调度**：ETL 中 `${BIZ_DT}`、`${BIZ_H}`、`${grass_region}`、`${timezone}`、`${grass_date}` 均为调度参数，各地区按本地时区独立调度，文档中所见的地区代码与时区仅为调度模板实例，本表覆盖所有已开通地区。

---

*文档生成时间：2026-04-22*