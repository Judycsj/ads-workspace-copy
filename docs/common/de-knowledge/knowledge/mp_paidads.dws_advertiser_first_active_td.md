<!-- ads-workspace-gdoc-sync: gdoc_id=1X3KxPkJMz8NkQfU9YwiAJ3x2W-brqbsnyAjNwPcK-dk gdoc_url=https://docs.google.com/document/d/1X3KxPkJMz8NkQfU9YwiAJ3x2W-brqbsnyAjNwPcK-dk/edit -->

# mp_paidads.dws_advertiser_first_active_td

**分层**：DWS（数据服务层 / 汇总宽表层）
**主键**：`shop_id` + `user_id` + `grass_region` + `grass_date` + `tz_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1 增量覆写，按地区参数化调度）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录每个广告主（卖家/店铺维度）在各广告类型上**首次激活广告的历史最早日期**，属于全量累计型（to-date）快照表。具体追踪两类关键词广告的首次生效时间：**手动关键词广告（Manual Mode Keyword Ads，简称 MM KW Ads）** 与 **简易模式关键词广告（Simple Mode Keyword Ads，简称 SM KW Ads）**。

本表的核心价值在于提供稳定、去重后的"首次激活时间"基准，可用于以下场景：广告主生命周期分析（新手 / 成熟广告主分层）、广告功能渗透率统计（何时首次使用某类广告）、用户成长漏斗建模，以及与活跃度/消耗等指标表 JOIN 后计算广告主使用广告功能的"天龄"（days since first active）。

各地区通过统一的参数化调度模板（`${region}`、`${grass_date}`）独立调度，每日以 `INSERT OVERWRITE` 方式更新当日分区，确保跨地区数据隔离，并支持按本地时区对齐分析口径。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。当前分区值固定写入为 `'local'`，表示数据以各地区本地时区对齐统计。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将全分区扫描，造成重复计算与性能浪费。 |
| `grass_region` | string | 国家/地区分区，由调度参数 `${region}` 大写转换后写入（如 `MX`、`TH`、`BR`）。各地区独立调度，数据物理隔离。⚠️ 查询时必须指定 `grass_region`，否则触发全地区扫描。 |
| `grass_date` | date | 日期分区，对应调度参数 `${grass_date}`，格式为 `YYYY-MM-DD`。每日覆写当日分区。⚠️ 查询时必须指定 `grass_date`，通常取最新业务日期以获取最新累计状态。 |

### 维度：主键与广告主身份

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，标识广告投放的具体店铺，与 `user_id` 联合构成业务主键。 |
| `user_id` | bigint | 卖家（Seller）ID，标识店铺归属的卖家账号。一个卖家可能拥有多个店铺。 |

### 指标：广告首次激活日期

| 字段 | 类型 | 说明 |
|------|------|------|
| `first_mm_kw_ads_active_date` | date | 该店铺/卖家手动关键词广告（Manual Mode Keyword Ads）**历史最早**首次生效日期。由 ETL 对历史累计值与当日新值取 `MIN` 得到，具有 to-date 累计语义。⚠️ 该值为跨日累计最小值，不代表当日新增；若用于判断"是否为新激活广告主"，需结合前一日分区数据对比使用。 |
| `first_sm_kw_ads_active_date` | date | 该店铺/卖家简易模式关键词广告（Simple Mode Keyword Ads）**历史最早**首次生效日期。同样由 ETL 对历史累计值与当日新值取 `MIN` 得到，具有 to-date 累计语义。⚠️ 同上，为累计最小值，不可直接用于当日新增统计。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，否则将触发全表扫描，造成资源浪费并可能引入多地区、多日期的重复数据：

| 分区字段 | 推荐过滤方式 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `tz_type = 'local'` | 当前仅有 `local` 分区，遗漏不影响结果但增加无效扫描 |
| `grass_region` | `grass_region = '目标地区代码'`（如 `'MX'`） | 混入所有地区数据，导致 `shop_id` / `user_id` 跨地区重复 |
| `grass_date` | `grass_date = '目标日期'`（通常取最新业务日期） | 扫描所有历史分区，返回历史快照而非最新累计状态 |

**推荐标准过滤模板**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'XX'       -- 替换为目标地区
  AND grass_date = 'YYYY-MM-DD' -- 替换为目标业务日期
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|------|----------|-------------|
| `first_mm_kw_ads_active_date` | 为日期型累计最小值，跨行直接聚合无业务意义 | 若需统计"首次激活在某日期之前的广告主数量"，使用 `COUNT(DISTINCT shop_id) WHERE first_mm_kw_ads_active_date <= 'target_date'` |
| `first_sm_kw_ads_active_date` | 同上 | 同上，使用条件过滤后的 `COUNT(DISTINCT)` |

### 时效性说明

本表为 **to-date（td）累计快照**，每日分区存储截至该日的历史最早激活日期：

- **取最新业务日期分区**（如昨日）即可获得最新的累计历史首次激活记录；
- 若需计算"某日新增首次激活广告主"，需将 `grass_date = T` 与 `grass_date = T-1` 两个分区进行对比（当日有值而前日为 NULL，或当日值等于 T 日的记录即为当日新增）；
- 由于 ETL 为 `INSERT OVERWRITE`，**历史分区数据一经写入不会再被修改**，若上游当日数据存在延迟补录，可能导致当日分区首次激活日期偏晚，以次日分区为准。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_activeness_1d__${region}_s0_live` | 提供当日（`grass_date = T`）各广告主的广告活跃明细，包含 `first_mm_kw_ads_active_date` 和 `first_sm_kw_ads_active_date` |
| `mp_paidads.dws_advertiser_first_active_td__${region}_s0_live`（自身前一日分区） | 提供截至 `T-1` 日的历史累计首次激活日期，与当日数据合并后取 `MIN`，实现累计滚动更新 |

---

## ETL 逻辑摘要

### 数据流

```
┌─────────────────────────────────────────────────────────────────┐
│          上游：当日活跃明细（grass_date = T）                     │
│  mp_paidads.dws_advertise_activeness_1d__${region}_s0_live      │
│  字段：shop_id, user_id,                                        │
│        first_mm_kw_ads_active_date,                             │
│        first_sm_kw_ads_active_date                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │  UNION ALL
┌─────────────────────────▼───────────────────────────────────────┐
│          上游：昨日累计快照（grass_date = T-1）                   │
│  mp_paidads.dws_advertiser_first_active_td__${region}_s0_live   │
│  字段：shop_id, user_id,                                        │
│        first_mm_kw_ads_active_date,                             │
│        first_sm_kw_ads_active_date                              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
              ┌───────────────────────┐
              │   GROUP BY shop_id,   │
              │   user_id             │
              │   取 MIN(日期字段)     │
              └───────────┬───────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  目标表（INSERT OVERWRITE，当日分区）                             │
│  mp_paidads.dws_advertiser_first_active_td__${region}_s0_live   │
│  partition(tz_type='local', grass_region=upper(${region}),      │
│            grass_date=${grass_date})                            │
└─────────────────────────────────────────────────────────────────┘
```

### 关键 CTE 说明

本 ETL 无显式 CTE（`WITH` 子句），核心逻辑通过内联子查询（`UNION ALL` + `GROUP BY MIN`）实现。

| 逻辑层 | 来源表 | 作用 |
|--------|--------|------|
| 当日增量子查询 | `dws_advertise_activeness_1d__${region}_s0_live`（`grass_date = T`） | 获取当日广告活跃记录中的首次激活日期字段 |
| 历史累计子查询 | `dws_advertiser_first_active_td__${region}_s0_live`（`grass_date = T-1`） | 读取上一日已累计的首次激活历史最小日期 |
| 聚合层 | UNION ALL 结果集 | 按 `(shop_id, user_id)` 分组，对两类日期字段分别取 `MIN`，滚动更新历史最早值 |

### 注意事项

1. **自引用滚动更新**：本表 ETL 读取自身前一日分区（`T-1`）并写入当日分区（`T`），属于自依赖增量模式。若某日 ETL 失败导致 `T-1` 分区数据缺失，则当日分区将仅包含 `dws_advertise_activeness_1d` 的当日数据，**丢失历史累计信息**，需触发历史分区修复后重跑。

2. **MIN 语义保证单调性**：`first_mm_kw_ads_active_date` 和 `first_sm_kw_ads_active_date` 均由 `MIN` 聚合计算，字段值只会随时间保持不变或提前，**不会出现日期后退的情况**（前提是上游数据质量稳定）。

3. **分区写入方式**：ETL 采用 `INSERT OVERWRITE` + 静态分区（`tz_type='local'`）+ 动态分区（`grass_region`、`grass_date`）混合模式，每次仅覆写当日分区，不影响历史分区。

4. **地区参数化**：`grass_region` 由 `upper('${region}')` 写入，统一为大写国家代码。各地区独立调度，互不干扰，文档中所见的具体地区代码仅为调度模板的参数化实例，本表覆盖所有已接入的地区。

5. **NULL 值含义**：若某 `shop_id` + `user_id` 组合的 `first_mm_kw_ads_active_date` 为 NULL，表示该广告主历史上**从未激活**手动关键词广告；`first_sm_kw_ads_active_date` 同理。查询时应注意 NULL 过滤逻辑，避免将未激活用户误纳入激活统计。

---

*文档生成时间：2026-04-22*