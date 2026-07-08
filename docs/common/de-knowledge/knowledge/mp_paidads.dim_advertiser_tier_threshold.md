<!-- ads-workspace-gdoc-sync: gdoc_id=1vdr30mvLDBRlxLj3j-Z9WEo_KytxecAhMcZJaogMNjM gdoc_url=https://docs.google.com/document/d/1vdr30mvLDBRlxLj3j-Z9WEo_KytxecAhMcZJaogMNjM/edit -->

# mp_paidads.dim_advertiser_tier_threshold

**分层**：dim（维度层）
**主键**：`grass_region`, `advertiser_tier`
**分区**：无分区字段
**更新频率**：手工维护（Google Sheets 同步）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表为广告主分层阈值维表，定义了各地区（`grass_region`）下不同广告主层级（`advertiser_tier`）所对应的 GMV 区间上下限（以美元计）。广告主分层通常包括 micro、small、medium、large 四档，每档通过 `min_value_usd` 与 `max_value_usd` 划定 USD GMV 边界，用于将广告主按体量归类，进而支撑差异化的商业策略、资源分配与效果分析。

本表在 Paid Ads 数据域中承担"分层标准参照"的核心职责，下游宽表或报表在判断某广告主属于哪一层级时，通过关联本表的区间条件进行打标。由于各地区市场体量与用户规模存在显著差异，不同 `grass_region` 的阈值各自独立设定，确保分层结果在各市场内具备合理的业务区分度。

该维表由业务团队在 Google Sheets 中手工维护，经自动化流程同步写入数仓。当业务需要调整某地区的分层标准时，只需更新 Sheets 中对应行的阈值，数据将在下一次同步后生效，下游所有引用本表的任务均会自动继承最新标准，无需修改 ETL 逻辑。

---

## 字段列表

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区代码，如 `ID`（印尼）、`MY`（马来西亚）、`PH`（菲律宾）、`SG`（新加坡）、`TH`（泰国）、`TW`（台湾）、`VN`（越南）、`BR`（巴西）等；与 `advertiser_tier` 共同构成主键 |
| `advertiser_tier` | string | 广告主层级，取值为 `micro_advertiser` / `small_advertiser` / `medium_advertiser` / `large_advertiser`，层级由低到高；与 `grass_region` 共同构成主键 |

### 指标：广告主分层阈值（USD GMV）

| 字段 | 类型 | 说明 |
|------|------|------|
| `min_value_usd` | string | 该层级 GMV 区间下限（含），单位：美元；实际使用时需转换为数值类型进行比较 ⚠️ 字段存储类型为 string，范围过滤时须显式 CAST 为数值型（如 `CAST(min_value_usd AS DOUBLE)`），直接数值比较会导致字典序错误 |
| `max_value_usd` | string | 该层级 GMV 区间上限（不含上边界，最高层级上限为 `9999999999` 表示无穷大），单位：美元 ⚠️ 同上，需 CAST 为数值型使用；`large_advertiser` 的上限为占位值 `9999999999`，不代表真实业务上限，过滤时应注意处理 |

### 维度：元数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据从 Google Sheets 同步写入数仓的时间戳，用于追踪本次数据刷新的时效，格式为字符串 ⚠️ 该字段为写入时间戳而非业务时间，不应用于业务时间过滤或趋势分析 |

---

## 查询使用须知

本表为维表，直接 SELECT 或 JOIN 使用，无聚合场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（业务手工维护） | 各地区广告主分层阈值的原始数据源，由业务团队按需更新后自动同步至数仓 |

---

## ETL 逻辑摘要

### 维表说明

本表为 Google Sheets 驱动的手工维护维表，无自动化 SQL ETL 逻辑。数据维护流程如下：

1. **内容维护**：业务团队在指定 Google Sheets 中按 `grass_region` × `advertiser_tier` 维度填写或更新 `min_value_usd` 与 `max_value_usd` 阈值。
2. **自动同步**：调度系统定期读取 Sheets 最新内容，全量覆写写入本表，同时记录 `ingestion_timestamp`。
3. **覆盖范围**：表中已覆盖 ID、MY、PH、SG、TH、TW、VN、BR 等多个地区，每个地区均包含 micro / small / medium / large 四个层级，共 32 条标准记录（以当前版本为基准，实际以 Sheets 为准）。
4. **生效机制**：Sheets 更新后，下一次同步任务执行完成即全表生效，下游引用任务无需感知变更。

### 注意事项

- **阈值区间语义**：分层判断逻辑通常为 `min_value_usd <= 广告主GMV_USD < max_value_usd`，注意边界方向，避免重叠或遗漏。
- **类型转换**：`min_value_usd`、`max_value_usd` 均为 string 类型，JOIN 或过滤时务必 `CAST` 为数值类型，否则字典序比较会产生错误的层级归属。
- **占位值处理**：`large_advertiser` 的 `max_value_usd = 9999999999` 为占位上限，在做区间展示或区间长度计算时应特殊处理，避免产生误导性的数值。
- **维护时效**：本表不设历史分区，任意时刻读取均为最新阈值版本。若下游需要复现历史分层结果，需结合 `ingestion_timestamp` 自行归档或在下游快照表中保留当期阈值。
- **新增地区**：若业务拓展新市场，需在 Sheets 中补充对应地区的四档阈值后方可在下游使用，数仓侧无需额外改造。

---

*文档生成时间：2026-04-22*