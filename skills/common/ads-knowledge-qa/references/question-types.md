# Intent Classification Reference

Five intent types drive the retrieval entry layer. Correctly identifying intent
avoids unnecessary retrieval (e.g., reading source code to answer a concept question
that is fully covered by the indexed atomic notes under `docs/common/core-knowledge/`).

---

## concept — What is X?

**Definition:** User wants a definition, explanation, or comparison of a term, metric,
algorithm, or component.

**Entry layer:** L2 (`docs/common/index-synthesis*.md` → `docs/common/core-knowledge/`)

**Linguistic signals:** 是什么、什么意思、解释一下、有什么用、X 和 Y 的区别

**Typical questions:**
- "eCPM 是什么，和 RPM 有什么区别？"
- "GSP 和 GFP 竞价机制有什么不同？"
- "NoBid 出价模式是什么，适用于哪些场景？"
- "直接归因（Direct Attribution）和间接归因（Broad Attribution）的区别？"
- "OhMyEmb 是干什么的？"
- "双出价的核心思想是什么？"

**Expected retrieval path:** L2a index → selected `docs/common/core-knowledge/01.ads-overview/` or `02.ads-strategy/` atomic note → exit

---

## arch — How does X work at a system / flow level?

**Definition:** User wants to understand the overall architecture, data flow, component
relationships, or end-to-end processing pipeline.

**Entry layer:** L2 (`docs/common/index-synthesis*.md` → `docs/common/core-knowledge/`)

**Linguistic signals:** 架构、流程、链路、怎么运转、模块关系、如何配合、整体设计

**Typical questions:**
- "ads-engine 的整体架构是什么，API0~API4 分别做什么？"
- "广告请求从用户搜索到最终展示的完整链路是什么？"
- "ads-engine 和 online-bidding 是怎么交互的？"
- "Indexer 和 AdsInfo 在广告系统里分别承担什么角色？"
- "UltraV core 和 online-bidding 的分工是什么？"
- "召回服务（paidads-recall）的离线和在线数据流是如何设计的？"

**Expected retrieval path:** L2a index → selected architecture atomic note → exit

---

## usage — How do I configure / use X?

**Definition:** User wants to know how to operate, configure, or call a specific
feature, API, or configuration item. Usually tied to a concrete artifact (config file,
interface, parameter).

**Entry layer:** L2a → optional source-repo docs fallback or L4 if ads-workspace docs lack the detail

**Linguistic signals:** 怎么配置、怎么用、字段含义、参数是什么、如何开启、接口怎么调用

**Typical questions:**
- "rule_config.json 里 `enable_roi3` 字段有哪些可选值，含义是什么？"
- "BiddingRequest proto 里 `adslot_type` 的枚举值有哪些？"
- "如何给一个广告场景开启 oCPX 出价模式？"
- "operator 的配置里 `weight` 参数是怎么生效的？"
- "feature_config.yaml 里的 slot_id 和 AFP 的 slot 是同一个概念吗？"

**Expected retrieval path:** L2a index → selected core-knowledge or repo-specific `docs/common/readme/<repo>/` atomic note if a repo is identified → optional source-repo docs fallback or L4

---

## debug — Why is X failing or behaving incorrectly?

**Definition:** User has observed an unexpected outcome and wants to diagnose the root
cause. Requires understanding conditional branches, error handling, or data dependencies
in the actual code.

**Entry layer:** L2a → L4, with optional source-repo docs fallback only when useful docs exist

**Linguistic signals:** 为什么、没有生效、不符合预期、报错、为什么没有、异常

**Typical questions:**
- "广告没有被召回，可能是什么原因？"
- "eCPM 计算结果为 0，从哪里开始排查？"
- "online-bidding 返回的 bid price 比预期低很多，可能在哪个环节被调整了？"
- "降级（downgrade）之后广告数量大幅下降，downgrade 逻辑具体做了什么？"
- "日志里出现 `bid_info_empty`，这个错误是在哪里抛出的？"

**Expected retrieval path:** L2a index → selected centralized README/docs atomic note → optional source-repo docs fallback for runbooks → L4 source code

---

## impl — Show me the implementation of X

**Definition:** User has a specific function, struct, or algorithm in mind and wants
to see the actual code. Intent is explicitly code-level from the start.

**Entry layer:** L4 directly (no need for L2 detour unless the user also asks for conceptual context)

**Linguistic signals:** 怎么实现的、函数逻辑是什么、源码、具体算法、代码在哪

**Typical questions:**
- "`CalcEcpm` 函数在 roi3 模式下 bid price 是怎么计算的？"
- "`BuildBiddingRequest` 是如何组装 bidding 请求的？"
- "paidads-recall 里 `RetrievalDowngrade` 的降级判断逻辑是什么？"
- "`PrepareRoi3Data` 做了哪些数据准备工作？"
- "`GraphEngine` 的 operator 执行顺序是在哪里决定的？"

**Expected retrieval path:** L4 directly (zgrep symbol + symbol-content)

---

## data — Data tables, SQL, metrics query

**Definition:** User asks about data warehouse tables, actual metric data, field names, or needs SQL to query ads metrics. This intent should be **delegated to `sra-data-query`** rather than searched in docs/code.

**Entry layer:** Delegate directly — do not proceed through L2/L4.

**Linguistic signals:** 表、字段、SQL、query、grass_date、grass_region、数据表、指标口径、曝光量、GMV、CTR数据、取数、查数、mp_paidads、写SQL、帮我查数据

**Typical questions:**
- "过去7天各国家的广告曝光量在哪张表？"
- "mp_paidads_dws_shop_daily_perf 这张表有哪些字段？"
- "如何写SQL查广告CTR和CVR？"
- "广告GMV的指标口径是什么，take_rate怎么算？"

**Action:** Directly suggest using `/sra-data-query` and explain why it's better suited.

**Note:** If the question is about *how a metric is defined conceptually* (e.g., "eCPM 是什么"), treat it as `concept` intent (L2). Only delegate to `sra-data-query` when the user wants actual data or SQL generation.

---

## Mixed Intent Handling

Some questions span two intents. Split and serve the shallow part first:

**"eCPM 是什么，ads-engine 里具体是怎么计算的？"**
- First half = `concept` → search `docs/common/index-synthesis*.md`, then answer from the selected strategy-mechanisms atomic note
- Second half = `impl` → prompt: "如需查看 `CalcEcpm` 的代码实现，请告诉我"
- Only proceed to L4 if the user confirms

**"出价系统的整体架构是什么，online-bidding 的 `ProcessBid` 函数做了什么？"**
- First half = `arch` → search `docs/common/index-synthesis*.md`, then answer from the selected traffic-strategy/billing atomic note
- Second half = `impl` → defer to user confirmation before reading source code

**Principle:** Always satisfy the lowest-cost layer first, then surface the option
to go deeper. Never speculatively read source code when docs are sufficient.
