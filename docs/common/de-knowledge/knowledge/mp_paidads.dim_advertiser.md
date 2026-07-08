<!-- ads-workspace-gdoc-sync: gdoc_id=1hYuJ9Eur6Dd6HY4YIX8RCGLlxTF8cci-x5FOE7x8dik gdoc_url=https://docs.google.com/document/d/1hYuJ9Eur6Dd6HY4YIX8RCGLlxTF8cci-x5FOE7x8dik/edit -->

# mp_paidads.dim_advertiser

**分层**：DIM（维度层）
**主键**：`shop_id`（联合 `grass_region`、`grass_date`、`tz_type`）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1，覆盖前一自然日）
**引用频次**：123 次（候选表范围内）

---

## 业务描述

`mp_paidads.dim_advertiser` 是付费广告域的**广告主维度宽表**，以店铺（`shop_id`）为粒度，聚合了广告账户基础属性、卖家身份标签、店铺经营状态、商品类目归属、自动化广告功能开关及充值配置等多维信息。每个广告主对应一条记录，是广告业务分析中最核心的维度表之一。

本表广泛用于广告主分层运营（官方店、优选店、托管卖家、跨境卖家等）、功能采纳率分析（自动充值、自动竞价、受众定向、预算自动增加、Auto Escrow 等）、广告主生命周期画像（账户创建时间、首次上架时间）以及 GMV/ROI 类报表的维度关联。下游 ETL 及报表均通过关联本表获取广告主标签，是付费广告数仓中引用最频繁的维度表之一。

本表按地区与时区参数化调度，各地区按本地时区独立调度，`tz_type='local'` 为标准分析口径。每日覆盖写入（INSERT OVERWRITE），保留历史快照，支持对广告主状态、功能开关等属性做时序分析。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `tz_type` | string | 时区类型分区。各地区按本地时区参数化调度，标准分析口径取 `tz_type = 'local'`。⚠️ 查询时必须指定，否则导致跨时区重复计数 |
| `grass_region` | string | 地区分区，如 `SG`、`MY`、`TH` 等大写地区代码。⚠️ 查询时必须指定，避免全表扫描 |
| `grass_date` | date | 日期分区，取值为业务前一日（`BIZ_YESTERDAY`）。⚠️ 查询时必须指定，避免全表扫描 |

---

### 维度：主键与广告账户标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，本表主键 |
| `user_id` | bigint | 卖家用户 ID |
| `beetalk_userid` | bigint | Beetalk 用户 ID，来源于 `shopeeods.s_account_tab`；当前 ETL 以 NULL 填充（`CAST(NULL AS bigint)`），实际可能为空 |
| `user_name` | string | 卖家用户名 |
| `language` | string | 广告商语言偏好，来源于 `shopeeods.s_account_tab`；当前 ETL 以 NULL 填充（`CAST(NULL AS string)`），实际可能为空 |

---

### 维度：账户与店铺状态

| 字段名 | 类型 | 说明 |
|---|---|---|
| `status` | tinyint | 用户账号状态（来源于 `mp_user.dim_user`） |
| `account_status` | tinyint | 广告账户状态（来源于广告账户表 `ads_account_tab`） |
| `shop_status` | tinyint | 店铺运营状态（来源于 `mp_user.dim_shop`） |
| `is_seller` | tinyint | 卖家是否有至少 1 个活跃商品。`1`=有活跃商品；`0`=无活跃商品 |

---

### 维度：账户时间信息

| 字段名 | 类型 | 说明 |
|---|---|---|
| `create_datetime` | string | 用户账号创建时间（本地时区格式，`yyyy-MM-dd HH:mm:ss`） |
| `modify_datetime` | string | 用户账号最近修改时间（本地时区格式） |
| `account_create_datetime` | string | 广告账户创建时间（本地时区格式）。⚠️ 时间戳由 SGT 转换至各地区本地时区，跨地区对比时须注意时区差异 |
| `account_create_timestamp` | bigint | 广告账户创建时间戳（Unix 秒级，SGT 基准） |
| `account_modify_datetime` | string | 广告账户最近修改时间（本地时区格式） |
| `account_modify_timestamp` | bigint | 广告账户最近修改时间戳（Unix 秒级，SGT 基准） |
| `shop_create_datetime` | string | 店铺创建时间（本地时区格式） |
| `shop_modify_datetime` | string | 店铺最近修改时间（本地时区格式） |
| `first_item_create_datetime` | string | 该店铺首次上架商品的时间，取 `MIN(create_datetime)` 自 `ods_shopee_item_v5_db__item_v5_tab_df__reg` |

---

### 维度：卖家身份标签

| 字段名 | 类型 | 说明 |
|---|---|---|
| `is_managed_seller` | tinyint | 是否为托管卖家（Managed Seller）。`1`=是；`0`=否；NULL 时 COALESCE 为 0 |
| `is_official_shop` | tinyint | 是否为官方商店（Official Shop）。`1`=是；`0`=否；NULL 时 COALESCE 为 0 |
| `is_preferred_shop` | tinyint | 是否为优选商店（Preferred Shop）。`1`=是；`0`=否；NULL 时 COALESCE 为 0 |
| `is_cb_seller` | tinyint | 是否为跨境卖家（Cross-Border Seller）。`1`=是；`0`=否；NULL 时 COALESCE 为 0 |
| `is_cb_sip_affiliated` | tinyint | SIP 标签：父店铺为跨境店时，子店铺标记为 1 |
| `is_local_sip_affiliated` | tinyint | SIP 标签：父店铺为本地店时，子店铺标记为 1 |
| `is_self_mcn` | tinyint | 是否为 MCN 用户。`1`=是；`0`=否 |
| `seller_type` | string | 店铺卖家类型，如 `MYCB`、`CNCB`、`Local` 等，来源于 `mp_seller.dim_shop_ext` |
| `seller_type_1p` | string | 1P 店铺细分类型，取值如 `Lovito`、`SCS`、`Local SCS`、`Others`、`Unknown`；无匹配时 COALESCE 为 `'Unknown'` |

---

### 维度：商品类目

| 字段名 | 类型 | 说明 |
|---|---|---|
| `shop_level1_global_be_category` | string | 店铺一级全球后端类目 |
| `shop_level1_fe_display_category` | string | 店铺一级前端展示类目 |
| `shop_level1_kpi_category` | string | 店铺一级 KPI 类目 |
| `shop_level2_global_be_category` | string | 店铺二级全球后端类目 |
| `shop_level2_fe_display_category` | string | 店铺二级前端展示类目 |
| `shop_level2_kpi_category` | string | 店铺二级 KPI 类目 |

---

### 维度：自动化广告功能开关

| 字段名 | 类型 | 说明 |
|---|---|---|
| `is_auto_topup_enabled` | tinyint | 是否开启自动充值功能。`1`=已开启；`0`=未开启 |
| `is_campaign_auto_bid_enabled` | tinyint | 是否开启广告活动自动竞价。`1`=已开启；`0`=未开启 |
| `is_auto_budget_increase_enabled` | tinyint | 是否开启预算自动增加功能。`1`=已开启；`0`=未开启 |
| `is_roi_three_voucher_enabled` | tinyint | 是否开启 ROI3 智能券功能。`1`=已开启；`0`=未开启 |
| `is_auto_escrow_enabled` | tinyint | 是否开启 Auto Escrow Top-Up 功能。`1`=已开启；`0`=未开启 |
| `is_auto_ads_solution_enabled` | tinyint | 是否开启 Automated Ads Solution（自动化广告方案，旨在提升 ROAS 和 GMV）。`1`=已开启；`0`=未开启 |
| `adopt_audience_targeting` | boolean | 历史上是否有至少 1 个广告系列开启受众定向（`group_status=1`）。`true`=已采用；`false`=未采用。⚠️ 为历史累计判断标签，非当日快照，不反映当前活跃状态 |

---

### 维度：自动充值配置

| 字段名 | 类型 | 说明 |
|---|---|---|
| `auto_topup_threshold_amt` | double | 触发自动充值的余额阈值（本地货币），原始值除以 100000 换算。⚠️ 为配置值，不可直接 SUM 做汇总分析 |
| `auto_topup_threshold_amt_usd` | double | 触发自动充值的余额阈值（美元），由本地货币除以当日汇率换算。⚠️ 汇率时点为 `BIZ_YESTERDAY`，跨期对比需注意汇率变化 |
| `auto_topup_amt` | double | 每次自动充值金额（本地货币），原始值除以 100000 换算。⚠️ 为配置值，不可直接 SUM 做汇总分析 |
| `auto_topup_amt_usd` | double | 每次自动充值金额（美元）。⚠️ 汇率时点为 `BIZ_YESTERDAY` |
| `auto_topup_daily_cap_amt` | double | 自动充值每日上限金额（本地货币），原始值除以 100000 换算。⚠️ 为配置值，不可直接 SUM 做汇总分析 |
| `auto_topup_daily_cap_amt_usd` | double | 自动充值每日上限金额（美元）。⚠️ 汇率时点为 `BIZ_YESTERDAY` |

---

### 维度：预算自动增加配置

| 字段名 | 类型 | 说明 |
|---|---|---|
| `auto_budget_increase_daily_cap` | int | 预算自动增加每日最大次数上限。⚠️ 为配置值，不可直接 SUM 做汇总分析 |
| `auto_budget_increase_percentage` | double | 预算自动增加的百分比（`increase_pct / 100000.0`，如 0.1 表示 10%）。⚠️ 为预计算比率字段，不可直接 SUM |
| `auto_budget_increase_effective_types` | array\<int\> | 预算自动增加功能适用的广告类型列表（整数数组）。⚠️ 数组类型，查询时需使用 `LATERAL VIEW EXPLODE` 展开后再筛选 |

---

### 维度：Auto Escrow 配置

| 字段名 | 类型 | 说明 |
|---|---|---|
| `auto_escrow_additional_fee_rate` | double | 广告主在 Auto Escrow 自动充值中设置的附加费率（`additional_fee_rate / 100000.0`，如 0.03 表示 3%，最大 1.0 表示 100%）。⚠️ 为预计算比率字段，不可直接 SUM |
| `auto_escrow_fixed_program_fee_rate` | double | 平台在 Auto Escrow 自动充值中设置的固定项目费率（`fixed_program_fee_rate / 100000.0`）。⚠️ 为预计算比率字段，不可直接 SUM |

---

### 维度：账户余额与版本

| 字段名 | 类型 | 说明 |
|---|---|---|
| `balance` | bigint | 广告账户当前余额（单位为平台内部计量单位，非直接货币金额）。⚠️ 注意单位，勿与本地货币金额混用 |
| `version_flag` | int | 记录版本标志，用于版本控制和变更追踪。⚠️ 当前 ETL 中未见赋值逻辑，实际写入值需核实 |
| `version_tag` | int | 广告账户 Setup Flow 版本号，来源于 `decoded_extinfo.setup_flow_version.version` |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区条件，否则将触发全表扫描，造成资源浪费及结果重复：

```sql
WHERE tz_type      = 'local'          -- 标准分析口径，避免跨时区重复计数
  AND grass_region = 'SG'             -- 替换为目标地区代码（大写）
  AND grass_date   = '2026-04-21'     -- 替换为目标日期
```

- **`tz_type`**：必须指定 `'local'`（本地时区口径）。遗漏将导致同一广告主被多时区重复统计。
- **`grass_region`**：必须指定目标地区。遗漏将触发全地区扫描，且跨地区 `shop_id` 可能冲突。
- **`grass_date`**：必须指定目标日期。遗漏将扫描全量历史数据，产生大量重复记录。

---

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|---|---|---|
| `auto_budget_increase_percentage` | 预计算比率（原始值 / 100000），直接 SUM 无业务含义 | 用于筛选、分组或展示单条记录值 |
| `auto_escrow_additional_fee_rate` | 预计算比率，直接 SUM 无意义 | 用于筛选或展示配置值 |
| `auto_escrow_fixed_program_fee_rate` | 预计算比率，直接 SUM 无意义 | 用于筛选或展示配置值 |
| `auto_topup_threshold_amt` / `_usd` | 每个广告主的独立配置值，SUM 无业务含义 | 用于分布分析时取 `AVG` / `PERCENTILE` |
| `auto_topup_amt` / `_usd` | 同上 | 同上 |
| `auto_topup_daily_cap_amt` / `_usd` | 同上 | 同上 |
| `auto_budget_increase_daily_cap` | 每个广告主的独立配置值 | 同上 |
| `balance` | 单位为平台内部计量单位，非货币金额，直接 SUM 需确认单位换算 | 汇总前确认单位与业务需求一致 |
| `auto_budget_increase_effective_types` | 数组类型，不可直接聚合 | 使用 `LATERAL VIEW EXPLODE(auto_budget_increase_effective_types)` 展开后再统计 |

---

### 时效性说明

本表为**每日全量快照**，每个分区（`grass_date`）存储该日广告主的最新状态。

- 查询当前最新状态：取 `grass_date = CURRENT_DATE - 1`（即最新可用分区）。
- `adopt_audience_targeting` 字段为**历史累计标签**，基于全量历史数据判断，非仅当日数据，使用时需了解其累计语义。
- `auto_topup_*_usd` 和 `auto_topup_*_usd` 美元换算字段使用的是当日（`BIZ_YESTERDAY`）汇率，跨日期对比时汇率不同，需注意汇率影响。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.shopee_ads_${region}_${db_type}__ads_account_tab__reg_continuous_s0_live` | 广告账户核心字段，含余额、状态、各类功能开关及配置参数（通过解析 `_decoded_extinfo` JSON 字段获取） |
| `mp_paidads.shopee_ads_${region}_${db_type}__target_audience_group_tab__reg_continuous_s0_live` | 受众定向组信息，用于判断广告主是否采用受众定向（`adopt_audience_targeting`） |
| `mp_user.dim_user__reg_s0_live` | 用户基础信息（`user_name`、`status`、`is_cb_shop`、注册时间等） |
| `mp_user.dim_shop__reg_s0_live` | 店铺信息（店铺状态、创建时间、是否官方店/优选店/托管店） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 当日汇率，用于本地货币金额转换为 USD |
| `mp_seller.dim_shop_ext__reg_s0_live` | 1P 卖家扩展信息（`seller_type`、`is_cb_sip_affiliated`、`is_local_sip_affiliated`、GGP 卖家名称） |
| `marketplace.ods_shopee_item_v5_db__item_v5_tab_df__reg` | 商品原始数据，用于计算店铺首次上架时间（`first_item_create_datetime`） |
| `mp_item.dws_shop_listing_td__reg_s0_live` | 店铺商品类目汇总，提供一二级类目标签 |
| `mp_paidads.dim_local_scs_shop_list` | 本地 SCS 店铺白名单，用于标记 `seller_type_1p = 'Local SCS'` |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_*__ads_account_tab          mp_paidads.*__target_audience_group_tab
  (JSON 解析 _decoded_extinfo，除以 100000 换算)         (group_status=1 计数)
              │                                                  │
              ▼                                                  ▼
      [CTE: account_tab_df]                     [CTE: adopt_target_audience_flag]
              │
              ├──── LEFT JOIN ──── mp_user.dim_user__reg_s0_live
              │                    (user_name, status, is_cb_seller)
              │
              ├──── LEFT JOIN ──── mp_user.dim_shop__reg_s0_live  (x2)
              │                    (shop_status, shop时间, 官方/优选/托管标签)
              │
              ├──── LEFT JOIN ──── mp_order.dim_exchange_rate__reg_s0_live
              │                    (汇率，本地货币→USD)
              │
              ├──── LEFT JOIN ──── marketplace.ods_shopee_item_v5_db__item_v5_tab_df__reg
              │                    (MIN(create_datetime) → first_item_create_datetime)
              │
              ├──── LEFT JOIN ──── mp_item.dws_shop_listing_td__reg_s0_live
              │                    (类目标签)
              │
              ├──── LEFT JOIN ──── adopt_target_audience_flag
              │                    (adopt_audience_targeting 布尔标签)
              │
              └──── LEFT JOIN ──── [CTE: seller_1p]
                                   (mp_seller.dim_shop_ext + mp_paidads.dim_local_scs_shop_list)
                                   (seller_type, seller_type_1p, SIP 标签)
                                          │
                                          ▼
                          INSERT OVERWRITE dim_advertiser__reg_s0_live
                          PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|---|---|---|
| `account_tab_df` | `shopee_ads_*__ads_account_tab__reg_continuous_s0_live` | 解析广告账户 `_decoded_extinfo` JSON 字段，提取自动充值、自动竞价、预算自动增加、Auto Escrow 等各类功能的开关与配置参数；金额字段统一除以 100000 换算为实际金额；时间戳从 SGT 转换至本地时区 |
| `adopt_target_audience_flag` | `shopee_ads_*__target_audience_group_tab__reg_continuous_s0_live` | 对 `group_status=1` 的记录按 `userid` 聚合计数，标识历史上是否启用过受众定向功能 |
| `seller_1p` | `mp_seller.dim_shop_ext__reg_s0_live` + `mp_paidads.dim_local_scs_shop_list` | 关联 GGP 卖家名称与 SCS 白名单，生成细粒度 1P 卖家分类标签 `seller_type_1p` |

### 注意事项

1. **金额字段单位换算**：广告账户原始表中的金额字段（auto_topup_threshold/amount/daily_cap 等）以整数存储（放大 100000 倍），ETL 中统一除以 100000 还原为实际金额。`balance` 字段**未做此换算**，单位为平台内部计量单位，使用前需确认业务口径。

2. **时间戳时区转换**：广告账户表时间戳以 SGT（新加坡时间，Asia/Singapore）为基准存储，ETL 中通过 `from_utc_timestamp(to_utc_timestamp(..., 'Asia/Singapore'), '${timezone}')` 转换为各地区本地时区输出为 datetime 字符串。各地区按本地时区参数化调度，datetime 字段值随地区不同而不同。

3. **`dim_shop__reg_s0_live` 被关联两次**：第一次取 `shop_status`、`shop_create_datetime`、`shop_modify_datetime`；第二次取 `is_official_shop`、`is_preferred_shop`、`is_managed_shop`。两次均使用 `user_id` 或 `shop_id` 关联，注意去重（均使用 `DISTINCT`）。

4. **`adopt_audience_targeting` 为历史累计标签**：基于广告主历史全量受众定向组数据判断（`group_status=1` 曾存在即为 `true`），不限于特定时间窗口，反映的是广告主**曾经**是否使用过该功能，而非当前活跃状态。

5. **`language` 与 `beetalk_userid` 字段**：当前 ETL 中两个字段均以 `CAST(NULL AS ...)` 方式写入，实际值始终为 NULL，字段保留用于兼容下游 schema，勿依赖其值进行业务判断。

6. **`seller_type` 与 `seller_1p`**：来源于 `mp_seller.dim_shop_ext__reg_s0_live`，使用 `PREV_2D`（前两日）分区，与其他上游表使用 `BIZ_YESTERDAY` 存在一日差异，系 `dim_shop_ext` 数据可用时效所致。

7. **`auto_budget_increase_effective_types` 数组字段**：存储为 `array<int>`，若需按广告类型筛选，须使用 `LATERAL VIEW EXPLODE` 展开，不可直接用 `=` 比较。

*文档生成时间：2026-04-22*