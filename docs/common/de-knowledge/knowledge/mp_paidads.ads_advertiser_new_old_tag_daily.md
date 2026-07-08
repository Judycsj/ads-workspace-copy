<!-- ads-workspace-gdoc-sync: gdoc_id=1VyZin3GFaFXf-c6KPXj8ZmhuvRVbHFpWKtQl1vCX3eg gdoc_url=https://docs.google.com/document/d/1VyZin3GFaFXf-c6KPXj8ZmhuvRVbHFpWKtQl1vCX3eg/edit -->

# mp_paidads.ads_advertiser_new_old_tag_daily

**分层**：ADS（应用数据服务层）
**主键**：`shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（各地区按本地时区参数化调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是广告主生命周期分层标签日快照表，以店铺（`shop_id`）为粒度，基于近 30 日与近 60 日广告消耗行为，将平台上的每个店铺每日打上生命周期阶段标签（新卖家、潜力卖家、活跃老卖家、短期流失卖家、流失唤回卖家等）。标签体系分三层（L1 / L2 / L3），从粗到细刻画广告主在平台生命周期中的位置与健康状态，是广告运营精细化管理的核心数据基础。

本表的核心使用场景包括：①广告主分层运营与策略制定（如对 `regular_seller_p0` 高价值卖家提供 VIP 服务、对 `short_term_churn_seller` 触发挽留策略）；②广告消耗趋势监控（通过 30d / 60d 消耗对比识别增长、稳定或预流失信号）；③预算触顶分析（`shop_hit_budget_rate`、`valid_budget_tier_30d` 用于识别受预算限制的增长机会）。

作为 ADS 末端表，本表聚合了广告主基础画像、消耗指标、GMV 指标、预算触顶率等多维信息，业务侧和数据产品可直接基于此表做分析报表与策略投放名单生成，无需再回溯多张原始明细表。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型。ETL 固定写入值为 `'local'`（各地区按本地时区调度），查询时**必须**指定此字段以避免全表扫描 |
| `grass_region` | string | 地区编码（大写），如 `'MX'`、`'BR'`，各地区通过参数化调度独立产出 |
| `grass_date` | date | 数据日期（本地时区），即标签的计算基准日，格式 `YYYY-MM-DD` |

### 维度：主键与广告主标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 店铺 ID，主键之一，来源于 `mp_user.dim_shop` 全量店铺维表 |

### 维度：广告主生命周期标签

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `advertiser_lifeycle_type` | string | **L1 标签**：最粗粒度生命周期分类，枚举值：`potential_seller`（潜力卖家，近60日无消耗）、`new_seller`（新卖家，首消耗日在近29日内）、`short_term_churn_seller`（短期流失）、`regular_seller`（活跃老卖家）、`churn_recall_seller`（流失唤回） |
| `advertiser_lifeycle_type_level2` | string | **L2 标签**：在 L1 基础上细分，`regular_seller` 进一步拆分为 `regular_seller_new`（卖家新进入活跃期，首消耗在近30~60日）与 `regular_seller_regular`（首消耗早于60日前的成熟活跃卖家）；其余枚举值与 L1 保持一致 |
| `advertiser_lifeycle_type_level3` | string | **L3 标签**：最细粒度标签，在 L2 基础上按消耗增减趋势细分，枚举值见下方说明。⚠️ 此字段为规则派生字段，含义依赖当日 `grass_date` 参数，跨日比较时需注意口径一致性 |
| `regular_seller_tag` | string | 针对 `regular_seller` 群体的二级运营优先级标签（P0~P4），综合卖家体量（`seller_tier`）、预算利用率分位（`valid_budget_tier_30d`）与预算触顶率（`shop_hit_budget_rate`）计算。非 `regular_seller` 的店铺此字段为 `NULL` |
| `first_expenditure_date` | string | 广告主历史首次产生消耗的日期，来源于 `ads_advertiser_new_old_base_metrics_daily` 的 `ads_first_revenue_date`。⚠️ 存储格式为 string，日期比较时需显式转换（`DATE(first_expenditure_date)`） |

> **L3 标签枚举说明**
> | L3 标签值 | 含义 |
> |-----------|------|
> | `potential_seller_without_gmv` | 近60日无广告消耗且无 GMV |
> | `potential_seller_with_gmv` | 近60日无广告消耗但有 GMV |
> | `new_seller` | 首消耗日在近29日内 |
> | `short_term_churn_seller_new` | 近30日无消耗，30~60日有消耗，且首消耗在30~60日内（新卖家流失） |
> | `short_term_churn_seller_regular` | 近30日无消耗，30~60日有消耗，且首消耗早于60日前（老卖家短期流失） |
> | `regular_seller_new_uplift` | 新进活跃期，近30日日均消耗较前30~60日增长 ≥30% |
> | `regular_seller_new_stable` | 新进活跃期，消耗变化幅度 <30% |
> | `regular_seller_new_pre_churn` | 新进活跃期，近30日日均消耗较前30~60日下降 ≥30% |
> | `regular_seller_regular_uplift` | 成熟活跃期，消耗增长 ≥50% |
> | `regular_seller_regular_stable` | 成熟活跃期，消耗变化幅度 <50% |
> | `regular_seller_regular_pre_churn` | 成熟活跃期，消耗下降 ≥50% |
> | `churn_recall_seller` | 近30日有消耗，30~60日无消耗，且首消耗早于60日前（流失后唤回） |

### 指标：广告消耗

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `expenditure_amt_usd_30d` | double | 近30日（t-29 至 t）广告总消耗，USD |
| `expenditure_amt_usd_60d` | double | 近60日（t-59 至 t）广告总消耗，USD |
| `avg_daily_expenditure_amt_usd_30d` | double | 近30日广告日均消耗（`ads_arpu_30d`），计算方式：`expenditure_amt_usd_30d / 实际消耗天数`。⚠️ 分母为首消耗日至当日的自然天数，并非固定30天；不可对多行直接 SUM，需用分子/分母原始值重新计算 |
| `avg_daily_expenditure_amt_usd_60d` | double | **前30~60日**（t-59 至 t-30）广告日均消耗（`ads_arpu_30_60d`），字段名含"60d"但实为前半段窗口。⚠️ 命名易误导为"60日均值"，实际是 30~60 日区间均值，请注意区分；同样不可直接 SUM |

### 指标：平台大盘 GMV

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `gmv_usd_60d` | double | 过去60天店铺 GMV（USD），来源于 `mp_order.dws_item_gmv_nd`，用于区分有无 GMV 的潜力卖家 |

### 指标：预算触顶与预算分层

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_hit_budget_rate` | double | 近30日店铺预算触顶率，计算方式：近30日内消耗超过计划预算97%的活动数 / 总活动数。⚠️ 为预计算比率，不可直接 SUM，如需汇总应使用上游 `hit_campaign_cnt` / `campaign_cnt` 原始值重新计算 |
| `valid_budget_amt_usd_30d` | double | 近30日有效预算总额（USD），仅统计 `pricing_type` 在 (1,2,11,15,20) 范围内的计划 |
| `valid_budget_tier_30d` | string | 店铺有效预算在同类 `regular_seller` 群体中的分位段标签（`p0`~`p95`，步长5%）。⚠️ 分位计算基于当日全量 `regular_seller` 群体，非 `regular_seller` 店铺此字段为 `NULL`；该分位为相对排名，跨日对比时分组基数可能变化 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下三个分区字段，否则将触发全分区扫描，造成计算资源浪费和性能问题：

```sql
WHERE tz_type = 'local'          -- 当前 ETL 仅写入 local 分区，遗漏将扫描空分区或产生重复
  AND grass_region = 'XX'        -- 指定目标地区（大写），遗漏将跨地区汇总
  AND grass_date = DATE('...')   -- 指定具体日期，遗漏将全量历史扫描
```

- `tz_type`：ETL 写入时固定为 `'local'`，查询时必须显式指定，否则扫描所有时区分区
- `grass_region`：各地区数据独立存储，遗漏将导致跨地区数据混合汇总，口径错误
- `grass_date`：本表为日快照表，遗漏将造成全历史扫描，性能极差

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确做法 |
|------|------|----------|
| `avg_daily_expenditure_amt_usd_30d` | 预计算日均值，分母为动态天数 | 用 `expenditure_amt_usd_30d` 除以实际消耗天数重新计算 |
| `avg_daily_expenditure_amt_usd_60d` | 预计算日均值（30~60日区间），分母为动态天数 | 用上游 `expenditure_amt_usd_30_60d` 除以实际天数重新计算 |
| `shop_hit_budget_rate` | 预计算比率 | 需回溯上游 `ads_campaign_valid_budget_1d` 取 `hit_campaign_cnt` / `campaign_cnt` |
| `valid_budget_tier_30d` | 基于当日 `regular_seller` 群体的分位标签（字符串） | 不可数值聚合，如需排名分析应回溯 `valid_budget_amt_usd_30d` 原始值 |

> 注意：`avg_daily_expenditure_amt_usd_60d` 字段命名含"60d"，但实际含义是**前30~60日区间**的日均消耗，并非近60日均值，使用时务必注意。

### 时效性说明

本表为日快照表，每条记录仅代表 `grass_date` 当日的标签快照。查询最新状态时，应取**最新已产出的 `grass_date` 分区**（通常为 T-1），而非直接使用 `max(grass_date)` 跨分区扫描（建议在业务调度中固定传入日期参数）。`valid_budget_tier_30d` 等分位字段的基数随每日 `regular_seller` 群体变化，跨日对比时分层标准不固定，需注意时效性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertiser_new_old_base_metrics_daily__reg_s0_live` | 提供广告主历史首次消耗日期（`ads_first_revenue_date`） |
| `mp_paidads.dws_advertise_performance_nd__reg_s0_live` | 提供近30日、近60日广告消耗汇总指标（`expenditure_amt_usd_30d`、`expenditure_amt_usd_60d`） |
| `mp_paidads.dws_advertiser_deduction_1d__reg_s0_live` | 提供近60日每日消耗明细，用于计算近30日及30~60日区间内的首消耗日与日均 ARPU |
| `mp_order.dws_item_gmv_nd__reg_s0_live` | 提供近60日店铺 GMV 汇总（`gmv_usd_60d`） |
| `mp_user.dim_shop__reg_s0_live` | 店铺维表，作为 Driver 表确定当日全量店铺范围 |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 提供近30日计划级预算与消耗明细，用于计算预算触顶率（`shop_hit_budget_rate`）和有效预算（`valid_budget_amt_usd_30d`） |
| `mp_paidads.dim_shop_info__reg_s0_live` | 提供卖家体量分层（`seller_tier`），用于 `regular_seller_tag` 优先级计算 |

---

## ETL 逻辑摘要

### 数据流

```
mp_user.dim_shop (全量店铺范围 Driver)
         │
         ├──────────────────────────────────────────────────────────┐
         │                                                          │
         ▼                                                          │
ads_advertiser_new_old_base_metrics_daily                          │
  (ads_first_revenue_date)                                         │
         │                                                          │
dws_advertise_performance_nd                                       │
  (expenditure_amt_usd_30d / 60d)                                  │
         │                                                          │
dws_advertiser_deduction_1d                                        │
  (近60日每日消耗 → 首消耗日 → 日均 ARPU 30d / 30-60d)           │
         │                                                          │
mp_order.dws_item_gmv_nd                                           │
  (gmv_usd_60d)                                                    │
         │                                                          │
         ▼                                                          │
    [CTE: metrics]                                                  │
  (合并消耗、ARPU、GMV)                                             │
         │                                                          │
         ▼                                                          │
    [CTE: tag]                                                      │
  (按规则打 L3 生命周期标签)                                         │
         │                                                          │
         ├── regular_seller (过滤出活跃老卖家子集)                   │
         │         │                                               │
         │   ads_campaign_valid_budget_1d                          │
         │   (近30日计划级预算触顶统计 → hit_budget_ratio)          │
         │         │                                               │
         │   dim_shop_info (seller_tier)  ◄──────────────────────┘
         │         │
         ▼         ▼
    [CTE: regular_seller_tag]
  (PERCENT_RANK 分位 → valid_budget_tier_30d → P0~P4 标签)
         │
         ▼
    [最终 INSERT]
  tag LEFT JOIN regular_seller_tag
  → 生成 L1/L2/L3 标签 + 消耗指标 + GMV + 预算标签
         │
         ▼
ads_advertiser_new_old_tag_daily__reg_s0_live
(partition: tz_type='local' / grass_region / grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `rev` | `ads_advertiser_new_old_base_metrics_daily` | 获取每个店铺的历史首次消耗日期 `ads_first_revenue_date` |
| `rev_nd` | `dws_advertise_performance_nd` | 汇总近30日、近60日广告消耗，计算 30~60日区间消耗（60d - 30d） |
| `arpu` | `dws_advertiser_deduction_1d` | 从每日扣费明细中识别近30日区间与30~60日区间内的首消耗日，用于后续日均 ARPU 计算 |
| `platform_gmv` | `mp_order.dws_item_gmv_nd` | 汇总店铺近60日 GMV |
| `dim_advertiser` | `mp_user.dim_shop` | 获取当日全量店铺范围，作为 LEFT JOIN 基准确保不遗漏任何店铺 |
| `metrics` | 以上所有 CTE | 以 `dim_advertiser` 为驱动，LEFT JOIN 合并所有指标，计算日均 ARPU（30d / 30~60d） |
| `tag` | `metrics` | 基于多条件规则将每个店铺分配 L3 生命周期标签，同时保留消耗指标和 ARPU |
| `hit_budget_ratio` | `ads_campaign_valid_budget_1d` | 统计近30日计划级预算触顶情况，聚合为店铺级触顶率和有效预算总额 |
| `tier` | `dim_shop_info` | 获取店铺体量分层 `seller_tier`（large / medium / small / micro） |
| `regular_seller` | `tag` | 过滤出所有 `regular_seller_*` 标签的店铺子集，作为分位计算的基准群体 |
| `regular_seller_tag` | `regular_seller` + `hit_budget_ratio` + `tier` | 对 regular_seller 群体做 `PERCENT_RANK` 分位计算，结合卖家体量生成 P0~P4 优先级标签及分位区间标签 |

### 注意事项

1. **Driver 表确保全量覆盖**：ETL 以 `dim_shop` 为驱动，所有广告指标均 LEFT JOIN，未有消耗记录的店铺指标默认填充为 0（`COALESCE(..., 0.0)`），因此表中包含当日全量店铺，而非仅有消耗的广告主。

2. **`avg_daily_expenditure_amt_usd_60d` 命名陷阱**：该字段在 ETL 中对应 `ads_arpu_30_60d`，即 **t-59 至 t-30 日区间**的日均消耗，命名中"60d"并非"近60日均值"，而是"60日窗口的前半段"，使用时务必注意区分。

3. **`shop_hit_budget_rate` 仅覆盖 regular_seller**：`hit_budget_ratio` CTE 基于全量店铺计算，但 `regular_seller_tag` 仅对 `regular_seller` 子集关联，非 `regular_seller` 店铺的 `shop_hit_budget_rate`、`valid_budget_amt_usd_30d`、`valid_budget_tier_30d` 均为 `NULL`。

4. **分位计算的相对性**：`valid_budget_tier_30d` 使用 `PERCENT_RANK()` 在**当日 `regular_seller` 群体内**排序，群体规模每日变化，同一店铺在不同日期的分位标签具有可比性有限，跨日趋势分析时需谨慎。

5. **地区参数化调度**：ETL 中出现的 `upper('${region}')`、`'${grass_date}'`、`'${timezone}'` 均为调度参数占位符，各地区独立调度产出，`grass_region` 字段标识具体地区。

6. **`pricing_type = 5` 排除**：预算触顶计算中排除了 `pricing_type = 5` 的计划类型，`valid_budget_amt_usd_30d` 仅统计 `pricing_type in (1,2,11,15,20)` 的有效预算，与广告总消耗口径不完全一致。

---

*文档生成时间：2026-04-22*