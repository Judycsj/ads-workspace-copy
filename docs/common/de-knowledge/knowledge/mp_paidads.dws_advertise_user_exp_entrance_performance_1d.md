<!-- ads-workspace-gdoc-sync: gdoc_id=1qKJgbouuptr--nqbfmsur_M8s_M2Ro-2nD_BHzjTbng gdoc_url=https://docs.google.com/document/d/1qKJgbouuptr--nqbfmsur_M8s_M2Ro-2nD_BHzjTbng/edit -->

# mp_paidads.dws_advertise_user_exp_entrance_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`group_id` + `entrance` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表记录广告系统中**用户实验分组（A/B Test）维度**下，各广告入口的付费广告与自然流量的每日绩效数据。核心使用场景为：评估不同实验分组在 Search（搜索）、Daily Discover（首页发现）、YMAL（You May Also Like，猜你喜欢）三个主要广告入口上的广告曝光、点击、成单、GMV 等关键指标，以支持广告策略实验的效果对比与决策。

表中数据将付费广告指标（`ads_*`）与对应入口的自然流量指标（`organic_*`）并列呈现，便于实验分析师在同一分组、同一入口维度下，同时观察广告干预对自然流量的影响，从而进行全量流量（付费 + 自然）维度的实验评估，避免仅看广告归因而遗漏自然流量的替代效应。

本表是广告 A/B 实验效果分析的核心数据源，支撑广告算法团队和商业化分析团队进行实验 SRM 检测、指标显著性分析及多入口横向对比，具有较高的业务价值。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前写入值固定为 `'local'`（本地时区）。各地区按本地时区参数化调度。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 国家/地区代码，大写，如 `'MX'`、`'BR'`。各地区独立调度写入。⚠️ 查询时应明确指定，避免跨地区全扫描 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD`。⚠️ 查询时必须指定，避免全表扫描 |

### 维度：实验分组与广告入口

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_id` | bigint | 用户实验分组 ID（A/B Test 实验组 ID），来源于 `srdi_mart.dim_sr_data_warehouse_abtest_user_group.exp_group_id`。Search 入口使用 `is_assignment_log = 1` 的分组，DD / YMAL 入口使用 `is_dim_join = 1` 的分组 |
| `entrance` | string | 广告入口名称，枚举值：`'search'`（搜索页）、`'dd'`（Daily Discover，首页发现）、`'ymal'`（You May Also Like，猜你喜欢）。由原始整型码（1/3/4）转换而来 |

### 指标：付费广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt` | bigint | 付费广告曝光次数，来源于 `dwd_advertise_performance_di__reg_s0_live.impression_cnt`，已按实验分组聚合 |
| `ads_clk_cnt` | bigint | 付费广告点击次数，来源于 `dwd_advertise_performance_di__reg_s0_live.click_cnt`，已按实验分组聚合 |
| `ads_order_cnt` | bigint | 付费广告直接带来的成单数（归因订单数），来源于 `dwd_advertise_performance_di__reg_s0_live.order_cnt`，已按实验分组聚合 |
| `ads_gmv_usd` | decimal(25,10) | 付费广告直接带来的成单 GMV（美元），由本地货币金额（`ads_order_gmv_local`）除以当日汇率转换而来。⚠️ 已完成货币换算，跨地区汇总时须注意汇率来源一致性；为已聚合值，跨分区不可直接 SUM（相同 group_id + entrance 不会跨分区重复，但需确认分区完整性） |
| `ads_revenue_usd` | decimal(25,10) | 付费广告收入（广告主消耗金额，美元），由本地货币消耗额（`expenditure_amt_local`）除以当日汇率转换而来。⚠️ 已完成货币换算，含义为广告消耗/花费（spend），并非平台收入利润；跨地区汇总须注意汇率统一性 |

### 指标：自然流量绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `organic_imp_cnt` | bigint | 自然流量曝光次数，来源于 `traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live`，按实验分组聚合。Search 入口对应 `item_impr_organic_cnt_1d`；DD/YMAL 对应 `impr_organic_cnt_1d`。⚠️ ads 与 organic 数据的分组关联方式不同（Search 用 assignment log，DD/YMAL 用 dim join），跨入口对比时需注意口径差异 |
| `organic_clk_cnt` | bigint | 自然流量点击次数，来源同上。Search 对应 `item_click_organic_cnt_1d`；DD/YMAL 对应 `click_organic_cnt_1d` |
| `organic_order_cnt` | bigint | 自然流量成单数，来源同上，对应 `order_organic_1d` |
| `organic_gmv_usd` | decimal(25,10) | 自然流量 GMV（美元），来源同上，对应 `gmv_usd_organic_1d`。⚠️ 该字段来源表中已为 USD 单位，无需再换算；与 `ads_gmv_usd` 的换算方式不同，跨字段汇总时应注意单位一致性 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，导致查询超时或产生大量不必要的计算费用：

```sql
WHERE tz_type      = 'local'           -- 当前仅写入 local，必须指定
  AND grass_region = 'XX'              -- 替换为目标地区代码，如 'MX'、'BR'
  AND grass_date   = '2026-04-21'      -- 替换为目标日期
```

- `tz_type`：ETL 固定写入 `'local'`，遗漏此条件将造成无效全分区扫描。
- `grass_region`：各地区数据独立写入，遗漏将导致跨地区重复聚合。
- `grass_date`：日级分区，遗漏将扫描全量历史数据。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确处理方式 |
|------|----------|--------------|
| `ads_gmv_usd` | 已由本地货币按当日汇率换算为 USD，跨地区、跨日期聚合时汇率基准不同 | 跨地区汇总时应在同一汇率口径下重新核查，或直接 SUM 同一地区同一日期的值 |
| `ads_revenue_usd` | 同上，本地消耗额除以汇率所得，跨地区混合 SUM 含义明确但需确认汇率口径一致 | 同一地区同一日期内可直接 SUM；跨地区汇总前应确认汇率统一性 |
| `organic_gmv_usd` | 来源表已为 USD 单位，与 `ads_gmv_usd` 换算链路不同，两者直接相加需确认口径对齐 | 合并总 GMV 时应分别验证两个字段的货币单位来源，再进行加总 |

> **关于 CTR / CVR 等比率**：本表未存储比率字段，如需计算点击率（CTR）、转化率（CVR）等，应使用 `ads_clk_cnt / NULLIF(ads_imp_cnt, 0)` 等方式自行计算，**不可跨分组直接平均**。

### 时效性说明

本表为 T+1 日更新，`grass_date` 分区对应业务发生日期（本地时区）。查询昨日数据时应使用 `grass_date = current_date - 1`。由于自然流量数据来源 `traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` 可能存在上游延迟，建议取 **T-1** 分区而非当日数据，以保证数据完整性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供付费广告的曝光、点击、成单、GMV（本地货币）、消耗额（本地货币）等原始明细数据 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供用户实验分组信息，用于将用户行为数据关联到对应实验组（Search 用 `is_assignment_log`，DD/YMAL 用 `is_dim_join`） |
| `traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` | 提供各业务线（Search、Homepage-Daily Discover、Rcmd-YMAL）的自然流量曝光、点击、成单、GMV（USD）汇总数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 提供每日汇率，用于将广告 GMV 和消耗额从本地货币换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  (entrance in 1,3,4)
        │
        ├─ entrance=1 (search) ──────────────────────────────────────────────┐
        │       inner join                                                   │
        │   srdi_mart.dim_sr_data_warehouse_abtest_user_group               │
        │       (is_assignment_log=1)                                        │
        │   → search_group_performance (ads: search)                        │
        │                                                                   │
        └─ entrance=3,4 (dd/ymal) ───────────────────────────────────────── ┤
                inner join                                                  │
            srdi_mart.dim_sr_data_warehouse_abtest_user_group              │
                (is_dim_join=1)                                             │
            → dd_ymal_group_performance (ads: dd/ymal)                     │
                                                                           │
                    ┌──────────────────────────────────────────────────────┘
                    │  UNION ALL → ads_performance（主驱动表）
                    │
                    │               LEFT JOIN
                    │
traffic_omni_oa.dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live
  ├─ business_line='Search'
  │    → search_organic_base
  │        inner join search_group (is_assignment_log=1)
  │    → search_organic_group_performance
  │
  ├─ business_line='Homepage', module='Daily Discover'
  │    → dd_ymal_organic_base (entrance=3)
  │
  └─ business_line='Rcmd', module='User Scenario' (YMAL)
       → dd_ymal_organic_base (entrance=4)
           inner join dd_ymal_group (is_dim_join=1)
       → dd_ymal_organic_group_performance
                    │
                    │  UNION ALL → organic_performance
                    │                    LEFT JOIN (on entrance + group_id)
                    │
                    ├────────────────────────────────────────────────────────┐
                    │                                                        │
mp_order.dim_exchange_rate__reg_s0_live                                     │
  (本地货币 → USD 汇率)                                                      │
  LEFT JOIN (on grass_region)                                               │
                    │                                                        │
                    └──────────────────────────────────────────────────────→ │
                                                                            ▼
                    dws_advertise_user_exp_entrance_performance_1d__reg_s0_live
                    partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `ads_performance_base` | `dwd_advertise_performance_di__reg_s0_live` | 按日期、地区过滤付费广告明细，保留 entrance 1/3/4 |
| `search_group` | `dim_sr_data_warehouse_abtest_user_group` | 获取 Search 实验分组（`is_assignment_log=1`），去重为 user→group_id 映射 |
| `dd_ymal_group` | `dim_sr_data_warehouse_abtest_user_group` | 获取 DD/YMAL 实验分组（`is_dim_join=1`），去重为 user→group_id 映射 |
| `dd_ymal_organic_base` | `dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` | 提取 DD（entrance=3）和 YMAL（entrance=4）自然流量用户级明细 |
| `search_organic_base` | `dws_business_line_sales_funnel_metrics_1d__reg_sensitive_live` | 提取 Search（entrance=1）自然流量用户级明细，限定 `feature_detail like '%-item'` |
| `search_organic_group_performance` | `search_organic_base` + `search_group` | Search 自然流量按实验分组聚合 |
| `dd_ymal_organic_group_performance` | `dd_ymal_organic_base` + `dd_ymal_group` | DD/YMAL 自然流量按实验分组聚合 |
| `search_group_performance` | `ads_performance_base` + `search_group` | Search 付费广告按实验分组聚合（entrance=1） |
| `dd_ymal_group_performance` | `ads_performance_base` + `dd_ymal_group` | DD/YMAL 付费广告按实验分组聚合（entrance=3,4） |

### 注意事项

1. **两套分组逻辑并存**：Search 实验组使用 `is_assignment_log = 1`（曝光日志分组），DD/YMAL 实验组使用 `is_dim_join = 1`（维度加入分组）。两者含义不同，跨入口对比实验指标时需明确知晓各自分组口径，不能混用。

2. **付费 GMV 与有机 GMV 的货币换算差异**：`ads_gmv_usd` 和 `ads_revenue_usd` 是由本地货币经 `dim_exchange_rate` 汇率换算为 USD；而 `organic_gmv_usd` 来源表中已为 USD，两条链路的汇率处理不同。跨字段合并计算全量 GMV 时需确认口径一致。

3. **ads 与 organic 的关联为 LEFT JOIN**：以付费广告数据（`ads_performance`）为主表，LEFT JOIN 自然流量数据。因此若某实验组在某入口有广告数据但无自然流量命中，`organic_*` 字段将为 NULL，聚合时需使用 `COALESCE` 或 `NVL` 处理。

4. **入口编码转义**：原始数据中 entrance 为整型（1=search，3=dd，4=ymal），最终写入表时已转换为字符串，查询时须用字符串过滤，如 `entrance = 'search'`。

5. **数据唯一性**：同一 `group_id` + `entrance` + `grass_region` + `grass_date` + `tz_type` 组合在写入时通过 INSERT OVERWRITE 幂等覆盖，每次调度全量重刷当日分区，无增量追加场景。

6. **汇率缺失风险**：汇率表以 LEFT JOIN 关联，若当日汇率数据缺失，`ads_gmv_usd` 和 `ads_revenue_usd` 将为 NULL。查询时建议增加非空校验或监控汇率表完整性。

---

*文档生成时间：2026-04-22*