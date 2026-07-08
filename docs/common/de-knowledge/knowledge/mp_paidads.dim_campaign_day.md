<!-- ads-workspace-gdoc-sync: gdoc_id=1w3LdUcPDu3jqAy4EwawTaCETuA7bSnx_eSGqgdvz2o8 gdoc_url=https://docs.google.com/document/d/1w3LdUcPDu3jqAy4EwawTaCETuA7bSnx_eSGqgdvz2o8/edit -->

# mp_paidads.dim_campaign_day

**分层**：DIM（维度层）
**主键**：`id`、`campaign_day`、`tz_type`、`grass_region`、`grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1，覆盖前一业务日）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是广告活动（Campaign）有效日历天的维度表，核心逻辑是将每条广告活动的 `start_time` ～ `end_time` 时间区间按天展开（序列展开），为每一天生成一条记录，以便后续事实表按天粒度关联广告活动信息。表名中的 `campaign_day` 即代表"广告活动所归属的日历天"。

该表的典型使用场景包括：按天统计广告活动的曝光/点击/消耗等绩效指标、判断某条广告在特定日期是否处于投放状态、以及作为广告活动日粒度分析的基准维度。通过过滤 `is_not_campaign_day` 标志（ETL 层已处理），确保展开出的每一天均为真实有效的活动日，避免非活动日数据污染分析结果。

各地区通过 `${region}`、`${timezone}` 参数化调度，按本地时区将原始 UTC+8（Asia/Singapore）时间戳转换为各地区本地时间后再做日期切分，保证不同市场的日期边界均与当地时区对齐。当前仅写入 `tz_type = 'local'` 分区，即本地时区口径数据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型标识。当前 ETL 仅写入 `'local'`（本地时区）分区。查询时**必须指定**此字段以避免全表扫描。⚠️ 若不过滤，将读取所有时区分区，造成数据重复或性能浪费 |
| `grass_region` | string | 地区分区键，如 `'ID'`、`'TH'`、`'MY'` 等，由调度参数 `${region}` 大写填充。查询时**必须指定**以避免跨地区混读 |
| `grass_date` | date | 数据业务日期分区键，格式 `yyyy-MM-dd`，对应调度参数 `${BIZ_YESTERDAY}`（即 T-1 日）。查询时应指定最新或目标分区日期 |

---

### 维度：主键与广告活动属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint | 广告活动在 `campaign_day_tab` 中的原始 ID，对应源表主键 |
| `campaign_name` | string | 广告活动名称 |
| `start_time` | bigint | 广告活动开始时间戳（Unix 秒级，原始存储为 Asia/Singapore 时区基准）。⚠️ 为原始整型时间戳，使用时需通过 `from_utc_timestamp(to_utc_timestamp(cast(start_time as timestamp), 'Asia/Singapore'), <目标时区>)` 转换为可读时间 |
| `end_time` | bigint | 广告活动结束时间戳（Unix 秒级，原始存储为 Asia/Singapore 时区基准）。⚠️ 同 `start_time`，使用时需做时区转换，不可直接与日期字段比较 |
| `campaign_day` | date | 广告活动所对应的日历天（本地时区），由 ETL 将 `start_time`～`end_time` 区间按天序列展开得出。一条广告活动会在本表中生成多行（每天一行）。⚠️ 该字段是展开派生字段，不代表单次事件，勿将其与事实表直接 SUM 聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，避免全表扫描和数据重复：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 local 分区，不过滤仍建议显式指定；若未来引入其他时区分区将导致重复计算 |
| `grass_region` | `grass_region = 'XX'`（替换为目标地区） | 读取全地区数据，产生跨地区数据混合，结果错误且性能极差 |
| `grass_date` | `grass_date = '${最新业务日期}'` | 全分区扫描，产生历史数据重复，且存储成本极高 |

**推荐过滤模板：**
```sql
WHERE tz_type = 'local'
  AND grass_region = 'ID'          -- 替换为目标地区
  AND grass_date = '2026-04-21'    -- 替换为目标业务日期
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|------|----------|-------------|
| `campaign_day` | 由时间区间展开派生，一条广告对应多行，不代表独立事件计数 | 作为关联键或 `GROUP BY` 维度使用，不做数值聚合 |
| `start_time` / `end_time` | 整型时间戳，语义为广告活动的起止时间，对多行直接聚合无意义 | 与其他表关联时作为维度字段使用；如需计算活动时长，应用 `end_time - start_time`，并在活动维度（而非本表展开后）上计算 |

### 时效性说明

- 本表每日 T+1 调度，分区 `grass_date` 对应 `${BIZ_YESTERDAY}`（即昨日业务日期）。
- 查询最新数据时，应取 **昨日**（`grass_date = CURRENT_DATE - 1`）分区；若需分析历史区间，按需指定对应 `grass_date` 分区并注意避免多分区重复读取导致数据膨胀（每日全量覆盖写入，历史分区数据不变）。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_db__campaign_day_tab__reg_continuous_s0_live` | 各地区广告活动天原始表，提供广告 ID、名称、起止时间戳等基础属性，以及 `_decoded_extinfo` 中的 `is_not_campaign_day` 标志用于过滤非活动日记录 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.shopee_ads_${region}_db__campaign_day_tab__reg_continuous_s0_live
  │
  │  1. 过滤：is_not_campaign_day = false（仅保留有效活动日记录）
  │
  ▼
  时区转换
  Asia/Singapore（源存储基准）→ ${timezone}（目标地区本地时区）
  │
  │  2. 日期序列展开：sequence(start_date, end_date, interval 1 day)
  │     每条广告活动按天拆分为多行，每行对应一个 campaign_day
  │
  ▼
mp_paidads.dim_campaign_day__reg_s0_live
  partition(tz_type='local', grass_region=upper('${region}'), grass_date='${BIZ_YESTERDAY}')
  [INSERT OVERWRITE，每日全量覆盖当日分区]
```

### 注意事项

1. **时区转换机制**：源表时间戳以 Asia/Singapore（UTC+8）为基准存储，ETL 通过 `to_utc_timestamp(..., 'Asia/Singapore')` 先还原为 UTC，再通过 `from_utc_timestamp(..., '${timezone}')` 转换为各地区本地时间，最终取日期部分作为 `campaign_day`。各地区调度时注入各自的本地时区参数，保证日期边界与当地一致。

2. **序列展开导致行数膨胀**：`explode(sequence(...))` 将一条广告活动记录展开为 N 行（N = 活动天数）。下游关联时需注意 JOIN 基数放大，避免笛卡尔积风险。

3. **`is_not_campaign_day` 过滤**：ETL 通过 `COALESCE(cast(get_json_object(_decoded_extinfo, '$.is_not_campaign_day') as boolean), false) = false` 过滤掉标记为非活动日的记录，`_decoded_extinfo` 字段为 JSON 格式扩展信息，该过滤逻辑已在 ETL 层完成，本表中所有记录均为有效活动日。

4. **INSERT OVERWRITE 全量覆盖**：每次调度对当日 `grass_date` 分区执行覆盖写入，历史分区数据不受影响。若重跑历史分区，需注意调度参数与实际数据日期的对应关系。

5. **ETL SQL 中的地区示例**：SQL 中出现的 `upper('mx')`、`'${timezone}'` 等为调度模板占位符的示例实例，本表通过参数化调度覆盖所有地区，并非仅限特定市场。

---

*文档生成时间：2026-04-22*