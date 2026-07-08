<!-- ads-workspace-gdoc-sync: gdoc_id=1naPz98l_eI5qaF2rrh4hHYrc46YkNenP79MItww8CeE gdoc_url=https://docs.google.com/document/d/1naPz98l_eI5qaF2rrh4hHYrc46YkNenP79MItww8CeE/edit -->

# mp_paidads.dim_advertiser_escrow_whitelist

**分层**：DIM（维度层）
**主键**：`shop_id`（在给定分区内唯一）
**分区**：`grass_region`（地区）/ `grass_date`（业务日期）
**更新频率**：每日全量刷新（T+1）
**引用频次**：0（末端 ADS 层维表，未被其他候选表直接引用）

---

## 业务描述

本表记录各地区**广告担保交易（Escrow）白名单**商家的准入信息，核心字段为商家 ID（`shop_id`）及其最早进入白名单的日期（`whitelist_date`）。白名单准入资格来源于 Seller Feature Toggle 系统中 `ads_atu_escrow` 功能键的开启状态，只有功能状态为"启用（`feature_status = 1`）"且标签映射关系有效（`feature_toggle_tag_mapping_status != 3`）的商家才会被纳入。

本表的典型使用场景包括：判断某商家是否具备投放担保广告的资格、分析白名单商家的准入时间分布、结合广告投放数据评估担保广告功能的覆盖范围与增长趋势，以及在广告业务规则校验中用作资格过滤维表。

本表采用**增量累积**策略：每次调度时将前一天历史快照与当日最新 Feature Toggle 数据合并，取每个商家最早的白名单日期（`MIN(whitelist_date)`），确保白名单准入时间的历史可追溯性不丢失。各地区按本地时区参数化调度，全量覆盖所有运营地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区代码，大写，如 `ID`、`TH`、`MY` 等。每次查询必须指定，否则触发全分区扫描 ⚠️ 分区裁剪字段，遗漏将导致全表扫描，查询成本极高 |
| `grass_date` | date | 业务日期（昨日，即调度的 `BIZ_YESTERDAY`）。每次查询建议指定最新分区，避免重复计算历史累积数据 ⚠️ 分区裁剪字段，遗漏将导致全表扫描 |

### 维度：商家白名单信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 商家 ID，白名单维表在单个 `(grass_region, grass_date)` 分区内唯一标识一个商家 |
| `whitelist_date` | date | 商家**最早**进入担保广告白名单的日期（按所在地区本地时区换算）。由历史累积快照与当日新增数据取 `MIN` 计算得出 ⚠️ 为历史累积最小值，直接对多分区聚合时会产生重复计算，应仅取最新分区的值 |

---

## 查询使用须知

> 本表为维度维表，常见用法为关联过滤或资格判断，以下为 SQL 生成者须知。

### 必须包含的过滤条件

每次查询**必须同时指定**以下两个分区条件，否则将触发全分区扫描，造成严重资源浪费：

```sql
WHERE grass_region = 'XX'          -- 替换为目标地区大写代码，如 'ID'、'TH'
  AND grass_date = '${BIZ_DATE}'   -- 推荐取最新业务日期（T-1），如 '2026-04-21'
```

**遗漏后果**：本表按地区×日期双分区存储，历史每日均保留一份累积快照，缺少分区过滤将扫描所有历史分区的全量数据，查询成本随历史深度线性增长。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确做法 |
|------|----------|----------|
| `whitelist_date` | 该字段为历史累积 `MIN` 值，跨多个 `grass_date` 分区聚合时同一商家会重复出现 | 仅在**单个最新 `grass_date` 分区**内使用，不跨分区 `GROUP BY` 或聚合 |

### 时效性说明

本表每日 T+1 刷新，最新可用分区为 **`grass_date = BIZ_YESTERDAY`**（即调度当日的前一个业务日期）。

- **查询当前白名单成员**：始终取最新 `grass_date` 分区，该分区已包含截至该日期为止的所有历史累积白名单商家。
- **查询商家何时加入白名单**：在最新分区中直接读取 `whitelist_date` 字段即可，无需扫描历史分区，因为历史数据已通过累积策略合并至最新分区。
- **不建议跨多个 `grass_date` 分区联合查询**，除非有明确的历史时点还原需求。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertiser_escrow_whitelist__reg_s0_live`（前日分区 `PREV_2D`） | 历史累积白名单快照，作为存量基础数据滚动继承 |
| `marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df` | Feature Toggle 功能配置表，筛选功能键 `ads_atu_escrow` 且状态为启用（`feature_status = 1`）的记录，获取 `feature_id` |
| `marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df` | Feature Toggle 与标签的映射关系表，排除已删除映射（`feature_toggle_tag_mapping_status != 3`），获取 `tag_id` 及创建时间 `ctime` |
| `marketplace.shopee_seller_shop_tag_mapping_latam_${region}_db__shop_tag_mapping_tab__reg_continuous_s0_live` | 商家与标签的映射关系表，筛选有效映射（`shop_tag_mapping_status = 1`），获取 `shop_id` |

---

## ETL 逻辑摘要

### 数据流

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  每日调度（各地区按本地时区参数化，grass_date = BIZ_YESTERDAY）              │
└─────────────────────────────────────────────────────────────────────────────┘

【存量数据（历史累积）】
dim_advertiser_escrow_whitelist__reg_s0_live
  grass_date = PREV_2D（前天分区）
  ─────────────────────────────────────────
  shop_id, whitelist_date（历史最小值）
                    │
                    │ UNION ALL
                    │
【增量数据（当日新增/在线商家）】
feature_toggle_info_tab                  ──┐
  feature_key = 'ads_atu_escrow'           │
  feature_status = 1                       │ INNER JOIN on feature_id
  → 获取 feature_id                        │
                                         feature_toggle_tag_mapping_tab ──┐
                                           feature_toggle_tag_mapping      │ INNER JOIN on tag_id
                                           _status != 3                    │
                                           → 获取 tag_id, ctime            │
                                                                    shop_tag_mapping_tab
                                                                      shop_tag_mapping_status = 1
                                                                      region = UPPER('${region}')
                                                                      → 获取 shop_id
                                                                           │
                                           ctime（SGT）→ 按本地时区转换
                                           → whitelist_date（本地日期）
                    │
                    ▼
          ┌─────────────────────┐
          │  UNION ALL 合并      │
          │  GROUP BY shop_id   │
          │  MIN(whitelist_date)│  ← 取历史最早入白名单日期
          └─────────────────────┘
                    │
                    ▼
  dim_advertiser_escrow_whitelist__reg_s0_live
  PARTITION (grass_region = UPPER('${region}'), grass_date = BIZ_YESTERDAY)
  INSERT OVERWRITE（全量覆盖当日分区）
```

### 关键 CTE 说明

本 ETL 未使用命名 CTE，采用子查询嵌套方式，核心逻辑层次如下：

| 逻辑层 | 来源表 | 作用 |
|--------|--------|------|
| 子查询 `a` | `feature_toggle_info_tab` | 筛选功能键 `ads_atu_escrow` 且状态启用的记录，输出 `feature_id` |
| 子查询 `b` | `feature_toggle_tag_mapping_tab` | 关联有效的功能-标签映射，输出 `tag_id` 和创建时间 `ctime`（新加坡时间） |
| 子查询 `c` | `shop_tag_mapping_tab` | 关联有效的商家-标签映射，输出 `shop_id` |
| 外层子查询（增量分支） | `a` JOIN `b` JOIN `c` | 三表关联后，将 `ctime`（SGT）转换为本地时区日期，生成 `whitelist_date` |
| 历史分支 | `dim_advertiser_escrow_whitelist__reg_s0_live`（PREV_2D） | 继承前日累积白名单存量 |
| 最终聚合 | UNION ALL 结果 | `GROUP BY shop_id`，`MIN(whitelist_date)` 取最早入白名单日期 |

### 注意事项

1. **累积快照策略**：本表采用"历史快照滚动继承 + 当日增量合并"模式。每日调度时读取 `PREV_2D`（前天）分区作为存量，与当日最新 Feature Toggle 状态合并后写入 `BIZ_YESTERDAY` 分区。这意味着最新分区天然包含所有历史累积白名单商家，**无需扫描历史分区**即可获取完整白名单。

2. **时区转换口径**：`whitelist_date` 由 Feature Toggle 记录的创建时间 `ctime`（存储为新加坡时间 SGT）经由 `from_utc_timestamp(..., '${timezone}')` 转换为**各地区本地时区**后取日期部分，确保准入日期与本地业务日历一致。各地区时区参数由调度系统注入，非固定值。

3. **白名单退出不回滚**：当前 ETL 逻辑中，历史存量数据通过 UNION ALL 无条件继承，即使商家在 Feature Toggle 系统中被移除（`feature_toggle_tag_mapping_status = 3` 或 `feature_status != 1`），**其历史白名单记录仍会保留在最新分区中**。若需判断商家当前是否仍具备白名单资格，需结合 Feature Toggle 源表的当前状态另行校验。

4. **分区依赖**：ETL 读取 `PREV_2D` 而非 `YESTERDAY` 作为历史基准，是为保留一天的容错窗口。若某日调度失败，重跑时 `PREV_2D` 分区仍为有效状态，避免累积数据断链。

5. **`shop_tag_mapping` 表去重**：子查询 `c` 对 `shop_id, tag_id` 执行 `GROUP BY`，排除同一商家同一标签的重复映射关系，确保后续 JOIN 不产生数据膨胀。

---

*文档生成时间：2026-04-22*