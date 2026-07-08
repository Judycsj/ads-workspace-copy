---
name: ads-diagnose
description: >
  通过查询 ClickHouse 漏斗、出价和预估数据，诊断广告效果异常 (Ads performance anomaly diagnosis) — 用于排查 ads_id、campaign_id 或 shop_id 的效果问题。诊断包含 ID 诊断和异常类型诊断；归因用于已知异常类型的直接根因分析。
  TRIGGER when: user provides an ads_id, campaign_id, shop_id, or item_id and asks to diagnose,
  or mentions "广告诊断", "ads-diagnose", "效果异常", "停投", "超收", "cost 骤降", "零曝光",
  "广告排查", "为什么不投", "为什么扣费多", "广告效果", "campaign 诊断", "ads 诊断".
  DO NOT TRIGGER when: analyzing overall ads platform metrics (use ads-biz-diagnose),
  running general SQL queries (use ads-text2da), querying Kafka or CacheCloud infrastructure.
---

# 广告诊断 Skill

本 Skill 分为两类任务：**诊断**和**归因**。

- **诊断**：发现或确认异常，并输出归因 diagnose report。
  - **ID 诊断**：给定 `ads_id`、`campaign_id`、`shop_id` 或 `item_id`，先做异常判断，再对检测到的异常做归因。
  - **异常类型诊断**：给定异常类型（如 `A8 广告 cost 骤降`、`B12 店铺 CVR 转换效率低`），按异常类型定义筛选 top case，再对 top case 做归因。
- **归因**：已知异常类型和具体 case，跳过全量异常发现，直接围绕该异常类型做根因归因并输出 diagnose report。

遇到用户输入不完整时，先明确缺失信息，不能默默假设。例如只说“查 A8”但未给 region/date/层级时，需询问筛选范围；只说“归因”但未给异常类型时，需询问已知异常类型。

## 权威依赖路径

诊断知识库和 agent 已拆到公共目录，执行时优先读取以下路径，不再从本 skill 的 `references/factual_nodes.md` / `references/table_info.md` 读取节点和表信息：

| 依赖 | 路径 | 用途 |
|------|------|------|
| Overall 节点定义 | `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` | A/B 异常类型、R1-R10 一级模块、自身桶叶子、R3/R4/R5 一级宽口径与方向过滤 |
| Overall 表信息 | `docs/common/skill-knowledge/diagnose/overall/table_info.md` | 主 skill Step 0-5 基础查询、UNION / STATUS / INACTIVE / funnel 表字段 |
| Rank-model 节点定义 | `docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md` | R3 二级及以下叶子节点 |
| Rank-model 表信息 | `docs/common/skill-knowledge/diagnose/rank-model/table_info.md` | R3/model deep-dive 查询字段 |
| Bidding 节点定义 | `docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md` | R4 分层叶子节点 |
| Bidding 表信息 | `docs/common/skill-knowledge/diagnose/bidding/table_info.md` | R4/bidding deep-dive 查询字段 |
| Funnel 节点定义 | `docs/common/skill-knowledge/diagnose/funnel/factual_nodes.md` | R5 二级叶子节点 |
| Funnel 表信息 | `docs/common/skill-knowledge/diagnose/funnel/table_info.md` | R5/funnel 查询字段 |
| 路由契约 | `skills/common/ads-diagnose/references/triage_routing.md` | 主 skill 与 sub-agent 的输入输出契约、报告合并规则 |
| 模型 sub-agent | `agents/common/ads-diagnose-model-deepdive-hb.md` | R3 命中时调度 |
| 出价 sub-agent | `agents/common/ads-diagnose-bidding-deepdive-xyz.md` | R4 命中时调度 |
| 一级模块评审 agent | `agents/common/ads-diagnosis-module-reviewer.md` | GSheet / report 自动评审 |

## 任务模式判定

按用户输入选择任务模式：

| 用户输入 | 模式 | 执行方式 |
|----------|------|----------|
| 给出 ID，要求”诊断/排查/看异常” | ID 诊断 | 走 `ID 诊断流程`：Step 0-3 数据查询 → Step 4 异常检测 → Step 5 L1 模块判定 → Step 6 桶路由（自身桶主 skill 展开；R3/R4 命中先输出整体诊断报告、经用户确认后并行 dispatch sub-agent）→ Step 7 合并报告 |
| 给出异常类型，要求”诊断/top case/找 case” | 异常类型诊断 | 走 `异常类型诊断流程`：按类型定义筛选 top case → 对 top case 归因（不走桶路由） |
| 给出 ID/case + 已知异常类型，要求”归因/原因/根因” | 归因 | 走 `已知异常归因流程`：验证已知异常 → 直接归因（同样走桶路由） |
| 给出单个诊断报告 / 单行 GSheet / 多行 GSheet，要求“评审/自动评审/看一级模块是否正确” | 一级模块自动评审 | 走 `一级模块自动评审流程`：抽取 R1-R10 命中模块 → 校验证据与方向 → 输出正确性和下钻 owner |

**关键区分：**
- ID 诊断必须先做异常判断；不能预设异常类型。
- 异常类型诊断必须先按 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 的异常定义筛 top case；不能只解释异常定义。
- 已知异常归因不再遍历所有异常类型；只验证用户给定异常是否被当前数据支持，然后围绕该异常匹配 R 系列归因节点。

## 单 case / 批量 case 自动评审与自演化

单个 case 诊断报告、单行 GSheet 记录、多行批量 GSheet 记录都可以自动评审一级模块归因。批量 top case 诊断结果会沉淀到 weekly case GSheet，用于人工 review、自动评审和后续回归：

```text
https://docs.google.com/spreadsheets/d/1Cnop5beSDfF-JOZbmCk7HnWi8H1HHECNUJImyPsG7Do/edit?gid=394519611#gid=394519611
```

当前固定 tab 示例为 `skill_2026-05-02`，核心列含义如下：

| 列 | 字段 | 用途 |
|----|------|------|
| A | 异常类型 | top case 对应的主异常 |
| B | grass_region | region |
| C | campaign_id | case ID |
| F | 异常检测 | 异常命中与未命中依据 |
| G | 根因归因 | 叶子 R 节点命中依据 |
| H | 一级模块归因总结 | R1-R10 一级模块结论 |
| I | 因果链 | trigger / amplifier / direct 链路 |
| J:N | cost ratio / PCOC 等核心指标 | 自动评审辅助指标 |
| O | skill 归因是否正确 | 人工对整体诊断质量的标注 |
| P | 一级模块归因是否正确@qianqian | 人工对一级模块是否正确的标注 |

当用户要求“评审单个 case / 评审 GSheet / 批量评审 / 回归 case / 看一级模块是否正确 / 从 P 列学习优化”时，优先使用 `agents/common/ads-diagnosis-module-reviewer.md` 做自动评审。评审目标是**一级模块 R1-R10 是否归因正确**，不是重跑完整诊断。

### 一级模块自动评审流程

| 输入形态 | 处理方式 | 输出 |
|----------|----------|------|
| 单个 diagnose report | 直接从报告的异常检测、根因归因、一级模块总结、因果链中抽取证据 | 单 case JSON 评审结果 |
| 单行 GSheet case | 读取 A/B/C/F/G/H/I/J:N/O/P 列；P 列存在时作为人工标签 | 单 case JSON 评审结果 |
| 多行 GSheet case | 逐行执行单 case 评审，再汇总正确率、待下钻 owner、问题类型 | 汇总统计 + 有问题或需下钻 case 列表 |

自动评审可以在诊断后立即执行，也可以对历史 GSheet 记录离线执行。即使只有单个 case，也不要跳过自动评审；单 case 与批量 case 使用同一套判断口径。

### P 列人工标注约定

P 列标注只评价一级模块，不等价于整体诊断报告全对：

| P 列模式 | 解释 | skill 处理 |
|----------|------|------------|
| `正确` | 一级模块归因正确 | 作为正样本保留 |
| `正确, 需要@haibo继续下钻模型` | 一级模块正确，但 R3 / 模型证据需要模型同事下钻 | 不视为归因错误；输出模型下钻建议 |
| `正确, 需要@xinyu继续下钻出价` | 一级模块正确，但 R4 / 出价调控 / 控制策略需要出价同事下钻 | 不视为归因错误；输出出价下钻建议 |
| 同时包含 `@haibo` 和 `@xinyu` | 一级模块正确，模型与出价链路均需要下钻 | 输出双 owner 下钻建议 |
| 空值 | 尚未人工评审 | 不作为正确或错误样本 |

重要：如果 O 列为 `FALSE` 但 P 列为 `正确`，说明一级模块层面可以被接受，但报告细节、叶子节点、措辞、legacy unsupported content 或下钻深度仍可能需要优化。优化时不要把这类样本误当成一级模块错误样本。

### 自动评审规则

自动评审一级模块时按以下顺序判断：

1. 从 H 列或诊断报告的“一级模块归因总结”抽取命中模块集合，只接受当前 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 定义的 R1-R10。
2. 检查每个命中模块是否有方向匹配的叶子节点和数字证据支撑；仅有方向不匹配旁证的模块不能进入一级模块总结。
3. 检查摘要、根因合表、一级模块总结和因果链中的模块集合是否一致。
4. 区分“一级模块正确但需要下钻”和“一级模块错误”：需要模型/出价同事进一步分析不代表一级模块错。
5. 若出现未定义或已移除的 legacy 模块，不计入 R1-R10 正确性；在评审中单独标记为 `legacy_unsupported_module`。

### 下钻 owner 建议

在单 case、批量 GSheet 或自动评审输出中，按以下规则生成下钻建议：

- `@haibo`（模型下钻）：R3 命中或强疑似命中，包括 pCTR / pCR / pGMV PCOC 高估或低估、模型预估失败率高、模型校准漂移。
- `@xinyu`（出价下钻）：R4 命中或强疑似命中，包括 final_coef、PID / 控制速度、MPC ROI、出价调控、预算控制、调控系统并联系统失效。
- `@xinyu` 也可用于 R5 / R10，但只有在证据指向出价控制、流量分配或场景出价策略时才推荐；不要把自然的充值、预算释放、投放时长恢复一概路由给出价。
- R1 / R2 / R7 等广告主、商品、店铺事实足够解释异常且无模型/出价不确定性时，不强制推荐 owner 下钻。

## 广告实体层级关系

广告投放体系由四层实体组成，自上而下分别承担余额管理、投放策略、出价竞价和内容展示的职责：

| 层级 | 实体 | 核心职责 | 说明 |
|------|------|----------|------|
| L1 | 广告账户 (Account) | 余额管理 | 账户余额的载体，所有 Campaign 共享同一账户余额。shop_id 对应此层级 |
| L2 | 投放计划 (Campaign) | 预算与投放策略 | 设定日预算、出价方式（手动/自动）、出价目标（Target ROAS、CPC 等）和目标 ROI。campaign_id 对应此层级 |
| L3 | 广告单元 (Ads) | 竞价单元 | 一个 Campaign 下可包含多个 Ads，继承 Campaign 的出价策略参与竞价，是参与广告竞拍的最小单元。ads_id 对应此层级 |
| L4 | 投广载体 | 内容展示 | 一个 Ads 绑定的实际展示实体，不同广告类型对应不同载体 |

不同广告类型的投广载体：

| 广告类型 | 投广载体 | 推荐主体 |
|----------|----------|----------|
| Product Ads | Item（商品） | Item |
| Shop Ads | Shop（店铺） | Shop x Item |
| Video Ads | Video（短视频） | Video x Item |
| Live Ads | Livestream（直播间） | Stream room x Item |

**关键传导关系：**
- **Account → Campaign**：多个 Campaign 共享同一 Account 余额
- **Campaign → Ads**：预算、出价方式和目标 ROAS 设置在 Campaign 层，其下所有 Ads 继承相同的出价策略和预算约束
- **Ads → 投广载体**：扣费发生在载体的曝光或点击事件上。同一 Campaign 下多个 Ads 共享日预算，平台根据各 Ads 竞价表现动态分配预算消耗

## 如何查询 ClickHouse

使用 curl + Basic Auth 发送 SQL 查询。始终在 SQL 末尾追加 `FORMAT TabSeparatedWithNames` 以获取带表头的数据行。

数据分布在两个集群上，根据 region 选择对应集群：

| 集群 | 适用 Region | URL | 数据库名 |
|------|------------|-----|---------|
| SG (默认) | ID, TH, PH, VN, MY, TW, SG | `clickhouse-office-only-ytl.data-infra.shopee.io` | `mkplpaidads_search_ads_ads_debug` |
| US-VA2 | BR | `clickhouse-office-only-us-va2.data-infra.shopee.io` | `mkplpaidads_search_ads_ads_diagnosis` |

**SG 集群**（默认，适用大部分 region）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

**US-VA2 集群**（仅 BR region）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_us_2replicas_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-us-va2.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

> **注意**：BR 的数据库名为 `mkplpaidads_search_ads_ads_diagnosis`（非 `_ads_debug`），查询时需替换表名中的数据库前缀。

**`{DB}` 变量规则**：本文档中 UNION 表的 SQL 使用 `{DB}` 占位数据库名（STATUS/INACTIVE 表不受影响）。执行时按以下规则替换：
- `grass_region` ≠ `BR` → `{DB}` = `mkplpaidads_search_ads_ads_debug`，使用 SG 集群
- `grass_region` = `BR` → `{DB}` = `mkplpaidads_search_ads_ads_diagnosis`，使用 US-VA2 集群

### 数据表

仅 UNION 表需按 region 区分集群（使用 `{DB}` 占位）。STATUS 和 INACTIVE 表始终在 SG 集群，不区分 region。

| 别名 | 表名 | 集群 |
|------|------|------|
| UNION | `{DB}.ads_union_key_metrics_daily__reg_s0_live` | 按 region 选择 |
| STATUS | `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live` | 始终 SG |
| INACTIVE | `mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics` | 始终 SG |

### 单位约定

- `_usd` 后缀的字段：美元，直接使用
- `bid_price_sum`、`daily_budget`、`ecpm_sum_by_imp`、`item_price_sum_by_imp`、`padvv_sum_by_imp`、`pgmv_*_sum_by_imp`、`rt_remain_budget_*_by_imp`：美元，直接使用
- `daily_budget = 0` 表示无限制

## 异常类型诊断流程

用户给出异常类型（A/B 编号或中文名称）但未指定单个 case 时，执行本流程。目标是：**用异常定义筛出 top case，并对 top case 输出归因 diagnose report**。

### Step T0：异常类型解析

1. 从用户输入解析异常编号或名称，映射到 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md`：
   - `A1-A14`：Campaign/Ads 异常
   - `B1-B15`：Shop 异常
2. 若只给中文名称，按名称匹配异常节点；若存在多个候选，向用户确认。
3. 确认筛选范围：
   - 必需：`region`、诊断日期或日期范围
   - A 系列还需确认层级：`campaign` 或 `ads`
   - B 系列固定为 `shop`
4. 未给 `top_n` 时默认输出 Top 1；如用户指定则按用户指定。

### Step T1：按异常定义筛选 Top Case

必须按 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 中该异常节点的检测公式生成筛选 SQL。不要用主观关键词或宽泛指标替代公式。

**Campaign/Ads 级 Top Case 模板（A 系列）：**

```sql
WITH base AS (
    SELECT
        grass_date,
        campaign_id,
        ads_id,
        item_id,
        shop_id,
        grass_region,
        revenue_usd,
        advv_usd,
        broad_gmv_usd,
        ads_imp,
        ads_clk,
        ads_broad_order,
        target_roi,
        troi_sum_by_imp,
        if(ads_imp > 0, troi_sum_by_imp / ads_imp, NULL) AS target_roi_by_imp,
        idx_roi_upperbound,
        final_coef,
        daily_budget,
        account_balance_shop,
        after_recall_num,
        after_prerank_num,
        after_rank_num,
        after_mixrank_num,
        pctr_sum_by_imp,
        pcr_broad_sum_by_clk,
        daily_pgmv_sum_last_7d_clk,
        daily_model_pgmv_sum_last_7d_clk
    FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
    WHERE
        type = '{campaign_or_ads}'
        AND grass_region = '{region}'
        AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
),
scored AS (
    SELECT
        *,
        {anomaly_condition} AS is_anomaly,
        {anomaly_score_expr} AS anomaly_score
    FROM base
)
SELECT *
FROM scored
WHERE is_anomaly
ORDER BY {top_case_order_by}
LIMIT {top_n}
FORMAT TabSeparatedWithNames
```

**Shop 级 Top Case 模板（B 系列）：**

```sql
WITH daily AS (
    SELECT
        grass_date,
        shop_id,
        grass_region,
        SUM(revenue_usd) AS revenue_usd,
        SUM(advv_usd) AS advv_usd,
        SUM(broad_gmv_usd) AS broad_gmv_usd,
        SUM(direct_gmv_usd) AS direct_gmv_usd,
        SUM(ads_imp) AS ads_imp,
        SUM(ads_clk) AS ads_clk,
        SUM(ads_broad_order) AS ads_broad_order,
        SUM(ads_direct_order) AS ads_direct_order
    FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
    WHERE
        type = 'campaign'
        AND grass_region = '{region}'
        AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
    GROUP BY grass_date, shop_id, grass_region
),
scored AS (
    SELECT
        *,
        {anomaly_condition} AS is_anomaly,
        {anomaly_score_expr} AS anomaly_score
    FROM daily
)
SELECT *
FROM scored
WHERE is_anomaly
ORDER BY {top_case_order_by}
LIMIT {top_n}
FORMAT TabSeparatedWithNames
```

Top case 排序规则：
- `{top_case_order_by}` 必须按下述规则展开；超收/欠收 case 的 SELECT 结果必须包含 `absolute_delta` 和 `ratio_severity`，用于排序和报告解释。
- 超收/欠收类（A1-A4、B1-B4）：按绝对金额差和 ratio 严重度综合排序。
  - 7d 超收：`absolute_delta = revenue_usd_7d - advv_usd_7d`，`ratio_severity = cost_ratio_7d = revenue_usd_7d / advv_usd_7d`
  - 7d 欠收：`absolute_delta = advv_usd_7d - revenue_usd_7d`，`ratio_severity = 1 / cost_ratio_7d`
  - 1d 超收：`absolute_delta = revenue_usd - advv_usd`，`ratio_severity = cost_ratio_1d = revenue_usd / advv_usd`
  - 1d 欠收：`absolute_delta = advv_usd - revenue_usd`，`ratio_severity = 1 / cost_ratio_1d`
  - SQL 排序：`ORDER BY absolute_delta DESC, ratio_severity DESC, revenue_usd DESC`。若只能输出一个 `anomaly_score`，用 `absolute_delta` 作为主分数，同时在结果中保留 ratio 字段用于二级排序和解释。
- 爆量/掉量类（A8/A9、B9/B10）：按 cost 变化绝对值排序，不按环比倍数优先。
  - 掉量：`absolute_delta = revenue_usd_1 - revenue_usd_0`，`ORDER BY absolute_delta DESC, revenue_usd_0 DESC`
  - 爆量：`absolute_delta = revenue_usd_0 - revenue_usd_1`，`ORDER BY absolute_delta DESC, revenue_usd_0 DESC`
- 其他效率骤降类：按指标下降绝对值排序，再用当前 revenue 或流量规模作为 tie-breaker，例如 `ORDER BY baseline - current DESC, revenue_usd DESC`
- 低效率类：先满足最小流量阈值，再按低效率严重度和流量规模排序
- 若异常定义需要 7 天聚合或前后窗口，必须在 SQL 中构造对应窗口后再筛选

### Step T2：Top Case 归因

对 Top 3-5 case 逐个执行归因：

1. 补齐该 case 的上下文（ID、shop、campaign、region、日期范围）。
2. 按 `ID 诊断流程` 的 Step 1-3 查询明细数据，但不重新筛选其他异常作为主任务。
3. 使用 `已知异常归因流程` 对指定异常类型做根因分析。
4. 输出一个汇总 diagnose report：先列 top case，再给每个 case 的归因结论和证据链。

## 已知异常归因流程

用户已经给出异常类型和具体 case 时，执行本流程。目标是：**围绕已知异常类型直接归因，输出 diagnose report**。本流程与 `ID 诊断流程` 共享 Step 5-7（L1 模块判定 + 桶路由 + 报告合并），区别仅在前 4 步：跳过全量异常发现，只验证用户给定的异常类型。

1. 解析并确认异常类型，映射到 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 的 A/B 节点。
2. 查询该 case 的必要数据窗口：至少包含异常日、异常前基线和异常后恢复期（数据查询参考 `ID 诊断流程` 的 Step 0-3）。
3. 只验证该异常类型的检测公式是否成立：
   - 成立：进入归因，报告中写明”已验证异常”。
   - 不成立：报告中写明”当前数据未验证该异常”，但仍可基于用户给定前提输出低置信归因。
4. 不做全量异常扫描；若发现其他异常，只作为”伴随现象/辅助证据”写入，不替代用户给定异常类型。
5. **L1 模块判定 + 桶路由 + 报告合并**：按 `ID 诊断流程` 的 Step 5-7 执行 — 主 skill 对 R1-R10 给出模块级 verdict，自身桶（R1/R2/R5/R6/R7/R8/R9/R10）命中模块由主 skill 展开叶子；R3 命中 dispatch `ads-diagnose-model-deepdive-hb` agent，R4 命中 dispatch `ads-diagnose-bidding-deepdive-xyz` agent（dispatch 前按 Step 6「Deep Dive 用户确认闸门」先输出主 skill 整体诊断报告并经用户确认；多桶并行）；主 skill 按 `references/triage_routing.md` 第 6 节合并最终报告并做一致性校验。

## ID 诊断流程

用户提供一个 ID 后，按以下步骤依次执行。用户可以输入以下任一类型：`ads_id`、`campaign_id`、`shop_id` 或 `item_id`（可选附带 `region`）。也可以选择性提供日期：

- **提供了日期**：查询范围 = `[date - 3 天, date + 3 天]`（以给定日期为中心的 7 天）。给定日期标记为 `_0`（诊断日）。
- **未提供日期**：查询范围 = 从今天起往前 7 天。

### 快速数据采集 collect.py（优先）/ Fast Data Collection

Step 0-3 的 ID 识别与三查询是**确定性**的，已固化为脚本，**优先调用**，避免逐条拼 SQL（也彻底规避 Step 1 的 nested-aggregate 陷阱）：

```bash
uv run skills/common/ads-diagnose/scripts/collect.py <id> [--date YYYY-MM-DD] [--region MY]
```

一次调用返回结构化 JSON，覆盖 Step 0-3：
- `resolved`：ID 识别（`id_kind` / `campaign_id` / `shop_id` / `region` / `cluster`）；`id_kind=ambiguous` 时才需人工确认
- `daily`：campaign 按天聚合概览 + 确定性派生比率（`cost_ratio_1d`、`avg_coef`、`cvr`、`ctr`、`target_roi_by_imp`、`pgmv_calib_ratio`、`pgmv_gmv_ratio`）
- `rolling_7d_ending_d0`：`cost_7d` / `advv_7d` / `cost_ratio_7d`
- `daily_markdown`：**已渲染好的逐日 markdown 表**（表A 效果&出价 + 表B PCOC&漏斗，诊断日加粗）——报告的「PCOC & 漏斗汇总」章节**直接粘贴此字段**，不要逐格重打（省 token + 不会抄错数字）
- `module_signals`：每个 R 模块预算好的**关键数值信号**（d0/d1/7d 值 + 比率，如 R1 troi/budget 环比与 status change 行、R3 pgmv 比率、R4 coef、R6 mixrank/ecpm、R10 各场景 cost_ratio）——L1 合表的「关键数值」列**直接用这些预算值**，不必再从 daily 逐日翻找计算。**脚本只给数字、不给判定**：四态 verdict（命中/未命中/证据不足/不适用）与方向过滤仍由你按 factual_nodes 权威定义做
- `anomaly_contribution`：7d 超收/欠收的**逐日金额贡献分解 + 病灶日定位**（口径同 R4 xyz：方向过滤 + gap 最大）。含 `direction` / `top_contrib_day`（病灶日）/ `top_contrib_pct` / `d0_contrib_pct` / `relocate_focus` / `focus_date`
- `focus_signals`：**仅 `relocate_focus=true` 时存在**——以**病灶日**为锚（D* vs D*−1）重算的 module_signals；此时 L1 归因改用它（见下「7d 异常病灶日重定位」）
- `ad_by_entrance`：ad 级按 entrance 明细（含 `mixrank_rate`）
- `unactive_reasons` / `status_ops`：停投与 STATUS 操作日志
- 输入为 `shop_id` 时返回 `top_campaigns`，选定后对单个 `campaign_id` 重跑

拿到 JSON 后**直接进入 Step 4 异常检测与 Step 5 归因**，不必再手工跑下方 Step 0-3 SQL。脚本**只做确定性采集，不做异常判定/归因**。仅当脚本报错、`id_kind=ambiguous`、或需要脚本未覆盖的额外维度时，才回退到下方手工 SQL 模板（它们同时是脚本的字段口径来源）。

#### 7d 异常病灶日重定位 / Lesion-Day Refocus

> 7d 超收/欠收是滚动窗口聚合，异常可能由窗口内某一天主导，而用户随手指定的日期未必是那天。死盯 `_0` 会**锚错日期、误判根因力度**（真实案例：129185318 的 7d 欠收 81% 来自 06-25 的模型 pCR/pGMV 崩塌，锚 _0 时 R3 pgmv 看着正常 0.79、锚病灶日才暴露 0.05）。

当 `anomaly_contribution.relocate_focus=true`（`_0` 对 7d 异常贡献 <25% 且存在某天 >40% 且 ≠ `_0`）：
- **归因焦点转到 `focus_date`（病灶日）**：L1 合表「关键数值」列改用 `focus_signals`（锚病灶日）；报告开头加 1 句「7d {方向} X% 来自 {focus_date}，用户输入 {\_0} 仅 Y% → 焦点重定位到 {focus_date}」。
- **dispatch sub-agent 传 `focus_date`**：R3→`ads-diagnose-model-deepdive-hb` 传 `date=focus_date`；R4→`ads-diagnose-bidding-deepdive-xyz` 传 `local_date=focus_date`（或传 `date_range`，xyz 按同口径 gap 最大会自动选出同一天）。**契约与 sub-agent 无需改**，只换 dispatch 传入的日期锚点。
- **窗口固定不递归**：7d 窗口始终锚用户 `_0` 的 `[_0-6, _0]`，病灶日只定位一次，归因用 D* 单日环比；**禁止以病灶日重新开 7d 窗口**。
- `relocate_focus=false`（分布均匀 / 病灶日=_0，如 328823131 超收摊在 4 天、169042373 advv≈0 长期结构性）→ 按 `_0` 正常归因，用 `module_signals`。

### Step 0：ID 识别

通过一条统一查询确定 ID 类型并解析完整上下文。**此时尚不知道 region，需先查 SG 集群，若无结果再查 US-VA2 集群（BR）**：

```sql
SELECT DISTINCT
    type, ads_id, item_id, campaign_id, shop_id, grass_region
FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
WHERE (campaign_id = {ID} OR ads_id = {ID} OR item_id = {ID} OR shop_id = {ID})
    AND grass_date >= today() - 7
ORDER BY grass_date DESC
LIMIT 5
```

**执行顺序**：先用 SG 集群（`{DB}` = `mkplpaidads_search_ads_ads_debug`）执行。若无结果，再用 US-VA2 集群（`{DB}` = `mkplpaidads_search_ads_ads_diagnosis`）重试。

**结果处理：**

1. **两个集群均无结果** → 提示用户该 ID 在最近 7 天内未找到，请验证 ID 是否正确。
2. **所有行的 `type` 相同** → 自动识别 ID 类型：
   - 若 `type = 'campaign'` 且所有行的 `campaign_id` = {ID} → 输入为 `campaign_id`
   - 若 `type = 'campaign'` 且所有行的 `shop_id` = {ID}（但 `campaign_id` ≠ {ID}）→ 输入为 `shop_id`
   - 若 `type = 'ads'` 且所有行的 `ads_id` = {ID} → 输入为 `ads_id`
   - 若 `type = 'ads'` 且所有行的 `item_id` = {ID} → 输入为 `item_id`
3. **行中存在多种 `type`** → 向用户展示匹配到的类型，请用户确认输入的是哪种 ID（如："该 ID 同时匹配到 campaign 和 ads 记录，请确认您输入的是哪种 ID？"）。

识别完成后，**向用户展示解析结果**再继续下一步：

```
解析结果：
  campaign_id: 67890
  shop_id:     11111
  region:      ID
```

### Step 0.5：Shop 级别 Top Campaign 识别（仅 shop_id 输入时）

当输入为 `shop_id` 时，**必须**先识别 Top Campaign，再逐个深入分析。**不要**将所有 campaign 聚合为 shop 级汇总 —— 这会掩盖关键的单 campaign 信号（如真实 target ROI / TROI 变更和 final_coef 趋势）。

```sql
SELECT
    campaign_id,
    SUM(revenue_usd) AS total_rev,
    SUM(advv_usd) AS total_advv,
    SUM(ads_broad_order) AS total_order,
    -- 检测真实 target ROI / TROI 跨天变化
    groupArray((grass_date, if(ads_imp > 0, troi_sum_by_imp / ads_imp, NULL))) AS target_roi_history,
    -- 保留配置 ROI 下限，避免与真实 TROI 混淆
    groupArray((grass_date, target_roi)) AS roi_lower_bound_history,
    -- 检测 final_coef 趋势崩溃
    groupArray((grass_date, final_coef)) AS coef_history,
    -- 预算挤压检测
    groupArray((grass_date, daily_budget)) AS budget_history,
    groupArray((grass_date, account_balance_shop)) AS balance_history
FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
WHERE
    type = 'campaign'
    AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
    AND shop_id = {shop_id}
    AND grass_region = '{region}'
GROUP BY campaign_id
ORDER BY total_rev DESC
LIMIT 10
FORMAT TabSeparatedWithNames
```

识别 Top Campaign 后：

1. **扫描每个 Top Campaign 的 target_roi_history 和 coef_history** —— 寻找真实 target ROI / TROI 变更、coef 崩溃和预算挤压
2. **选取收入 Top 3-5 的 campaign** 进行完整的 Step 1-3 深入分析
3. **同时产出 shop 级别的每日汇总**（聚合数据）用于整体趋势参考，但**务必**与单 campaign 数据交叉验证后再下结论

**shop_id 场景的关键规则：** 在排除单 campaign 原因（coef 崩溃、ROI 变更、预算挤压）之前，绝不要得出"shop 级别问题"（如平台处罚、店铺封禁）的结论。Shop 级别结论是最后手段，不是第一猜测。

### Step 1：Campaign 级别概览

查询已解析 campaign 的 campaign 级别数据。

> **UNION 表按 entrance 分行**：campaign 级别每个 `grass_date` 按 `entrance`（SEARCH/VIDEO/YMAL/DD/PP/GAME/IN_SHOP/SHOP/other）拆成多行，**必须按 `grass_date` 聚合成每天一行**再做异常检测与趋势判断，否则 7d cost_ratio、真实 TROI、coef 趋势会被 entrance 打散算错。entrance 明细留给 R10 场景分析和 Step 2 ad 级下钻。
> **ClickHouse 聚合陷阱（务必按下方写法）**：聚合列别名**不要与被聚合的原始列同名**（如 `SUM(ads_imp) AS ads_imp`），否则同层比率里的 `SUM(ads_imp)` 会被解析成该别名 → 报 `Aggregate function ... is found inside another aggregate function (nested aggregate)`。统一给聚合列加 `s_`（SUM）/ `m_`（max）前缀，**外层再算比率**（avg_coef / target_roi_by_imp）并映射回标准列名。下方 SQL 已按此写法验证可跑，直接套用。

日期范围：
- 用户提供了日期范围 `[D1, D2]`：`start_date = D1 - 3`，`end_date = D2 + 5`（包含下降前基线和恢复期）
- 用户提供了单个日期 `D`：`start_date = D - 7`，`end_date = D + 5`
- 未提供日期：`start_date = today() - 7`，`end_date = today()`

给定日期（或今天）映射为 `_0`。之前的天数为 `_1`、`_2`、`_3`。之后的天数作为未来上下文（如有数据）。

**重要：** 始终查询异常结束日之后的数据，以捕获恢复数据。恢复模式对验证根因假设至关重要 —— 例如，如果充值后订单恢复，说明原因是资金问题；如果 coef 重置后订单恢复，说明原因是出价问题。

```sql
-- 外层：把子查询的 s_/m_ 聚合列映射回标准列名，并计算按曝光加权的比率（避免 nested aggregate）
SELECT
    grass_date,
    -- 效果指标 (USD)
    s_revenue_usd AS revenue_usd,
    s_advv_usd AS advv_usd,
    s_direct_gmv_usd AS direct_gmv_usd,
    s_broad_gmv_usd AS broad_gmv_usd,
    s_ads_imp AS ads_imp,
    s_ads_clk AS ads_clk,
    s_ads_direct_order AS ads_direct_order,
    s_ads_broad_order AS ads_broad_order,
    -- 7 天滚动指标
    s_revenue_usd_7d AS revenue_usd_7d,
    s_advv_usd_7d AS advv_usd_7d,
    s_broad_gmv_usd_7d AS broad_gmv_usd_7d,
    s_ads_broad_order_7d AS ads_broad_order_7d,
    -- 漏斗
    s_request_cnt AS request_cnt,
    s_after_recall_num AS after_recall_num,
    s_after_prerank_num AS after_prerank_num,
    s_after_rank_num AS after_rank_num,
    s_after_mixrank_num AS after_mixrank_num,
    -- 广告配置（取当天各 entrance 行的 max）
    m_pricing_type AS pricing_type,
    m_target_roi AS target_roi,
    m_idx_roi_upperbound AS idx_roi_upperbound,
    m_active_hour AS active_hour,
    -- 出价 & 系数
    s_bid_price_sum AS bid_price_sum,
    s_ecpm_sum_by_imp AS ecpm_sum_by_imp,
    s_coef_sum_by_imp AS coef_sum_by_imp,
    if(s_ads_imp > 0, s_coef_sum_by_imp / s_ads_imp, NULL) AS avg_coef,
    m_final_coef AS final_coef,
    s_troi_sum_by_imp AS troi_sum_by_imp,
    if(s_ads_imp > 0, s_troi_sum_by_imp / s_ads_imp, NULL) AS target_roi_by_imp,
    -- 预算
    m_daily_budget AS daily_budget,
    m_rt_daily_budget_min_by_imp_v2 AS rt_daily_budget_min_by_imp_v2,
    m_rt_remain_budget_sum_by_imp AS rt_remain_budget_sum_by_imp,
    m_account_balance_shop AS account_balance_shop,
    -- 预估
    s_pctr_sum_by_imp AS pctr_sum_by_imp,
    s_pcr_broad_sum_by_clk AS pcr_broad_sum_by_clk,
    s_item_price_sum_by_imp AS item_price_sum_by_imp,
    s_pcr_direct_fail_imp_cnt AS pcr_direct_fail_imp_cnt,
    -- pGMV PCOC 字段（7 天滚动，按 click 维度）
    s_daily_pgmv_sum_last_7d_clk AS daily_pgmv_sum_last_7d_clk,
    s_daily_model_pgmv_sum_last_7d_clk AS daily_model_pgmv_sum_last_7d_clk,
    -- MPC & Ultra Core
    s_mpc_e_gmv AS mpc_e_gmv,
    s_mpc_e_cost AS mpc_e_cost,
    s_ultra_core_rev AS ultra_core_rev,
    s_ultra_core_advv AS ultra_core_advv
FROM (
    -- 内层：按 grass_date 聚合掉 entrance，聚合列一律加 s_/m_ 前缀，绝不与原始列同名
    SELECT
        grass_date,
        SUM(revenue_usd) AS s_revenue_usd,
        SUM(advv_usd) AS s_advv_usd,
        SUM(direct_gmv_usd) AS s_direct_gmv_usd,
        SUM(broad_gmv_usd) AS s_broad_gmv_usd,
        SUM(ads_imp) AS s_ads_imp,
        SUM(ads_clk) AS s_ads_clk,
        SUM(ads_direct_order) AS s_ads_direct_order,
        SUM(ads_broad_order) AS s_ads_broad_order,
        SUM(revenue_usd_7d) AS s_revenue_usd_7d,
        SUM(advv_usd_7d) AS s_advv_usd_7d,
        SUM(broad_gmv_usd_7d) AS s_broad_gmv_usd_7d,
        SUM(ads_broad_order_7d) AS s_ads_broad_order_7d,
        SUM(request_cnt) AS s_request_cnt,
        SUM(after_recall_num) AS s_after_recall_num,
        SUM(after_prerank_num) AS s_after_prerank_num,
        SUM(after_rank_num) AS s_after_rank_num,
        SUM(after_mixrank_num) AS s_after_mixrank_num,
        max(pricing_type) AS m_pricing_type,
        max(target_roi) AS m_target_roi,
        max(idx_roi_upperbound) AS m_idx_roi_upperbound,
        max(active_hour) AS m_active_hour,
        SUM(bid_price_sum) AS s_bid_price_sum,
        SUM(ecpm_sum_by_imp) AS s_ecpm_sum_by_imp,
        SUM(coef_sum_by_imp) AS s_coef_sum_by_imp,
        max(final_coef) AS m_final_coef,
        SUM(troi_sum_by_imp) AS s_troi_sum_by_imp,
        max(daily_budget) AS m_daily_budget,
        max(rt_daily_budget_min_by_imp_v2) AS m_rt_daily_budget_min_by_imp_v2,
        max(rt_remain_budget_sum_by_imp) AS m_rt_remain_budget_sum_by_imp,
        max(account_balance_shop) AS m_account_balance_shop,
        SUM(pctr_sum_by_imp) AS s_pctr_sum_by_imp,
        SUM(pcr_broad_sum_by_clk) AS s_pcr_broad_sum_by_clk,
        SUM(item_price_sum_by_imp) AS s_item_price_sum_by_imp,
        SUM(pcr_direct_fail_imp_cnt) AS s_pcr_direct_fail_imp_cnt,
        SUM(daily_pgmv_sum_last_7d_clk) AS s_daily_pgmv_sum_last_7d_clk,
        SUM(daily_model_pgmv_sum_last_7d_clk) AS s_daily_model_pgmv_sum_last_7d_clk,
        SUM(mpc_e_gmv) AS s_mpc_e_gmv,
        SUM(mpc_e_cost) AS s_mpc_e_cost,
        SUM(ultra_core_rev) AS s_ultra_core_rev,
        SUM(ultra_core_advv) AS s_ultra_core_advv
    FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
    WHERE
        type = 'campaign'
        AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
        AND shop_id = {shop_id}
        AND grass_region = '{region}'
        AND campaign_id = {campaign_id}
    GROUP BY grass_date
) t
ORDER BY grass_date DESC
LIMIT 100
```

### Step 2：Ad 级别漏斗下钻

对 campaign 下的广告进行 ad 级别数据下钻：

> **注意**：ad 级别同样按 `entrance` 每天多行。本查询保留 `entrance` 明细用于场景/漏斗下钻；若要看单个 ad 的每日汇总，需按 `(grass_date, ads_id)` 聚合（聚合写法与 Step 1 相同：别名加 `s_`/`m_` 前缀、比率放外层）。

```sql
SELECT
    grass_date,
    ads_id,
    campaign_id,
    item_id,
    entrance,
    -- 效果指标 (USD)
    revenue_usd,
    advv_usd,
    direct_gmv_usd,
    broad_gmv_usd,
    ads_imp,
    ads_clk,
    ads_direct_order,
    ads_broad_order,
    -- 7 天滚动指标
    revenue_usd_7d,
    advv_usd_7d,
    broad_gmv_usd_7d,
    ads_broad_order_7d,
    -- 漏斗
    request_cnt,
    after_recall_num,
    ads_after_recall_num,
    after_prerank_num,
    after_rank_num,
    after_mixrank_num,
    -- 广告配置
    pricing_type,
    target_roi,
    idx_roi_upperbound,
    active_hour,
    -- 出价 & 系数
    bid_price_sum,
    ecpm_sum_by_imp,
    coef_sum_by_imp,
    final_coef,
    troi_sum_by_imp,
    if(ads_imp > 0, troi_sum_by_imp / ads_imp, NULL) AS target_roi_by_imp,
    -- 预算
    daily_budget,
    rt_daily_budget_min_by_imp_v2,
    rt_remain_budget_sum_by_imp,
    account_balance_shop,
    -- 预估
    pctr_sum_by_imp,
    pcr_broad_sum_by_clk,
    item_price_sum_by_imp,
    pcr_direct_fail_imp_cnt,
    -- pGMV PCOC 字段
    daily_pgmv_sum_last_7d_clk,
    daily_model_pgmv_sum_last_7d_clk,
    -- MPC & Ultra Core
    mpc_e_gmv,
    mpc_e_cost,
    ultra_core_rev,
    ultra_core_advv,
    -- 分层
    under_bidding_tier_1d,
    under_bidding_tier_7d,
    budget_tier,
    pcoc_tier
FROM {DB}.ads_union_key_metrics_daily__reg_s0_live
WHERE
    type = 'ads'
    AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
    AND shop_id = {shop_id}
    AND grass_region = '{region}'
    AND campaign_id = {campaign_id}
ORDER BY grass_date DESC, revenue_usd DESC
LIMIT 200
```

### Step 3：广告状态 & 停投原因

对曝光为零、效果突然下降、或 R1.1/R1.2 可能由广告主操作触发的广告，检查状态变更、配置操作和停投原因。STATUS 表不仅用于停投，也用于补足 UNION 日聚合中缺失或滞后的 TROI / budget 变更。

**状态变更：**

```sql
SELECT
    grass_date,
    id AS ads_id,
    type,
    visible,
    reason,
    operation,
    status,
    hour
FROM mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live
WHERE
    id = {ads_id}
    AND grass_date >= '{start_date}' AND grass_date <= '{end_date}'
    AND grass_region = '{region}'
ORDER BY grass_date DESC, hour DESC
LIMIT 50
```

**Campaign 多 ads 操作日志扫描（用于 R1.1/R1.2 兜底）：**

```sql
SELECT
    grass_date,
    hour,
    id AS ads_id,
    type,
    visible,
    status,
    operation,
    reason
FROM mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live
WHERE
    grass_region = '{region}'
    AND grass_date >= '{start_date}' AND grass_date <= '{end_date}'
    AND id IN ({top_ads_ids})
    AND (
        reason LIKE '%change_budget%'
        OR reason LIKE '%change roi%'
        OR reason LIKE '%target roi%'
        OR reason LIKE '%change_target%'
        OR operation != 'INDEX'
        OR status != 0
    )
ORDER BY grass_date DESC, hour DESC, ads_id
LIMIT 200
```

R1 操作日志归因规则：
- `daily_budget` / `target_roi_by_imp` / `idx_roi_upperbound` 可用且方向明确时，优先用 UNION 日聚合证据。
- UNION 字段缺失、为 0、无限制值、或未反映同日广告主操作时，必须使用 STATUS `reason` 作为 R1.1/R1.2 兜底证据；报告中标注 `STATUS operation fallback`。
- 方向过滤必须和主异常一致：超收/爆量只接受 budget 增加或 TROI 降低；欠收/掉量只接受 budget 降低或 TROI 提高。
- `reason` 可解析数值时，按 `old -> new` 或数值出现顺序比较相邻值；达到 `>1.3` / `<0.7`（TROI）或 `>1.5` / `<0.5`（budget）才写命中。只能判断方向但不能解析比例时，写 `证据不足`。

**停投原因：**

```sql
SELECT
    grass_date,
    ads_id,
    item_id,
    shop_id,
    placement,
    operation,
    reason
FROM mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics
WHERE
    shop_id = {shop_id}
    AND grass_region = '{region}'
    AND grass_date BETWEEN DATE('{start_date}') AND DATE('{end_date}')
    AND ads_id = {ads_id}
ORDER BY grass_date DESC
LIMIT 100
```

### Step 4：异常类型检测/Anomaly Type Detection

对 Step 1-3 查到的数据，按 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 中 A1-A14（campaign/ads 级）和 B1-B15（shop 级）的检测公式逐一计算，输出命中异常类型列表。多种异常可同时存在。

### Step 5：L1 模块判定/L1 Module Verdict

对 R1-R10 每个一级归因模块输出四态判定（命中 / 未命中 / 证据不足 / 不适用）+ 模块级数字依据，**只到模块级，不展开叶子**（自身桶叶子在 Step 6a 展开；R3/R4 叶子由对应 sub-agent 在 Step 6b/6c 展开）。判定标准详见 `references/triage_routing.md` 第 2 节。

关键补充：
- R1 必须同时看 UNION 日聚合字段和 STATUS 操作日志；不要因为 `daily_budget=0` 或 TROI 日均值没变就忽略同日 `change_budget` / `change roi` 操作。
- R3/R4 方向过滤覆盖超收/爆量（A1/A3/A9/B1/B3/B10）和欠收/掉量（A2/A4/A7/A8/B2/B4/B8/B9）。
- R4 除绝对阈值外，还要判断欠收/掉量场景下的相对退化：`avg_coef_0/avg_coef_1 < 0.7` 或 `final_coef_0/final_coef_1 < 0.8`，避免绝对 coef 尚高但环比明显收缩的 case 被漏掉。
- R6 对 A7/A8/B8/B9 掉量场景要检查联合退化信号：GMV/revenue 掉量 + avg_coef 相对下降 + mixrank_rate 同步下降。

### Step 6：桶路由/Bucket Routing

按 `references/triage_routing.md` 第 1 节的三桶模型路由：

#### Deep Dive 用户确认闸门（R3/R4 dispatch 前强制）/ Deep Dive User Confirmation Gate

> R3 或 R4 verdict 为**命中**、需要 dispatch deep-dive sub-agent 时，本闸门强制生效：先完成自身桶展开并输出主 skill 整体诊断报告，经用户**显式确认**后才允许调用 `Agent` 工具。

1. **先输出主 skill 整体诊断报告**：dispatch 前先完成 Step 6a 自身桶叶子展开，再按「输出格式」输出一份完整的整体诊断报告（异常检测、模块/节点判定合表 + 证据明细、命中根因与因果链、PCOC & 漏斗汇总、7 天聚合、一级模块归因总结等主 skill 可独立产出的全部章节），让用户先看到完整诊断信息和问题大致来自哪里：
   - R3/R4 命中桶在合表中仅保留 L1 模块级行，判定标注 `命中（待确认 deep dive）`，不展开叶子、不下叶子根因结论
   - 报告末尾给出问题来源初步判断：1-3 句说明当前证据指向哪些桶（自身桶 / 出价桶 R4 / 模型桶 R3）及理由
2. **再请求用户显式确认**：列出待 dispatch 的 sub-agent（R3 → `ads-diagnose-model-deepdive-hb`，R4 → `ads-diagnose-bidding-deepdive-xyz`）并询问是否执行 deep dive。R3、R4 同时命中时一次性确认，用户可选择全部执行、只执行其一或全部跳过。
3. **按确认结果执行**：
   - 用户确认的桶 → 按 Step 6b/6c dispatch（确认了多个桶时仍必须并行 dispatch）；deep dive 返回后按 Step 7 合并，只输出**增量更新**（R3/R4 的合表行与证据明细、二级归因总结、因果链/修复优先级如有变化），整体报告中未变化的章节不必重复输出
   - 用户拒绝/跳过的桶 → 标记为 `skipped by user / 用户跳过`，报告中该桶保持 L1 模块级 verdict，不展开叶子、不下叶子根因结论
4. **禁止绕过**：不得因“用户已调用 skill / 已授权诊断”视为已授权 deep dive；不得先 dispatch 再补问确认。

- **Step 6a — 自身桶**：R1/R2/R5/R6/R7/R8/R9/R10 中**命中**的模块，主 skill 直接展开所有叶子节点，按 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 中的检测公式输出叶子判定（命中 / 未命中 / 证据不足 / 不适用）+ 数字依据。方向过滤、四态压缩规则同既有「归因模块与节点判定表」章节。
- **Step 6b — 出价桶**：如果 R4 verdict 为**命中**且已过「Deep Dive 用户确认闸门」，调用 `Agent` 工具，`subagent_type: ads-diagnose-bidding-deepdive-xyz`。主 skill 只负责按 `triage_routing.md` 第 3 节传入必要上下文（mode / target / main_anomaly / l1_verdict_for_this_bucket / key_metrics_table / ad_level_table / other_buckets_l1_summary / leaves_to_evaluate）；R4 deep dive 的具体执行流程只以 `agents/common/ads-diagnose-bidding-deepdive-xyz.md` 为准。
  - `leaves_to_evaluate` 必须运行时从 `docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md` 提取所有当前 `^### R4.` 节点编号，不允许手写固定范围或固定清单。
  - 主 skill / prompt 不得复写或替代 `xyz` 的 Step 1-7；不得把 R4 deep dive 降级为只评估 `R4.1-R4.10` 日级节点。
  - prompt 可以禁止修改源码、skills、agents、README，但必须允许 `xyz` 按自身规范写诊断 artifact 到 `outputs/ads-diagnose-bidding-deepdive-xyz/...`。
- **Step 6c — 模型桶**：如果 R3 verdict 为**命中**且已过「Deep Dive 用户确认闸门」，调用 `Agent` 工具，`subagent_type: ads-diagnose-model-deepdive-hb`，prompt 契约同上。`leaves_to_evaluate` 必须运行时从 `docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md` 提取所有当前 R3 叶子节点编号；如果使用 HB agent 额外输出到达/归因链路子节点，也必须以 agent 当前 Node 定义和 SQL 结果为准补齐，不允许手写固定范围或固定清单。

R3 和 R4 同时命中且均经用户确认时，6b 和 6c 必须**并行 dispatch**（在同一条 message 里放两个 Agent 工具调用）。其它桶都未命中（健康 case）→ 跳过 6a/6b/6c，直接进 Step 7。

#### Codex 执行兼容 / Codex Sub-Agent Compatibility

本段只约束 Codex 执行 `ads-diagnose` 时的 sub-agent 调度；Claude Code 仍按上文 `Agent` / `subagent_type` 执行。

- 用户调用 `$ads-diagnose` / `ads-diagnose` 只授权 Step 0-5 与自身桶展开；R3/R4 worker dispatch 前，Codex 同样必须过「Deep Dive 用户确认闸门」——先输出主 skill 整体诊断报告（R3/R4 命中桶仅 L1 行并标注待确认，末尾附问题来源初步判断），再询问用户是否执行 deep dive，确认后才 spawn worker。
- 如果 Codex 没有 Claude Code 命名 `Agent` 工具，但有 worker/sub-agent 能力，默认 spawn worker，并把对应 `agents/common/*.md` 作为唯一执行规范注入 prompt。
- worker prompt 必须按 `triage_routing.md` 第 3 节传入上下文，并要求输出符合第 4 节 `### deep_dive_module: ...` schema。
- R4 worker prompt 必须声明：`ads-diagnose-bidding-deepdive-xyz.md` 是唯一执行流程；主 prompt 只传上下文，不复写 xyz Step 1-7；不得降级为只评估 `R4.1-R4.10`。
- R4 worker 必须允许写 `outputs/ads-diagnose-bidding-deepdive-xyz/...` 诊断产物，同时禁止修改源码、skills、agents、README；不要写“只读分析、不写文件”。
- worker 不可用、返回明确失败、`blocked` 或 `script_failed` 时才允许本地 fallback；fallback 必须读取对应 agent markdown 和 factual nodes，按同 schema 输出，并标注 `Codex local fallback: <reason>`。worker 仍在运行或只是耗时较长时，不得启动本地 fallback；应继续等待，或在用户要求先出报告时将该桶标记为 `pending / 进行中`，且不输出该桶叶子根因结论。

#### Worker 完成闸门（async 调度强约束 / Worker Completion Gate）

> 解决「worker 耗时过长、主流程没等到返回就直接出报告」的核心闸门。**只要 dispatch 了 worker，本闸门强制生效。**

1. **轮询直到终态，不靠单次读取**：spawn worker 后，必须主动**轮询/等待 worker 结果**（用 worker 平台的查询/等待能力反复 check），直到 worker 进入下列**终态**之一才允许推进：① 返回符合第 4 节 schema 的 `### deep_dive_module: Rx` 成功块；② 显式 `failed` / `blocked` / `script_failed`；③ 用户在等待期间明确要求先出报告。
2. **「仍在运行 / 超时 / 无结果 / 读到空」不是终态**：禁止据此判定 worker 失败、禁止启动本地 fallback、禁止用主 prompt 自己的推理替 worker 写该桶叶子结论。正确动作是**继续等待并再次 check**。
3. **未拿到成功块前，禁止输出该桶任何叶子根因**：进入 Step 7 前，每个已 dispatch 的桶必须二选一——要么已收到成功块，要么标记为 `pending / 进行中`（仅输出 L1 模块级 verdict，不展开叶子、不下根因结论）。
4. **R3+R4 双 worker**：必须等到**两个**桶都到达终态（或被显式标 pending）后再合并；不允许只回来一个就出完整报告。

### Step 7：报告合并与一致性校验/Report Merge & Consistency Check

**进入合并前先过完成闸门（Completion Gate）——逐桶核对，任一不满足都不得产出最终报告：**

- [ ] 每个已 dispatch 的桶（R3/R4），是否真的收到了对应的 `### deep_dive_module: Rx` 返回块？
- [ ] 未收到的桶，是否已按 Step 6「Worker 完成闸门」继续等待，或经用户同意标为 `pending / 进行中`？
- [ ] 用户在「Deep Dive 用户确认闸门」跳过的桶，是否已标记 `skipped by user / 用户跳过`，且只保留 L1 模块级 verdict、没有展开叶子？
- [ ] 报告中是否**没有**任何由主 skill 自己推理顶替的 R3/R4 叶子根因（即没有把幻觉当 deep dive 输出）？



按 `references/triage_routing.md` 第 6 节的 schema 把三方输出拼装为最终 diagnose report。合并完成后做第 7 节的一致性校验：

1. 修复优先级 P0 ⇄ 摘要主根因（同一节点必须在两处一致）
2. 同模块多 direct 节点的并联识别
3. 因果链 ↔ P0 节点一致
4. R4 合表完整性：`ads-diagnose-bidding-deepdive-xyz` 返回的命中 `selection_evidence` 节点（例如 R4.20-R4.27，包括 R4.22 / R4.24）必须进入最终“模块/节点判定合表”和“二级归因总结”；它们可以不是 P0/P1 修复项，但不能被压缩进 R4.30.x 的证据描述后省略

如 sub-agent 返回明确失败、`blocked`、`script_failed` 或输出不符 schema，按 `triage_routing.md` 第 8 节错误处理规则降级输出；sub-agent 只是耗时较长不视为失败。

## 字段说明

### 命名约定

数据使用天偏移量约定进行分析：
- `_0` = 诊断日（最近日期），`_1` = 前一天，... `_7` = 7 天前
- 按 ClickHouse 行的 `grass_date` 降序映射：第一行 = `_0`，第二行 = `_1`，以此类推。

### 效果字段 (USD)

| 字段 | 含义 |
|------|------|
| `revenue_usd` / `revenue_usd_7d` | 花费（1 天 / 7 天滚动）—— 诊断中称为 `cost` |
| `advv_usd` / `advv_usd_7d` | 目标 GMV（1 天 / 7 天滚动）—— 诊断中称为 `advv` |
| `broad_gmv_usd` / `broad_gmv_usd_7d` | 实际宽口径 GMV（1 天 / 7 天滚动） |
| `ads_direct_order` / `ads_broad_order` | 直接 / 宽口径订单数 |

### 漏斗字段

| 字段 | 含义 |
|------|------|
| `request_cnt` | 进入漏斗的广告请求数 |
| `after_recall_num` | 通过召回 |
| `after_prerank_num` | 通过粗排 |
| `after_rank_num` | 通过精排 |
| `after_mixrank_num` | 通过混排（最终阶段） |
| `ads_imp` | 曝光数 |
| `ads_clk` | 点击数 |

### 广告配置字段

| 字段 | 含义 |
|------|------|
| `pricing_type` | `11` = TargetROAS，`15` = Simple2.0 |
| `target_roi` | ROI 下限/配置值（即 `idx_target_roi`；pricing_type=15 Simple 时作为下限，不代表真实 TROI） |
| `target_roi_by_imp` | 真实 target ROI / TROI 日均值，按曝光加权计算：`troi_sum_by_imp / ads_imp`；R1 TROI 变更和绝对值判断使用该字段 |
| `idx_roi_upperbound` | ROI 上限（pricing_type=15 时使用） |
| `active_hour` | 当天活跃投放小时数 |


### 出价 & 系数字段

| 字段 | 含义 |
|------|------|
| `coef_sum_by_imp` | 出价系数之和（/ 曝光数 = 平均 coef） |
| `final_coef` | 最终出价系数（每日均值） |
| `bid_price_sum` | 出价总和（USD） |
| `ecpm_sum_by_imp` | eCPM 总和（USD） |
| `troi_sum_by_imp` | 真实 target ROI / TROI 按曝光求和；必须除以 `ads_imp` 后得到 `target_roi_by_imp`，不要直接当 ROI 使用 |

### 预算字段

| 字段 | 含义 |
|------|------|
| `daily_budget` | 每日预算（USD；0 = 无限制） |
| `rt_daily_budget_min_by_imp_v2` | 曝光时的实时每日预算下限 |
| `account_balance_shop` | 店铺账户余额 (USD) |

### 预估 & PCOC 字段

| 字段 | 含义 |
|------|------|
| `pctr_sum_by_imp` | 预估 CTR 总和（按曝光） |
| `pcr_broad_sum_by_clk` | 预估宽口径 CR 总和（按点击），用于 pcr PCOC |
| `pcr_direct_fail_imp_cnt` | pCR 预估失败的曝光数 |
| `item_price_sum_by_imp` | 商品价格总和（USD，/ 曝光数 = 均价） |
| `daily_pgmv_sum_last_7d_clk` | 7 天滚动最终 pGMV 总和（按点击，校准后） |
| `daily_model_pgmv_sum_last_7d_clk` | 7 天滚动模型 pGMV 总和（按点击，校准前） |

### MPC & Ultra Core 字段

| 字段 | 含义 |
|------|------|
| `mpc_e_gmv` | MPC 当日预估 GMV |
| `mpc_e_cost` | MPC 当日预估 cost |
| `ultra_core_rev` | Ultra Core 收集的 revenue |
| `ultra_core_advv` | Ultra Core 收集的 advv |

## 异常检测与归因

异常类型定义（A1-A14 Campaign/Ads 级别，B1-B15 Shop 级别）和归因节点定义（R1-R10）详见 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md`。

不同模式的处理方式：

1. **ID 诊断**：根据查询到的数据，对照异常类型节点逐一检测；检测到异常后，再根据数据特征推理适用的 R 系列归因节点。
2. **异常类型诊断**：先用指定异常类型的检测公式筛选 top case；然后对 top case 执行归因，不需要重新发现主异常。
3. **已知异常归因**：只验证用户指定异常类型是否成立；直接围绕该异常匹配 R 系列归因节点。
4. 多种异常可以同时存在，但只有 ID 诊断需要完整列出；异常类型诊断和已知异常归因中，其他异常只能作为辅助证据。
5. 归因必须输出**一张按模块分组的合表**：每个一级模块（R1-R10）作为分组锚点，下方按四态压缩规则展开叶子节点。模块汇总行和叶子节点行都要给出 `命中` / `未命中` / `证据不足` / `不适用` 和数字依据。
6. 报告末尾必须输出“一级模块归因总结”，只汇总所有命中的一级模块，并说明每个命中模块的核心证据和作用。
7. 归因节点的 `role` 标签（`trigger` / `amplifier` / `direct`）帮助构建因果链。

## 分析工作流

### Step 1 完成后（Campaign 级别）：

1. **向用户展示已解析的 ID**
2. **将数据行映射到天偏移量**：最近日期 = `_0`，以此类推
3. **计算 7 天聚合指标**：`cost_7d = SUM(revenue_usd_0..6)`，`advv_7d = SUM(advv_usd_0..6)`，`cost_ratio_7d = cost_7d / advv_7d`
4. **检测异常**：仅在 ID 诊断中，对照 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 中的异常类型节点（A 系列 / B 系列）逐一检测；异常类型诊断/已知异常归因只验证指定异常类型
5. **L1 模块判定**：对 R1-R10 每个一级模块给出四态 verdict + 模块级数字依据（详见 Step 5）；R3/R4 不在此处展开叶子，交给 sub-agent 在 Step 6b/6c 处理；自身桶（R1/R2/R5/R6/R7/R8/R9/R10）命中模块在 Step 6a 展开叶子
6. **进入 Step 2** 进行 ad 级别下钻

### Step 2 完成后（Ad 级别）：

1. **逐广告逐天**：漏斗通过率、PCOC、coef 趋势、item_price 趋势
2. **跨天对比**：发现突变
3. **曝光为零的广告** → 进入 Step 3

### Step 3 完成后（状态/停投）：

1. **关联**状态变更时间点与效果下降时间点
2. **将停投原因映射**到具体广告

### 归因模块与节点判定表

每次输出归因报告时，必须输出**按模块分组的合表**，由「瘦身判定表 + 证据明细」两部分组成（渲染格式见「输出格式」章节），同时承载一级模块汇总行和叶子节点判定行：

- 每个一级模块（R1-R10）必须出现一行**模块汇总行**（加粗模块名），给出该模块的判定（`命中` / `未命中` / `证据不足` / `不适用`）；判定表的 `关键数值` 列只放一条最核心数字，完整数字依据写入表下方的「证据明细」
- 模块汇总行下展开**叶子节点行**（用 `·` 前缀缩进）按下方"四态压缩规则"展开
- 四态压缩规则中对"数字依据"的全部要求（枚举缺失项、写排除数值、写前提值等）在「证据明细」中落地；判定表单元格保持简短，避免终端折行

#### 四态压缩规则

| 模块状态 | 叶子展开方式 | 模块汇总行附加要求 |
|---------|-------------|----------------|
| **命中** | 必须逐行展开所有命中叶子；方向不匹配但公式命中的旁证叶子也单独列出（标"方向不匹配，不计入一级模块归因"）；其余未命中叶子可压缩为一行汇总 | 数字依据写命中叶子最关键数值 |
| **证据不足** | 所有叶子折叠，**不展开** | 模块汇总行**必须枚举所有缺失项**（缺什么字段/查询/外部数据），让 reader 看一行就知道下一步补什么 |
| **未命中** | 所有叶子合并为**一行汇总**（"X 节点全部未命中: ..."加最关键排除数值），不必逐叶展开 | 数字依据写最关键的排除数值 |
| **不适用** | 所有叶子合并为**一行汇总**，写明前提不成立的具体数值，不必逐叶展开 | 数字依据写前提值 |

没有二级子节点的一级模块（如 `R6 广告位质量坍塌`、`R7 Shop 级别问题`）模块汇总行即叶子判定行，无需重复展开。

一级模块判定规则：

- **命中**：该一级模块下至少一个叶子节点命中，且命中节点与当前主异常方向一致；数字依据汇总方向一致的命中叶子节点和最关键数值。
- **未命中**：该一级模块下所有可计算叶子节点均未命中，且不存在命中节点；数字依据写最关键的排除数值。
- **证据不足**：该一级模块无命中节点，且关键叶子节点缺少必要数据；数字依据写缺失字段/缺失查询。
- **不适用**：该一级模块有明确前提且前提不成立，或该模块整体不适用于当前异常方向；数字依据写前提值。

方向不一致的叶子节点即使公式命中，也不能计入一级模块命中，不能进入"命中根因与因果链"，也不能进入"一级模块归因总结"；只在合表中以独立行保留（判定列写"旁证"），并在备注里标注"方向不匹配，不计入一级模块归因"。

R3 模型预估异常的方向过滤规则、当前 R3 叶子节点的逐叶展开和判定，由 `ads-diagnose-model-deepdive-hb` agent 在 Step 6c 输出；主 skill 在 Step 5 L1 阶段只给 R3 模块级的 verdict + 关键数字依据。R3 一级宽口径与方向过滤规则见 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md`，R3 二级叶子定义见 `docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md`，agent 定义见 `agents/common/ads-diagnose-model-deepdive-hb.md`。不要在 skill 中写死 `R3.x` 连续范围；每次诊断都按权威节点文件和 agent 输出的当前节点集合合并。

R4 出价调控的逐叶展开，由 `ads-diagnose-bidding-deepdive-xyz` agent 在 Step 6b 输出；主 skill 在 Step 5 L1 阶段只给 R4 模块级的 verdict + 关键数字依据。R4 一级宽口径与方向过滤规则见 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md`，R4 分层叶子定义见 `docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md`，agent 定义见 `agents/common/ads-diagnose-bidding-deepdive-xyz.md`。不要在 skill 中写死 `R4.x` 连续范围；每次诊断都按权威节点文件和 agent 输出的当前节点集合合并。R4 agent 返回的 `selection_evidence` 节点是合表节点，不是可丢弃的中间过程；命中或旁证的 R4.20-R4.27 行必须逐行保留。

叶子节点判定规则：

- **命中**：节点公式/条件被数据满足，数字依据必须写成 `{实际值} {比较符} {阈值}` 或 `{当前值} vs {基线值}`。
- **未命中**：节点公式/条件可计算但不满足，也必须给出数字依据，例如 `target_roi_by_imp_0/target_roi_by_imp_1 = 1.00，不满足 >1.3`。
- **证据不足**：节点需要的数据没有查询到或表中缺失；写明缺失字段/缺失查询，例如 `缺同品类 P25，无法判定 R1.6.1`。
- **不适用**：节点有明确前提且前提不成立；写明前提数字。

合表必须覆盖所有 R1-R10 一级模块（每个模块至少 1 行模块汇总），叶子展开按上方"四态压缩规则"执行。异常检测表中状态为**未命中**或**不适用**的异常类型行可合并为一行（"其余 N 类异常未命中：..."），仅命中或紧密相关的异常类型保留独立行。

最终因果链只使用"命中"的一级模块和叶子节点，未命中和证据不足项保留在合表中作为排除依据。

### 输出一致性约束

**摘要、命中根因与因果链、修复优先级三处对根因的力度判断必须一致。** 同一个命中节点不能在一处当主根因、在另一处降级为放大因素。具体约束：

- **修复优先级 P0 ⇄ 摘要主根因**：如果某节点出现在修复优先级 **P0** 中，摘要必须把它列为"主根因"或"独立根因"，不能在摘要中降级为"放大因素"或"共同放大"；反之，摘要列为放大因素的节点不应进入 P0。
- **同模块多 direct 节点的并联识别**：如果一个一级模块下有多个 `role: direct` 命中叶子（如 R4.4 数据收集异常 + R4.6 调控速度过慢），不要默认把数字最劲爆的那个当"主"、把另一个当"次"——它们可能是**两个独立的系统失效**（计费链路 vs 出价决策），各自需要独立修复。判定时分别问：
  - 如果只修 A 不修 B，问题能不能解决？
  - 如果只修 B 不修 A，问题能不能解决？
  - 两个都需要修 → 两个都是主根因，并联列出，不要伪因果。
- **causal chain 的并联 vs 串联**：因果链图里如果两个节点都在 P0 修复列表，但你画成了上下游串联（A → B），先验证一下 A 充值/修复后 B 是否会自动恢复。如果不会，应改画为并联（A 和 B 都直接指向异常）。

违反此约束的报告视为内部不一致，需要修正后再输出。

### 因果链分析

**这是最重要的分析步骤。** 当检测到多个异常或子原因时，**不要**将它们作为独立发现列出。而应构建因果链：

1. **找到最早的触发事件** —— 通常是广告主操作（ROI 调整、预算变更）或外部事件（余额耗尽）。按时间顺序检查什么**最先**发生了变化。
2. **追踪下游影响** —— 触发事件如何传播？常见因果链：
   - `target_roi_by_imp ↑ + 余额 ↓ → 系统砍有效预算 → 系统降低 coef → eCPM ↓ → 更差的广告位 → CVR ↓ → 零订单 → coef 被进一步压低（死亡螺旋）`
   - `预算撞线 → 曝光减少 → 订单减少 → cost_ratio 飙升 → 系统调整 coef`
3. **识别自我强化循环** —— 如果某个变量的下降导致自身进一步下降（coef → 位置 → CVR → coef），标记为死亡螺旋
4. **用恢复数据验证** —— 如有恢复期数据，检查什么变化打破了螺旋（如充值、降低 ROI）。这可以确认根因。
5. **按角色分类原因**：
   - **触发因素**：引发下降的初始变化
   - **放大因素**：使下降加剧的因素（如低流量下 pCR 模型退化）
   - **直接原因**：最近端的作用机制（如广告位质量坍塌）

**以事件链图方式输出：**
```
{触发事件} ({日期}, {具体数值})
    → {第一层影响} ({指标变化})
        → {第二层影响} ({指标变化})
            → {自我强化循环（如适用）}
```

### 账户余额趋势分析

始终检查完整日期范围内的 `account_balance_shop` 趋势。关键模式：

- **持续下降未充值**：余额接近零时触发系统自动砍 campaign 预算
- **低余额 + ROI 调整在同一天**：乘数效应 —— 双重挤压出价
- **检测**：`account_balance_shop` 连续 3 天以上下降且达到 < 日均花费的 3 倍
- **预算挤压检测**：逐日对比 `daily_budget`。如果在余额触底的同一天下降 >20%，说明系统自动砍了预算

## 输出格式

```
## 诊断报告

### 上下文
- 模式: {ID 诊断 / 异常类型诊断 / 已知异常归因}
- 已知/指定异常类型: {A/B 编号与名称；ID 诊断且未预指定时填“自动检测”}
- Campaign ID: {campaign_id}
- Shop ID: {shop_id}
- Region: {region}
- 时间段: {start_date} ~ {end_date}
- 计价类型: Target / Simple
- 目标 ROI: {value}

### 摘要
{1-3 句概述：检测到什么异常、关键根因}

### 异常检测
{按模式输出：ID 诊断逐一列出检测到的异常类型；异常类型诊断列出 top case 的指定异常命中情况；已知异常归因只验证指定异常类型。附具体数值}
{展开规则：命中的异常类型逐行展开；未命中或不适用的异常类型合并为一行汇总（"其余 N 类异常未命中：..."）}
- 例: A1 超收（命中）: cost_ratio_7d = 1.42 (> 1.25)
- 例: A6 cost 骤降（命中）: revenue_usd_0 / revenue_usd_1 = 0.32 (< 0.5)
- 例: 其余 12 类未命中：A2-A5/A7-A9/A11-A14 环比未达阈值

### Top Case（仅异常类型诊断）

| 排名 | ID/Case | Region | 异常类型 | 异常分数 | 关键指标 |
|------|---------|--------|----------|----------|----------|
| ...  | ...     | ...    | ...      | ...      | ...      |

### 根因归因

#### 模块/节点判定合表

> **用 collect.py 时，「关键数值」列直接取 `module_signals` 的预算值**（d0/d1/7d/比率已算好），不要再从 daily 逐日翻找计算；四态判定与方向过滤仍按 factual_nodes 由你做。例如 R1 行取 `module_signals.R1_self.troi_ratio_d0_d1` / `budget_ratio_d0_d1`，R4 行取 `avg_coef_d0` / `final_coef_7d_avg`。
> 合表固定拆成「瘦身判定表 + 证据明细」两部分输出，**不要输出单张宽表**——长证据放表格单元格会在终端折行、破坏表格渲染。
> 判定表：模块汇总行（加粗 R 编号）+ 叶子节点行（`·` 前缀缩进），按四态压缩规则展开；`关键数值` 列只写一条最核心数字（形如 `{实际值} {比较符} {阈值}`），不写多条、不写整句。
> 证据明细：表下方按模块分组的列表，承载完整数字依据、缺失项枚举和备注；与判定表的模块/判定一一对应。
> 命中模块逐叶展开（含方向不匹配旁证）；证据不足模块叶子折叠；未命中/不适用模块仅保留模块汇总行。

| 模块/节点 | 判定 | role | 关键数值 |
|---|---|---|---|
| **R1 Campaign/Ads 自身原因** | 未命中 | - | target_roi_by_imp_0/_1 = 1.00 |
| **R3 模型预估异常** | 命中 | - | 0.427 < 0.8 |
| · R3.1.3 model_pgmv 校准前低估 | 命中 | amplifier | 0.427 < 0.8 |
| · R3.1.2 final_pgmv 高估 | 旁证 | amplifier | 1.205 > 1.2 |
| **R4 出价调控策略异常** | 命中 | - | final_coef_0 = 2.22 > 0.7 |
| · R4.5 出价调控速度过慢 | 命中 | direct | final_coef_0 = 2.22 > 0.7 |
| **R8 外部/环境因素** | 证据不足 | - | - |
| **R9 Shop 级别聚合归因** | 不适用 | - | single campaign |
| ... | ... | ... | ... |

**证据明细**

- **R1 未命中**：14 节点全部未命中——target_roi_by_imp_0/_1 = 1.00；daily_budget_0/_1 = 1.00；active_hour_0 = 24
- **R3 命中**（命中叶子: R3.1.3）：
  - R3.1.3 命中：model_pgmv 校准前低估 0.427 < 0.8，方向匹配欠收
  - R3.1.2 旁证：1.205 > 1.2，方向不匹配，不计入 R3 模块归因
- **R4 命中**（命中叶子: R4.5）：R4.5 final_coef_0 = 2.22 > 0.7；final_coef_avg_7d = 2.78 > 1，调控未及时压低
- **R8 证据不足**：缺同品类/地区平台大盘趋势（R8.1）+ impression share（R8.2），叶子折叠
- **R9 不适用**：当前为 single campaign 诊断

#### 命中根因与因果链

##### [{异常编号}] {归因节点编号} {归因名称} (role: {trigger/amplifier/direct})
- **证据**: {来自数据的具体数值；必须与上方合表一致}
- **建议**: {排查或修复方向}

##### [{异常编号}] {归因节点编号 2}（如适用）
...

### PCOC & 漏斗汇总

> **用 collect.py 时整段粘贴 `daily_markdown` 字段**——它已渲染好覆盖完整时间窗口的表A/表B（逐日、用户输入日加粗、病灶日标 ★），不要逐格重打、**也不要手动增删行**（省 token + 避免抄错）。下方两张表仅为字段口径参考（手工 SQL 路径或需自定义列时用）。
> **病灶日重定位不截断表格**：即使 `relocate_focus=true`，逐日表仍是从用户 `_0` 往前的**完整窗口**（重定位只改归因焦点和 dispatch 日期，不改表格范围）；病灶日已在 `daily_markdown` 里标 ★，无需另截子表。
> **必须覆盖 Step 1 查询的完整时间窗口**（提供日期 D 时为 `D-7 ~ D+5` 共 13 天；提供日期范围 `[D1, D2]` 时为 `D1-3 ~ D2+5`；未提供日期时为 `today()-7 ~ today()` 共 8 天）。不要只贴诊断日 ±2 天的样本——恢复期和基线趋势对验证因果链至关重要（例如 balance 断崖、coef 锁死轨迹、CVR 多日下降）。
> 为适配终端宽度，固定拆分为下面两张窄表输出，**不要合并成一张宽表**；两张表使用同一日期集合逐日对齐。

**表 A：效果 & PCOC（含 balance，方便看余额耗尽轨迹）**

| 日期 | Rev(USD) | Advv(USD) | CostRatio_1d | pgmv_pcoc | pctr_pcoc | pcr_pcoc | final_coef | balance |
|------|----------|-----------|--------------|-----------|-----------|----------|------------|---------|
| ...  | ...      | ...       | ...          | ...       | ...       | ...      | ...        | ...     |

**表 B：流量 & 漏斗**

| 日期 | Imp | Clicks | 粗排% | 精排% | 混排% |
|------|-----|--------|-------|-------|-------|
| ...  | ... | ...    | ...   | ...   | ...   |

### 7 天聚合
- cost_7d: {value} USD
- advv_7d: {value} USD
- cost_ratio_7d: {value}
- gmv_7d: {value} USD

### 一级模块归因总结
- 命中一级模块: {按 R 编号升序排列的 R 编号 + 模块名列表}
- {R 编号 模块名}: {核心证据；该模块在因果链中的作用}
- 按 R 编号升序逐条总结命中的一级模块；不要按主观重要性或因果先后重排
- 未进入总结的模块均为未命中、证据不足、不适用，或仅有方向不匹配的叶子节点命中，详见上方合表

### 二级归因（叶子节点）总结/Leaf Attribution Summary

> 按一级模块分组，列出所有命中叶子节点的简明总结。
> 来源标注：自身桶叶子由主 skill 展开；R3 叶子由 `ads-diagnose-model-deepdive-hb` agent 输出；R4 叶子由 `ads-diagnose-bidding-deepdive-xyz` agent 输出。
> 必须按叶子节点编号自然升序逐条排列（先按一级模块 R 编号，再按二级/三级编号，例如 R3.1.1 → R3.1.2 → R3.1.3 → R3.1.3.1 → R3.1.3.2 → R3.1.4 → R3.2.1）；不要按 P0/P1、影响占比、主观重要性或 agent 返回顺序排序。未命中 / 不适用 / 证据不足 / 旁证叶子不进入本表（详见上方合表）。R4 中判定为命中的 `selection_evidence` 节点（如 R4.22/R4.24）也进入本表，优先级填 `-`，用于支撑对应 R4.30.x direct 根因。

| 一级模块 | 命中叶子 | role | 关键证据 | 来源 | 优先级 |
|---|---|---|---|---|---|
| {R 模块名} | {Rx.y 叶子名} | {trigger/amplifier/direct} | {数字依据} | {主 skill / model agent / bidding agent} | {P0 / P1 / P2 / -} |

- 排序规则：二级归因总结表只按叶子节点编号自然排序；优先级仅保留在"优先级"列，不参与排序。
- 跨桶 P0 主因汇总: {按 R 编号升序列出所有 P0 叶子}
- 跨桶 P1 次因汇总: {按 R 编号升序列出所有 P1 叶子}
- 叶子总数: {n} 命中叶子，分布在 {m} 个一级模块

### 一级模块自动评审（单 case / 批量 GSheet / 回归评审时输出）

> 自动评审是给人读的报告结论，不要只输出裸 JSON。默认先输出 Markdown 评审摘要；如用户需要批量程序消费，再在末尾追加“机器可读摘要”。

#### 评审结论

| 项目 | 结果 |
|------|------|
| 评审对象 | {单 case: campaign_id / shop_id / ads_id；批量: GSheet tab + 行数} |
| 一级模块结论 | {正确 / 部分正确 / 错误 / 证据不足 / 未评审} |
| 人工标注 | {P 列原文；无人工标注填 `-`} |
| 认可模块 | {R 编号 + 模块名，按 R 编号升序} |
| 存疑模块 | {无 / R 编号 + 存疑原因} |
| 缺失模块 | {无 / R 编号 + 缺失原因} |
| 下钻 owner | {无 / @haibo / @xinyu / @haibo, @xinyu} |

#### 模块评审明细

| 模块 | 自动评审 | 关键证据 | 结论说明 |
|------|----------|----------|----------|
| R1 Campaign/Ads 自身原因 | {认可 / 存疑 / 缺失 / 不适用} | {最关键数字或事件；无则填 `-`} | {为什么接受、存疑或不适用} |
| R3 模型预估异常 | {认可 / 存疑 / 缺失 / 不适用} | {PCOC / fail rate / 方向过滤证据} | {是否需要模型下钻} |
| R4 出价调控策略异常 | {认可 / 存疑 / 缺失 / 不适用} | {final_coef / MPC / 数据收集证据} | {是否需要出价下钻} |
| ... | ... | ... | ... |

#### 下钻建议

| Owner | 是否需要 | 原因 | 建议动作 |
|-------|----------|------|----------|
| @haibo 模型 | {是 / 否} | {R3 或模型相关证据；没有则填 `-`} | {建议排查 pCTR / pCR / pGMV / serving / 校准等；没有则填 `-`} |
| @xinyu 出价 | {是 / 否} | {R4/R5/R10 中与出价控制相关的证据；没有则填 `-`} | {建议排查 coef / PID / MPC / bid control / budget control 等；没有则填 `-`} |

#### 问题与反馈

| 严重程度 | 类型 | 说明 |
|----------|------|------|
| {P0/P1/P2/-} | {direction_mismatch / insufficient_evidence / over_attribution / under_attribution / role_inconsistency / legacy_unsupported_module / none} | {问题说明；无问题填 `无`} |

#### skill 反馈

- {可反哺 skill 的一句话规则优化；无则填 `无`}

#### 批量汇总（仅多 case 时输出）

| 指标 | 数量 |
|------|------|
| 总 case 数 | {n} |
| 一级模块正确 | {n} |
| 部分正确 | {n} |
| 错误 | {n} |
| 证据不足 | {n} |
| 未评审 | {n} |
| 需要 @haibo 下钻 | {n} |
| 需要 @xinyu 下钻 | {n} |

批量 case 明细只展开有问题或需要下钻的 case；完全正确且无需下钻的 case 可以合并为一行统计。

#### 机器可读摘要（可选）

{
  "case_id": "{campaign_id or row id}",
  "module_review": "correct | partially_correct | incorrect | evidence_insufficient | unreviewed",
  "manual_p_label": "{raw Column P label if present}",
  "accepted_modules": ["R1", "R3"],
  "questionable_modules": [],
  "missing_modules": [],
  "drilldown_owner": ["@haibo"],
  "skill_feedback": "{short rule improvement or none}"
}
```

未检测到异常时（cost_ratio_7d 在 0.75-1.25 之间且无环比暴跌），明确说明该 campaign 状态健康并展示关键指标。
