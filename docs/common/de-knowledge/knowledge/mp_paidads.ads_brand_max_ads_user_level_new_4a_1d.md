<!-- ads-workspace-gdoc-sync: gdoc_id=1PxVltYJZdAVdoejKeagB6LjbqHhdLC8B8DWvqo75qJM gdoc_url=https://docs.google.com/document/d/1PxVltYJZdAVdoejKeagB6LjbqHhdLC8B8DWvqo75qJM/edit -->

# mp_paidads.ads_brand_max_ads_user_level_new_4a_1d

**分层：** ADS（应用数据服务层）
**主键：** `shop_id`, `campaign_id`, `user_id`, `tz_type`, `grass_region`, `grass_date`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（T+1，覆盖业务昨日数据）
**引用频次：** 0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表记录 **Brand Max Ads（品牌最大化广告，placement = 65）** 曝光下，用户在 4A 品牌用户分层模型中发生"首次晋级"的每日明细。具体而言，ETL 每天比较用户在"昨日"与"前日"的人群分层（Aware / Appeal / Action / Advocate），若用户的分层标签在昨日相较前日发生了向上跃升，则将其判定为该层级的"新增用户（new）"，并以 0/1 标记写入本表。

4A 模型将用户按品牌认知程度划分为四个递进层级：**Aware（认知）→ Appeal（兴趣）→ Action（行动）→ Advocate（倡导）**。本表仅保留过去 7 天内曾被 Brand Max Ads 曝光且在昨日发生层级晋级的用户记录，过滤掉当日无任何层级变化的用户，有效压缩数据规模。

本表的核心价值在于支撑广告主和运营团队评估 Brand Max Ads 在用户心智培育上的增量效果，例如：单日新增 Aware/Appeal/Action/Advocate 用户数、各广告活动在不同市场的 4A 漏斗晋级效率，以及结合花费数据计算各层级新增用户的获客成本（CPNew）等分析场景。各地区按本地时区参数化调度，统一写入 `tz_type = 'local'` 分区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前 ETL 仅写入 `'local'`（本地时区）分区；查询时须显式过滤 `tz_type = 'local'`，否则可能因分区扫描异常导致结果错误。⚠️ 目前仅存在 `local` 分区，若直接省略过滤条件将触发全分区扫描，影响性能。 |
| `grass_region` | string | 市场/地区编码（如 `MY`、`SG`、`TH`、`ID`、`VN`、`PH`、`TW`），各地区按本地时区参数化调度独立写入。 |
| `grass_date` | date | 业务日期（本地时区），对应"昨日"（`BIZ_YESTERDAY`），即层级判定的基准日期。 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，标识广告归属的店铺。 |
| `campaign_id` | bigint | 广告活动 ID，标识触发曝光的 Brand Max Ads 广告计划。 |
| `user_id` | bigint | 用户 ID，标识在过去 7 天内被该广告曝光并在昨日发生 4A 层级晋级的用户。 |

### 指标：4A 层级新增标记

| 字段 | 类型 | 说明 |
|------|------|------|
| `new_aware` | bigint | 新增 Aware（认知）层用户标记。当用户昨日 segment = 1（Aware）且前日 segment < 1 时取 1，否则取 0。⚠️ 为 0/1 标记字段，对同一用户的多行记录 SUM 前须先按 `user_id` 去重，或直接 SUM 后注意结合业务语义；本表已过滤"所有指标均为 0"的行，但单用户仍只会在某一字段为 1。 |
| `new_appeal` | bigint | 新增 Appeal（兴趣）层用户标记。当用户昨日 segment = 2（Appeal）且前日 segment < 2 时取 1，否则取 0。⚠️ 同 `new_aware`，为 0/1 标记字段，含义为"该用户在昨日首次晋级至 Appeal 层"。 |
| `new_action` | bigint | 新增 Action（行动）层用户标记。当用户昨日 segment = 3（Action）且前日 segment < 3 时取 1，否则取 0。⚠️ 同 `new_aware`，为 0/1 标记字段。 |
| `new_advocate` | bigint | 新增 Advocate（倡导）层用户标记。当用户昨日 segment = 4（Advocate）且前日 segment < 4 时取 1，否则取 0。⚠️ 同 `new_aware`，为 0/1 标记字段。 |

> **4A segment 编码对照：**
> | 编码 | segment_name | 含义 |
> |------|-------------|------|
> | 0 | opportunity | 机会用户（潜在） |
> | 1 | aware | 认知层 |
> | 2 | appeal | 兴趣层 |
> | 3 | action | 行动层 |
> | 4 | advocate | 倡导层 |
> | -1 | 未命中/缺失 | 在用户分层表中无记录 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**显式指定以下分区字段，避免全表扫描导致性能问题或查询超时：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|---------|---------|
| `tz_type` | `tz_type = 'local'` | 触发所有 tz_type 分区扫描；当前虽仅有 `local` 分区，但省略会阻止分区剪裁优化 |
| `grass_region` | `grass_region = 'MY'`（按需指定） | 扫描全部地区分区，数据量成倍增加 |
| `grass_date` | `grass_date = '2026-04-21'` 或范围过滤 | 扫描历史全量分区，严重影响查询性能 |

**标准查询模板：**
```sql
SELECT
    shop_id,
    campaign_id,
    SUM(new_aware)    AS new_aware_users,
    SUM(new_appeal)   AS new_appeal_users,
    SUM(new_action)   AS new_action_users,
    SUM(new_advocate) AS new_advocate_users
FROM mp_paidads.ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live
WHERE tz_type      = 'local'
  AND grass_region = 'MY'           -- 替换为目标市场
  AND grass_date   = '2026-04-21'   -- 替换为目标日期
GROUP BY shop_id, campaign_id;
```

### 不可直接 SUM 的字段

本表 `new_aware` / `new_appeal` / `new_action` / `new_advocate` 均为 **0/1 二值标记**，**不是预计算比率**，SUM 本身在数学上成立，但需注意以下陷阱：

- **本表已进行行级过滤**：仅保留四个指标之和 > 0 的用户行，因此不存在"全零行"，但**同一用户在同一 `grass_date` + `grass_region` + `campaign_id` 下理论上仅有一行**（由主键结构保证），可以直接 `SUM` 统计晋级人数。
- **跨日多日汇总时需去重**：若对 `grass_date` 范围查询并统计"区间内新增人数"，同一 `user_id` 可能在不同日期各自晋级，是否去重取决于业务需求（统计"人次"还是"人数"）。去重计算示例：
  ```sql
  -- 统计区间内去重新增 Aware 用户数
  SELECT COUNT(DISTINCT CASE WHEN new_aware = 1 THEN user_id END) AS unique_new_aware
  FROM mp_paidads.ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live
  WHERE tz_type = 'local'
    AND grass_region = 'MY'
    AND grass_date BETWEEN '2026-04-15' AND '2026-04-21';
  ```

### 时效性说明

- 本表每日 T+1 调度，`grass_date` 分区对应**业务昨日**数据。查询最新数据时，应取 `grass_date = CURRENT_DATE - 1`（按本地时区）。
- 4A 层级判定依赖**昨日**（`BIZ_YESTERDAY`）与**前日**（`DAY_BEFORE_YESTERDAY`）的用户分层快照 join，若上游 `dwd_shop_user_segment_di_reg_s0` 存在数据延迟，本表对应分区的层级判定结果将不完整。调度依赖需关注上游表的 SLA。
- 曝光数据窗口为**滚动过去 7 天**（`grass_date >= BIZ_YESTERDAY - 6`），因此本表反映的是"过去 7 天内曾被曝光、且昨日发生晋级"的用户，而非仅昨日曝光用户。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告曝光明细表，筛选 placement = 65（Brand Max Ads）、过去 7 天内有曝光（impression_cnt > 0）的用户，生成候选人群 |
| `mkpldp_business_insight.dwd_shop_user_segment_di_reg_s0` | 店铺用户 4A 分层快照表，分别取昨日（`BIZ_YESTERDAY`）和前日（`DAY_BEFORE_YESTERDAY`）的分层标签，用于判断用户层级是否发生晋级 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_advertise_performance_di__reg_s0_live
  (placement=65, 过去7天, impression_cnt>0)
                │
                ▼
    [CTE: campaign_user_performance]
    按 grass_region/shop_id/campaign_id/user_id
    聚合 impression_cnt，筛选曝光用户
                │
                ├──────────────────────────────────────────────┐
                ▼                                              ▼
dwd_shop_user_segment_di_reg_s0                dwd_shop_user_segment_di_reg_s0
     (grass_date = BIZ_YESTERDAY)                (grass_date = DAY_BEFORE_YESTERDAY)
     INNER JOIN → 获取昨日 segment              LEFT JOIN → 获取前日 segment
                │                                              │
                └──────────────┬───────────────────────────────┘
                               ▼
                  [CTE: yesterday_user_segment]
                  曝光用户 × 昨日分层标签
                               │
                               ▼
                  [CTE: full_user_segment]
                  叠加前日分层标签（LEFT JOIN）
                               │
                               ▼
                  计算 new_aware/appeal/action/advocate
                  (yesterday_segment = N AND day_before_yesterday_segment < N)
                               │
                  过滤：四项指标之和 > 0
                               │
                               ▼
  ads_brand_max_ads_user_level_new_4a_1d__reg_s0_live
  partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `campaign_user_performance` | `dwd_advertise_performance_di__reg_s0_live` | 筛选 Brand Max Ads（placement=65）在过去 7 天内有有效曝光（impression_cnt > 0）的用户，按 `grass_region / shop_id / campaign_id / user_id` 聚合，生成曝光候选人群 |
| `yesterday_user_segment` | `campaign_user_performance` + `dwd_shop_user_segment_di_reg_s0`（昨日） | 将曝光候选人群与昨日用户分层快照 **INNER JOIN**，获取每个用户昨日的 4A 层级编码；无分层记录的用户 segment 默认为 -1 |
| `full_user_segment` | `yesterday_user_segment` + `dwd_shop_user_segment_di_reg_s0`（前日） | 在昨日分层基础上 **LEFT JOIN** 前日分层快照，补充每个用户前日的 4A 层级编码；无记录的前日 segment 默认为 -1，用于后续晋级判断 |

### 注意事项

1. **曝光窗口为滚动 7 天，非单日**：`campaign_user_performance` CTE 拉取的是 `[BIZ_YESTERDAY - 6, BIZ_YESTERDAY]` 共 7 天的曝光数据，而晋级判定基准日为 `BIZ_YESTERDAY`（昨日）。这意味着用户可能是在 7 天前被曝光、昨日才完成晋级，两者在时间口径上存在错位，使用时需注意。

2. **4A 晋级定义为"严格向上跃升"**：判定条件为 `yesterday_segment = N AND day_before_yesterday_segment < N`，即昨日层级必须恰好等于目标层级 N，且前日层级严格低于 N。未在分层表中找到记录的用户 segment 为 -1，仍可能触发晋级判定（如昨日首次出现在 Aware 层），需关注 -1 作为"缺失"与"未晋级"语义的混用风险。

3. **INNER JOIN 昨日分层导致用户缩减**：`yesterday_user_segment` 使用 INNER JOIN，曝光用户中若昨日在 `dwd_shop_user_segment_di_reg_s0` 中无任何记录（即既非任何层级也非 opportunity），该用户将被完全排除在外，不会写入本表。

4. **仅写入 `tz_type = 'local'` 分区**：ETL 硬编码 `partition(tz_type = 'local', ...)`，本表不存在 `utc` 等其他时区分区。

5. **过滤零行**：最终 INSERT 前有 `WHERE new_aware + new_appeal + new_action + new_advocate > 0` 过滤，四个指标全为 0 的用户行不写入，因此本表行数相对于全量曝光用户大幅压缩，是稀疏的晋级事件表。

6. **各地区独立调度**：本表通过 `${region}`、`${timezone}` 等参数化变量覆盖多个市场，各地区按本地时区独立触发调度，`grass_region` 分区值由调度参数注入。

---

*文档生成时间：2026-04-22*