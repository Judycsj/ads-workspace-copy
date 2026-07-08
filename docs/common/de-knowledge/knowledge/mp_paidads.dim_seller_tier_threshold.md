<!-- ads-workspace-gdoc-sync: gdoc_id=1xd-UY8512R8wBeiDednrsUf-88LmnCCMMyYqRktFbzI gdoc_url=https://docs.google.com/document/d/1xd-UY8512R8wBeiDednrsUf-88LmnCCMMyYqRktFbzI/edit -->

# mp_paidads.dim_seller_tier_threshold

**分层**：dim（维度层）
**主键**：`grass_region`, `seller_tier`
**分区**：无（Google Sheets 维表，全量静态加载）
**更新频率**：手工维护（按业务需要不定期更新）
**引用频次**：2 次

---

## 业务描述

本表为卖家分层阈值维表，记录各地区（`grass_region`）下不同卖家等级（`seller_tier`）所对应的 GMV 区间上下界（以 USD 计）。业务上将卖家划分为 micro、small、medium、large 四个层级，每个层级在不同市场的绝对 GMV 门槛各有差异，本表统一维护这套分层标准，供下游 ETL 任务在关联时将连续 GMV 值映射为离散的卖家等级标签。

本表的核心使用场景是：在广告效果分析、卖家分群运营、付费广告预算分配等业务中，将卖家的历史 GMV 与本表的 `[min_value_usd, max_value_usd)` 区间做范围匹配，从而为每位卖家打上对应的 `seller_tier` 标签，进而按层级汇总投放效率、ROI、渗透率等核心指标。

由于各市场货币购买力和平台规模不同，各地区的分层阈值差异显著。本表集中管理跨地区分层口径，确保全平台对卖家等级的定义保持一致，避免各下游任务各自硬编码阈值导致口径分裂。

---

## 字段列表

### 维度：地区与卖家分层主键

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 市场/地区代码，如 `ID`、`MY`、`SG`、`TH`、`PH`、`TW`、`VN`、`BR` 等，与主键 `seller_tier` 联合唯一标识一条分层阈值记录 |
| `seller_tier` | string | 卖家等级标签，取值为 `micro_seller`、`small_seller`、`medium_seller`、`large_seller`，代表从低到高的四个分层 |

### 维度：分层 GMV 阈值

| 字段 | 类型 | 说明 |
|------|------|------|
| `min_value_usd` | string | 该卖家等级 GMV 区间的下界（USD，含），即卖家 GMV ≥ 此值时归入本层；存储为字符串类型，使用时需转换为数值类型 ⚠️ 字段类型为 string，参与数值比较或计算前须显式 CAST 为 `double` 或 `decimal`，否则将触发字典序比较而非数值比较，导致分层结果错误 |
| `max_value_usd` | string | 该卖家等级 GMV 区间的上界（USD，不含），即卖家 GMV < 此值时归入本层；`large_seller` 的上界设为 `9999999999` 表示无上限；存储为字符串类型，使用时需转换为数值类型 ⚠️ 字段类型为 string，同 `min_value_usd`，必须 CAST 后使用；`9999999999` 为哨兵值，代表无上限，不应直接用于业务展示 |

### 维度：元数据

| 字段 | 类型 | 说明 |
|------|------|------|
| `ingestion_timestamp` | string | 数据写入时间戳，记录本条记录最近一次从 Google Sheets 同步入数仓的时间，可用于判断数据新鲜度；非业务字段，不参与分层逻辑 |

---

## 查询使用须知

本表为 Google Sheets 维表，直接 `SELECT` 或 `JOIN` 使用，无聚合场景。

补充说明：

1. **范围匹配时必须 CAST**：`min_value_usd` 与 `max_value_usd` 均为 `string` 类型。在与卖家 GMV 做区间匹配时，务必使用 `CAST(min_value_usd AS DOUBLE)` 和 `CAST(max_value_usd AS DOUBLE)`，否则字典序比较会产生错误的分层结果。

2. **区间为左闭右开**：匹配逻辑应为 `seller_gmv_usd >= CAST(min_value_usd AS DOUBLE) AND seller_gmv_usd < CAST(max_value_usd AS DOUBLE)`，各层级之间无重叠，`large_seller` 的上界哨兵值 `9999999999` 可直接参与比较。

3. **地区字段对齐**：JOIN 时需确认上游表的地区字段与本表 `grass_region` 的编码格式一致（均为大写两字母代码），避免因大小写不一致导致关联失败。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（手工维护表格） | 由业务/运营团队手工录入各地区各卖家等级的 GMV 阈值上下界，通过数据接入管道定期同步至数仓 |

---

## ETL 逻辑摘要

### 维表说明

本表为 Google Sheets 类型维表，数据由业务或运营团队在 Google Sheets 中手工维护，通过自动化数据接入流程（如 Fivetran、自研 gsheet 同步任务等）定期拉取并写入数仓，写入时记录 `ingestion_timestamp`。

**内容结构**：Google Sheets 中每行对应一个（地区 × 卖家等级）组合，共包含 `grass_region`、`seller_tier`、`max_value_usd`、`min_value_usd` 四列业务字段。目前覆盖地区包括 ID、MY、PH、SG、TH、TW、VN、BR，每个地区下固定维护 `micro_seller`、`small_seller`、`medium_seller`、`large_seller` 四个层级。

**数据流**：

```
Google Sheets（运营手工维护）
        │
        │  gsheet 同步任务（定期拉取）
        ▼
mp_paidads.dim_seller_tier_threshold__reg_s0_live
（全量覆盖写入，记录 ingestion_timestamp）
```

### 注意事项

1. **阈值变更需人工触发**：分层阈值由运营团队在 Google Sheets 中维护，若业务调整了某地区的分层标准，需手工更新 Sheet 并等待同步任务完成后下游才能感知变更，不存在自动回溯机制。
2. **哨兵值勿用于展示**：`large_seller` 的 `max_value_usd = 9999999999` 为约定上限哨兵值，在报表展示层应替换为 `"无上限"` 或 `NULL`，不应直接透出给用户。
3. **类型陷阱**：全表字段均为 `string` 类型存储，数值字段在任何计算场景下都需要显式类型转换，这是本表最常见的使用错误来源。
4. **覆盖地区以 Sheet 实际内容为准**：如有新市场上线，需运营团队在 Sheet 中补充对应地区的四行阈值记录，下游逻辑无需改动即可自动生效。

---

*文档生成时间：2026-04-22*