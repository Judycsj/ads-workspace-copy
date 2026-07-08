<!-- ads-workspace-gdoc-sync: gdoc_id=1vKbkX44VQkzD6hzwALfjMpOLDxMRJqeFEMihjz9ucVE gdoc_url=https://docs.google.com/document/d/1vKbkX44VQkzD6hzwALfjMpOLDxMRJqeFEMihjz9ucVE/edit -->

# mp_paidads.dws_advertiser_placement_performance_td

**分层**：DWS（数据服务层 / 汇总宽表）
**主键**：`shop_id` + `placement` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日增量滚动更新（T+1）
**引用频次**：7 次（候选表范围内）

---

## 业务描述

本表以**广告主（店铺）× 投放位（placement）**为聚合粒度，按地区、日期存储广告投放的**累计至今（To-Date，td）**核心绩效指标，涵盖曝光、点击、订单、销售件数、直接归因 GMV 及广告消耗等维度。"累计至今"含义为：当日分区的数据等于历史所有日期累积叠加，而非单日增量，因此一次查询即可获取任意截止日期的累计汇总值，避免对历史分区进行全扫描聚合。

本表是付费广告效果分析的核心宽表之一，适用于广告主投放看板、投放位效果排行、消耗-GMV 对比分析、ROAS 计算等场景。下游可直接按 `shop_id`、`placement` 以及任意日期分区进行过滤取值，无需再对原始明细表进行多日聚合，显著降低查询成本。

表数据按地区和时区参数化调度，各地区以本地时区对齐，确保跨地区分析时业务日期口径一致。当前正式环境任务编号为 `data_paidadsmart.studio_3860626`，每日稳定产出。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。标识当前行数据所对齐的时区口径。各地区按本地时区参数化调度，当前写入值为 `'local'`。**查询时必须指定**，否则将触发多时区重复扫描。 |
| `grass_region` | string | 国家/地区分区，大写字母，如 `'MX'`、`'TH'`。**查询时必须指定**，否则将全量扫描所有地区分区。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`。本表为累计至今（td）存储，**该分区代表数据的截止日期**，即查询某日的数据即为截止该日的全部累计值。 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，标识广告主（卖家）身份，联合 `placement` 构成本表业务主键。 |
| `placement` | bigint | 广告投放位 ID，标识广告展示的具体位置类型（如搜索、发现等）。⚠️ 字段注释仅为 `placement`，含义需结合业务枚举表解码，裸值无业务语义。 |

### 指标：流量漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt_td` | bigint | 截至当前分区日期的**累计曝光次数**，包含去重后及欺诈流量数据。⚠️ 已含欺诈数据，若需净曝光分析需额外过滤；本字段为累计值，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |
| `click_cnt_td` | bigint | 截至当前分区日期的**累计有效点击次数**（已成功扣费的点击）。⚠️ 累计存储，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |

### 指标：广告转化

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt_td` | bigint | 截至当前分区日期的**累计直接归因订单量**（direct order，即广告直接带来的订单）。⚠️ 累计存储，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |
| `ads_items_sold_cnt_td` | bigint | 截至当前分区日期，直接归因订单中的**累计销售商品件数**。⚠️ 累计存储，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |
| `ads_gmv_amt_local_td` | double | 截至当前分区日期，直接归因订单的**累计 GMV（本地货币）**。货币单位因地区而异，跨地区聚合无意义，需使用 USD 口径字段。⚠️ 累计存储，跨分区 SUM 会导致重复计算；跨地区不可直接 SUM，应改用 `ads_gmv_amt_usd_td`。 |
| `ads_gmv_amt_usd_td` | double | 截至当前分区日期，直接归因订单的**累计 GMV（美元）**。⚠️ 累计存储，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |
| `broad_gmv_amt_usd_td` | double | 截至当前分区日期，**广泛匹配广告订单的累计 GMV（美元）**，口径较 `ads_gmv_amt_usd_td` 更宽泛，包含非直接归因的广泛关联订单。⚠️ 累计存储，跨分区 SUM 会导致重复计算；与 `ads_gmv_amt_usd_td` 口径不同，不可混用或叠加。 |

### 指标：广告消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local_td` | double | 截至当前分区日期的**累计广告扣费金额（本地货币）**。货币单位因地区而异。⚠️ 累计存储，跨分区 SUM 会导致重复计算；跨地区不可直接 SUM，应改用 `expenditure_amt_usd_td`。 |
| `expenditure_amt_usd_td` | double | 截至当前分区日期的**累计广告扣费金额（美元）**。⚠️ 累计存储，跨分区 SUM 会导致重复计算，应取单一 `grass_date` 分区值。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，产生大量无效 I/O 并可能返回多时区重复数据：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，当前仅有 `local` 分区，遗漏等价于全扫描且存在未来扩展后多计风险 |
| `grass_region` | `grass_region = 'XX'`（大写） | 跨地区全扫描，且本地货币字段跨地区无法比较 |
| `grass_date` | `grass_date = '2026-04-21'` | 累计型存储下跨分区扫描会严重放大数据量，且多分区 SUM 导致重复计算 |

### 不可直接 SUM 的字段

本表所有指标字段均为**累计至今（td）存储**，即每个 `grass_date` 分区独立存储截至该日的全量累计值，而非增量差值。因此：

- ❌ **禁止对不同 `grass_date` 分区的指标进行 SUM**，会导致数值成倍重复计算。
- ✅ **正确做法**：仅查询**单一目标日期**的分区，直接读取该分区的累计值作为最终结果。

若需计算某日期区间内的**新增量**（如某月新增消耗），应使用：
```sql
-- 区间增量 = 区间末日累计值 - 区间首日前一天累计值
expenditure_amt_usd_td (grass_date = '区间末日') 
  - expenditure_amt_usd_td (grass_date = '区间首日前一天')
```

此外，以下字段存在额外使用限制：

| 字段 | 限制说明 | 正确用法 |
|------|----------|----------|
| `ads_gmv_amt_local_td` / `expenditure_amt_local_td` | 本地货币，跨地区不可 SUM | 跨地区聚合改用 USD 口径字段 |
| `broad_gmv_amt_usd_td` | 广泛归因口径，与 `ads_gmv_amt_usd_td` 不同，不可叠加 | 按业务场景选择对应口径，勿混用 |
| `impression_cnt_td` | 含欺诈流量，非净曝光 | 如需净曝光需结合业务规则单独处理 |
| ROAS、CTR 等派生比率 | 本表未存储，需现场计算 | 如 `ROAS = ads_gmv_amt_usd_td / expenditure_amt_usd_td`，使用分子/分母字段重新计算，不可对中间比率 SUM |

### 时效性说明

- 本表为 **T+1 更新**，每日调度产出前一业务日的最新累计值。
- 查询最新数据时，应使用**已产出的最近 `grass_date` 分区**（通常为昨日日期），避免查询当日分区（可能尚未写入或数据不完整）。
- `td` 后缀代表"To-Date（累计至今）"，即当前分区值已包含该日期及之前所有历史数据的累计汇总，无需再 JOIN 历史分区。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 提供当日（1d）广告绩效明细数据，按 `shop_id` + `placement` 聚合后作为当日增量 |
| `mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live`（自身前一日分区） | 提供截至前一日的历史累计值，通过 UNION ALL 与当日增量合并后再次聚合，实现累计滚动更新 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_performance_1d__reg_s0_live
  [WHERE grass_date = ${grass_date}, tz_type='local', grass_region = upper('${region}')]
  └── GROUP BY shop_id, placement → 当日增量 (impression/click/order/gmv/expenditure)
                │
                │  UNION ALL
                │
mp_paidads.dws_advertiser_placement_performance_td__reg_s0_live (自身前一日分区)
  [WHERE grass_date = ${grass_date} - 1, tz_type='local', grass_region = upper('${region}')]
  └── 历史累计值（td）
                │
                ▼
       GROUP BY shop_id, placement (SUM 所有指标)
                │
                ▼
dws_advertiser_placement_performance_td__reg_s0_live
  PARTITION (tz_type='local', grass_region=upper('${region}'), grass_date=${grass_date})
  [INSERT OVERWRITE，Parquet 格式]
```

### 关键 CTE 说明

本 ETL 无显式 CTE，逻辑通过内联子查询（UNION ALL 子查询）实现：

| 子查询层 | 来源表 | 作用 |
|----------|--------|------|
| 增量子查询 | `dws_advertise_performance_1d__reg_s0_live` | 读取当日 1d 明细，按 `shop_id`+`placement` 聚合得到当日增量指标 |
| 历史累计子查询 | 本表自身（前一日分区） | 读取 `grass_date - 1` 的累计 td 值，作为历史基准 |
| 外层聚合 | 上述两层 UNION ALL 结果 | 将当日增量与历史累计 SUM 合并，产出当日最终累计值写入新分区 |

### 注意事项

1. **自引用滚动累计（Snowball 模式）**：本表通过 `UNION ALL 当日增量 + 前一日 td 分区自身` 的方式实现逐日滚动累计，ETL 强依赖前一日分区已成功产出。若前一日分区缺失（如任务失败未修复），当日分区将仅包含当日增量，历史累计数据丢失，导致 td 值严重低估。**补数时必须按日期顺序串行执行，不可并行跳跃补数。**

2. **INSERT OVERWRITE 幂等性**：写入采用 `INSERT OVERWRITE PARTITION`，同一分区重跑会覆盖，保证幂等；但若前一日分区不完整，即使重跑当日也无法修复累计值，需从数据断点日期起逐日重跑。

3. **地区参数化调度**：ETL SQL 中的 `upper('${region}')`、`date('${grass_date}')` 均为调度模板变量，由调度系统按地区实例化后分别执行，本表覆盖所有已接入地区，各地区按本地时区对齐。

4. **`impression_cnt_td` 含欺诈数据**：按字段注释说明，曝光数包含 deduplicated 及 fraud 数据，若用于质量分析需额外说明口径；消耗、订单等字段不受此影响。

5. **`broad_gmv_amt_usd_td` 口径差异**：该字段来源于上游 `broad_gmv_amt_usd_1d` 字段，归因范围较 `ads_gmv_amt_usd_td`（仅直接归因）更宽，两者不可叠加使用，使用前需与业务方确认所需归因口径。

---

*文档生成时间：2026-04-22*