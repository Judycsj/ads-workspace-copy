<!-- ads-workspace-gdoc-sync: gdoc_id=1wA3MX3l1ABqt5h9hnnWwLHw1SB7iB6fILV33TzoLJ2E gdoc_url=https://docs.google.com/document/d/1wA3MX3l1ABqt5h9hnnWwLHw1SB7iB6fILV33TzoLJ2E/edit -->

# mp_paidads.dim_campaign_days_1y

**分层**：DIM（维度层）
**主键**：`campaign_day` + `grass_region`
**分区**：无分区字段（全量小表）
**更新频率**：按需手工维护（Google Sheets 快照同步）
**引用频次**：0（末端 ADS 层维表，由下游业务查询直接消费）

---

## 业务描述

本表为 Shopee Ads 付费广告团队维护的**大促/Campaign 日期维度表**，记录各地区在近一年内被识别为"大促日"或"流量高峰日"的日期及其对应的活动类型编码。数据源自 Google Sheets《[Shopee Ads] Campaign days forecasting / campaign_days_2026》，由各地区 Local Marketing PIC 与 BI PIC 协作填报，覆盖 PH、ID、VN、TW、SG、MY、TH、BR 等多个市场。

本表的核心价值在于为广告预算预测、广告消耗归因、大促期间 GMV Surge 系数配置等下游分析提供标准化的"大促日历"参考。在 Campaign Surge（大促流量激增）场景下，本表可用于标记哪些日期属于大促窗口期，进而在广告绩效分析中区分大促日与平日的消耗基线，避免将大促异常值混入常规趋势建模。

下游使用场景包括但不限于：广告主预算预测模型的特征工程、广告 ROI 分析的大促期过滤、大盘 GMV 预测中的 Campaign Boost 系数引入，以及系统侧 Campaign Surge 配置的核对依据。

---

## 字段列表

### 维度：主键与广告大促属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_day` | date | 大促/高流量日期，格式为 `YYYY-MM-DD`。与 `grass_region` 联合构成本表主键，标识某地区某天为大促日。⚠️ 本表仅收录被识别为大促日的日期，不存在"普通日"记录，查询时不可将缺失日期理解为非大促日而做补全聚合；如需完整日历须与日期维表 LEFT JOIN。 |
| `campaign_type` | tinyint | 大促活动类型编码（整型枚举）。字段来源于 Google Sheets 原始数据中 `Is configured in DB for Campaign Surge` 列（"Y" 映射为特定枚举值）及活动性质分类。具体枚举含义需参考业务枚举字典或与 Ads BI PIC 确认。⚠️ 字段为枚举编码，直接数值无业务含义，请勿对该字段进行 SUM/AVG 等数值聚合。 |
| `grass_region` | string | 地区编码，采用大写两字母缩写，如 `PH`（菲律宾）、`ID`（印尼）、`VN`（越南）、`TW`（台湾）、`SG`（新加坡）、`MY`（马来西亚）、`TH`（泰国）、`BR`（巴西）。与 `campaign_day` 联合构成本表主键。⚠️ 各地区大促日历差异显著，跨地区聚合前务必按 `grass_region` 分组，避免不同市场大促日期混算。 |

---

## 查询使用须知

本表为维表，直接 SELECT 使用，无聚合场景。

典型用法为与事实表 JOIN，筛选出大促日对应的广告数据：

```sql
SELECT
    f.*,
    d.campaign_type
FROM fact_ads_performance f
JOIN mp_paidads.dim_campaign_days_1y d
    ON f.stat_date = d.campaign_day
    AND f.grass_region = d.grass_region
WHERE d.grass_region = 'SG'
  AND d.campaign_day BETWEEN '2026-01-01' AND '2026-12-31';
```

**注意**：`campaign_type` 为枚举编码，不可做数值聚合；`campaign_day` 仅含大促日，非全日历，JOIN 时需注意匹配语义。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets：`1fzKsIQz1T7saO1mvODUHQ25L9IJ_H5pwBTE2Qvjcmx4`，Sheet `campaign_days_2026`（gid: 1670187272） | 各地区大促日期、预期 GMV 增幅系数、Campaign Surge 配置状态等原始数据，由 Local Marketing PIC 与 Local BI PIC 共同维护 |

---

## 维表说明

本表为手工维护的 Google Sheets 快照维表，通过 `gws sheets.spreadsheets.values.get` API 定期拉取并写入数仓。原始 Google Sheets 文档包含 12 列、501 行数据，涵盖 2026 年全年各地区大促日历，字段涵盖地区（Region）、日期（Date）、预期 GMV 增幅系数（Expected increase in GMV (in %)）、负责人（Local Marketing PIC / Local BI PIC）、备注（Remarks）、系统配置状态（Config in system）、Ticket 号、Boost 系数是否 > 1.2（Boost > 1.2）、是否已在 DB 配置 Campaign Surge（Is configured in DB for Campaign Surge）等信息。

入库时，原始 Sheet 数据经过清洗与字段映射，仅保留 `campaign_day`、`campaign_type`（由 Campaign Surge 配置状态派生）、`grass_region` 三个核心字段写入本表。Sheet 内容由业务侧按活动排期滚动维护，**如需更新大促日历，请联系对应地区的 Local Marketing PIC 或 Ads BI PIC 在源 Sheet 中修改后重新触发同步**，不得直接修改数仓表数据。

各地区数据更新节奏不同步，部分未来大促日期可能尚未录入或 `Expected increase in GMV` 系数仍为估算值，使用前建议核对 Sheet 原始记录的填报完整性。

---

*文档生成时间：2026-05-20*