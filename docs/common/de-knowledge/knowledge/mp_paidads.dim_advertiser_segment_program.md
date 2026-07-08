<!-- ads-workspace-gdoc-sync: gdoc_id=11rjbJbISUSkymjy2uQkflZRU6RjVw4UBTGN0Xs2e5Tw gdoc_url=https://docs.google.com/document/d/11rjbJbISUSkymjy2uQkflZRU6RjVw4UBTGN0Xs2e5Tw/edit -->

# mp_paidads.dim_advertiser_segment_program

**分层**：DIM（维度层）
**主键**：`shop_id` + `program_id` + `segment_id`（联合唯一，部分分支 segment_id 可为 NULL）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖写入（INSERT OVERWRITE）
**引用频次**：74 次（候选表范围内）

---

## 业务描述

本表是付费广告域中广告主激励计划（Advertiser Incentive Program）的核心维度表，整合了**广告激励项目（Program）**、**广告主参与记录（Seller Program）**、**白/黑名单分群（Segment White-Blacklist）** 以及 **QSS（Quick Start Service）算法配置** 四个业务维度，形成以 `shop_id × program_id` 为粒度的宽表快照。

使用场景涵盖：
- 查询某广告主当前参与的激励计划类型（QSS、充值激励、固定消耗激励、返现激励等）及其参与状态；
- 分析激励计划的覆盖范围、参与进度及奖励发放情况（免费广告金额度、充值门槛、到期时间等）；
- 为下游 ADS 报表、激励漏斗分析、运营决策提供统一口径的维度关联键。

本表采用三路 UNION ALL 构建，分别对应：①标准激励流程（program_type ≠ '1' 或 owner_operator_type ≠ 2）、②QSS 算法新流程（program_type = '1' AND owner_operator_type = 2，配置来源为 seller_qss_config_tab）、③新 Program 数据流（program_type_name IS NOT NULL，参与记录来源为 incentive_tab）。下游使用时须理解三路数据在字段填充上的差异。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`，表示各地区按本地时区参数化调度 ⚠️ 查询时必须过滤 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 地区代码（大写），如 `TW`、`ID`、`TH` 等，由调度参数 `${region}` 参数化生成，覆盖所有上线地区 |
| `grass_date` | date | 数据日期，格式 `yyyy-MM-dd`，为快照日期 |

---

### 维度：主键与广告主标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主唯一标识 |
| `program_id` | bigint | 激励计划 ID |
| `segment_id` | bigint | 分群 ID，关联白/黑名单分群；QSS 算法流程分支可能为 NULL |
| `id` | bigint | 白/黑名单模型记录的自增主键（来自 segment_white_blacklist_model_tab）；QSS 算法流程及新 Program 流程分支为 NULL |
| `incentive_id` | bigint | 激励记录 ID（来自 seller_program_tab 或 incentive_tab）；标准流程取自 seller_program.id，新流程取自 incentive_tab.incentive_id |

---

### 维度：激励计划基本信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `program_name` | string | 激励计划名称 |
| `program_status` | bigint | 激励计划状态码（枚举值，具体含义参考上游 dim_program） |
| `program_type` | string | 激励计划类型编码：`1`=QSS（快速启动服务）、`2`=充值激励（TOPUP_INCENTIVE）、`3`=固定消耗激励（FIXED_SPENDING_INCENTIVE）、`4`=返现消耗激励（CASHBACK_SPENDING_INCENTIVE）；新数据流中可能存在更多类型（5/6/7/8）⚠️ 该字段为字符串类型，过滤时须使用字符串值（如 `program_type = '1'`），不可用整数比较 |
| `program_type_name` | string | 激励计划类型名称；仅新 Program 数据流（第三路 UNION）填充，其余分支为 NULL |
| `program_quota` | bigint | 激励计划配额（总参与名额上限） |
| `extinfo` | string | 激励计划扩展信息，JSON 格式；QSS 算法流程分支来源为 seller_qss_config_tab 的 `_decoded_extinfo` |
| `operator_id` | bigint | 操作人 ID；新 Program 流程分支为 NULL |
| `operator` | string | 操作人名称；新 Program 流程分支为 NULL |
| `owner_operator_type` | int | 计划所有者操作类型：`0`=任何人可编辑，`1`=系统可操作任意计划，其他值=需匹配所有者类型；QSS 算法新流程固定写入 `2` |
| `priority_score` | bigint | 优先级分数，从 `seller_program_extinfo` JSON 中按 `program_type` 路由解析：type 1 取 `$.qss.base.priority_score`，type 2/3/4 取 `$.incentive.priority_score`，type 5 取 `$.cashback_onboarding.base.priority_score`，type 6/7/8 分别取对应路径 ⚠️ 为 JSON 解析派生字段，不可直接 SUM；新 Program 流程分支为 NULL |
| `learn_more_link` | string | 激励计划说明链接；新 Program 流程分支为 NULL |

---

### 维度：激励计划时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `program_create_timestamp` | bigint | 激励计划创建时间戳（Unix 秒级） |
| `program_create_datetime` | string | 激励计划创建时间，格式 `yyyy-MM-dd HH:mm:ss`，按本地时区转换 ⚠️ 为字符串格式，时间比较请转换为时间戳字段 |
| `program_last_modified_timestamp` | bigint | 激励计划最后修改时间戳（Unix 秒级） |
| `program_last_modified_datetime` | string | 激励计划最后修改时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 同上，字符串格式 |
| `program_start_timestamp` | bigint | 激励计划开始时间戳（Unix 秒级） |
| `program_start_datetime` | string | 激励计划开始时间，格式 `yyyy-MM-dd HH:mm:ss`，按本地时区转换 ⚠️ 同上，字符串格式 |
| `program_end_timestamp` | bigint | 激励计划结束时间戳（Unix 秒级） |
| `program_end_datetime` | string | 激励计划结束时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 同上，字符串格式 |
| `display_timestamp` | bigint | 展示触发时间戳；非零时在卖家中心展示该任务（显示为"即将开始"），为零时使用 program_start_time；新 Program 流程分支为 NULL |
| `display_datetime` | string | 展示触发时间，格式 `yyyy-MM-dd HH:mm:ss`；新 Program 流程分支为 NULL ⚠️ 同上，字符串格式 |
| `topup_deadline_timestamp` | bigint | 充值截止时间戳（Unix 秒级）；仅充值激励类型有效，QSS 算法流程来源于 extinfo 中 `$.qss.topup_deadline`；新 Program 流程分支为 NULL |
| `topup_deadline_datetime` | string | 充值截止时间，格式 `yyyy-MM-dd HH:mm:ss`；新 Program 流程分支为 NULL ⚠️ 同上，字符串格式 |

---

### 维度：激励计划奖励参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_credit_amt` | double | 免费广告金额度，本地货币；QSS 算法流程来源于 extinfo `$.qss.free_credit`（已除以 100000） ⚠️ 汇率折算字段，跨地区加总需先统一货币 |
| `free_credit_amt_usd` | double | 免费广告金额度，美元；QSS 算法流程为 `free_credit / exchange_rate` ⚠️ 派生字段，不可直接 SUM 后再做汇率换算，应使用此字段直接聚合 |
| `min_topup_amt` | double | 最低充值金额，本地货币；QSS 算法流程来源于 extinfo `$.qss.min_topup`（已除以 100000）；新 Program 流程分支为 NULL ⚠️ 跨地区加总需注意货币单位差异 |
| `min_topup_amt_usd` | double | 最低充值金额，美元；QSS 算法流程为 `min_topup / exchange_rate`；新 Program 流程分支为 NULL ⚠️ 派生字段 |
| `min_item_price_amt` | double | 最低商品价格门槛，本地货币；QSS 算法流程来源于 extinfo `$.qss.item_price_floor`（已除以 100000）；新 Program 流程分支为 NULL ⚠️ 跨地区加总需注意货币单位差异 |
| `min_item_price_amt_usd` | double | 最低商品价格门槛，美元；QSS 算法流程为 `item_price_floor / exchange_rate`；新 Program 流程分支为 NULL ⚠️ 派生字段 |
| `default_daily_budget` | double | 默认每日预算，本地货币；QSS 算法流程来源于 extinfo `$.qss.default_daily_budget`（已除以 100000）；新 Program 流程分支为 NULL ⚠️ 跨地区加总需注意货币单位差异 |
| `credit_expiry_days_cnt` | bigint | 广告金有效天数；QSS 算法流程来源于 extinfo `$.qss.credit_expiry_duation`（注意原字段存在拼写错误 `duation`）；新 Program 流程分支为 NULL |
| `credit_expiry_duration` | bigint | 广告金到期时长，单位秒；新 Program 流程分支为 NULL |
| `credit_claim_period` | bigint | 广告金领取有效期，单位秒；新 Program 流程分支为 NULL |
| `topup_window` | bigint | 充值窗口期，QSS 算法流程来源于 extinfo `$.qss.topup_window`；新 Program 流程分支为 NULL |
| `sku_number` | bigint | 参考 SKU 数量；QSS 算法流程来源于 extinfo `$.qss.sku_number`；新 Program 流程分支为 NULL |

---

### 维度：广告主参与状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_program_event_id` | bigint | 广告主与计划交互事件枚举值：0=NOOP、1=VIEW、2=SIGNUP、3=CREATE_ADS、4=REMOVE、5=RESUME、6=CHECK_TOPUP、7=JOIN_OTHERS、8=READ_ADS；新 Program 流程分支为 NULL |
| `seller_program_event` | string | 广告主与计划交互事件名称（seller_program_event_id 对应文本）；新 Program 流程分支为 NULL ⚠️ ETL 中仅枚举至事件 8（READ_ADS），字段 comment 中列出的 9~11 号事件暂未在 CASE WHEN 中处理，返回 NULL |
| `seller_program_status_id` | bigint | 广告主计划参与状态枚举值，完整枚举见字段 comment；新 Program 流程分支来源为 incentive_tab.incentive_status |
| `seller_program_status` | string | 广告主计划参与状态名称；标准流程与 QSS 流程使用 seller_program_tab 映射（含 NOT_STARTED 至 PREVIOUS_STATE），新 Program 流程映射为 INACTIVE/ACTIVE/COMPLETED/DISMISSED/FAILED ⚠️ 三路 UNION 的映射枚举不同，跨 program_type 聚合时需注意状态含义差异 |
| `seller_program_extinfo` | string | 广告主计划扩展信息，JSON 格式；`priority_score` 等字段均从本字段解析而来 ⚠️ 存储为 JSON 字符串，使用 `get_json_object` 解析，不可直接比较 |

---

### 维度：广告主参与时间

| 字段 | 类型 | 说明 |
|------|------|------|
| `sign_up_timestamp` | bigint | 广告主报名时间戳（Unix 秒级）；新 Program 流程分支为 NULL |
| `sign_up_datetime` | string | 广告主报名时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式，时间比较请使用 sign_up_timestamp |
| `deadline_timestamp` | bigint | 广告主完成任务截止时间戳（Unix 秒级）；新 Program 流程分支为 NULL |
| `deadline_datetime` | string | 广告主完成任务截止时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式 |
| `seller_program_onboard_timestamp` | bigint | 广告主加入计划时间戳（Unix 秒级），对应 seller_program_tab / incentive_tab 的 ctime |
| `seller_program_onboard_datetime` | string | 广告主加入计划时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式 |
| `seller_program_last_modified_timestamp` | bigint | 广告主参与记录最后修改时间戳（Unix 秒级）|
| `seller_program_last_modified_datetime` | string | 广告主参与记录最后修改时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式 |
| `advertiser_program_popup_create_timestamp` | bigint | 广告主计划弹窗创建时间戳 ⚠️ 已废弃（2025-06-06 ETL 中注释）；当前全量写入 NULL，请勿依赖此字段 |
| `advertiser_program_popup_create_datetime` | string | 广告主计划弹窗创建时间 ⚠️ 同上，已废弃，全量为 NULL |

---

### 维度：白/黑名单分群信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `model_type_id` | bigint | 分群模型类型枚举值：1=BLACKLIST、2=WHITELIST；QSS 算法流程及新 Program 流程分支为 NULL |
| `model_type` | string | 分群模型类型名称（BLACKLIST / WHITELIST）；QSS 算法流程及新 Program 流程分支为 NULL |
| `model_status_id` | bigint | 分群模型状态枚举值：0=DELETED、1=NORMAL、2=PENDING_ADD、3=PENDING_DELETE；QSS 算法流程及新 Program 流程分支为 NULL |
| `model_status` | string | 分群模型状态名称；QSS 算法流程及新 Program 流程分支为 NULL |
| `segment_create_timestamp` | bigint | 分群创建时间戳（Unix 秒级）；QSS 算法流程及新 Program 流程分支为 NULL |
| `segment_create_datetime` | string | 分群创建时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式；QSS 算法流程及新 Program 流程分支为 NULL |
| `segment_last_modified_timestamp` | bigint | 分群最后修改时间戳（Unix 秒级）；QSS 算法流程及新 Program 流程分支为 NULL |
| `segment_last_modified_datetime` | string | 分群最后修改时间，格式 `yyyy-MM-dd HH:mm:ss` ⚠️ 字符串格式；QSS 算法流程及新 Program 流程分支为 NULL |

---

### 维度：QSS 算法配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_qss_config_status` | int | 卖家 QSS 配置状态：0=INACTIVE、1=ACTIVE；仅 `program_type = '1'` 且 `owner_operator_type = 2` 的 QSS 算法新流程分支有值，其余分支为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，避免全表扫描导致资源浪费：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区，但若未来新增其他类型会导致数据重复 |
| `grass_region` | `grass_region = 'TW'`（按实际地区填写） | 扫描所有地区全量数据，计算资源消耗极大 |
| `grass_date` | `grass_date = '2025-01-01'`（按业务日期填写） | 扫描全历史分区，极易造成超时或 OOM |

示例：
```sql
SELECT *
FROM mp_paidads.dim_advertiser_segment_program__reg_s0_live
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2025-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确计算方式 |
|------|----------|--------------|
| `free_credit_amt_usd` / `min_topup_amt_usd` / `min_item_price_amt_usd` | QSS 算法流程分支通过 `本地金额 / exchange_rate` 派生，标准流程直接来自上游维表，口径不完全统一 | 跨地区汇总前先确认数据来源分支，同地区聚合可直接 SUM |
| `priority_score` | 从 `seller_program_extinfo` JSON 按 `program_type` 路由解析，不同 program_type 路径不同，聚合无业务意义 | 用于过滤/排序，不作 SUM；新 Program 流程分支为 NULL |
| `seller_program_extinfo` | JSON 字符串，不可直接 SUM | 使用 `get_json_object(seller_program_extinfo, '$.path')` 提取具体字段 |
| `default_daily_budget` / `free_credit_amt` / `min_topup_amt` | 本地货币单位，各地区货币不同 | 跨地区比较须统一使用 `_usd` 后缀字段 |

### 时效性说明

- 本表为每日全量快照，`grass_date` 代表数据截止日期；查询"当前最新状态"请取 **`grass_date = date_sub(current_date, 1)`**（T-1 快照），当日数据在次日调度完成后可用。
- CTE 内所有上游表过滤条件均为 `ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))`，即包含截至 `grass_date` 当天 23:59:59 为止的全量历史数据，并非仅当日新增记录。
- `advertiser_program_popup_create_timestamp` / `advertiser_program_popup_create_datetime` 已于 2025-06-06 废弃，全量写入 NULL，请勿在新查询中依赖此字段。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_program__reg_s0_live` | 激励计划维度主表，提供 program 基本信息、时间、奖励参数等字段 |
| `mp_paidads.shopee_ads_srm_${region}_db__segment_white_blacklist_model_tab__reg_daily_s0_live` | 白/黑名单分群模型表，提供分群类型、状态及时间信息 |
| `mp_paidads.shopee_ads_srm_${region}_db__seller_program_tab__reg_continuous_s0_live` | 广告主参与标准激励计划的记录表，提供参与状态、时间、事件类型等 |
| `mp_paidads.shopee_ads_srm_${region}_db__seller_qss_config_tab__reg_continuous_s0_live` | QSS 算法新流程下卖家配置表，提供 QSS 特有奖励参数（通过 JSON 解析） |
| `mp_paidads.shopee_ads_srm_${region}_db__incentive_tab__reg_continuous_s0_live` | 新 Program 数据流下广告主激励参与记录（incentive_tab），提供参与状态、时间信息 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于将本地货币金额转换为美元（仅 QSS 算法流程分支使用） |
| `mp_user.dim_user__reg_s0_live` | 用户维表，通过 `user_id → shop_id` 桥接，将 incentive_tab 的 user_id 转换为 shop_id（新 Program 流程分支） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dim_program__reg_s0_live
        │
        ├─[program_type≠'1' or owner_operator_type≠2]──────────────────────────────────────────┐
        │                                                                                       │
        │        shopee_ads_srm__seller_program_tab                                             │
        │                     │                                                                 │
        │        LEFT JOIN ───┤ (on program_id)                                                │
        │                     │                                                                 │
        │        shopee_ads_srm__segment_white_blacklist_model_tab                              │
        │                     │                                                                 │
        │        LEFT JOIN ───┘ (on segment_id + shop_id + grass_region)                       │
        │                                                          UNION ALL ──► 分支①          │
        ├─[program_type='1' AND owner_operator_type=2]──────────────────────────────────────────┤
        │                                                                                       │
        │        shopee_ads_srm__seller_qss_config_tab                                          │
        │                     │                                                                 │
        │        LEFT JOIN ───┤ (on program_id)                                                │
        │                     │                                                                 │
        │        shopee_ads_srm__seller_program_tab                                             │
        │                     │                                                                 │
        │        LEFT JOIN ───┤ (on program_id + shop_id)                                      │
        │                     │                                                                 │
        │        mp_order.dim_exchange_rate__reg_s0_live                                        │
        │                     │                                                                 │
        │        LEFT JOIN ───┘ (on grass_region)                                              │
        │                                                          UNION ALL ──► 分支②          │
        └─[program_type_name IS NOT NULL]───────────────────────────────────────────────────────┤
                                                                                               │
                 shopee_ads_srm__incentive_tab                                                  │
                             │                                                                  │
                 LEFT JOIN ──┤ (on program_id)                                                 │
                             │                                                                  │
                 mp_user.dim_user__reg_s0_live                                                  │
                             │                                                                  │
                 LEFT JOIN ──┘ (on user_id → shop_id)                                         │
                                                          UNION ALL ──► 分支③                  │
                                                                        │
                                                                        ▼
                             INSERT OVERWRITE PARTITION(tz_type='local', grass_region, grass_date)
                             mp_paidads.dim_advertiser_segment_program__reg_s0_live
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `white_blacklist` | `shopee_ads_srm_${region}_db__segment_white_blacklist_model_tab__reg_daily_s0_live` | 清洗白/黑名单分群数据，映射 model_type / model_status 枚举，转换时间戳为本地时间字符串 |
| `dim_program` | `mp_paidads.dim_program__reg_s0_live` | 过滤当日地区的激励计划维度数据，作为三路 UNION ALL 的主驱动表 |
| `seller_qss_config` | `shopee_ads_srm_${region}_db__seller_qss_config_tab__reg_continuous_s0_live` | 解析 QSS 算法配置 JSON（`_decoded_extinfo`），提取 sku_number、topup_window、min_topup 等参数（原始值除以 100000 还原真实金额） |
| `seller_program` | `shopee_ads_srm_${region}_db__seller_program_tab__reg_continuous_s0_live` | 清洗广告主参与记录，映射 seller_program_event / seller_program_status 枚举，转换时间戳为本地时间字符串 |

### 注意事项

1. **三路 UNION ALL 字段填充差异**：三路数据分支在字段完整性上存在明显差异。分支①（标准流程）字段最完整；分支②（QSS 算法流程）白/黑名单相关字段（id、segment_create_xxx 等）均为 NULL；分支③（新 Program 流程）的 min_topup、free_credit、sign_up 等奖励参数字段均为 NULL。下游若需确保字段完整性，请先通过 `program_type` 和 `program_type_name` 过滤相应分支。

2. **seller_program_view_tab 已废弃**：ETL SQL 中已注释掉对 `seller_program_view_tab` 的引用（2025-06-06 废弃），`advertiser_program_popup_create_timestamp` 和 `advertiser_program_popup_create_datetime` 两字段全量写入 NULL，请勿在新需求中使用。

3. **seller_program_event 枚举不完整**：ETL CASE WHEN 中仅处理了事件类型 0~8，字段 comment 中记录的 9（CHECK_PROGRESS）、10（CLAIM_REWARD）、11（DISMISS）在 ETL 中未映射，将返回 NULL。若需分析这些事件，须从 `seller_program_event_id` 字段自行处理。

4. **QSS 金额字段精度**：`seller_qss_config` CTE 中从 JSON 解析的金额字段（min_topup、free_credit、item_price_floor、default_daily_budget）均执行了 `/ 100000.0` 操作以还原实际金额，与标准流程直接来自 dim_program 的金额口径保持一致。

5. **汇率转换仅限 QSS 算法流程**：`_usd` 后缀的美元字段在分支②中通过 `mp_order.dim_exchange_rate__reg_s0_live` 实时计算，分支①中直接继承自 `dim_program`（其上游已完成汇率换算），分支③中为 NULL。

6. **数据截止口径**：所有 CTE 均使用 `ctime < UNIX_TIMESTAMP(DATE_ADD(DATE('${grass_date}'), 1))` 过滤，即截至 `grass_date` 当日末的全量历史快照，非增量记录。`dim_program` 使用 `grass_date = DATE('${grass_date}')` 精确取当日分区。

7. **参数化调度**：ETL 通过 `${region}`、`${grass_date}`、`${timezone}` 参数化，覆盖所有上线地区，各地区按本地时区独立调度。SQL 中出现的具体地区代码或时区仅为调度模板的参数化实例，不代表表仅覆盖单一地区。

---

*文档生成时间：2026-04-22*