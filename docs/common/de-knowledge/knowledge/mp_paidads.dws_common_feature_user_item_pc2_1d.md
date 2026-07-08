<!-- ads-workspace-gdoc-sync: gdoc_id=1pWHtbczCB6At07VtNZ5CPrs_hn3kvU4xaf0VuZeffQA gdoc_url=https://docs.google.com/document/d/1pWHtbczCB6At07VtNZ5CPrs_hn3kvU4xaf0VuZeffQA/edit -->

# mp_paidads.dws_common_feature_user_item_pc2_1d

**分层**：DWS（数据汇总层）
**主键**：`grass_date + grass_region + tz_type + user_id + item_id + common_feature`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度，覆盖写入（INSERT OVERWRITE）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是付费广告域的核心宽表，以**用户 × 商品 × 流量渠道（common_feature）× 日期**为粒度，汇总全渠道（Omni）归因下的 GMV、佣金收入、手续费、平台补贴（PRM）及付费广告相关指标，并在此基础上计算 PC2（平台二级利润）及其基准调整值。表名中的 `pc2` 代表 Platform Contribution 2，是衡量平台货币化能力的核心财务指标。

本表的典型使用场景包括：按流量入口（如搜索、直播、平台汇总等 `common_feature` 维度）拆解付费广告的货币化贡献；评估不同渠道下商品的佣金收入结构（强制 / 可选 / 跨境 / Mall）；以及利用 `adjusted_proxy_pc2_usd_1d` 进行跨地区、跨类目的 PC2 标准化对比分析。

本表通过多路数据源整合（订单收入流、订单补贴流、全渠道归因流、付费广告流），为付费广告效果评估、平台收入健康度监控及 ROI 分析提供一站式数据支撑，是付费广告产品及数据分析团队的核心依赖表。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。固定写入值为 `'local'`，表示各地区按本地时区参数化调度生成。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描。 |
| `grass_region` | string | 地区分区标识（如 `'MX'`、`'TH'` 等），通过 `${region}` 参数化调度覆盖所有地区。⚠️ 查询时须明确指定地区，避免跨地区数据叠加。 |
| `grass_date` | date | 订单创建日期（基于本地时区），为数据管理与分析的日期分区列。⚠️ 查询时须指定日期范围，避免全表扫描。 |

---

### 维度：主键与流量归因属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 买家唯一标识符。 |
| `item_id` | bigint | 订单中商品的标识符（对应 `order_item_id`）。 |
| `common_feature` | string | 流量来源归因标签，枚举值包括 Search、Live Streaming、Platform（全平台汇总）等。具体枚举定义参见 [映射文档](https://docs.google.com/spreadsheets/d/1zo9LlZaSvlpSeJk8wWTHdtrbVIWtsHfIKbsesetdcb8/edit?gid=0#gid=0)。⚠️ 含 `'Platform'` 行为全渠道汇总行，与各明细渠道行存在重叠，按渠道分析时须过滤掉 `'Platform'`；跨渠道加总时须仅保留 `'Platform'`，否则会重复计算。 |

---

### 指标：全渠道 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `omni_gmv_usd_1d` | double | 订单商品在全渠道归因下的加权 GMV（USD），由 Omni 归因模型按触点占比分摊计算得出。⚠️ 为归因加权值（`gmv_usd × atc_prorate × first_touchpoint_item`），非订单原始 GMV，不可与订单域 GMV 直接对比。 |

---

### 指标：平台综合收入（PC2）

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_mp_revenue_usd_1d` | double | 估算平台市场佣金收入（USD，不含 VAT），计算公式：强制佣金 + 可选佣金 + 手续费 + 付费广告净收入。⚠️ 为派生字段，不可直接 SUM 后与其他分项加总对比，应以分项字段重新加总。 |
| `proxy_pc2_usd_1d` | double | 代理 PC2（USD），口径为：强制佣金 + 可选佣金 + 手续费 + 其他 MP 收入 + 付费广告收入（ROI3 + ROI4）- 不含 3PL Margin 的 PRM。⚠️ 为派生聚合指标，请勿与其他 PC2 字段混用，需理解其含 Ads ROI3/ROI4 的特殊口径。 |
| `adjusted_proxy_pc2_usd_1d` | double | 调整后代理 PC2（USD，标准版），计算逻辑：`item_proxy_pc2_rate × (local_category_pc2_rate / category_proxy_pc2_rate) × omni_gmv_usd`，即通过本地化类目基准率对商品代理 PC2 率进行校正后乘以 GMV。⚠️ 为派生估算值，不可直接 SUM 进行跨粒度聚合，需结合 `omni_gmv_usd_1d` 重新以加权方式汇总。 |
| `adjusted_proxy_pc2_exp_usd_1d` | double | 调整后代理 PC2（USD，实验 v2 版），使用 `local_pc2_rate_exp_v2` 替代 `local_category_pc2_rate` 进行调整，计算逻辑同上。⚠️ 为实验性派生估算值，使用前确认业务场景是否适用实验版本口径，不可直接 SUM。 |
| `commission_base_amt_usd_1d` | double | 佣金计费基础金额（USD）。⚠️ 字段注释为空，从 ETL 上下文推断为佣金计算的基准金额，具体口径请结合上游表 `dws_order_item_rev_di` 确认。 |

---

### 指标：佣金收入明细

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_mandatory_commission_fee_usd_1d` | double | 估算强制佣金收入合计（USD，不含 VAT），含 Local C2C、Local Mall、CB 三类渠道之和。 |
| `estimate_local_c2c_mandatory_commission_fee_usd_1d` | double | 估算本地非官方店铺（C2C）强制佣金收入（USD，不含 VAT）。 |
| `estimate_local_mall_mandatory_commission_fee_usd_1d` | double | 估算本地官方店铺（Mall）强制佣金收入（USD，不含 VAT）。 |
| `estimate_cb_mandatory_commission_fee_usd_1d` | double | 估算跨境店铺（CB）强制佣金收入（USD，不含 VAT）。 |
| `estimate_optional_commission_fee_usd_1d` | double | 估算可选佣金收入合计（USD，不含 VAT）。 |
| `estimate_local_c2c_optional_commission_fee_usd_1d` | double | 估算本地非官方店铺（C2C）可选佣金收入（USD，不含 VAT）。 |
| `estimate_local_mall_optional_commission_fee_usd_1d` | double | 估算本地官方店铺（Mall）可选佣金收入（USD，不含 VAT）。 |
| `estimate_cb_optional_commission_fee_usd_1d` | double | 估算跨境店铺（CB）可选佣金收入（USD，不含 VAT）。 |

---

### 指标：手续费收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_handling_fee_usd_1d` | double | 估算卖家 + 买家手续费收入合计（USD，不含 VAT）。 |
| `estimate_seller_handling_fee_usd_1d` | double | 估算卖家手续费收入（USD，不含 VAT）。 |
| `estimate_buyer_handling_fee_usd_1d` | double | 估算买家净手续费收入（USD，不含 VAT）。 |

---

### 指标：平台补贴（PRM）

| 字段 | 类型 | 说明 |
|------|------|------|
| `estimate_promotion_excl_3pl_usd_1d` | double | 估算优质交易中商品券记录的净补贴总额（USD，不含 3PL 利润部分）。 |
| `estimate_logst_prm_usd_1d` | double | 估算物流补贴净总额（USD）。 |
| `estimate_item_card_prm_usd_1d` | double | 估算商品卡推广净补贴总额（USD）。 |
| `estimate_voucher_prm_usd_1d` | double | 估算优惠券推广净补贴总额（USD）。 |
| `estimate_coin_prm_usd_1d` | double | 估算金币补贴相关净总额（USD）。 |

---

### 指标：付费广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_ads_revenue_usd_1d` | double | 付费广告收入（广告花费，USD）。 |
| `paid_ads_net_revenue_usd_1d` | double | 付费广告净收入（USD，扣除返还后），来源于 `dws_user_net_ads_revenue_1d`。 |
| `paid_ads_broad_gmv_usd_1d` | double | 广告带动的广义 GMV 总计（USD），含广告归因订单。 |
| `paid_ads_voucher_ads_part_amt_usd_1d` | double | 广告侧承担的券补贴金额（USD）。计算逻辑：`ads_voucher_amt_usd × (1 - COALESCE(voucher_cofund_ratio, 0))`。ROI3 口径下含全部券，ROI Cofund 口径下仅含广告承担部分。⚠️ 该字段在不同 ROI 口径下含义不同，使用前需确认分析所用的 ROI 口径。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，导致查询超时及资源浪费：

| 过滤条件 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有 tz_type 分区；本表目前仅写入 `'local'` 分区，遗漏等同于重复读取所有数据 |
| `grass_region` | `grass_region = 'XX'`（指定具体地区） | 跨地区数据混合，指标失真且扫描量成倍增加 |
| `grass_date` | `grass_date = 'YYYY-MM-DD'` 或日期范围 | 全量历史扫描，极高资源消耗 |

### 不可直接 SUM 的字段

以下字段为预计算派生值或归因加权值，**不可跨行直接 SUM 聚合**：

| 字段 | 问题原因 | 正确计算方式 |
|------|----------|-------------|
| `adjusted_proxy_pc2_usd_1d` | 由 `omni_gmv_usd × adjusted_proxy_pc2_rate` 派生，跨粒度 SUM 会导致率×GMV错误叠加 | 使用分子（`pc2`）和分母（`omni_gmv_usd`）分别 SUM 后重新计算率再乘以汇总 GMV |
| `adjusted_proxy_pc2_exp_usd_1d` | 同上，实验版本口径 | 同上 |
| `omni_gmv_usd_1d` | 全渠道归因加权 GMV，含多渠道分摊；`common_feature` 各明细行之和 ≠ 订单实际 GMV | 汇总时须过滤 `common_feature = 'Platform'`，取全平台汇总行；或仅在单一渠道维度下使用 |
| `estimate_mp_revenue_usd_1d` | 为多项收入合计的派生字段 | 若需验证，请用 `estimate_mandatory_commission_fee_usd_1d + estimate_optional_commission_fee_usd_1d + estimate_handling_fee_usd_1d + paid_ads_net_revenue_usd_1d` 重新加总 |
| `proxy_pc2_usd_1d` | PC2 口径包含特定 ROI 层级（ROI3+ROI4），已聚合多个分项 | 不可与其他佣金字段二次叠加，理解口径后直接使用 |

**`common_feature` 重复计算风险**：`'Platform'` 行为所有渠道的汇总行，与 Search、Live Streaming 等明细行**存在数据重叠**。按渠道分析时须 `WHERE common_feature != 'Platform'`；跨渠道求总时须 `WHERE common_feature = 'Platform'`，两者不可混用。

### 时效性说明

- 本表采用 **INSERT OVERWRITE** 覆盖写入，每日调度时按 `(tz_type, grass_region, grass_date)` 分区覆盖当日数据，分区内数据为最新版本。
- ETL 上游从近 30 天窗口读取数据（`central_base`、`rebate_base` 等），若上游订单数据存在延迟补录，当日分区数据可能在调度完成后发生变更，建议使用 **T-1 或 T-2 分区**的数据，以确保数据稳定性。
- `adjusted_proxy_pc2_usd_1d` / `adjusted_proxy_pc2_exp_usd_1d` 依赖 `traffic_omni_oa.dim_item_pc2_rate_map` 的类目基准率，若该维表未及时刷新，上述字段的当日值可能沿用前日基准率，需关注维表更新情况。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_mgmt.dws_order_item_rev_di__reg_s0_live` | 订单商品级佣金收入（强制 / 可选佣金、手续费）的核心来源 |
| `mp_mgmt.dws_order_item_rebate_di__reg_s0_live` | 订单商品级平台补贴（PRM：物流 / 商品卡 / 优惠券 / 金币）来源 |
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | 全渠道归因（Omni）数据，提供 `common_feature` 归因标签及加权 GMV |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 付费广告绩效数据，提供广告收入（花费）及广告带动 GMV |
| `mp_paidads.dws_user_net_ads_revenue_1d__reg_s0_live` | 用户级付费广告净收入（扣除返还后） |
| `mp_paidads.ads_order_voucher_1d__reg_s0_live` | 广告关联订单券信息，用于计算广告侧承担的券补贴金额 |
| `mp_paidads.dim_common_feature_mapping_v2__reg_s0_live` | 广告入口（entrance）到 `common_feature` 渠道标签的维度映射表 |
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供商品二级全球后台类目 ID（`level2_global_be_category_id`） |
| `traffic_omni_oa.dim_item_pc2_rate_map__reg_live` | 类目级本地化 PC2 基准率维表，用于计算 `adjusted_proxy_pc2` |

---

## ETL 逻辑摘要

### 数据流

```
mp_mgmt.dws_order_item_rev_di          mp_mgmt.dws_order_item_rebate_di
          │                                          │
          ▼                                          ▼
    [central_base]                           [rebate_base]
    佣金/手续费行级读取                       PRM补贴行级读取
          │                                          │
          └──────────────┐      ┌────────────────────┘
                         ▼      ▼
traffic_omni_oa.dwd_order_item_atc_journey_di
          │
          ▼
      [omni_base]
   4段UNION ALL构建渠道归因
   (click/source1/source2/Platform)
          │
          ▼
  [omni_central_rebate_base]
  omni LEFT JOIN central LEFT JOIN rebate
  → 按 (grass_date, user_id, item_id, common_feature) 聚合
          │
          │         mp_paidads.dwd_advertise_performance_di
          │         mp_paidads.dim_common_feature_mapping_v2
          │                    │
          │                    ▼
          │               [ads_base]
          │           广告收入 + 广义GMV
          │
          │         mp_paidads.dws_user_net_ads_revenue_1d
          │         mp_paidads.dim_common_feature_mapping_v2
          │                    │
          │                    ▼
          │              [net_rev_base]
          │              广告净收入
          │
          │         mp_paidads.ads_order_voucher_1d
          │         mp_paidads.dim_common_feature_mapping_v2
          │                    │
          │                    ▼
          │           [ads_voucher_base]
          │           广告券分摊金额
          │
          └─────────────────┐
                            ▼
                       [real_pc2]  ← mp_item.dim_item（类目信息）
              4段UNION ALL → 聚合 → PC2核心指标计算
              (CACHE TABLE)
                  │               │
                  ▼               ▼
           [item_pc2]      [category_pc2]
          商品级PC2率       类目级平台实测PC2率
                  │               │
                  │               │    traffic_omni_oa.dim_item_pc2_rate_map
                  │               │               │
                  │               │               ▼
                  │               │    [local_category_pc2]
                  │               │    类目级本地化基准PC2率
                  │               │               │
                  └───────────────┴───────────────┘
                                  │
                                  ▼
                        [adjusted_item_pc2]
                   商品代理PC2率 × 本地化基准校正
                                  │
                                  │
                  [real_pc2（过滤 common_feature!='Others'）]
                                  │
                                  ▼
                             [output]
                     real_pc2 LEFT JOIN adjusted_item_pc2
                     → 计算 adjusted_proxy_pc2_usd_1d 等派生字段
                                  │
                                  ▼
        INSERT OVERWRITE dws_common_feature_user_item_pc2_1d__reg_s0_live
              PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `central_base` | `mp_mgmt.dws_order_item_rev_di` | 行级读取订单商品佣金收入与手续费，COALESCE 补零，合并买卖家手续费 |
| `rebate_base` | `mp_mgmt.dws_order_item_rebate_di` | 行级读取订单商品平台补贴（PRM），COALESCE 补零 |
| `omni_base` | `traffic_omni_oa.dwd_order_item_atc_journey_di`（4次UNION ALL） | 构建全渠道归因视角（click/source1/source2/Platform四层），映射 `common_feature` 标签，计算归因加权 GMV |
| `omni_central_rebate_base` | `omni_base` + `central_base` + `rebate_base` | 六键关联整合归因 GMV 与收入/PRM，聚合到 `(grass_date, user_id, item_id, common_feature)` |
| `ads_base` | `dwd_advertise_performance_di` + `dim_common_feature_mapping_v2`（2次UNION ALL） | 映射广告入口为渠道标签，计算广告收入及广义 GMV |
| `net_rev_base` | `dws_user_net_ads_revenue_1d` + `dim_common_feature_mapping_v2`（2次UNION ALL） | 计算扣除返还后的净广告收入 |
| `ads_voucher_base` | `ads_order_voucher_1d` + `dim_common_feature_mapping_v2`（2次UNION ALL） | 计算广告侧承担的券补贴金额（`amt × (1 - cofund_ratio)`） |
| `real_pc2` | 以上四路 UNION ALL + `dim_item`（CACHE TABLE） | 整合所有收入与补贴数据，计算核心 PC2 指标，关联商品类目信息 |
| `item_pc2` | `real_pc2`（Platform行） | 计算商品级 PC2 率（`SUM(pc2) / SUM(omni_gmv_usd)`） |
| `category_pc2` | `real_pc2`（Platform行） | 计算类目级平台实测 PC2 率 |
| `local_category_pc2` | `traffic_omni_oa.dim_item_pc2_rate_map` | 获取类目级本地化基准 PC2 率（含实验版 v2），使用 `SUM(DISTINCT ...)` 去重聚合 |
| `adjusted_item_pc2` | `item_pc2` + `category_pc2` + `local_category_pc2` | 用本地化基准率对商品 PC2 率做校正：`item_pc2_rate × (local_rate / category_rate)` |
| `output` | `real_pc2` + `adjusted_item_pc2` | 最终整合，计算 `adjusted_proxy_pc2_usd_1d` 等派生字段，输出完整宽表 |

### 注意事项

1. **`common_feature = 'Platform'` 汇总行与明细行重叠**：ETL 中通过两段 UNION ALL 分别生成渠道明细行和 Platform 汇总行，二者数据存在重叠。`item_pc2` 和 `category_pc2` 的 PC2 率计算**仅使用 `Platform` 行**，以避免双重计算。使用本表时须同样注意此逻辑。

2. **`adjusted_proxy_pc2` 的分母为零风险**：`adjusted_item_pc2` 计算中若 `category_pc2_rate = 0`（类目无 GMV），校正公式将产生除零异常或 NULL。下游使用时需对此类情况做保护性过滤。

3. **上游 30 天窗口与分区关系**：`central_base`、`rebate_base`、`omni_base` 等均读取近 30 天数据，但最终写入按单日分区覆盖，每日数据由全量 30 天窗口聚合后筛选当日 `grass_date`，若历史日期的订单在窗口期内有补录，对应历史分区的数据可能因当日调度而被更新。

4. **`is_bi_excluded_rev_prm = 0` 过滤**：`central_base` 和 `rebate_base` 均排除了 BI 豁免订单（`is_bi_excluded_rev_prm = 1`），本表的佣金 / 手续费 / PRM 字段均不含豁免订单口径，与全量订单域数据存在差异。

5. **`ads_voucher_base` 的额外过滤**：在 `real_pc2` 的 UNION ALL 汇总中，`ads_voucher_base` 分支有额外过滤条件 `paid_ads_voucher_ads_part_amt_usd_1d > 0`，即仅保留有实际广告券金额的记录，负值或零值记录被排除，使用时需知晓此口径限制。

6. **各地区按本地时区参数化调度**：表通过 `${region}` / `${timezone}` 参数覆盖所有地区，每个地区独立调度、独立写入对应 `grass_region` 分区，`grass_date` 基于各地区本地时区生成。

---

*文档生成时间：2026-05-20*