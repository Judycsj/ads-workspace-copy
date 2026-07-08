<!-- ads-workspace-gdoc-sync: gdoc_id=1_NBOFR4LGubu5QAQb5id4984ydRpLZ25D2b_X2tKatE gdoc_url=https://docs.google.com/document/d/1_NBOFR4LGubu5QAQb5id4984ydRpLZ25D2b_X2tKatE/edit -->

# mp_paidads.ads_campaign_entrance_attribution_metrics_1d

**分层**：ADS（应用数据服务层）
**主键**：`campaign_id` + `click_event_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表围绕**广告投放入口归因**主题，将广告主创建 Campaign 时所经由的入口点击事件（TMS 埋点）与该 Campaign 的实际广告消耗和商品供给数据进行关联，形成"入口 → Campaign → 消耗 → 商品"的完整链路视图。核心回答的业务问题是：**广告主通过哪些产品入口（`entrance_feature` / `entrance_feature_group`）创建了 Campaign，这些 Campaign 当日产生了多少净广告收入，以及覆盖了多少活跃广告商品**。

本表主要服务于付费广告（Paid Ads）产品增长与运营团队，用于评估各广告创建入口的拉新效果与变现能力，支持入口投资回报率分析、入口漏斗对比、以及去除 1P/SIP 商家干扰后的市场健康度评估。

各地区按本地时区（`tz_type = 'local'`）参数化调度，当前版本分区固定写入 `tz_type = 'local'`，数据仅覆盖 Campaign 创建日与消耗日均为分区日的记录（即新建 Campaign 当日消耗口径）。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前 ETL 仅写入 `'local'`（各地区本地时区），查询时**必须指定此字段**以避免全分区扫描 |
| `grass_region` | string | 地区编码（大写），如 `'ID'`、`'TH'`、`'MY'` 等，通过调度参数 `${region}` 参数化覆盖各地区 |
| `grass_date` | date | 数据日期（本地时区），对应广告消耗统计日，格式 `YYYY-MM-DD` |

---

### 维度：主键与广告主信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_id` | bigint | Campaign 唯一标识，广告投放活动的核心主键 |
| `shop_id` | bigint | 广告主店铺 ID，来源于广告消耗明细表（`campaign_rev`） |
| `user_id` | bigint | 广告主用户 ID，来源于入口归因维表 |

---

### 维度：Campaign 创建属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `main_product_type` | string | 广告产品类型，如搜索广告、发现广告等 |
| `campaign_create_datetime` | string | Campaign 创建时间（字符串格式），来源于入口归因维表 ⚠️ 存储为 string 而非 timestamp，范围过滤请转换后比较，如 `cast(campaign_create_datetime as timestamp)` |
| `campaign_create_timestamp` | bigint | Campaign 创建时间戳（毫秒级或秒级），与 `campaign_create_datetime` 语义一致，建议用此字段做数值比较 ⚠️ 注意确认时间戳单位（毫秒/秒）后再换算 |
| `api_creation_method` | int | Campaign 创建时使用的 API 入口点编码，用于区分不同创建路径（如界面创建、批量 API 创建等） |
| `platform` | string | 广告主创建 Campaign 所用的平台，如 `'web'`、`'shopee app'` 等 |

---

### 维度：入口点击归因属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `click_event_id` | string | 归因关联到的入口点击埋点的 TMS `click_event_id`，是入口归因的核心关联键 |
| `click_feature_detail` | string | 归因点击事件的埋点位置描述，格式为 `page_type-page_section-target_type`，用于精细化定位点击发生的页面结构 |
| `click_event_timestamp` | bigint | 归因入口点击事件的时间戳 ⚠️ 注意确认时间戳单位（毫秒/秒）后再换算 |
| `click_event_datetime` | string | 归因入口点击事件的时间（字符串格式）⚠️ 存储为 string，范围过滤需类型转换 |
| `entrance_feature` | string | 归因关联到的入口名称，标识广告主从哪个具体功能入口进入创建流程 |
| `entrance_feature_group` | string | 入口分组名称，是 `entrance_feature` 的上层归类，用于在报表中汇总同类入口的表现 |

---

### 指标：广告消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `net_expenditure_amt_usd_1d` | double | Campaign 当日净广告收入（USD），来源于 `ads_advertise_mkt_1d` 的 `net_ads_revenue_usd_1d` 汇总，仅含特定 placement（0/2/3/5/40/50/1200/1202/1205/2003）且 Campaign 创建日与消耗日相同的记录 ⚠️ 已在 ETL 中按 campaign_id 维度聚合求和，若在本表基础上再按更粗粒度汇总时可 SUM，但需注意本表粒度为 campaign_id + click_event_id + item_id 聚合后的结果，跨行 SUM 存在重复计数风险——建议先确认分析粒度再决定是否直接 SUM |

---

### 指标：活跃商品供给

| 字段 | 类型 | 说明 |
|------|------|------|
| `active_ads_item_cnt` | bigint | Campaign 下当日活跃广告商品数（去重 item_id 计数），包含所有商家类型 |
| `active_ads_item_cnt_excl_1p_sip` | bigint | Campaign 下当日活跃广告商品数，**已排除 1P 商家（Lovito、SCS）及 SIP 商家**，同时要求 30 日内有平台成交且当日有消耗或曝光，并排除指定黑名单店铺 ⚠️ 与 `active_ads_item_cnt` 口径不同，两者不可直接相减得到 1P/SIP 商品数，因排除条件涉及多个维度筛选 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致查询超时或产生高额计算费用：

| 分区字段 | 推荐过滤方式 | 说明 |
|----------|-------------|------|
| `tz_type` | `tz_type = 'local'` | 当前 ETL 仅写入 `'local'`，不指定会扫描空分区但仍引发全分区路径遍历 |
| `grass_region` | `grass_region = 'ID'`（按需替换） | 必须为大写地区编码；遗漏将扫描所有地区分区，数据量成倍放大 |
| `grass_date` | `grass_date = '2026-04-21'` 或 `grass_date between ... and ...` | 日期分区，遗漏将触发全历史扫描 |

```sql
-- ✅ 正确示例
select *
from mp_paidads.ads_campaign_entrance_attribution_metrics_1d__reg_s0_live
where tz_type      = 'local'
  and grass_region = 'ID'
  and grass_date   = '2026-04-21';
```

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确处理方式 |
|------|------|-------------|
| `net_expenditure_amt_usd_1d` | 本表粒度为 campaign_id × click_event_id（入口归因行），同一 campaign 若归因到多个入口点击则会出现多行，直接 SUM 可能造成消耗重复计算 | 分析 Campaign 维度消耗时，先 `group by campaign_id` 取唯一值或在上游 `campaign_rev` 视图层汇总；分析入口维度消耗时，需明确业务口径是否允许跨入口叠加 |
| `active_ads_item_cnt` / `active_ads_item_cnt_excl_1p_sip` | 商品计数已在 campaign 粒度下 `count(distinct item_id)` 计算，多行 SUM 会高估商品数 | 若需要跨 campaign 的唯一商品数，需回溯到明细层重新 `count(distinct item_id)`；若仅需 campaign 维度汇总，确保 `group by campaign_id` 后再取值 |
| `campaign_create_datetime` / `click_event_datetime` | 存储为 string 类型，不支持直接范围比较 | 使用 `cast(... as timestamp)` 或 `to_date(...)` 转换后再过滤 |

### 时效性说明

- 本表为 **T+1 日调度**，`grass_date = current_date - 1` 为最新可用分区。
- ETL 中额外过滤了 `date(ads_create_datetime) = grass_date`，即**仅统计 Campaign 创建日当天的消耗**，不含历史 Campaign 在该日的消耗。若需分析存量 Campaign 的日常消耗，本表不适用，应使用 `ads_advertise_mkt_1d` 等明细表。
- 入口归因数据来源于 `dim_campaign_entrance_attribution`，仅包含**能被成功归因到入口点击事件**的 Campaign；无法归因的 Campaign（如直接 API 创建、无埋点路径）不在本表中，分析覆盖率时需注意。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `dim_campaign_entrance_attribution__reg_s0_live` | 提供 Campaign 与入口点击事件的归因关系，输出 `click_event_id`、`entrance_feature`、`entrance_feature_group`、`click_feature_detail` 等归因维度及 Campaign 创建属性 |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 提供 Campaign 下各广告商品（item）维度的日度净广告消耗，过滤指定 placement 及当日新建 Campaign，汇总得到 `net_expenditure_amt_usd_1d` |
| `mp_paidads.ads_item_supply_1d__reg_s0_live` | 提供商品供给侧属性，包括是否活跃广告商品、是否 1P/SIP 商家、30 日成交量等，用于计算 `active_ads_item_cnt` 和 `active_ads_item_cnt_excl_1p_sip` |

---

## ETL 逻辑摘要

### 数据流

```
dim_campaign_entrance_attribution__reg_s0_live
  │  过滤: grass_region, grass_date, tz_type='local'
  │  输出: campaign_id → 入口归因维度
  └─────────────────────────────────┐
                                    │ LEFT JOIN on campaign_id
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
  │  过滤: grass_region, grass_date, ads_create_datetime=grass_date
  │        placement in (0,2,3,5,40,50,1200,1202,1205,2003)
  │        is_ads_active=1 OR has_performance=1
  │  输出: campaign_id, shop_id, item_id → net_expenditure_amt_usd_1d
  └─────────────────────────────────┤  (驱动表 campaign_rev)
                                    │ LEFT JOIN on item_id
mp_paidads.ads_item_supply_1d__reg_s0_live
  │  过滤: grass_region, grass_date, tz_type='local'
  │  输出: item_id → is_active_excl_1p_sip 标记
  └─────────────────────────────────┤
                                    ▼
              GROUP BY campaign_id, shop_id, user_id,
                       main_product_type, 创建属性, 入口归因属性
                       → SUM(net_expenditure_amt_usd_1d)
                       → COUNT(DISTINCT item_id)                [active_ads_item_cnt]
                       → COUNT(DISTINCT item_id WHERE excl=1)   [active_ads_item_cnt_excl_1p_sip]
                                    │
                                    ▼
  ads_campaign_entrance_attribution_metrics_1d__reg_s0_live
  partition(tz_type='local', grass_region, grass_date)
  [INSERT OVERWRITE, 每日全量覆盖]
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|---------------|--------|------|
| `new_campaign` | `dim_campaign_entrance_attribution__reg_s0_live` | 拉取指定地区、日期的 Campaign 入口归因记录，包含入口点击事件全部维度字段 |
| `campaign_rev` | `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 汇总指定地区、日期、指定 placement 范围内的 Campaign 当日净消耗，精确到 campaign_id × shop_id × item_id 粒度 |
| `item_supply` | `mp_paidads.ads_item_supply_1d__reg_s0_live` | 计算每个 item 是否满足"活跃且排除 1P/SIP"的判断标记 `is_active_excl_1p_sip` |

### 注意事项

1. **驱动表为消耗表**：最终 INSERT 以 `campaign_rev`（消耗明细）为驱动表，LEFT JOIN `item_supply` 和 `new_campaign`。这意味着**只有当日有消耗记录的 Campaign 才会出现在本表中**；有入口归因但当日无消耗的 Campaign 不会写入。

2. **入口归因为 LEFT JOIN**：`new_campaign` 以 LEFT JOIN 方式关联，若某 Campaign 在归因维表中不存在，则 `click_event_id`、`entrance_feature` 等入口字段为 NULL，但该 Campaign 的消耗和商品计数仍会保留。分析入口效果时需过滤 `click_event_id is not null`。

3. **消耗口径限制**：`campaign_rev` 额外要求 `date(ads_create_datetime) = grass_date`，即**只统计在分区日当天创建的广告商品产生的消耗**，不含历史日期创建的广告在分区日的续投消耗。此口径与通常意义的"Campaign 日消耗"不同，使用前需与业务方确认。

4. **黑名单店铺排除**：`item_supply` 中硬编码排除了 6 个 `shop_id`（1173241077、1206023866、1195230934、1200824394、50662979、851157471），这些店铺的商品不计入 `active_ads_item_cnt_excl_1p_sip`，但仍计入 `active_ads_item_cnt`。

5. **分区写入策略**：`INSERT OVERWRITE PARTITION(tz_type='local', grass_region, grass_date)` 为动态分区覆盖写入，每次调度会覆盖当日分区数据，历史分区数据不受影响。

6. **参数化调度**：ETL SQL 中出现的 `upper('${region}')`、`DATE('${grass_date}')` 均为调度模板变量，由调度系统按地区和日期参数化注入，覆盖所有上线地区，各地区按本地时区独立调度。

---

*文档生成时间：2026-04-22*