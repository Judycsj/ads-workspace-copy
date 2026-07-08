<!-- ads-workspace-gdoc-sync: gdoc_id=1mPHGGi2fPABBFVz-tf-gKLyYX9HVEzS2I0XEpU377CE gdoc_url=https://docs.google.com/document/d/1mPHGGi2fPABBFVz-tf-gKLyYX9HVEzS2I0XEpU377CE/edit -->

# mp_paidads.ads_report_ng_tms_diff_1d

**分层**：ADS（应用数据服务层）
**主键**：`user_id` + `ads_entrance` + `ads_placement` + `page_type` + `page_section` + `target_type` + `platform` + `app_version` + `rn_ver` + `entry_point` + `traffic_type` + `sub_product_type` + `product_type` + `main_product_type` + `feature_detail` + `feature_group` + `feature` + `module` + `object` + `scenario` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1 调度，覆盖 `grass_date` 当日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告（Paid Ads）流量分析的核心 ADS 层宽表，**打通了广告投放绩效数据（report_ng）与流量埋点事件数据（TMS）两条数据链路**，将广告曝光/点击数据与全站流量曝光/点击数据在同一维度粒度下对齐，用于分析广告在各入口的流量渗透率（Ads Load）及点击效率差异。

表名中的 `diff` 体现了其设计初衷：通过 `entry_point_total_impression/click`（全量流量）与 `entry_point_ads_impression/click`（广告流量）的对比，量化各渠道、各流量类型下广告的填充率与变现效率。同时，`ads_deduplicated_impression`、`ads_raw_click`、`ads_deduct_click`、`ads_cps_dedup_click` 等多维度点击指标支持广告计费逻辑的精细分析。该表既覆盖 CPC/CPS 等标准广告产品，也覆盖 Display Ads（展示广告），并通过 `main_product_type` 区分 Video Ads、Live Ads 及其他广告形态。

典型使用场景包括：①广告入口渗透率（Ads Load）监控与归因；②各 `entry_point` / `traffic_type` / `product_type` 维度的广告效果 BI 看板；③用户级别的广告曝光与点击行为分析（`user_id` 粒度保留）；④广告侧与流量侧指标对比分析及数据质量核查。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前仅写入 `'local'` 分区，表示按各地区本地时区统计。查询时**必须指定** `tz_type = 'local'` 以避免全表扫描 |
| `grass_region` | string | 地区编码，大写，如 `'MY'`、`'TH'`、`'VN'` 等。各地区按本地时区参数化调度，覆盖所有运营地区 |
| `grass_date` | date | 数据日期（本地时区），格式 `yyyy-MM-dd`。每日刷新，查询时**必须指定** |

---

### 维度：用户与平台信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户 ID。ETL 过滤了 `user_id > 0 and user_id is not null`，不含游客流量 |
| `platform` | string | 终端平台，已由数字码转换为可读字符串：`ios_app`、`android_app`、`ios_web`、`android_web`、`pc_mall`、`ios_lite`、`android_lite`、`android_app_lite`、`xiapi`、`others`、`unknown`。⚠️ 来自广告侧（report_all）的行已做枚举映射，来自 TMS 侧的行直接取原始字符串，两侧格式需确认一致性 |
| `app_version` | string | App 版本号 |
| `rn_ver` | string | React Native 版本号。⚠️ 仅 TMS 侧数据行有值，广告侧（report_all）对应行此字段固定为 `null` |

---

### 维度：广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_entrance` | bigint | 广告入口编码（数字枚举），对应广告投放系统的 entrance 字段。⚠️ 仅广告侧（report_all）数据行有值，TMS 侧数据行此字段为 `null` |
| `ads_placement` | bigint | 广告位编码（数字枚举），如 `9` 代表 Display Ads 位。⚠️ 仅广告侧数据行有值，TMS 侧数据行为 `null` |
| `sub_product_type` | string | 广告子产品类型，来自 `dim_product_type_mapping`，未匹配时填充为 `'others'`。⚠️ TMS 侧数据行为 `null` |
| `product_type` | string | 广告产品类型，来自 `dim_product_type_mapping`，未匹配时填充为 `'others'`。⚠️ TMS 侧数据行为 `null` |
| `main_product_type` | string | 广告主产品类型，来自 `dim_product_type_mapping`，未匹配时填充为 `'Others'`；ETL 中过滤了 `Video Ads`、`Live Ads` 进入广告侧分支。⚠️ TMS 侧数据行为 `null` |

---

### 维度：流量入口与渠道

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point` | string | 流量入口名称，如 `'Global Search'`、`'Daily Discover External'`、`'Shop'`、`'You May Also Like'`、`'Image Search'` 等。广告侧通过 `dim_entry_point_mapping_v2` 由 `ads_entrance` 映射得到，TMS 侧通过埋点字段（`page_type`、`module`、`feature_group` 等）规则推导。未匹配时为 `'Undefined'` |
| `traffic_type` | string | 流量类型，来自 `dim_entry_point_mapping_v2`（按 `entry_point` 关联），未匹配时填充为 `'Undefined'`。广告侧已过滤 `Video`、`Livestream` 类型进入非 TMS 分支 |

---

### 维度：页面与场景属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `page_type` | string | 页面类型，如 `'search'`、`'home'` 等 |
| `page_section` | string | 页面子区域，可为 `null` |
| `target_type` | string | 目标内容类型，如 `'item'`、`'video'`、`'livestream'`、`'related_search'` 等 |
| `scenario` | string | 场景标识，来自 TMS 埋点的 `search_property.scenario`。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |

---

### 维度：TMS 埋点特征字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `module` | string | TMS 埋点模块，如 `'Image Search'`、`'Daily Discover'` 等。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |
| `feature` | string | TMS 埋点功能标识，如 `'mpp_ymal-order_list'`、`'odp_ymal-order_detail'` 等。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |
| `feature_detail` | string | TMS 埋点功能细节，颗粒度比 `feature` 更细。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |
| `feature_group` | string | TMS 埋点功能分组，如 `'You May Also Like'`、`'Cart Recommendation'`、`'Video'` 等。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |
| `object` | string | TMS 埋点对象标识。⚠️ 仅 TMS 侧数据行有值，广告侧数据行为 `null` |

---

### 指标：全站流量曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `entry_point_total_impression_cnt` | bigint | 入口总曝光数（含广告与非广告），来自 TMS 埋点 `operation = 'impression'` 的事件计数。⚠️ 广告侧数据行中，仅 `entry_point in ('Game', 'Shop Game', 'Voucher Master Recommendation')` 时才有值，其余行为 `0`，聚合时需注意避免重复叠加两侧数据 |
| `entry_point_total_click_cnt` | bigint | 入口总点击数（含广告与非广告），来自 TMS 埋点 `operation = 'click'` 的事件计数。⚠️ 同上，广告侧数据行中特定入口外均为 `0` |
| `entry_point_ads_impression_cnt` | bigint | 入口中广告曝光数，来自 TMS 埋点 `is_ads = 1` 的曝光事件。⚠️ 同上，广告侧行中特定入口外均为 `0`；与 `ads_deduplicated_impression_cnt` 口径不同，前者来自 TMS 埋点，后者来自广告系统 |
| `entry_point_ads_click_cnt` | bigint | 入口中广告点击数，来自 TMS 埋点 `is_ads = 1` 的点击事件。⚠️ 同上；与 `ads_deduct_click_cnt` 口径不同 |

---

### 指标：广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_deduplicated_impression_cnt` | bigint | 广告去重曝光数，来自广告投放系统的 `impression_cnt`（已去重）。⚠️ 仅广告侧数据行有值，TMS 侧行固定为 `0` |
| `ads_raw_click_cnt` | bigint | 广告原始点击数（未扣除无效点击），来自广告投放系统的 `raw_click_cnt`。⚠️ 仅广告侧数据行有值，TMS 侧行固定为 `0` |
| `ads_deduct_click_cnt` | bigint | 广告有效点击数（已扣除无效点击/反作弊处理后的计费点击）。计算逻辑：Display Ads（placement=9）取 `click_before_deduction_cnt`；CPS 定价（pricing_type=20）取 `cps_dedup_click`；其余取 `click_cnt`。⚠️ 仅广告侧数据行有值，TMS 侧行固定为 `0`；不同 placement/pricing_type 计算逻辑不同，不可跨产品类型直接比较 |
| `ads_cps_dedup_click` | bigint | CPS（按销售额计费）广告去重点击数，仅适用于 CPS 定价广告。⚠️ 仅广告侧数据行有值，TMS 侧行固定为 `0`；非 CPS 广告行此字段也会写入（值为 0），聚合时需配合 `main_product_type` 或 `pricing_type` 过滤 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下分区字段**，否则将触发全表扫描，消耗大量计算资源：

| 分区字段 | 推荐用法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `grass_date = '2024-01-15'` 或指定日期范围 | 扫描全部历史分区，查询极慢且费用高 |
| `grass_region` | `grass_region = 'MY'` | 扫描所有地区数据，结果混杂且资源消耗翻倍 |
| `tz_type` | **固定使用** `tz_type = 'local'` | 本表当前仅写入 `local` 分区；不指定则可能因分区不存在而返回空或扫描额外分区 |

**示例过滤写法**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2024-01-15'
```

### 不可直接 SUM 的字段

本表为 **广告侧（report_all）与 TMS 侧 UNION ALL 后再聚合的宽表**，两侧数据行在同一指标字段上存在互斥填充（一侧有值，另一侧为 0），因此使用时须注意：

1. **`entry_point_total_impression_cnt` / `entry_point_total_click_cnt`**：跨广告侧与 TMS 侧 SUM 时，两侧数据不会重复（广告侧大部分为 0，TMS 侧为真实值），但若按 `entry_point` 聚合时需确认是否同时含广告侧特殊入口（Game、Shop Game 等），避免口径混淆。

2. **`entry_point_ads_impression_cnt` 与 `ads_deduplicated_impression_cnt`**：口径来源不同（前者为 TMS 埋点，后者为广告投放系统），**不可相加，也不宜直接对比**，两者差值即为分析广告数据一致性的核心指标。

3. **`entry_point_ads_click_cnt` 与 `ads_deduct_click_cnt`**：同上，口径不同，不可混用。

4. **`ads_cps_dedup_click`（即 `ads_cps_dedup_click` 字段）**：仅对 CPS 定价广告有业务意义。如需分析 CPS 广告点击，需同时过滤 `main_product_type` 或结合 `product_type` 筛选 CPS 产品。

5. **比率类指标（如 Ads Load = `entry_point_ads_impression_cnt` / `entry_point_total_impression_cnt`）**：**不可对多行的比率结果直接 SUM/AVG**，必须先分别 SUM 分子与分母，再相除计算加权比率。

### 时效性说明

- 本表按 `grass_date` 分区，每日 T+1 调度，查询时应取**已完成调度的最新 `grass_date`** 分区。
- 来自广告侧的 Display Ads 数据在 ETL 中通过 `budget_end_datetime >= grass_date` 过滤有效广告，若广告预算结束日期早于数据日期则该广告数据不计入，分析时需注意此口径。
- TMS 数据源（`dwd_scenario_event_log_hi`、`dwd_item_event_log_hi`）为小时级宽表，ETL 按天聚合后写入本表，无小时级明细。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放绩效明细表，提供广告曝光、原始点击、有效点击、CPS 去重点击等核心广告指标 |
| `mkplpaidads_data.dim_display_ads__reg_s3_live` | 展示广告（Display Ads）维度表，提供广告预算有效期（`budget_start/end_datetime`），用于过滤有效期内的展示广告 |
| `traffic_omni_oa.dwd_scenario_event_log_hi__reg` | 场景级流量埋点事件明细（小时粒度），提供搜索、推荐等场景下的全站曝光/点击事件，用于计算 `entry_point_total/ads_impression/click` |
| `traffic_omni_oa.dwd_item_event_log_hi__reg_sensitive_live` | 商品级流量埋点事件明细（小时粒度），提供视频、YMAL、Shop 等特殊入口的商品曝光/点击事件 |
| `mp_paidads.dim_entry_point_mapping_v2` | 入口映射维表，将 `entry_point` 名称映射为 `entrance`（数字编码）与 `traffic_type`（流量类型） |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 产品类型映射维表，将 `pricing_type` + `placement` 组合映射为 `sub_product_type`、`product_type`、`main_product_type` |

---

## ETL 逻辑摘要

### 数据流

```
┌─────────────────────────────────────────────┐   ┌──────────────────────────────────────────┐
│  广告侧（Ads Side）                           │   │  流量侧（TMS Side）                        │
│                                             │   │                                          │
│  dwd_advertise_performance_di               │   │  dwd_scenario_event_log_hi               │
│         │                                   │   │         │                                │
│         ▼                                   │   │         ▼ (entry_point 规则推导)          │
│  [cache] report_ng                          │   │  tms (场景事件，含搜索/推荐等入口)          │
│     ├─→ report_ng_cpc                       │   │                                          │
│     │    (placement ≠ 9，CPC/CPS 广告)      │   │  dwd_item_event_log_hi__reg_sensitive    │
│     └─→ report_ng_display                  │   │         │                                │
│          (placement = 9，Display Ads)        │   │         ▼ (entry_point 规则推导)          │
│               │                             │   │  tms_item (商品事件，含Shop YMAL/Video等)  │
│               ▼ (JOIN display_ads 过滤有效期) │   │                                          │
│         display_perf                        │   │  tms_item(Undefined行过滤) + tms + Shop补充│
│               │                             │   │         │                                │
│  dim_entry_point_mapping_v2 ──────────────┐ │   │         ▼ (LEFT JOIN entry_point_mapping) │
│  dim_product_type_mapping   ──────────────┤ │   │  tms_all (含 traffic_type 映射)           │
│                                           │ │   │                                          │
│  report_ng_cpc + display_perf             │ │   └──────────────────────────────────────────┘
│         │ UNION ALL                        │ │                    │
│         ▼ (LEFT JOIN mapping 维表)         │ │                    │
│  report_all                               │ │                    │
│  (已排除 Video/Livestream 广告)            ◄─┘                    │
└───────────────────────────────────────────┘                     │
               │ UNION ALL ◄──────────────────────────────────────┘
               ▼
       [最终 UNION ALL 子查询]
       (广告侧 + TMS 侧，platform 数字→字符串映射)
               │
               ▼ GROUP BY 20个维度字段
       INSERT OVERWRITE
  ads_report_ng_tms_diff_1d__reg_s0_live
  partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `report_ng`（cache） | `dwd_advertise_performance_di` | 广告绩效基础数据，含曝光、原始点击、有效点击、CPS 去重点击，缓存至内存加速后续多次引用 |
| `report_ng_cpc` | `report_ng` | 过滤 `placement ≠ 9`，处理 CPC/CPS 标准广告，按维度聚合 |
| `report_ng_display` | `report_ng` | 过滤 `placement = 9`（展示广告位），保留 `ads_id` 用于关联有效期 |
| `display_ads` | `dim_display_ads__reg_s3_live` | 展示广告维度数据（含预算有效期），过滤当日有效广告 |
| `display_perf` | `report_ng_display` + `display_ads` | 将展示广告绩效与有效期维表 LEFT JOIN，过滤 `budget_end_datetime >= grass_date` 的有效广告，再聚合 |
| `tms` | `dwd_scenario_event_log_hi` | 场景级埋点流量，按规则推导 `entry_point`，统计全站及广告曝光/点击 |
| `tms_item` | `dwd_item_event_log_hi__reg_sensitive_live` | 商品级埋点流量，补充 Shop YMAL、Video YMAL 等特殊入口的曝光/点击 |
| `traffic_mapping` | `dim_entry_point_mapping_v2` | 入口编码→流量类型映射，供广告侧和 TMS 侧共用 |
| `product_type_mapping` | `dim_product_type_mapping__reg_s0_live` | `(pricing_type, placement)` → 产品类型三级分类映射 |
| `tms_all` | `tms_item` + `tms` | 合并两个 TMS 来源，`tms_item` 非 Undefined 行优先，`tms` 中 Global Search 额外补充 Shop 入口行，LEFT JOIN 补全 `traffic_type` |
| `report_all` | `report_ng_cpc` + `display_perf` | UNION ALL 合并两类广告，LEFT JOIN 入口映射和产品类型映射，排除 Video/Livestream 广告，聚合产出广告侧汇总结果 |

### 注意事项

1. **双数据源 UNION ALL 结构**：最终写入前，广告侧（`report_all`）与 TMS 侧（`tms_all`）通过 UNION ALL 合并。两侧在字段上存在大量互斥 `null`/`0` 填充——广告侧的 `feature`/`module`/`scenario` 等 TMS 专属字段为 `null`，TMS 侧的 `ads_deduplicated_impression_cnt`/`ads_raw_click_cnt` 等广告专属指标为 `0`。分析时若不区分两侧来源，聚合结果仍正确，但下钻时须注意字段有效性。

2. **Display Ads 有效期过滤**：`display_perf` 中通过 `budget_end_datetime >= grass_date` 过滤展示广告有效期，这意味着已过期广告的绩效数据不会进入本表，分析展示广告历史数据时需注意此口径限制。

3. **`entry_point` 的 Shop 补充逻辑**：`tms_all` 中对 `tms` 里 `entry_point = 'Global Search'` 的行额外 UNION 一份 `entry_point = 'Shop'` 的记录，即 Global Search 的流量同时计入 Shop 入口，使同一批曝光在两个入口均有统计，**聚合多个 `entry_point` 时可能造成重复计数**。

4. **`platform` 字段映射范围**：广告侧数字→字符串映射仅覆盖 `0~9`、`99`、`128`，超出范围的 `platform` 值将映射为 `null`；TMS 侧直接使用字符串原始值，两侧来源的 `platform` 枚举值格式理论一致，但应在使用前校验。

5. **`rn_ver` 的单侧填充**：`rn_ver`（React Native 版本）仅在 TMS 侧（`rn_version`）有值，广告侧硬编码为 `null`。若按 `rn_ver` 维度分析，只能反映 TMS 流量侧的数据。

6. **调度参数化**：ETL SQL 中出现的 `upper('${region}')`、`'${timezone}'`、`DATE('${grass_date}')` 均为调度模板参数，由调度平台按地区和日期注入，实现多地区、多日期的自动化覆盖。

---

*文档生成时间：2026-04-22*