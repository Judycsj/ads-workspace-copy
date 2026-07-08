<!-- ads-workspace-gdoc-sync: gdoc_id=1mldU-9KIuJ9JWQUwlx40EslYwFqq0iTbwrBo_zVrT78 gdoc_url=https://docs.google.com/document/d/1mldU-9KIuJ9JWQUwlx40EslYwFqq0iTbwrBo_zVrT78/edit -->

# mp_paidads.dim_deduction_cost_cap

**分层**：DIM（维度层 / ADS）
**主键**：`date_type` + `grass_region` + `pricing_type` + `placement`
**分区**：无分区字段
**更新频率**：手工维护（Google Sheets 人工更新后同步）
**引用频次**：0（末端维表，由下游业务 SQL 直接 JOIN 使用）

---

## 业务描述

本表为付费广告（Paid Ads）扣费成本上下限（Cost Cap）的维度配置表，记录了各地区（`grass_region`）、计价类型（`pricing_type`）、广告投放位置（`placement`）及日期类型（`date_type`）组合下，广告平台允许的单次扣费金额下限（`cost_cap_min`）与上限（`cost_cap_max`）。数据来源为业务团队在 Google Sheets 中手工维护的配置数据，经 ETL 同步至数仓。

该表主要用于广告扣费合规性校验与异常检测，例如识别实际扣费金额超出或低于阈值的异常广告订单，辅助广告运营和结算团队进行稽核。在搭建广告扣费监控报表、建立预算超限预警以及对账分析时，通常将本表与广告实际扣费明细表进行 JOIN，以判断扣费是否在合规区间内。

本表覆盖多个市场（BR、ID、MY、PH、SG、TH、TW、VN、MX 等），支持普通日（`normal_day`）与活动日（`campaign_day`）两套不同的上下限配置，能够灵活适配大促期间更宽松或更严格的扣费管控策略，是广告计费治理的核心参考维表。

---

## 字段列表

### 维度：主键与配置维度

| 字段 | 类型 | 说明 |
|------|------|------|
| `date_type` | string | 日期类型，区分普通日与活动日。枚举值：`normal_day`（普通日）、`campaign_day`（大促/活动日）。活动日通常对应大促期间，上下限配置与普通日不同 |
| `grass_region` | string | 地区代码，如 `BR`（巴西）、`ID`（印尼）、`MY`（马来西亚）、`PH`（菲律宾）、`SG`（新加坡）、`TH`（泰国）、`TW`（台湾）、`VN`（越南）、`MX`（墨西哥）等 |
| `pricing_type` | string | 计价类型编码，如 `4`（CPM/CPC 等特定计价方式）、`8`、`11`、`15` 等，具体映射关系请参照计价类型维表 ⚠️ 字段类型为 string，但实际存储数字编码，JOIN 时注意类型转换 |
| `placement` | string | 广告投放位置编码，如 `805`、`802`、`40`、`50`、`4` 等，标识广告展示的具体版位 ⚠️ 字段类型为 string，但实际存储数字编码，JOIN 时注意类型转换 |

### 维度：成本上下限配置

| 字段 | 类型 | 说明 |
|------|------|------|
| `cost_cap_min` | string | 该组合下允许的单次扣费金额下限（本地货币），如 `0.004`、`20.000` 等 ⚠️ 字段类型为 string，使用时需转换为数值类型（如 `CAST(cost_cap_min AS DOUBLE)`）方可进行数值比较或计算；部分值含千位分隔符（如 `2,000.00`），需先去除逗号再转换 |
| `cost_cap_max` | string | 该组合下允许的单次扣费金额上限（本地货币），如 `0.60`、`2,000.00` 等 ⚠️ 字段类型为 string，使用时需转换为数值类型（如 `CAST(cost_cap_max AS DOUBLE)`）方可进行数值比较或计算；部分值含千位分隔符（如 `10,000.00`），需先去除逗号再转换 |

### 维度：元数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据写入时间戳，记录本条配置数据从 Google Sheets 同步至数仓的时间，格式为时间戳字符串 ⚠️ 该字段反映的是数据入库时间，不代表业务配置的生效时间，不应用于业务过滤逻辑 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 或 `JOIN` 使用，无聚合场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（人工维护） | 业务团队手工填写各地区、计价类型、投放位置的扣费上下限配置，经 ETL 管道同步至本表 |

---

## ETL 逻辑摘要

### 维表说明

本表属于 Google Sheets 手工维护维表（gsheet 类型）。数据由广告运营或结算团队在指定 Google Sheets 中维护，业务人员直接在表格中新增、修改或删除各地区+计价类型+投放位置+日期类型组合对应的扣费上下限配置；ETL 管道定期将 Google Sheets 内容全量同步至 `mp_paidads.dim_deduction_cost_cap__reg_s0_live`，同步时附加 `ingestion_timestamp` 记录入库时间。

**内容结构**：每行代表一条唯一配置组合（`date_type` + `grass_region` + `pricing_type` + `placement`），对应该组合下的扣费最小值（`cost_cap_min`）与最大值（`cost_cap_max`）。当前配置覆盖 BR、ID、MY、PH、SG、TH、TW、VN、MX 等多个市场，支持 `normal_day` 与 `campaign_day` 两种日期类型，涉及多种计价类型（4、8、11、15）和投放位置（802、805、40、50、4）的组合。

**维护注意事项**：
- 如需新增市场或调整阈值，需由有权限的业务人员在 Google Sheets 源文件中修改，待下次 ETL 同步后方可生效；
- `cost_cap_min` 和 `cost_cap_max` 在 Sheets 中为数值格式，但部分单元格可能因格式问题含千位分隔符（逗号），下游使用时需注意清洗；
- 本表无历史版本管理，每次全量同步会覆盖前一版本，如需追溯历史配置变更，需依赖 `ingestion_timestamp` 或外部审计记录。

---

*文档生成时间：2026-04-22*