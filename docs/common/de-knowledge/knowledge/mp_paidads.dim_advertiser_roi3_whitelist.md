<!-- ads-workspace-gdoc-sync: gdoc_id=16USRf7vBTPv_5rKomXWp4ygTySY8ZXVcMbo5Lz3uaaA gdoc_url=https://docs.google.com/document/d/16USRf7vBTPv_5rKomXWp4ygTySY8ZXVcMbo5Lz3uaaA/edit -->

# mp_paidads.dim_advertiser_roi3_whitelist

**分层**：DIM（维度层 / 白名单快照）
**主键**：`shop_id`（在给定分区 `tz_type + grass_region + grass_date` 下唯一）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度，各地区按本地时区参数化调度
**引用频次**：0（候选表中未被其他表直接引用，为末端 ADS 层维表）

---

## 业务描述

本表记录**广告主 ROI 3.0（roi_three）凭券功能白名单**的累计首次准入日期快照。每个店铺（`shop_id`）对应一条记录，`whitelist_date` 字段存储该店铺**历史上最早满足 ROI 3.0 凭券资质条件**的业务日期，代表该广告主首次被纳入白名单的时间节点。

表的核心价值在于通过"**滚动合并**"机制保证白名单的历史连续性：每日 ETL 将昨日新增满足条件的店铺与前日快照做 `UNION ALL + MIN(whitelist_date)` 合并，确保一旦店铺进入白名单、其最早入选日期永久保留，即使后续某天临时不满足条件也不会丢失历史记录。

该表主要用于：① 判断某广告主是否在某业务日已具备 ROI 3.0 凭券投放资格；② 分析白名单规模随时间的扩张趋势；③ 作为其他报表的维度关联表，过滤或标注 ROI 3.0 资质广告主。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识。当前写入值固定为 `'local'`（各地区本地时区），查询时**必须指定**此字段以避免全分区扫描。⚠️ 若遗漏过滤将读取所有时区分区，目前仅写入 `local` 分区，但仍应显式过滤。 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'`、`'VN'` 等，由调度参数 `${region}` 参数化注入，覆盖所有运营地区。查询时**必须指定**以限定地区范围。 |
| `grass_date` | date | 业务日期分区键，格式 `yyyy-MM-dd`，对应调度参数 `${BIZ_YESTERDAY}`（即调度日前一个自然业务日）。查询时**必须指定**以避免全量历史扫描。 |

### 维度：主键与白名单属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主的唯一标识，主键。ETL 中已过滤 `shop_id > 0`，不含无效值。 |
| `whitelist_date` | date | 该店铺**首次**满足 ROI 3.0 凭券（`is_roi_three_voucher_enabled > 0`）资质的业务日期，通过滚动 `MIN(whitelist_date)` 计算得出，一旦写入不会因后续状态变化而更新。⚠️ 本字段为历史累计最早日期，**不代表当日新增**，如需统计新增白名单店铺须对比相邻两日分区做差集。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发大范围分区扫描，导致性能劣化或计费超标：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描全部时区分区；当前仅 `local` 有数据，遗漏不影响结果但浪费资源 |
| `grass_region` | `grass_region = 'MY'`（按需替换） | 跨地区混合计算，结果无意义 |
| `grass_date` | `grass_date = date('2025-01-01')`（按需替换） | 读取全量历史快照，数据量成倍膨胀 |

**推荐查询模板：**
```sql
SELECT shop_id, whitelist_date
FROM mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live
WHERE tz_type      = 'local'
  AND grass_region = 'MY'           -- 替换为目标地区
  AND grass_date   = '2025-01-01';  -- 替换为目标业务日期
```

### 不可直接 SUM 的字段

本表为**维度白名单快照表**，无数值指标字段，不存在直接 SUM 的场景。

- `whitelist_date` 为日期类型，聚合场景应使用 `MIN()` / `MAX()` / `COUNT(DISTINCT shop_id)` 等，**不可 SUM**。
- 若需统计**当日新增白名单店铺数**，正确做法是对相邻两日分区取差集：
  ```sql
  -- 统计新增白名单店铺
  SELECT COUNT(*) AS new_whitelist_cnt
  FROM (
      SELECT shop_id FROM mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live
      WHERE tz_type = 'local' AND grass_region = 'MY' AND grass_date = '2025-01-02'
  ) t1
  LEFT ANTI JOIN (
      SELECT shop_id FROM mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live
      WHERE tz_type = 'local' AND grass_region = 'MY' AND grass_date = '2025-01-01'
  ) t2 ON t1.shop_id = t2.shop_id;
  ```

### 时效性说明

- 本表为**每日全量覆盖写入（`insert overwrite`）**，`grass_date` 分区对应调度参数 `${BIZ_YESTERDAY}`，即**今日调度写入的是昨日业务数据**。
- ETL 依赖**前日（`${PREV_2D}`，即 `grass_date - 1`）**分区数据做滚动合并，因此若某日调度失败，次日重跑时需确认前日分区数据完整，否则可能导致白名单历史记录部分丢失。
- 查询最新白名单状态时，应取**当前可用的最新 `grass_date` 分区**，而非固定写死日期。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主基础维度表，从中筛选 `is_roi_three_voucher_enabled > 0` 且 `shop_id > 0` 的店铺，作为当日新增白名单候选 |
| `mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live`（自身前日分区） | 滚动合并历史白名单快照，取 `grass_date = ${PREV_2D}` 分区，保留历史最早入选日期 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertiser__reg_s0_live
  (grass_date = BIZ_YESTERDAY, tz_type='local',
   is_roi_three_voucher_enabled > 0, shop_id > 0)
           │
           │  当日满足条件的新候选店铺
           │  whitelist_date = BIZ_YESTERDAY
           ▼
      ┌─────────────────────────────┐
      │        UNION ALL            │
      └─────────────────────────────┘
           ▲
           │  历史白名单快照
           │  whitelist_date = 历史最早入选日
mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live
  (grass_date = PREV_2D, tz_type='local')
           │
           ▼
      GROUP BY shop_id
      MIN(whitelist_date)   ← 取历史与当日中更早的日期
           │
           ▼
dim_advertiser_roi3_whitelist__reg_s0_live
  partition(tz_type='local', grass_region, grass_date=BIZ_YESTERDAY)
  [INSERT OVERWRITE]
           │
           ▼
  dim_advertiser_roi3_whitelist__${region}_s0_live
  [CREATE OR REPLACE VIEW，按地区过滤]
```

### 关键 CTE 说明

本 ETL 无显式 CTE，采用内联子查询结构：

| 子查询层 | 来源表 | 作用 |
|----------|--------|------|
| 内层 UNION ALL 左支 | `mp_paidads.dim_advertiser__reg_s0_live` | 获取当日（`BIZ_YESTERDAY`）新满足 ROI 3.0 凭券条件的店铺，赋予 `whitelist_date = BIZ_YESTERDAY` |
| 内层 UNION ALL 右支 | `mp_paidads.dim_advertiser_roi3_whitelist__reg_s0_live`（自身） | 读取前日（`PREV_2D`）历史白名单快照，保留已有的 `whitelist_date` |
| 外层聚合 | 上述 UNION ALL 结果 | `GROUP BY shop_id` + `MIN(whitelist_date)`，确保每个店铺只保留最早入选日期 |

### 注意事项

1. **滚动快照机制**：本表采用"当日新增 UNION 前日快照 + MIN 聚合"的滚动写入模式，而非从头全量重算。这意味着：
   - 白名单具有**单调递增**特性——一旦入选，历史记录永久保留，即使广告主当日失去资质也不会从快照中消失。
   - 若某地区某日调度缺失，**不可简单重跑当日**，需先确认 `PREV_2D` 分区数据完整，否则历史白名单数据将断链丢失。

2. **`PREV_2D` 依赖关系**：ETL 依赖的是**前两天**（`grass_date - 1`）分区，而非昨日（`grass_date`）分区自身，这是为了避免写入时读取同名分区产生的数据竞争问题。在评估数据依赖链时需注意此偏移量。

3. **`is_roi_three_voucher_enabled` 字段口径**：资质判断条件为 `> 0`（非零即真），来源于上游 `dim_advertiser` 表，具体字段的业务含义和更新频率需参考该表文档。

4. **地区视图**：ETL 末尾为每个地区创建了形如 `dim_advertiser_roi3_whitelist__${region}_s0_live` 的视图，本质是对主表的 `grass_region` 过滤封装，业务方也可直接使用视图而无需手动添加地区过滤条件。

5. **`tz_type` 当前仅写入 `local`**：ETL 中 `insert overwrite` 硬编码了 `tz_type = 'local'`，暂无 UTC 或其他时区分区写入，查询时固定使用 `tz_type = 'local'` 即可。

---

*文档生成时间：2026-04-22*