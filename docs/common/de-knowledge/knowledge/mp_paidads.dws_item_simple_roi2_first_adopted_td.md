<!-- ads-workspace-gdoc-sync: gdoc_id=1W-wuAqDgxdVtngJdxdnkVdd2KwdahSf1rMwtuLjx03c gdoc_url=https://docs.google.com/document/d/1W-wuAqDgxdVtngJdxdnkVdd2KwdahSf1rMwtuLjx03c/edit -->

# mp_paidads.dws_item_simple_roi2_first_adopted_td

**分层**：DWS（数据汇总层）
**主键**：`item_id`（在 `tz_type + grass_region + grass_date` 分区内唯一）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1，写入前一业务日数据）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录参与 **Simple ROI2 广告**的商品（Item）首次被采用（first adopted）的日期快照，是 Simple ROI2 投放分析体系中的核心维度表之一。表中每个商品行对应该商品在指定地区的历史最早曝光日期，并标记该商品是否属于从其他计价类型迁移而来的商品（`is_migrated_item`）。

本表采用**增量追加+历史回溯**的设计模式：每日 ETL 将当日新首次出现的曝光商品与前一天历史存量合并，取每个商品历史最小首次采用日期，确保 `item_first_adopted_date` 单调不增、且全量历史不丢失。这使得下游在任意一天的分区中都能读取到截至该天的累计首次采用情况（"截至当日"快照，即 TD — To Date 语义）。

典型使用场景包括：商品 ROI2 广告生命周期分析、新老商品分层报表、迁移商品专项监控，以及与广告绩效表 JOIN 后计算"入场后第 N 天"的表现曲线等。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`（各地区按本地时区参数化调度）。查询时**必须指定**此字段，否则触发全表扫描。⚠️ 当前分区仅写入 `local` 值，直接使用 `tz_type = 'utc'` 将返回空结果。 |
| `grass_region` | string | 地区分区键（大写地区代码，如 `'MX'`、`'BR'`）。查询时**必须指定**，否则跨地区合并导致全表扫描及数据膨胀。 |
| `grass_date` | date | 业务日期分区键，格式 `yyyy-MM-dd`，对应 ETL 写入时的前一业务日（`BIZ_YESTERDAY`）。TD 语义：每个分区存储截至该日的全量首次采用快照。**通常取最新分区**以获得最完整历史。 |

### 维度：商品主键与卖家归属

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，本表主键。ETL 过滤 `item_id > 0` 以排除无效记录。 |
| `shop_id` | bigint | 商品所属店铺 ID，关联自 `mp_item.dim_item__reg_s0_live`。若商品在商品维表中无匹配则为 NULL。 |
| `seller_id` | bigint | 卖家 ID，关联自 `mp_item.dim_item__reg_s0_live`。若商品维表无匹配则为 NULL。 |

### 维度：商品类目

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_global_be_category_id` | bigint | 全球后端一级类目 ID，关联自商品维表。 |
| `level1_global_be_category` | string | 全球后端一级类目名称。 |
| `level2_global_be_category_id` | bigint | 全球后端二级类目 ID，关联自商品维表。 |
| `level2_global_be_category` | string | 全球后端二级类目名称。 |
| `level3_global_be_category_id` | bigint | 全球后端三级类目 ID，关联自商品维表。 |
| `level3_global_be_category` | string | 全球后端三级类目名称。 |

### 指标：商品采用状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_first_adopted_date` | date | 该商品在本地区 Simple ROI2 广告中**最早**产生曝光（`impression_cnt > 0`，且 `placement = 50`）的业务日期。由历史所有分区取 `MIN` 累计得出，具有 TD（截至当日）语义。⚠️ 此字段为历史累计最小值，不可跨地区或跨商品直接聚合；多分区读取时应仅取最新分区，避免重复统计。 |
| `is_migrated_item` | tinyint | 商品是否为迁移商品标记。`1` 表示该商品在同一业务日同时满足：处于激活状态（`is_ads_active = 1`）或有曝光，且计价类型为 `pricing_type IN (3, 4, 8)`（其中 4、8 排除特定 placement）；`0` 表示非迁移商品（含 NULL 被 `COALESCE` 处理为 0）。历史分区中该字段取 `MAX`，即一旦被标记为迁移商品则永久保留。⚠️ 为累计 MAX 标记字段，不可直接 SUM 统计迁移商品数量，需按 `item_id` 去重后计数：`COUNT(DISTINCT CASE WHEN is_migrated_item = 1 THEN item_id END)`。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，导致查询超时并产生巨额计算费用：

```sql
WHERE tz_type      = 'local'                  -- 固定值，当前仅写入 local 分区
  AND grass_region = '<目标地区大写代码>'       -- 例：'MX'、'BR'、'TH'
  AND grass_date   = date('<目标日期>')         -- 建议取最新分区
```

- **`tz_type`**：必须指定为 `'local'`，其他值分区为空。
- **`grass_region`**：必须指定单一地区，跨地区分析需在应用层合并，不建议省略此过滤。
- **`grass_date`**：本表为 TD（截至当日）全量快照，通常**只需取最新一天分区**即可获得全量历史；若取多个分区会导致同一 `item_id` 重复出现，需特别注意去重。

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确用法 |
|------|------|----------|
| `item_first_adopted_date` | TD 累计最小值，多分区读取时同一商品重复出现 | 仅取单一最新分区，或先按 `item_id` 取 `MIN` 去重 |
| `is_migrated_item` | 标记字段，直接 SUM 无业务意义 | 统计迁移商品数：`COUNT(DISTINCT CASE WHEN is_migrated_item = 1 THEN item_id END)` |

### 时效性说明

- 本表具有 **TD（To Date，截至当日）语义**，每日分区存储的是截至该业务日的**全量历史快照**（含当日新增 + 历史存量）。
- 日常查询应取**最新业务日分区**（`grass_date = CURRENT_DATE - 1` 或调度产出后的最新分区），无需读取历史多个分区做 UNION，否则将产生重复的 `item_id` 记录。
- ETL 依赖前两日分区（`PREV_2D`）的历史存量，因此若历史分区缺失（如首次上线），当日快照仅包含当日新增商品。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 来源①：获取当日在 `placement=50` 有曝光（`impression_cnt > 0`）的商品列表，作为当日新增首次采用候选；来源②：判断商品是否满足迁移条件（`is_migrated_item` 标记）|
| `mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live`（自引用） | 读取前两日（`PREV_2D`）历史快照存量，与当日新增合并后取最小首次采用日期，实现 TD 累计 |
| `mp_item.dim_item__reg_s0_live` | 补充商品维度信息：`shop_id`、`seller_id` 及三级全球后端类目信息 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
  │  (placement=50, impression_cnt>0, grass_date=BIZ_YESTERDAY)
  │  → 获取当日新增候选商品 + item_first_adopted_date = BIZ_YESTERDAY
  │
  ├─── LEFT JOIN ─────────────────────────────────────────────────────┐
  │                                                                   │
  │  mp_paidads.ads_advertise_mkt_1d__reg_s0_live                   │
  │  (pricing_type IN(3,4,8), is_ads_active=1 or impression_cnt>0)  │
  │  → 标记 is_migrated_item = 1                                     │
  │                                                                   │
  └─── UNION ALL ──────────────────────────────────────────────────┘
          │
          │  mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live
          │  (grass_date = PREV_2D，历史存量)
          │  → 读取历史 item_first_adopted_date + is_migrated_item
          │
          ▼
    GROUP BY item_id
      → MIN(item_first_adopted_date)   [取历史最早日期]
      → MAX(is_migrated_item)          [曾被标记则永久为1]
          │
          │  LEFT JOIN
          │
          │  mp_item.dim_item__reg_s0_live (grass_date=BIZ_YESTERDAY)
          │  → 补充 shop_id, seller_id, 三级类目
          │
          ▼
dws_item_simple_roi2_first_adopted_td__reg_s0_live
  partition(tz_type='local', grass_region=${upper_region}, grass_date=BIZ_YESTERDAY)
```

### 关键 CTE 说明

本 ETL 未使用显式 CTE（WITH 子句），采用嵌套子查询结构，各逻辑层说明如下：

| 子查询层 | 来源表 | 作用 |
|----------|--------|------|
| 子查询 `a`（内层-当日新增） | `ads_advertise_mkt_1d` | 筛选当日 `placement=50` 且有曝光的商品，赋予 `item_first_adopted_date = BIZ_YESTERDAY` |
| 子查询 `b`（内层-迁移判断） | `ads_advertise_mkt_1d` | 筛选满足迁移条件的商品，标记 `is_migrated_item = 1` |
| UNION ALL 历史分支 | `dws_item_simple_roi2_first_adopted_td`（自引用） | 读取 `PREV_2D` 分区历史存量，提供历史最早日期和迁移状态 |
| 聚合层 `a` | 上述 UNION ALL 结果 | `GROUP BY item_id`，取 `MIN(item_first_adopted_date)`、`MAX(is_migrated_item)` |
| 维度补充 `b` | `dim_item__reg_s0_live` | LEFT JOIN 补充 `shop_id`、`seller_id`、三级类目 |

### 注意事项

1. **自引用累计逻辑**：ETL 读取 `PREV_2D`（前两日）而非 `PREV_1D`（前一日）作为历史基准，这是调度链的设计保证（T 日 ETL 在 T-1 日数据就绪后执行，`PREV_2D` 即为稳定的上一个已完成分区）。若历史分区缺失则当日只有新增记录。

2. **`is_migrated_item` 的语义**：迁移商品需同时满足"广告激活或有曝光"且"计价类型为 ROI 类（3/4/8）、且 4/8 不在特定展位（20、2003、2030）"。历史取 `MAX` 确保一旦被标记为迁移则不可逆，因此该字段反映的是"历史上是否曾满足迁移条件"。

3. **类目信息时效性**：类目信息每日从 `dim_item__reg_s0_live` 的 `BIZ_YESTERDAY` 分区 LEFT JOIN 获取，因此历史 `item_first_adopted_date` 很早的商品，其类目信息反映的是**最新一次 ETL 运行时**的类目归属，而非首次采用时的类目，可能存在类目迁移导致的口径不一致。

4. **双表结构设计**：DDL 中存在两个表定义——带 `__reg_s0_live` 后缀的主表（三分区：`tz_type + grass_region + grass_date`）和带 `__${region}_s0_live` 后缀的地区子表（单分区：`grass_date`，LOCATION 指向主表对应分区目录）。两者物理数据相同，地区子表是主表的分区视图封装，供按地区独立查询使用。

5. **`COALESCE(is_migrated_item, 0)`**：当商品在当日新增但未匹配到迁移条件（`b` 表无记录），LEFT JOIN 结果为 NULL，经 `COALESCE` 处理后写入 `0`，确保字段无 NULL 值。

---

*文档生成时间：2026-04-22*