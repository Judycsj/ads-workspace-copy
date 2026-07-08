<!-- ads-workspace-gdoc-sync: gdoc_id=1Cj5FifyO3RvGJQXuItRMulBdeatp7Yy-u-GFNB2upkc gdoc_url=https://docs.google.com/document/d/1Cj5FifyO3RvGJQXuItRMulBdeatp7Yy-u-GFNB2upkc/edit -->

# mp_paidads.dim_campaign_entrance_attribution

**分层**：DIM（维度层）
**主键**：`campaign_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录每个 **Product Ads Campaign 的创建入口归因信息**，即在 Campaign 创建前的归因窗口内（创建时间戳前 86400 秒 ~ 后 60 秒），将 Campaign 的创建行为关联到卖家在 Web、Shopee APP 或 Seller APP 上的具体点击埋点，从而识别卖家是通过哪个产品入口触发了广告创建动作。

典型使用场景包括：**广告创建入口效果分析**（各入口对新广告创建的带动能力）、**卖家行为路径分析**（创建前的页面浏览与点击路径还原）、以及**广告产品运营决策支撑**（入口曝光位置与创建转化的归因分析）。

本表每日仅收录**当日新建**的 Product Ads Campaign（`date(campaign_create_datetime) = grass_date`），配合入口点击埋点和创建前末次页面浏览信息，为广告运营和产品团队提供精准的入口归因维度，是 Campaign 增长归因体系的核心维表。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `local`（各地区按本地时区参数化调度）。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 地区编码（大写），如 `MY`、`TH`、`PH` 等，覆盖所有调度地区 |
| `grass_date` | date | 数据日期（本地时区），对应 Campaign 创建所在日期 |

---

### 维度：Campaign 主体信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_id` | bigint | Campaign 唯一标识，本表主键 |
| `shop_id` | bigint | 创建该 Campaign 的店铺 ID |
| `user_id` | bigint | 创建该 Campaign 的用户 ID |
| `main_product_type` | string | 广告产品类型，本表当前仅包含 `Product Ads` |
| `campaign_create_datetime` | string | Campaign 创建时间（字符串格式，本地时区），例如 `2024-01-15 10:23:45` |
| `campaign_create_timestamp` | bigint | Campaign 创建时间戳（毫秒级 Unix 时间戳）。⚠️ 为毫秒级，与点击事件时间戳做差值计算时需注意单位对齐 |

---

### 维度：Campaign 创建渠道与平台

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `api_creation_method` | int | Campaign 创建的 API 入口枚举值（`creation_entry_point`），标识通过哪个 API 路径创建，可关联 `dim_campaign_entrance_mapping` 的 `api_enum` 字段解码 |
| `be_creation_platform` | int | 后端记录的创建平台枚举值（`creation_platform`），如 `1` 表示 `PLATFORM_PC`（Web Seller Center）；本字段用于过滤 view_tracking 归因路径 |
| `platform` | string | 归因到的入口所在平台，取自点击埋点或 mapping 表回填，值域为 `Web`、`Shopee APP`、`Seller APP`。⚠️ 由 `COALESCE(点击来源platform, mapping默认platform)` 合并而来，若点击未命中则使用 mapping 表缺省值 |
| `is_cb_shop` | tinyint | 是否为跨境店铺，`1` 表示是，`0` 表示否；来源于 `mp_user.dim_shop` |

---

### 维度：入口点击归因信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `click_event_id` | string | 关联到的入口点击埋点 TMS event_id，唯一标识一次点击事件 |
| `click_feature_detail` | string | 点击埋点的页面特征拼接字段，格式为 `page_type-page_section[0]-target_type`，用于与 mapping 表匹配 |
| `click_event_timestamp` | bigint | 关联点击事件的时间戳（毫秒级）。⚠️ 为毫秒级，换算秒级时需除以 1000 |
| `click_event_datetime` | string | 关联点击事件时间（字符串格式），由 `from_unixtime(click_event_timestamp / 1000)` 转换 |
| `entrance_feature` | string | 关联入口的名称，来自 mapping 表，标识具体的广告创建入口（如特定横幅、诊断卡等）。⚠️ 由 `COALESCE(点击匹配结果, mapping默认值)` 填充，`api_creation_method` 无法匹配到点击时仍可能有值 |
| `entrance_feature_group` | string | 关联入口的分组名称，来自 mapping 表，是 `entrance_feature` 的上级分类，便于按入口大类汇总分析。⚠️ 同上，存在 COALESCE 回填逻辑 |

---

### 维度：创建前末次页面浏览信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `last_view_page_type` | string | Campaign 创建前，用户在 Seller Center Web 端（`be_creation_platform = 1`）末次浏览页面的页面类型，来源于 `sellercenter_dwd_view_di` |
| `last_view_event_timestamp` | bigint | 末次页面浏览事件的时间戳（毫秒级）。⚠️ 为毫秒级；仅 `be_creation_platform = 1` 的 Campaign 才会有此字段，其他平台为 NULL |
| `last_view_event_datetime` | string | 末次页面浏览事件时间（字符串格式），由 `from_unixtime(last_view_event_timestamp / 1000)` 转换；仅 Web 端创建场景下有效 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，避免全表扫描导致性能劣化或数据重复：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区，遗漏不影响结果但触发不必要的分区枚举 |
| `grass_region` | `grass_region = 'MY'`（按需替换地区） | 遗漏将扫描所有地区数据，严重影响性能且结果集膨胀 |
| `grass_date` | `grass_date = '2024-01-15'` 或指定日期范围 | 遗漏将全量扫描历史数据，极大影响查询性能 |

**示例过滤子句**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2024-01-15'
```

### 不可直接 SUM 的字段

本表为维度表，所有字段均为维度属性或 ID 类字段，**无指标字段**，不存在直接 SUM 的业务场景。以下字段有特殊使用注意事项：

- **`campaign_create_timestamp` / `click_event_timestamp` / `last_view_event_timestamp`**：均为**毫秒级**时间戳，计算时间差时需除以 1000 转换为秒，不可与秒级时间戳直接比较。
- **`platform` / `entrance_feature` / `entrance_feature_group`**：存在 `COALESCE` 回填逻辑，当点击事件未命中时由 mapping 表默认值填充，分析时应注意区分"有点击归因"与"仅 API 归因"两类数据的口径差异。
- **`last_view_page_type` / `last_view_event_timestamp` / `last_view_event_datetime`**：仅对 `be_creation_platform = 1`（PC Web 端）的 Campaign 有效，其他平台创建的 Campaign 此三字段为 NULL，过滤时需注意。

### 时效性说明

- 本表每日覆盖**当日新建 Campaign**（`date(campaign_create_datetime) = grass_date`），查询特定日期的新建广告数据，取对应 `grass_date` 分区即可。
- 点击归因窗口为 Campaign 创建时间戳前 86400 秒（约前一天）至后 60 秒，因此 ETL 拉取了 `grass_date` 及前一日的点击/浏览埋点数据；数据通常于次日（T+1）产出，取最新 `grass_date` 分区获取最新数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_campaign_entrance_mapping__reg_s0_live` | 入口归因规则维表，提供 `api_enum`、`entrance_feature`、`entrance_feature_group`、`tracking_feature`、`restriction` 等匹配规则 |
| `mp_paidads.dim_advertise__reg_s0_live` | 筛选当日 Product Ads 类型的 Campaign ID |
| `mp_paidads.dim_campaign__reg_s0_live` | 提供 Campaign 基础属性：`shop_id`、`user_id`、`campaign_create_datetime`、`campaign_create_timestamp`、`creation_entry_point`、`creation_platform` |
| `mp_user.dim_shop__reg_s0_live` | 提供店铺是否为跨境店（`is_cb_shop`） |
| `traffic.sellercenter_dwd_click_di__reg_live` | Web Seller Center 端点击埋点数据 |
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | Shopee APP 端点击埋点数据 |
| `traffic.seller_dwd_all_di__reg_live` | Seller APP 端点击埋点数据（`operation='click'`，`app_id=286`） |
| `traffic.sellercenter_dwd_view_di__reg_live` | Web Seller Center 端页面浏览埋点数据，用于补充末次浏览页面归因 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_advertise                    mp_paidads.dim_campaign
(筛选 Product Ads Campaign ID)              (Campaign 基础属性)
            │                                         │
            └──────────── JOIN(campaign_id) ──────────┘
                                  │
                           [new_campaign]
                      (当日新建 Product Ads,
                       含 shop_id/user_id/
                       create_ts/platform/is_cb_shop)
                                  │
              ┌───────────────────┼──────────────────────┐
              │                   │                       │
         LEFT JOIN           LEFT JOIN                   │
              │                   │                       │
    [creation_tracking]    [view_tracking]               │
    (点击埋点归因)          (末次浏览归因)                │
              │                   │                       │
    traffic.sellercenter           traffic.sellercenter   │
    _dwd_click_di                  _dwd_view_di           │
    traffic.shopee_traffic                                 │
    _dwd_click_hi                                         │
    traffic.seller_dwd_all_di                             │
              │                   │                       │
              │  JOIN mapping 规则                        │
              │  (click_feature_detail +                  │
              │   platform + restriction)                 │
              │                   │                       │
    [seller_center_entrance_salt] [view_oa_salt]          │
    (随机盐 + row_number 去重)    (随机盐 + row_number)   │
              │                   │                       │
    [seller_center_entrance]  ───────── LEFT JOIN ────────┘
    (全局 row_number 取最近一次点击 + 浏览)
              │
           [result]
    (COALESCE 回填 platform/entrance_feature/
     entrance_feature_group，关联 mapping 默认入口)
              │
              ▼
  dim_campaign_entrance_attribution__reg_s0_live
  partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `mapping` | `dim_campaign_entrance_mapping` | 加载入口归因规则，包含 API 枚举、入口名称、追踪点及限制条件 |
| `product_campaign` | `dim_advertise` | 过滤当日 Product Ads 类型 Campaign ID |
| `new_campaign` | `dim_campaign` + `product_campaign` + `dim_shop` | 组装当日新建 Campaign 的完整基础信息（含 `is_cb_shop`） |
| `all_tracking` | `sellercenter_dwd_click_di` + `shopee_traffic_dwd_click_hi` + `seller_dwd_all_di` | 合并三端（Web / Shopee APP / Seller APP）近两日点击埋点，解析 JSON 字段 |
| `creation_tracking` | `all_tracking` + `mapping` | 按 `click_feature_detail`、`platform` 及多条件 `restriction` 规则匹配点击归因入口 |
| `view_tracking` | `sellercenter_dwd_view_di` | 提取近两日 Web 端页面浏览记录，用于末次浏览归因 |
| `seller_center_entrance_salt` | `new_campaign` + `creation_tracking` | 以 Campaign 创建时间戳为基准（前86400s ~ 后60s）关联点击归因，引入随机盐打散热点 partition 后 `row_number` 初步去重 |
| `view_oa_salt` | `new_campaign` + `view_tracking` | 仅对 `be_creation_platform = 1`（Web）Campaign 关联末次浏览，随机盐 + `row_number` 初步去重 |
| `seller_center_entrance` | `seller_center_entrance_salt` + `view_oa_salt` | 全局 `row_number` 取最近一次点击及最近一次浏览，合并为单行归因记录 |
| `result` | `seller_center_entrance` + `mapping` | `COALESCE` 回填无点击命中的 Campaign 的 `platform`、`entrance_feature`、`entrance_feature_group`（使用 `tracking_feature in ('-','')` 的 mapping 默认规则） |

### 注意事项

1. **去重机制与随机盐**：ETL 采用两阶段去重——先在 `partition by campaign_id, api_creation_method, cast(rand()*100 as int)` 内取最近点击（盐值打散热点），再全局 `partition by campaign_id, api_creation_method` 取最近点击，确保每个 Campaign 仅保留唯一一条最近的入口点击归因。由于使用 `rand()` 随机盐，不同调度批次的结果在极端边界情况下可能存在微小差异。

2. **归因窗口口径**：点击事件时间范围为 `click_event_timestamp / 1000 BETWEEN campaign_create_timestamp - 86400 AND campaign_create_timestamp + 60`，即创建前最多回溯 1 天、创建后允许 60 秒误差；**时间戳单位：`campaign_create_timestamp` 为秒级，`click_event_timestamp` 为毫秒级**，ETL 中已将 click 除以 1000 对齐，下游二次使用时需注意。

3. **`platform` 字段来源混合**：最终写出的 `platform` 为 `COALESCE(归因点击平台, mapping默认平台)`，前者来自埋点 hard-code 字符串（`Web` / `Shopee APP` / `Seller APP`），后者来自 mapping 维表，两者口径一致但逻辑路径不同，分析时需知晓。

4. **仅覆盖 Product Ads**：`new_campaign` 通过 `main_product_type = 'Product Ads'` 过滤，本表当前**仅包含 Product Ads 类型**的 Campaign，查询前无需再加此过滤，但引用时需注意与其他 ads product 相关表 JOIN 时的口径对齐。

5. **`last_view_*` 字段的 NULL 值**：末次浏览归因仅对 `be_creation_platform = 1`（PC Web Seller Center）的 Campaign 执行关联，其余平台（Shopee APP、Seller APP 等）的 Campaign 此三字段为 NULL，统计覆盖率时需排除 NULL 行。

6. **多地区参数化调度**：ETL SQL 中的 `upper('${region}')`、`DATE('${grass_date}')`、`set time zone '${timezone}'` 均为调度参数占位符，由调度平台按各地区本地时区分别注入，覆盖所有调度地区，非单一地区专属表。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_campaign_entrance_mapping__reg_s0_live` | 入口归因规则维表，定义 API 枚举与入口特征的映射及 restriction 条件 |
| `mp_paidads.dim_advertise__reg_s0_live` | 过滤当日 Product Ads 类型的有效 Campaign |
| `mp_paidads.dim_campaign__reg_s0_live` | Campaign 核心属性（创建时间、创建平台、创建者） |
| `mp_user.dim_shop__reg_s0_live` | 补充店铺跨境属性（`is_cb_shop`） |
| `traffic.sellercenter_dwd_click_di__reg_live` | Web Seller Center 点击埋点（近 2 日） |
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | Shopee APP 点击埋点（近 2 日） |
| `traffic.seller_dwd_all_di__reg_live` | Seller APP 点击埋点（近 2 日，`app_id=286`） |
| `traffic.sellercenter_dwd_view_di__reg_live` | Web Seller Center 页面浏览埋点（近 2 日，用于末次浏览归因） |

---

*文档生成时间：2026-04-22*