---
doc_id: pc2_metrics
title: "PC2 Metrics Guide"
status: verified
owner: ads_dpm
source_type: manual
domain: ads_mart
doc_type: business_playbook
source_refs:
  - type: confluence
    url: "https://confluence.shopee.io/display/SPV/PC+2"
    title: "PC 2"
    status: read
    note: "canonical page, last updated 2026-05-18"
  - type: confluence
    url: "https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPV&title=%5BDRD_20251111%5D+Add+New+PC2+Metrics"
    title: "[DRD_20251111] Add New PC2 Metrics"
    status: read
    note: "DRD page, last updated 2026-04-21"
  - type: google_doc
    url: "https://docs.google.com/document/d/1_opR7lGV60HrvmWI7G_p7W8M44tNiODNmR2yr-Lh0Aw/edit?tab=t.0#heading=h.vj10f3ktqzb5"
    title: "[User Guide] PC2 data"
    status: read
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1SkMRIb-fb5ybhhsN7-503GkpLLcAqZ3ucJU2e4Qhr9k/edit?gid=279010624#gid=279010624"
    title: "[Support Doc] Central Mart User Guide by Reg BI - Sample Queries"
    status: read
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1zo9LlZaSvlpSeJk8wWTHdtrbVIWtsHfIKbsesetdcb8/edit?gid=0#gid=0"
    title: "Ads Common Feature Mapping V2.0"
    status: read
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1Se19xyfBII7nDInHf_I-WSpgXJYLWXtmh3P7PFvmiOY/edit?gid=1629122432#gid=1629122432"
    title: "[data check] PC2 - Fee Rate Analysis"
    status: read
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1Se19xyfBII7nDInHf_I-WSpgXJYLWXtmh3P7PFvmiOY/edit?gid=1871344961#gid=1871344961"
    title: "[data check] PC2 - FPA vs order data source comparison"
    status: read
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1Jk40qFXY6hJoYO5RPIlC0OK_1sqOyKelBTYt0gCDyuA/edit?gid=0#gid=0"
    title: "PC 2 Template for Food"
    status: no_access
  - type: google_sheet
    url: "https://docs.google.com/spreadsheets/d/1ClBb-g0sYp0qV12fMps3idrdEmkLiM61j7WGzM5IeKo/edit?gid=0#gid=0"
    title: "PC2 related sheet"
    status: no_access
  - type: datasuite
    url: "https://datasuite.shopee.io/scheduler/task/data_paidadsmart.studio_10306943/code"
    title: "dws_common_feature_user_item_pc2_1d__my"
    status: read
    note: "pulled with sra-get-dashboard-sql after Chrome cookie became available; SQL length about 41K"
  - type: local_etl
    path: "dist/etl/mp_paidads.dws_common_feature_user_item_pc2_1d__reg_s0_live.json"
    status: read
  - type: local_etl
    path: "dist/etl/mp_paidads.dws_user_pc2_1d__reg_s0_live.json"
    status: read
  - type: local_etl
    path: "dist/etl/mp_paidads.ads_new_pc2_rate_exp_1d__reg_s0_live.json"
    status: read
last_reviewed: 2026-05-19
aliases:
  - PC2
  - PC 2
  - Platform Contribution 2
  - Local PC2
  - Proxy PC2
  - Adjusted Proxy PC2
  - True PC2
  - pc2_rate
  - PC2 rate
  - proxy_pc2_usd_1d
  - adjusted_proxy_pc2_usd_1d
  - adjusted_proxy_pc2_exp_usd_1d
  - true_pc2_usd_1d
  - local_pc2_usd_1d
  - 平台利润
  - 贡献利润
  - PC2口径
related_tables:
  - mp_paidads.dws_common_feature_user_item_pc2_1d
  - mp_paidads.dws_user_pc2_1d
  - mp_paidads.ads_new_pc2_rate_exp_1d
  - mp_paidads.dws_user_net_ads_revenue_1d
  - mp_paidads.ads_order_voucher_1d
  - mp_paidads.dim_common_feature_mapping_v2
external_tables:
  - traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live
  - traffic_omni_oa.dim_item_pc2_rate_map__reg_live
  - mp_mgmt.dws_order_item_rev_di__reg_s0_live
  - mp_mgmt.dws_order_item_rebate_di__reg_s0_live
  - mp_mgmt.dws_order_3pl_margin_di__reg_s1_live
  - mp_mgmt.ads_mgmtview_pl_1d__reg_live
  - mp_item.dim_item__reg_s0_live
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1ivX3eid7zeVE8YHWKSkyhrxH2T4yIiVGpdmv4gUFdIw gdoc_url=https://docs.google.com/document/d/1ivX3eid7zeVE8YHWKSkyhrxH2T4yIiVGpdmv4gUFdIw/edit -->


# PC2 Metrics Guide

## 1. 一页速览

PC2 是平台利润贡献口径。当前广告数仓中同时存在 Local PC2、Proxy PC2、Adjusted Proxy PC2、True PC2 四套口径，分别服务不同场景，不能混用。

基础定义：

```text
PC1 = MP Revenue + 3PL Margin - PRM excl. 3PL Margin - RSF / RTS
PC2 = PC1 - Gross Transaction Fee
```

实际分析时更常用下面这张选择表：

| 使用场景 | 推荐口径 | 推荐表 | 关键限制 |
| --- | --- | --- | --- |
| 流量渠道、业务线、common_feature 拆解 | Proxy PC2 / Adjusted Proxy PC2 | `mp_paidads.dws_common_feature_user_item_pc2_1d` | 只能拆 Proxy/Adjusted，不能拆 True PC2 |
| 用户级平台利润分析 | Local / Proxy / Adjusted / True PC2 | `mp_paidads.dws_user_pc2_1d` | True PC2 是用户级，RSF/GTF/other revenue 含均摊估算 |
| A/B 实验组对比 | `ads_new_pc2_rate_exp_1d` 中的 Proxy/Adjusted 字段 | `mp_paidads.ads_new_pc2_rate_exp_1d` | 必须过滤单一 `scenario_tag`；Platform-only 字段只在 `scenario_tag='Platform'` 有效 |
| 需要和 local 固定 PC2 率对齐 | Adjusted Proxy PC2 | `dws_common_feature_user_item_pc2_1d` 或 `dws_user_pc2_1d` | 依赖 `traffic_omni_oa.dim_item_pc2_rate_map` 的类目 PC2 rate |
| 财务最完整平台 PC2 | True PC2 | `mp_paidads.dws_user_pc2_1d` | 不支持 feature/business line 拆分 |

核心原则：

- 如果问题是“某个流量场景 / common_feature 的 PC2 贡献”，优先用 `dws_common_feature_user_item_pc2_1d` 的 `proxy_pc2_usd_1d` 或 `adjusted_proxy_pc2_usd_1d`。
- 如果问题是“平台整体 True PC2 uplift”，优先用 `dws_user_pc2_1d.true_pc2_usd_1d`，A/B 评估中只在 `ads_new_pc2_rate_exp_1d` 的 `scenario_tag='Platform'` 行使用。
- rate 一律用 `SUM(pc2_amount) / SUM(omni_gmv_usd_1d)`，不要先算行级 rate 再 AVG。
- `common_feature='Platform'` 是全平台聚合行，不能和其他 `common_feature` 行一起 SUM。
- Proxy / Adjusted Proxy PC2 可以为负值，这是收入成本组合后的正常结果，不应强行截断为 0。

## 2. 四套 PC2 口径

### 2.1 Local PC2

Local PC2 是 local team 维护或确认的固定口径，主要用于调节 item traffic weight，通常可以拆到 item 维度，也可以按 business line / common_feature 汇总观察。

在 `mp_paidads.dws_user_pc2_1d` 中，`local_pc2_usd_1d` 来自 omni journey 的 `pc2_usd`，并按 `atc_prorate * first_touchpoint_item` 加权到用户层。

适合回答：

- local 既有 PC2 口径下，某地区、某用户或某 item 的平台利润贡献。
- 需要和 local PC2 率表保持一致的流量调权、实验校准问题。

不适合回答：

- 新 PC2 全量组件拆解。
- True PC2 或财务完整 PC2 的绝对值。

### 2.2 Proxy PC2

Proxy PC2 是可拆到 user_id × item_id × common_feature 的代理利润口径。它保留广告算法和推荐算法更能影响、也更容易归因到流量场景的部分，生产 ETL 当前公式为：

```text
proxy_pc2_usd_1d
= estimate_mandatory_commission_fee_usd_1d
  + estimate_optional_commission_fee_usd_1d
  + estimate_handling_fee_usd_1d
  + paid_ads_net_revenue_usd_1d
  - paid_ads_voucher_ads_part_amt_usd_1d
```

其中：

- mandatory / optional commission / handling fee 来自 `mp_mgmt.dws_order_item_rev_di__reg_s0_live`。
- paid ads net revenue 来自 `mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live`。
- paid ads voucher ads part 来自 `mp_paidads.ads_order_voucher_1d__reg_s0_live`，计算为 `ads_voucher_amt_usd * (1 - coalesce(voucher_cofund_ratio, 0))`。

Proxy PC2 不包含 3PL、RSF/RTS、Gross Transaction Fee，也不等同于完整 True PC2。它的价值在于可以按 `common_feature` 归因和拆解。

### 2.3 Adjusted Proxy PC2

Adjusted Proxy PC2 用 local/category PC2 rate 对 Proxy PC2 做本地化缩放，使可拆分的 Proxy 口径更接近 local PC2 体系。当前生产 ETL 的核心公式是：

```text
item_proxy_pc2_rate = SUM(proxy_pc2) / SUM(omni_gmv_usd)
category_proxy_pc2_rate = SUM(proxy_pc2 by category) / SUM(omni_gmv_usd by category)

adjusted_proxy_pc2_rate
= item_proxy_pc2_rate * (local_category_pc2_rate / category_proxy_pc2_rate)

adjusted_proxy_pc2_usd_1d
= omni_gmv_usd_1d * adjusted_proxy_pc2_rate
```

实验字段 `adjusted_proxy_pc2_exp_usd_1d` 是 `mp_paidads.dws_common_feature_user_item_pc2_1d` 的字段，并被下游 `mp_paidads.ads_new_pc2_rate_exp_1d` 聚合消费。按当前生产 ETL 和 DataSuite SQL，字段使用 `traffic_omni_oa.dim_item_pc2_rate_map__reg_live.pc2_rate_exp_v2` 替换正式版 `pc2_rate`。DRD 中已有 v3 逻辑描述，但当前 ETL 尚未切到 v3；在上线前，知识库应按 v2 记录，同时标记 v3 待上线/待 ETL 切换。

### 2.4 True PC2

True PC2 是当前最完整的平台 PC2 口径：

```text
true_pc2_usd_1d
= estimate_mp_revenue_usd_1d
  - estimate_promotion_excl_3pl_usd_1d
  + estimate_3pl_margin_usd_1d
  - rsf_and_rts_usd_1d
  - gross_transaction_fee_usd_1d
```

它只适合用户级或平台级分析，不适合拆到 feature/business line，因为 3PL、RSF/RTS、Gross Transaction Fee、other revenue 等组件不能可靠归因到每个 common_feature。

在 `mp_paidads.ads_new_pc2_rate_exp_1d` 中，`true_pc2_usd_1d`、`local_pc2_usd_1d`、`estimate_3pl_margin_usd_1d`、`rsf_and_rts_usd_1d`、`gross_transaction_fee_usd_1d`、`other_revenue_usd_1d` 只在 `scenario_tag='Platform'` 的行有效，非 Platform 场景不能使用这些字段做场景级 True PC2。

## 3. 推荐用表

### 3.1 `mp_paidads.dws_common_feature_user_item_pc2_1d`

粒度：`grass_date + grass_region + tz_type + user_id + item_id + common_feature`。

主要字段：

| 字段 | 含义 |
| --- | --- |
| `omni_gmv_usd_1d` | 全渠道归因 GMV，按 `atc_prorate * first_touchpoint_item` 加权 |
| `proxy_pc2_usd_1d` | 可拆流量场景的代理 PC2 |
| `adjusted_proxy_pc2_usd_1d` | 经 local/category rate 校正后的代理 PC2 |
| `adjusted_proxy_pc2_exp_usd_1d` | 实验版 adjusted proxy PC2 |
| `paid_ads_net_revenue_usd_1d` | 净广告收入 |
| `paid_ads_voucher_ads_part_amt_usd_1d` | 广告券广告方承担金额，是 Proxy PC2 扣减项 |

查询要求：

- 必须过滤 `tz_type='local'`、`grass_region`、`grass_date`。
- 全平台口径用 `common_feature='Platform'`。
- 渠道拆分时用具体 `common_feature`，不要把 `Platform` 和具体渠道混在一起。
- 数据通常 T+1 下午或 T+2 更完整，并会滚动重刷近 30 天。

示例：

```sql
SELECT
    grass_date
    ,grass_region
    ,common_feature
    ,SUM(omni_gmv_usd_1d) AS omni_gmv_usd
    ,SUM(proxy_pc2_usd_1d) AS proxy_pc2_usd
    ,SUM(proxy_pc2_usd_1d) / NULLIF(SUM(omni_gmv_usd_1d), 0) AS proxy_pc2_rate
    ,SUM(adjusted_proxy_pc2_usd_1d) AS adjusted_proxy_pc2_usd
    ,SUM(adjusted_proxy_pc2_usd_1d) / NULLIF(SUM(omni_gmv_usd_1d), 0) AS adjusted_proxy_pc2_rate
FROM mp_paidads.dws_common_feature_user_item_pc2_1d
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date BETWEEN DATE '2026-05-01' AND DATE '2026-05-07'
  AND common_feature IN ('Platform', 'Global Search', 'Daily Discover')
GROUP BY 1, 2, 3;
```

### 3.2 `mp_paidads.dws_user_pc2_1d`

粒度：`grass_date + grass_region + tz_type + user_id`。

主要字段：

| 字段 | 含义 |
| --- | --- |
| `local_pc2_usd_1d` | local 固定口径 PC2 |
| `proxy_pc2_usd_1d` | 用户级 Proxy PC2 |
| `adjusted_proxy_pc2_usd_1d` | 用户级 adjusted proxy PC2 |
| `true_pc2_usd_1d` | 完整 True PC2 |
| `estimate_3pl_margin_usd_1d` | 3PL margin |
| `rsf_and_rts_usd_1d` | RSF/RTS，按有效用户均摊 |
| `gross_transaction_fee_usd_1d` | Gross transaction fee，按有效用户均摊 |
| `other_revenue_usd_1d` | 地区大盘 other revenue，按有效用户均摊 |

查询要求：

- 必须过滤 `tz_type='local'`、`grass_region`、`grass_date`。
- `true_pc2_usd_1d` 可以汇总到地区/实验组，但不建议解读单个用户的 RSF/GTF/other revenue 精确值，因为这些组件存在均摊。
- 多日 rate 仍然用 `SUM(true_pc2_usd_1d) / SUM(omni_gmv_usd_1d)`。

### 3.3 `mp_paidads.ads_new_pc2_rate_exp_1d`

粒度：`scenario_tag + exp_group_id + domain + grass_region + grass_date`。

适合做 A/B 实验结果聚合。关键风险是 `scenario_tag` 由多个原子场景和 Unify 场景 `UNION ALL` 构成，同一用户同一天可能出现在多个场景口径中，因此不能跨 `scenario_tag` 直接 SUM。

常见 `scenario_tag`：

| scenario_tag | 说明 |
| --- | --- |
| `Platform` | 全平台汇总口径 |
| `Cart Unify` | Cart / post-purchase / ODP / MPP / Me YMAL / Shop YMAL / SIP YMAL / Buy Again 等购物链路推荐集合 |
| `RCMD Unify` | `Cart Unify` + `You May Also Like` + `Daily Discover` |
| `Search_RCMD` | `RCMD Unify` + `Global Search` |
| `DD_PP Unify` | `Cart Unify` + `Daily Discover` |

使用限制：

- 查实验结果时必须明确 `domain` 和单一 `scenario_tag`。
- `local_pc2_usd_1d`、`true_pc2_usd_1d`、`estimate_3pl_margin_usd_1d`、`rsf_and_rts_usd_1d`、`gross_transaction_fee_usd_1d`、`other_revenue_usd_1d` 只在 `scenario_tag='Platform'` 有效。
- 非 Platform 场景主要看 `proxy_pc2_usd_1d`、`adjusted_proxy_pc2_usd_1d`、`adjusted_proxy_pc2_exp_usd_1d`。

## 4. Common Feature 口径

`common_feature` 是 PC2 拆流量场景的核心维度。广告 performance、net ads revenue、ads voucher 等链路会通过 `mp_paidads.dim_common_feature_mapping_v2` 将 `entrance` 映射到标准 feature；omni journey 侧则通过 feature/module/source 字段映射。

常见值包括：

| common_feature | 典型入口 |
| --- | --- |
| `Global Search` | 搜索商品流 |
| `Image Search` | 图片搜索 |
| `Daily Discover` | Daily Discover / PP 等推荐流 |
| `You May Also Like` | YMAL 推荐 |
| `Cart Recommendation` | 购物车推荐 |
| `Order Successful Recommendation` | 下单成功页推荐 |
| `Order Detail Page Recommendation` | 订单详情页推荐，实验表中常重命名为 `Order Detail Page YMAL` |
| `My Purchase Page Recommendation` | 我的购买页推荐 |
| `Search Shop` | search-shop 相关入口 |
| `Live Streaming` | Live 相关入口 |
| `Video` | Video 相关入口 |
| `Me YMAL` | Me 页 YMAL |
| `Shop YMAL` | Shop 页 YMAL |
| `Platform` | 全平台聚合口径 |

注意：

- `common_feature='Others'` 在 `dws_common_feature_user_item_pc2_1d` 最终输出中会被过滤。
- `Platform` 是 `UNION ALL` 额外写入的全平台聚合行，不是某个具体入口。
- 分析单 feature 时过滤该 feature；分析整体时过滤 `Platform`；不要把两类口径放在同一个 SUM 里。

## 5. Item Fee Rate 和 Local Rate 选择

PC2 的 adjusted proxy 依赖 item/category rate。Confluence 和 data check sheet 的主要结论是：以 commission fee base 估算 mandatory fee rate 更稳定，commission fee 本身相对稳定；受 G2N 和订单结算影响，建议使用订单创建后至少 14 天的数据来计算更稳定的 fee rate。

Item fee rate 相关口径：

| 字段/概念 | 含义 |
| --- | --- |
| `commission_base_amt_usd` | commission fee base，作为 mandatory rate 分母更稳定 |
| `commission_fee_usd` | mandatory commission 近似核心组件 |
| `service_fee_usd` | optional commission 近似核心组件 |
| `commission_fee_rate` | `commission_fee_usd / commission_base_amt_usd` |
| `service_fee_rate` | `service_fee_usd / commission_base_amt_usd` |
| `commission_and_service_fee_rate` | mandatory + optional 的近似 rate |

数据源选择：

- `mp_mgmt.dws_order_item_rev_di__reg_s0_live` 是 Finance/CM 口径，覆盖 1P/SIP 更完整，但为增量表，会重刷近 64 天。
- `mp_order.dwd_order_item_all_ent_df__reg_s0_live` 是 order mart 全量表，口径更贴近订单系统，适合非 1P/SIP 的基础 gross 指标。
- data check 的结论倾向于：除 Ads Rev 自身外，mandatory + optional 可用 `estimate_commission_fee_usd_level2_1d + estimate_optional_commission_fee_usd_level1_1d` 近似，覆盖大约 70%-80% 的 MP Rev；叠加 Ads Rev 后整体覆盖通常超过 80%，但 PH/VN 可能偏低。

当前生产 adjusted proxy 实际使用 `traffic_omni_oa.dim_item_pc2_rate_map__reg_live` 中的 `pc2_rate` 和 `pc2_rate_exp_v2`，按 level2 category 做 local/category ratio 缩放。

## 6. 业务解释边界

### 6.1 Org Algo 与 Ads Algo 的目标不同

从 PC2 user guide 看，Org Algo 更关注 Proxy PC2 和 Adjusted Proxy PC2 的绝对增长，因为这些指标可以拆到业务线和流量场景；Ads Algo 更适合看 A/B 组之间的 True PC2 uplift，而不是承诺提升 True PC2 的绝对值。

原因是 True PC2 包含 3PL、RSF/RTS、gross transaction fee、other revenue 等平台大盘组件，这些组件不是广告/推荐流量完全可控，也不能稳定拆到 feature。

### 6.2 Proxy PC2 与 True PC2 不应互相替代

Proxy PC2 是可归因、可拆解、可用于算法目标和场景诊断的代理值；True PC2 是完整财务口径，但只支持 user/platform 级别分析。

如果一个问题要求 feature/channel 级别解释，应使用 Proxy 或 Adjusted Proxy；如果问题要求平台最终利润口径，应使用 True PC2 并接受它不能拆 feature 的限制。

### 6.3 `paid_ads_voucher_ads_part_amt_usd_1d` 是扣减项

广告券金额在 PC2 里不是收入，而是广告方承担的券成本。生产公式使用：

```text
ads_voucher_ads_part = ads_voucher_amt_usd * (1 - coalesce(voucher_cofund_ratio, 0))
proxy_pc2 = commission + handling + paid_ads_net_revenue - ads_voucher_ads_part
```

所以分析 ROI3/Ads Voucher 对 PC2 的影响时，不能把该字段和 revenue 字段同向相加。

## 7. 常见问题

### 7.1 如何查某个 common_feature 的 PC2 rate？

用 `dws_common_feature_user_item_pc2_1d`，过滤目标 `common_feature`，然后：

```sql
SUM(proxy_pc2_usd_1d) / NULLIF(SUM(omni_gmv_usd_1d), 0)
```

或：

```sql
SUM(adjusted_proxy_pc2_usd_1d) / NULLIF(SUM(omni_gmv_usd_1d), 0)
```

不要把 `common_feature='Platform'` 和其他 feature 一起汇总。

### 7.2 如何查平台整体 True PC2？

用 `dws_user_pc2_1d`：

```sql
SELECT
    grass_region
    ,grass_date
    ,SUM(omni_gmv_usd_1d) AS omni_gmv_usd
    ,SUM(true_pc2_usd_1d) AS true_pc2_usd
    ,SUM(true_pc2_usd_1d) / NULLIF(SUM(omni_gmv_usd_1d), 0) AS true_pc2_rate
FROM mp_paidads.dws_user_pc2_1d
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date BETWEEN DATE '2026-05-01' AND DATE '2026-05-07'
GROUP BY 1, 2;
```

### 7.3 如何做 A/B 实验 PC2 评估？

用 `ads_new_pc2_rate_exp_1d`，按 `exp_group_id` 分组，同时固定 `domain`、`scenario_tag`、`grass_region`、`grass_date`。

非 Platform 场景优先看 Proxy/Adjusted Proxy：

```sql
SELECT
    exp_group_id
    ,SUM(omni_gmv_usd_1d) AS omni_gmv_usd
    ,SUM(proxy_pc2_usd_1d) AS proxy_pc2_usd
    ,SUM(adjusted_proxy_pc2_usd_1d) AS adjusted_proxy_pc2_usd
FROM mp_paidads.ads_new_pc2_rate_exp_1d
WHERE grass_region = 'SG'
  AND grass_date BETWEEN DATE '2026-05-01' AND DATE '2026-05-07'
  AND domain = 'RCMD_Ads'
  AND scenario_tag = 'RCMD Unify'
GROUP BY 1;
```

如果要看 True PC2 uplift，`scenario_tag` 统一使用 `Platform`。当前不补充非 Platform 特例，因为 True PC2 相关字段只在 Platform 行有效。

### 7.4 为什么表里有 `Platform` 还要有各 feature？

因为 `Platform` 是为了快速得到全平台口径额外写入的聚合行，各 feature 是拆解口径。两者不是互斥分桶，不能直接相加。

### 7.5 为什么 True PC2 不能按 feature 拆？

True PC2 的完整公式包含 3PL、RSF/RTS、gross transaction fee 和 other revenue。当前这些组件不是稳定的 user × item × common_feature 明细归因数据，其中一部分还是地区大盘按用户均摊，所以只能支持用户级或平台级分析。
