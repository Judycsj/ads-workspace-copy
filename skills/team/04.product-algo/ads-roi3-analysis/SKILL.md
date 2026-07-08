---
name: ads-roi3-analysis
description: >
  Roger 的 ROI3 分析路由 hub（总-分结构的"总"）。把模糊的分析诉求引导成一张
  分析计划卡（决策、五轴、口径、输出），按路由注册表分发给 spoke 执行，
  收尾回贴结论速览并沉淀方法。
  TRIGGER when: user mentions "ads-roi3-analysis", "roi3 分析", "ROI3 analysis",
  "分析一下 ROI3", "发券分析", "券效率分析怎么做", "边际还有没有空间",
  "实验该不该扩", "ROI3 赚不赚", or 表达了一个 ROI3 域的分析诉求但没点名具体工具.
  DO NOT TRIGGER when: 纯日报/周报生成（用 ads-roi3-monitoring-report /
  ads-roi3-weekly-sync）、用户已点名某个诊断工具（如 ads-roi3-diagnosis-v2）、
  机制/口径知识问答（用 ads-knowledge-qa）、非 ROI3 域的数据分析（用 ads-text2da）。
user-invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - Skill
  - Agent
  - Bash
  - Write
  - Edit
---

# ROI3 分析路由/ROI3 Analysis Hub

把"我想分析点什么"变成一张确认过的**分析计划卡**，再路由给对应的执行能力（spoke）。本 skill 只做引导、组卡、路由、收尾，不做分析本身。设计蓝本（分层架构、第一性原理、契约全文）：`references/framework-design.md`。

## 0. 硬规则/Hard Rules

1. **无验证不结论**：结论必须有经过验证的数据支撑；未验证的判断只能标"假设/待验证"。
2. **口径强制确认**：value 口径（advv / broad_gmv / platform_gmv / guardrail）必须在计划卡里显式确认；高风险决策类分析须多口径并行、分别给结论。
3. **提问预算**：快速流程 ≤1 次确认，标准 ≤2 次，完整 ≤3 次。预填让用户改，不逐项盘问；装不下的问题写进计划卡标"待定"。
4. **路由透明**：分发到 spoke 前说一句"接下来用 xx 跑 xx"；失败按注册表 known_failures 给降级方案，不静默换路径。
5. **报告守骨架**：所有产出按 `references/report-skeleton.md` 的总-分-附录结构和写作约束执行；结论速览指标表**必用"指标表标准格式"**——每指标给 打平流量后的绝对值（各臂归一等流量）+ 相对变化% 双栏（算法看绝对值/量级/AA、老板看相对%，缺一不可）。**出报告必留案底**：报告同目录伴生 `<报告名>-repro.md`（不放 tmp），含 SQL 全文 + 分析口径 + 整理后的分析 prompt，确保可复现（见 report-skeleton"案底/复现档"硬规则）。
6. **快照纪律**：所有数字带时间窗；引用定律台账（`references/laws.md`）做初始假设前，先核对失效条件，快照类条目过期先重验。
7. **反直觉必深挖**：结论反直觉、或将驱动大决策、或证据脆弱（单日/单源/单口径/相关非因果）时，强制执行"多想一层、多验一层"——穷举对手解释 → 各配能证伪的判别检验 → 落到硬通货（绝对值/多日+CI/多口径/因果）→ 预演老板会问的最狠问题。任一假象类未排除则结论降级"未坐实"。见 `references/laws.md` 的"反直觉与高挑战面"定律；"降本不掉值"类共动的三闸门落法见 `references/counter-intuitive-drilldown.md`。
8. **AB 人群源选择纪律**：判断实验分流/贯穿时，先分清是在问"完整实验人群"还是"实时事件上实际带到的实验 sign"。
   - **⚠️ 组卡铁律（不只贯穿校验，含指标读数）**：计划卡 `time_window` = **今天 / 实时 / intraday / 当日小时**时，数据源**必须**写 unified order（`mp_paidads.dwd_unified_order_event_hi__reg_s0_live`，券消耗）+ ReportNG 小时表（`mkplpaidads_data.dwd_advertise_tracking_item_hi__reg_s0_live`，曝光/rev/advv），分桶用 ab_sign token 匹配。**绝不把"今天"指向 ClickHouse P0（`_1d`）或 perf 表（`_di`）——这俩天级 T+1，没有当日数据。** 满日/历史才用 ClickHouse/perf/分流日志。详见 `references/data-sources.md` §2.1。
   - **用 AB 分流表**：离线/日级/历史 readout、完整用户桶定义、满日效果评估、跨表归因基准、或需要确认某个 `userid` 理论上属于哪个实验组时，优先用 AB 分流表（如 `srdi_mart.dim_sr_data_warehouse_abtest_user_group`）。前提是目标日期分区已产出且覆盖所需 region/date/layer/group；它回答"用户被分到哪里"。
   - **用业务表 `ab_sign`**：当用户明确说"实时数据"、"今天"、"local hour 选今天"、ReportNG / unified order / tracking item 等当日小时表，或 AB 分流表目标日期为空/滞后时，用对应实时业务表里的 `ab_sign` 做事件侧校验。它回答"这条事件实际带了哪些实验 sign"，不等价于完整实验人群。
   - **实时贯穿校验口径**：按 region + grass_date + local hour/h + 业务事件范围过滤后，使用 token 匹配 `strpos(ab_sign, '|<group_id>|') > 0`，不要用裸 `LIKE '%700837%'` 这类数字子串匹配；比较贯穿时先聚合 `distinct userid`，再看 A/B 两组 user set 的 `both / only_a / only_b`。
   - **解释 only-side**：`ab_sign` 的 only 用户通常说明某条业务链路/事件类型只打到了其中一层 sign，可能是实时链路覆盖差异、FE/BE sign 传递差异、某类事件未经过新层，而不是天然等同于回流订单或转化回流；必须再按 `operation/operation_desc/bz_type/ads_entrance/source table` 拆开验证。

## 1. 三种入口/Entry Modes

| 入口 | 用户怎么说 | 怎么接 |
|---|---|---|
| 引导式（默认） | "帮我分析下 MY 实验怎么样"（模糊表达） | 复述理解 → 预填五轴+口径 → 一张计划卡一次确认 |
| 直通式（熟手） | `/ads-roi3-analysis 评估 发多少 695008 MY 近7天 broad_gmv` | 参数顺序不限，能识别就填卡，只确认缺失项 |
| 场景词（高频） | "实验 readout" "日报" "边际还有空间吗" | 直接命中注册表格子，跳过轴选择 |

## 2. 工作流/Workflow

### Step 1 解析与预填

从用户表达抽取五轴并预填，缺省规则：

| 字段 | 缺省 |
|---|---|
| ① 问题类型 | 读数（出现"为什么"→诊断；"有没有效/谁更优"→评估；"什么关系"→探索；"调到多少"→决策；"对得上吗"→校验） |
| ② 决策杠杆 | 发多少 |
| ③ 链路层 | 效果指标层（诊断/校验类必须显式选） |
| ④ 切分维度 | region |
| ⑤ 证据来源 | 提到实验/桶号→AB 实验；否则观测对比 |
| 时间窗 | 近 7 个满日（数据滞后约 2 小时，当日不算满日） |
| 受众 | 自己（全量版报告） |

初始假设从定律台账（`references/laws.md`）起草（快照类标"待重验"）；历史计划卡在 `docs/personal/<user>/roi3/plan-cards/` 下，可参考同类分析的取值。

### Step 2 匹配格子

读 `references/routing-matrix.yaml`，按（问题类型 × 杠杆/链路层 × 证据）匹配 entry：

- 命中唯一 entry → 直接进 Step 3。
- 命中多个 → 菜单让用户选，每个选项标三件事：**成熟度**（全自动 skill / 半自动 playbook / 手工）、**预计耗时**（分钟级/小时级）、**产出物**。
- 无命中 → 走 `manual-fallback` 兜底（ads-text2da + 报告骨架），并提示该格子尚无成熟方法。

### Step 3 计划卡一次确认

按 `references/plan-card.schema.yaml` 生成计划卡；可从 `references/plan-card.template.yaml` 复制起草，并用 `uv run scripts/validate_plan_card.py <plan-card.yaml>` 做必填字段/枚举自检。一屏展示（决策、问题、五轴、scope、口径、输出、预计耗时），用 AskUserQuestion 给选项：**按卡执行 / 改口径 / 改 scope / 换格子**。流程分级（设计蓝本 §5.1）决定是否附加假设与反证、事实底座、子分析剪枝、中期节点字段。

确认后计划卡落盘：`docs/personal/<user>/roi3/plan-cards/<YYYYMMDD>-<slug>.yaml`（断了凭卡续跑）。

### Step 4 前置自检

执行 entry 的 `preflight_checks`（实验桶映射是否确认、表是否满日、口径是否锁定）。不过 → 报原因 + 给降级选项，不带病执行。

### Step 5 分发执行

计划卡确认并落盘后，用 **Agent 工具**把执行段派给 `ads-roi3-analysis-runner`（`subagent_type: ads-roi3-analysis-runner`），prompt 传**已确认计划卡的路径 + 内容**。runner 自主完成 preflight → 路由（读 routing-matrix.yaml）→ 内联调 spoke（skill/playbook/手工三档）→ 合成 → 出报告 + `-repro.md` 案底，回传**结论速览 + 报告路径**。

- runner **不与用户交互、不再派子代理**；它降级/失败会在回传里明说，hub 据此决定是否让用户改卡重跑。
- 多 spoke 合成当前由 runner **串行**内联（真并行 + 完成闸门见 agent 化方案第 2 步：把成熟 spoke 抽成独立 agent、dispatch 放回 hub）。
- runner 须经 `sra add` 安装到 `~/.claude/agents/` 才能被 `subagent_type` 解析；**未安装时降级**为旧版"hub 内用 Skill 工具直接内联调 spoke"（`maturity: skill` → Skill 调 entrypoint；`playbook` → 按方法论文档逐步执行、ads-text2da 跑数；`手工` → ads-text2da + 报告骨架）。
- 完整方案与迁移路径见 `docs/personal/roger.li/roi3/planning/roi3-分析-agent化方案-2026-06-25.md`。

完整流程在计划卡 `checkpoints` 节点回贴方向性中读（一句话+关键数字），用户可就地纠偏（改卡重跑 = 改派给 runner 的 prompt）。

### Step 6 收尾

1. **结论速览贴在会话里**（数字打头、方向判断），不是只给文件路径。
2. 报告归档到计划卡 `output.archive_path`——**ROI3 分析报告强制按"一分析一中文文件夹"归档**：`docs/personal/<user>/roi3/experiments/<中文分析事项>-<YYYYMMDD>/`，内含主报告 `<中文报告名>-<YYYYMMDD>.md` + 伴生 `-repro.md`，多版/多角度报告放同一文件夹（详见 `references/report-skeleton.md`"归档结构与命名"）。**组卡时 `output.archive_path` 就填到这个中文文件夹层**，别再用 experiments/ 根目录平铺或英文 slug。`<user>` = 会话当前用户；skill 能力资产仍在本 skill `references/` 内，不进个人目录。
3. **沉淀提示**（一句话，不打断）：新口径 → 写入 `references/data-sources.md`；新实验桶映射 → 写入 spoke 的 experiment-contracts；同一格子第 2 次手工 → 建议升级为 playbook/skill；新发现或被推翻的信念 → 提醒更新定律台账。

## 3. 计划卡与注册表/Contracts

- 计划卡 schema：`references/plan-card.schema.yaml`（含示例卡）；模板：`references/plan-card.template.yaml`；校验：`scripts/validate_plan_card.py`。
- 路由注册表：`references/routing-matrix.yaml`。**新增能力 = 加一条 yaml entry，本文件零改动。** 巡检：`scripts/audit_routing_matrix.py`。
- 数据源与口径权威索引：`references/data-sources.md`（只索引+落地快照，不复制 datamap）。

## 4. 失败与降级/Failure & Fallback

按注册表 entry 的 `known_failures` 处理：查询超时 → 缩 region/缩时间窗/串行重试；表滞后 → 回退到最近满日；spoke 不可用 → 降级 playbook 或手工兜底。每次降级都明说，并把新发现的坑回写进注册表 entry 的 `known_failures`。
