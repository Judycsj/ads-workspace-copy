<!-- ads-workspace-gdoc-sync: gdoc_id=1jyB0s6ZkU9xBFIW6SqQ65X-ZjsRcyWUEhKY5tNP2OeM gdoc_url=https://docs.google.com/document/d/1jyB0s6ZkU9xBFIW6SqQ65X-ZjsRcyWUEhKY5tNP2OeM/edit -->

# mp_paidads.dim_translog_order_type_mapping

**分层**：dim（维度层）
**主键**：`order_type`
**分区**：无分区字段
**更新频率**：人工维护，按需更新
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表是广告交易流水（translog）中订单类型（`order_type`）的枚举映射维表，由数据团队通过 Google Sheets 手工维护，并同步至数仓供下游查询使用。表中记录了广告账户资金流水所涉及的全部订单类型编码及其对应的业务名称，涵盖扣费类（点击扣费、展示扣费、CPS 扣费、手动扣费等）、充值类（普通充值、钱包充值、SVS 充值、免费额度充值等）、信用额度注入类（激励计划注入、直播激励注入、营销活动包注入等）以及冻结/解冻、转账、逾期余额处理等多种资金操作类型。

下游 ETL 通过 `order_type` 字段与本表 JOIN，可将交易流水中的数字编码转化为可读业务标签，方便分析师和运营人员按业务语义对广告账户收支进行分类汇总与监控。

本表作为纯维表使用，不涉及聚合计算，是交易流水相关报表和看板准确呈现业务含义的基础依赖。

---

## 字段列表

### 维度：主键与订单类型映射

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_type` | string | 订单类型编码，取值为数字字符串（如 `'1'`、`'2'` 等），对应广告交易流水中的资金操作类型，为本表主键。⚠️ 字段类型为 string，与上游交易流水表 JOIN 时需注意类型一致性，避免隐式类型转换导致 JOIN 失败或性能劣化 |
| `order_type_name` | string | 订单类型业务名称，为 `order_type` 的可读描述（见下方枚举说明）。⚠️ 编码 29、30、31 当前名称为空，含义待补充，JOIN 后如出现空值需结合业务上下文判断 |
| `ingestion_timestamp` | string | 数据从 Google Sheets 同步入仓的时间戳，标识本条记录的最新写入时间，可用于判断维表数据的新鲜度。⚠️ 仅为同步元数据，不代表业务事件时间，不可用于业务时序分析 |

**order_type 枚举参考：**

| order_type | order_type_name |
|---|---|
| 1 | Deduction Click |
| 2 | Topup |
| 3 | Topup Manual |
| 4 | Topup Wallet |
| 5 | Deduct Order |
| 6 | Topup SVS |
| 7 | Topup Free Credit |
| 8 | Topup Seller Mission |
| 9 | Inject Credit Ads Program |
| 10 | Ads Credit Adjustment |
| 11 | Deduct Imp |
| 12 | Inject Credit Incentive Program |
| 13 | Inject Credit Streamer Incentive Program |
| 14 | Inject Credit Campaign Package |
| 15 | Deduct CPS |
| 16 | Topup ACP |
| 17 | Offset Overdue Balance |
| 18 | Inject Credit SIP |
| 19 | Inject Credit Auto Rebate |
| 20 | Inject Credit Incentive Program V2 |
| 21 | Freeze Credit |
| 22 | Unfreeze Credit |
| 23 | Revert Overdue Balance |
| 24 | Deduct Manual |
| 25 | Deduct Credit Bank Chargeback |
| 26 | Transfer Manual Source |
| 27 | Transfer Manual Dest |
| 28 | ATU by Escrow |
| 29 | （待补充） |
| 30 | （待补充） |
| 31 | （待补充） |

---

## 查询使用须知

本表为维表，直接 `SELECT` 或与事实表 JOIN 使用，无聚合场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（人工维护） | 由数据团队在线表格中维护 `order_type` 与 `order_type_name` 的枚举映射关系，通过自动化同步流程写入数仓 |

---

## ETL 逻辑摘要

### 维表说明

本表为 **Google Sheets 驱动的手工维护维表**，不经过 SQL 转换逻辑。数据团队在 Google Sheets 中直接维护 `order_type`（订单类型编码）与 `order_type_name`（业务名称）的对应关系，由平台同步任务定期将最新内容写入数仓，并记录 `ingestion_timestamp` 作为同步时间戳。

内容结构为单一平铺枚举表，当前共包含 31 个订单类型编码，覆盖扣费、充值、信用额度注入、冻结/解冻、逾期余额处理、手动转账等多类资金操作场景。

**维护责任人**：数据运营 / 广告数据团队
**更新触发**：新增业务订单类型时，由业务或数据团队在 Google Sheets 中补充对应映射记录后触发同步。如发现 `order_type_name` 为空（当前包括编码 29、30、31），应联系维护团队确认并补充。

### 注意事项

- `order_type` 字段存储为 **string 类型**，下游与交易流水事实表 JOIN 时，需确认事实表中对应字段的类型，必要时显式 CAST，避免因类型不匹配导致 JOIN 失效或全表扫描。
- 编码 **29、30、31** 当前 `order_type_name` 为空，业务含义未知，查询结果中如出现此类空值，需联系维护团队确认含义后再用于业务口径统计。
- 本表**无版本历史记录**，`ingestion_timestamp` 仅反映最近一次同步时间，历史变更不可追溯；若业务对订单类型名称有变更敏感性，需自行做快照留存。

---

*文档生成时间：2026-04-22*