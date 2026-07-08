# 广告全量发布文档生成（ads-rollout-generate）使用指南

> **语言**：[English](ads-rollout-generate.md) | [中文](ads-rollout-generate.zh-CN.md)

根据一个 AB 实验平台 report link 生成标准 Ads rollout Markdown 初稿文件。该 skill 通过 `sp-ab` 拉取实验平台数据，填充最新版 `rollout-doc.md` 模板，并在指标映射或业务阈值不明确时先追问。

**唤醒词**：「generate rollout」、「fill rollout doc」、「rollout 文档」、「全量申请文档」、「实验平台 link 填模板」、「AB link 生成 rollout」、「填写 rollout-doc.md」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主流程和追问策略 |
| `references/template-mapping.md` | 模板字段映射和数据填写规则 |
| `references/guardrail-thresholds.yaml` | traffic-bucket 和 item-bucket 的静态 Guardrail 阈值 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|------|------|------|
| `sp-ab` | Skill | 获取 AB 平台 report JSON 和实验元信息 |
| AB platform report token | 凭据 | `sp-ab` 调用 Report Open API 所需 |
| `uv` | 运行时 | 运行 `sp-ab` 辅助脚本 |

---

## 基本用法

1. 提供一个 AB 实验平台 report link。
2. skill 使用 `sp-ab` 拉取报表，并先总结数据口径。
3. 对不明确的指标映射、公式、分桶映射、guardrail 阈值进行确认。
4. skill 优先填写 rollout 数据章节。
5. 根据追问补充项目背景、方法、Epic File、参与者、Ticket、Rollout Date。
6. 默认写入 `tmp/ads-rollout-generate/<exp_id-or-share_id>/...rollout.md`，并在对话中返回文件路径。

默认规则是一个 link 生成一份 rollout `.md` 初稿文件。如果一次提供多个 link，默认分别生成独立文档；只有用户明确要求时才合并。

---

## 示例 Prompt

> 用 `/ads-rollout-generate` 根据这个 AB 平台 link 填 rollout 模板：`https://abtest.shopee.io/...`

> 根据这个实验平台 link 生成 rollout 文档，先把数据部分填好，背景和参与者我后面补。

> 帮我把这个 item bucket 实验转成 `rollout-doc.md` 格式；不确定的达标率指标先问我。

---

## 注意事项

- 该 skill 不复用 `ads-experiment-analyze` 的指标判断口径。
- 已确认的默认映射会写在 `references/template-mapping.md`；只有未覆盖或仍有歧义的字段才追问。
- 为提升速度，skill 先恢复 share 参数并生成去重后的 query plan。若 rollout 需要 non-normalized `Mo.*`、item all-filter 行或补充 tab，不默认 replay 完整 shared UI summary。
- Query plan 只是执行优化：对相同 template/tab/date/region/group/dim/filter/normalization scope 的 metric 请求合并取数，复用 `tmp/ads-rollout-generate/` 下匹配的 raw 文件，并保持最终 rollout doc 结构和数值与既有口径完全一致；除非用户明确要求，不把 query-plan-only 元信息写入最终 Markdown。
- 对固定 AB 维度优先使用 server-side filter，例如 `target_feature`、`product_type`、`platform`、`is_ads`、`adtag_tier`、`budget_tier`、`campaign_order_tier`、`hit_budget_tier`；只有 AB API 语义不支持时才使用 client-side filter。
- fallback tab 不预取；只有 primary source 缺 metric 或没有 matching rows 时才补拉。
- skill 必须根据 AB link 对比实验参数：用 `sp-ab` group detail / feature-value API 拉取选定 base group 和 rollout treatment group 的 parameter payload，优先做结构化 diff，并把结果写入 Appendix `实验参数变化/Experiment Parameter Changes`。
- 参数变化只比较 AB group 的 `parameter` / feature-parameter payload。group name、bucket range、traffic share、日期、normalization config 和 report metric 不能算作参数变化。
- 如果选定 base 和 rollout treatment 的参数 payload 已成功比较且确认完全一致，需要在 Project Info 中新增 `参数变化风险提示 / Parameter Change Risk`。如果参数源缺失、baseline/treatment 不明确或 feature value 无法解析，则 Appendix 标记为 `unresolved`，不能声称“无参数变化”。
- 如果 AB report 选择了多个 treatment bucket，生成 treatment-derived metric 前必须追问用户哪一个是要推全的 bucket，不能默认第一个、随机选择或聚合多个 treatment。
- 如果 control selector 中包含 2 个以上 Base 桶，`置信度分析-AA` 默认用这些 Base 桶作为 AA 参考：先按 bucket traffic share 归一，再按 date / region / metric 取算术均值。若没有多个 Base 桶且没有显式 AA group，填 `未指定aa分桶桶号`。
- 如果 AB 平台 Date / `times_str` 包含多段日期，需要把所有日期段合并为同一个分析窗口。control / treatment 只能来自 group selector，不能从日期段推断；`exp days` 为所有日期段去重后的完整日期数。
- Item-bucket 数据中，`advv_999` 使用 `advv_cost_999`；`broad_gmv` 使用 `broad_gmv_usd`；`broad_gmv_999` 使用 `broad_gmv_usd_999`。不要用 999 字段填普通 `broad_gmv`。
- Item-bucket 的 `2.3` 中，`BiddingType` 行必须由选定 rollout bucket ID 推导。`24*` 是多品出价 `GMS`（`PricingType=24/25/27`，`adtag_tier=ALL`）；`99*` 是单品实验 ROI2，展示 `All` / `Target_ROI2` / `Simple_ROI2`（`adtag_tier=ALL` / `target_roas2.0` / `simple2.0`）；桶号 `<1000` 只展示匹配的冷启动 / 新品 / 空耗 `adtag_tier`。
- 对 `99*` item 实验，每个 source tab 需要把 `All`、`Target_ROI2`、`Simple_ROI2` 一次取齐：保留 `adtag_tier` 维度或使用一个多值 filter；当 tab/scope/metrics 相同且只有 `adtag_tier` 不同时，不要每个 BiddingType 单独 query。
- 三类 item 分桶出价实验互斥。`99*` 单品实验不能展示 `GMS` 或冷启动行；`24*` 多品实验不能展示 `All` / `Target_ROI2` / `Simple_ROI2`；`<1000` 实验不能展示无关 item 出价行。
- Item-bucket traffic share 在 AB `normalization_config` 缺失或只包含无关桶时，使用固定 Product Ads plan-bucket 映射推导。`24*` 和 `99*` 大桶（`2410-2414`、`2420-2424`、`9910-9914`、`9920-9924`）每桶 19%；对应小桶（`2415-2419`、`2425-2429`、`9915-9919`、`9925-9929`）每桶 1%。冷启动 `<1000` 大桶（`10-12`、`20-22`）每桶 `97/300 = 32.3333%`；小桶（`13-15`、`23-25`）每桶 1%。
- Item-bucket control 如果是分号分隔的多个 Base 桶，需要拆开后把固定 share 求和，例如 `2413-all;2414-all = 38%`。如果 AB normalization 与固定 item 映射冲突，需要追问是否是特殊流量配置。
- Core Metric Uplift Summary 中，traffic-bucket 实验的 `Rev达标率 abs` 和 `Rev达标率 Rel.` 必须填 `-`；达标率只适用于 item / plan bucket 实验。对于 item / plan bucket 实验，`2.2 Rev达标率 abs` 和 `Rev达标率 Rel.` 都必须使用 `fulfilled_rev_pct(1d)`，并与同 region、同 aggregate item row 的 `2.3 Item-Bucket-Exp.1d达标率` 对齐。`2.2` 不能使用 `fulfilled_rev_pct(7d)` / `7d达标率`；7d 达标率只允许用于明确要求 7d 的 sheet paste 字段。
- `Mo.*` 是 overall、非 Normalization 的绝对 uplift 指标：拉数前关闭 AB 平台 `Normalization`，不能复用 share 中已开启的 `normalization_config`，只保留 date / region / control / selected treatment，其他所有 filter 都设为 `ALL`（`pricing_type`、entrance / `target_feature`、`adtag_tier`、`budget_tier`、`campaign_order_tier`、`hit_budget_tier`、product / ads type、scene 等）。Product Ads plan-bucket 的 overall 行大小写敏感，使用大写 `adtag_tier=ALL`，不能用小写 `all`。
- `2.2 Core Metric Uplift Summary` 必须包含 `Region=ALL` 汇总行。对绝对影响列按 region 求和，包括 `Mo.*`（含 `Mo. Advv 7d (w usd)`）和未来可能出现的 entrance absolute-impact 列；如果任一参与汇总的 region 缺值，则 `ALL` 单元格填 `-`，不要展示部分总和；不要对 rate / ratio / relative / pp 列求和，例如 `VPR abs`、`Rev达标率 abs`、`Rev达标率 Rel.` 或当前 `Ent.* Rel.`。`*. Rel.` 列的 `ALL` 行用 full-traffic raw absolute 聚合后重算（`all_base_full = sum(region base_full)`，`all_exp_full = sum(region exp_full)`，`all_rel = all_exp_full / all_base_full - 1`），不对 region 百分比求和或平均。
- `2.2 Core Metric Uplift Summary` 新增 5 个相对提升参考列（`Rev Rel.`、`Advv 1d Rel.`、`Advv 7d Rel.`、`Broad GMV Rel.`、`Broad GMV 999 Rel.`），各紧跟对应 `Mo.*` 列后。这些列固定出现在表头中；缺数据时填 `-`。每个 `*. Rel.` 从对应 `Mo.*` 的同源 raw absolute base / treatment 计算：`rel_reference = exp_full / base_full - 1`，其中 `base_full = base_abs_raw / base_traffic_share`。不直接使用 AB report `relative_diff`（仅可作校验）；不从月化后 `Mo.*` 反推。
- 对 item / campaign-bucket rollout，Core Metric Uplift Summary 新增减 AA 后的相对提升参考：`Rev Adj. Rel.`、`Advv 999 Adj. Rel.`、`Advv Adj. Rel.`。公式为 `adjusted_lift = post_lift - pre_aa`，其中 `pre_aa` 和 `post_lift` 都必须从同源 raw treatment/base 绝对值先按 traffic share 归一到 full traffic 后计算。
- 减 AA 指标必须有固定 pre window，并确认 pre window 内 base / treatment 桶位没有其它实验或配置占用。缺 pre window 时填 `**【待确认】Pre AA Window**`；桶位可用性未确认时填 `**【待确认】Pre AA Bucket Availability**`；发现冲突时填 `-` 并在 Metric Mapping 记录。
- `Rev Adj. Rel.` 和 `Advv 999 Adj. Rel.` 是 overall 稳定性参考。raw lift 仍然必须保留，adjusted lift 不能替代原始实验结果。region 的 adjusted lift 只用于诊断，不作为 1% 硬 guardrail。
- `Mo. Advv 7d (w usd)` 仅用于 traffic-bucket 实验，来源固定为 `Ads Type (Ads Data Only) - Period.advv_cost_7d`，不走 `Rollout Checklist` / `Platformwide - Period` 优先级链。需通过 Mo.* Source Gate 和 reverse sanity check。来源 tab 缺 `advv_cost_7d` 或 gate 失败时填 `-`。
- `2.3 Traffic-Bucket-Exp` 中 `advv_cost_7d` 来源为 `Ads Type (Ads Data Only) - Period.advv_cost_7d`，按 `target_feature` 映射入口行（`platform=ALL`、`search=Search`、`rcmd_unify=RCMD Unify`、`dd=Daily Discover`、`ymal=You May Also Like`、`cart=Cart Unify`、`game=Game`）。来源 tab 缺对应入口行的 `advv_cost_7d` 时填 `-`；不 fallback 到 `advv_cost_1d`。
- `Ent. Rev Rel.`、`Ent. Advv Rel.`、`Ent. GMV Rel.` 是分场景指标，必须有用户明确指定的单一 entrance，或从 share filter 唯一推断出的 entrance；数据源优先使用 `Platformwide - Period`，若没有选定 entrance 指标再 fallback 到 `Ads Type (Ads Data Only) - Period`。在 Ads Type 中，entrance 可能是 `target_feature=Game` 这样的维度行，不一定是 `game_*` metric，不能默认使用 `platform_*`。
- `VPR abs` 按 `(advv_cost_1d_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift) / base_voucher_cost_norm` 计算，所有输入先按 bucket traffic share 归一。`2.3 Traffic-Bucket-Exp` 还需要新增绝对值 `voucher_profit = advv_cost_1d_uplift + gmv_995_v2_uplift / 4 - voucher_cost_uplift`；它是 VPR 分子，不再除以 `base_voucher_cost_norm`。
- `Mo. Broad GMV (w usd)` 和 `Mo. Broad GMV 999 (w usd)` 是两个独立字段。item / plan bucket 分别从 `GMV & ROI.broad_gmv_usd` 和 `GMV & ROI.broad_gmv_usd_999` 获取；traffic bucket 使用通过 scale 校验的 overall `broad_gmv_usd` / `broad_gmv` 和 `broad_gmv_999` source；如果绝对值 scale 与展示的 relative KPI 不一致，要拒绝该 source。
- Traffic-bucket 的 `Mo. Rev` / `Mo. Advv` 必须和 `2.3` platform relative metric 使用同一个业务 KPI scale（Product Ads 通常是 `Rollout Checklist.platform_revenue_usd` / `platform_advv_cost_1d`）。如果 `(Mo / 30) / base_daily_full_traffic` 不能近似还原展示的 relative uplift，就拒绝 `Platformwide - Period` 绝对值 source。
- `2.3 Key Metrics List` 中，先确认 bucket type；traffic-bucket 只展示 `Traffic-Bucket-Exp`，item / plan-bucket 只展示 `Item-Bucket-Exp`，不要在已知 bucket type 后保留另一张空表。
- `2.1 Experiment Info` 只放实验元信息和必要 data scope，不要新增 `数据结论/Data Observation`；指标证据放在 `2.2` / `2.3`，Guardrail 结论放在 `2.4`。
- `Traffic-Bucket-Exp` 中，`Entrance` 是 `target_feature` 维度，不是 metric prefix；必须保留 rollout template 的完整行：`platform/search/rcmd_unify/dd/ymal/cart/game/Guardrail Summary/置信度分析-by day/置信度分析-AA`。
- Traffic-bucket 的 `2.3` 中，`platform/search/rcmd_unify/dd/ymal/cart` 从 `Platformwide - Period` 按 `target_feature` 获取；`game` 从 `Ads Type (Ads Data Only) - Period` 获取，过滤 `target_feature=Game, product_type=all`；`bad_query_rate` 从 `Rollout Checklist.bad_query_rate` 例外补取，并用于 search 行、Guardrail Summary 和 by-day。
- `Guardrail Summary` 默认看 `platform` 行，`bad_query_rate` 例外使用 `Rollout Checklist.bad_query_rate`：有 metric 值且有静态阈值时判断 `pass/fail`；有 metric 值但没有静态阈值时默认填 `pass`；只有缺源数据时填 `-`。
- `置信度分析-by day` 对 traffic-bucket 和 item / plan bucket 都是必填。只要 period 表该 metric 有值，就必须拉取匹配 daily source 或按 daily 组件计算并渲染为 `x/n`，不能因为没有 guardrail 阈值、方向未配置或尚未拉 daily query 而填 `-`。item / plan bucket 的 `1d达标率` by-day 使用与 `2.3 1d达标率` 同 row scope 的 daily `fulfilled_rev_pct(1d)`。如果 daily source 无法获取，填 `**【待确认】Daily Source**` 并在 Metric Mapping 记录 blocker，不能填 `-`。`bad_query_rate` 使用 `Rollout Checklist.bad_query_rate`，不要填 daily-source 待确认占位。`置信度分析-AA` 统计 AB daily uplift 为正且大于同 metric AA daily uplift 的天数；优先用显式 AA group，否则在存在多个 control Base 桶时使用按流量归一后的 Base 桶均值。
- Daily query 采用懒加载。若 `exp days = 1`，直接用 period uplift 计算 by-day 为 `1/1` 或 `0/1`；若 AA 不可用，不拉 AA-only daily；若多个 Base 桶可作为 AA，则同一 tab/scope 的 AB by-day 和 AA 复用同一份 daily raw。
- `2.4 Guardrail 分析结论` 必须与 `2.3 Guardrail Summary` 一致：所有 `fail` 单元格都要汇总到 2.4，`pass` / `-` 不默认进入 2.4；每条 fail 结论必须展示具体静态阈值、阈值类型、方向、fail condition、来源和观测 uplift / diff。
- Monthly uplift 使用非 Normalization 的原始绝对值和实际选中流量比例：`monthly_abs_uplift = (exp_abs_raw / exp_traffic_share - base_abs_raw / base_traffic_share) * 30 / exp_days`；USD 结果填入 `w usd` 时除以 `10000`。Item-bucket 在 AB share metadata 没有匹配桶时，使用固定桶号 share 映射；如果 control 包含多个 Base 桶，`base_traffic_share` 是这些 Base 桶的流量比例之和。不要用 normalized 绝对值或 AB 报表 relative uplift 计算 `Mo.*`。每个 `Mo.*` 单元格要反推校验：`monthly_abs_uplift_w_usd * 10000 * exp_days / 30` 必须等于 `exp_abs_raw / exp_traffic_share - base_abs_raw / base_traffic_share`；如果只匹配 `raw_abs_delta * 30 / exp_days`，说明漏了 traffic-share normalization。还要做同源 scale 校验：`(monthly_abs_uplift_w_usd / 30) / (base_abs_raw / base_traffic_share / exp_days / 10000)` 必须近似等于同 metric 展示的 relative uplift。
- 每份生成的 rollout doc 都必须在 Appendix 中包含 `Guardrail 要求/Guardrail Requirements`、`指标映射关系/Metric Mapping` 和 `实验参数变化/Experiment Parameter Changes` 三类表。Guardrail 表罗列 `references/guardrail-thresholds.yaml` 中所有要求和具体值；Metric Mapping 表覆盖所有 metric-bearing rollout 字段及其 AB 平台展示指标名、来源 tab、scope 和公式；参数变化表展示 parameter path、base value、treatment value、change type、source 和 notes。如果是确认的 `no_change`，必须同时在 Project Info 给出参数变化风险提示。
- 默认输出位置是 `tmp/ads-rollout-generate/` 下的 `.md` 文件；只有用户要求时才在对话中粘贴完整 Markdown。
