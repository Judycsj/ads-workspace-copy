# Epic 项目评审的证据与 KB 加载规则

这个参考文件用来说明：做 Ads OKR Epic TD review 时，应该加载多少知识才够。目标不是把 review 做成 repo audit、数据 audit 或实现 review，而是用最小必要知识判断 Epic 的结构、定义、逻辑链路、交付物、指标设计、验证计划和节奏是否站得住。

不需要证明具体 baseline 数字、离线 replay 结果、精确数据字段或最终阈值。需要检查的是：Epic 有没有把这些事情的统计方式、分析方向或验证思路讲清楚。

默认评审范围只有元信息和第一、二、三章。第四章 `TRD 文档列表` 和第五章 `KP 执行与状态` 在这个 skill 里属于执行附录：不用于打分，也默认不顺着里面的链接继续读。

## 目标定位

### 本地文件路径

如果用户给的是文件路径：

1. 确认文件存在。
2. 优先使用名为 `epic-file.md` 的文件。
3. 如果是另一个 Markdown 文件，只有在用户意图明确时才当成目标 Epic 继续。

### KP 标识

如果用户给的是 `O1-KR1-KP1` 这类 KP 标识：

1. 匹配时忽略大小写。
2. 在 `docs/team/00.paid-ads-dev/10.trd-prd-td-list/` 下搜索。
3. 匹配目录名、文件名和 Epic 标题。
4. 如果只有一个目标，直接使用。
5. 如果有多个匹配文件，列出候选路径，让用户选择。

建议命令：

```bash
find docs/team/00.paid-ads-dev/10.trd-prd-td-list -path "*/epic-file.md" -print | rg -i "o1|kr1|kp1"
```

把最后的匹配词替换成实际 objective、KR 和 KP。

### GitLab Tree URL

如果用户给的是 GitLab tree URL：

1. 把仓库根路径 `https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/tree/master/` 映射到本地 `ads-workspace/` 根目录。
2. 保留 `master/` 后面的路径后缀。
3. 把映射后的本地路径当成目录或文件目标。
4. 如果本地路径不存在，说明情况，并请用户提供本地路径或更新 checkout。

### 目录输入

如果用户给的是目录：

1. 使用批量模式。
2. 在目录下找主 Epic 文件。
3. 优先使用 `epic-file.md`；如果当前 OKR 目录是一份 KP 一个 Markdown 文件，就直接读这些 KP Markdown。
4. 默认不要读取兄弟目录里的 `resource/`、CSV、xlsx、图片或外部平台数据。

建议命令：

```bash
find docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1 -name "*.md" -print | sort
```

## 加载顺序

按下面顺序加载知识：

1. 读取主 Epic TD 文件。
2. 读取元信息或第一、二、三章明确链接或引用的文件。
3. 只有当同目录上下文能解释目标 Epic 的元信息或第一、二、三章时，才读取同目录材料，例如 `MEMORY.md`、兄弟 overview 文档或被引用的 TD 文件。
4. 通过 index、README 或清楚命名的入口文件读取相关 `master/docs/common` 知识，使用最小有用集合。
5. 使用 `master/skills/common` 下相关只读 skill，例如 `ads-kb`、Confluence 知识查询、Ads knowledge QA、实验分析参考、rollout 参考、表/指标知识 helper 等，用来解释 Epic 依赖的概念。
6. 当已加载知识足够判断定义、业务链路、指标设计、验证方法和 KB 冲突时，就停止。

不要读取整个 Ads 文档树。用 Epic 核心范围里的明确术语收窄检索。除非用户明确要求执行、rollout 或进展 review，否则忽略第四章 TRD 链接和第五章状态表链接。

## 从 Epic 抽取什么

先抽事实，再做判断：

- 元信息：`KP Title`、`KP Type`、`Why Do`、`Deliverable`、`pic`，以及存在时的 owner 和日期字段。
- 第一、二、三章里的问题陈述和为什么现在做。
- 第一、二、三章里的 KA 列表、宣称交付物、验收标准和非目标。
- 第一、二、三章里的业务指标、技术指标、验证计划、分析计划、实验设计、rollout 判断或 go/no-go 规则。
- 第一、二、三章里的节奏、阶段顺序、验证 cadence、gate、风险和 open question。
- 第一、二、三章里的关键术语、缩写、系统名、表名、指标名、策略名和引用文档。
- 如果某个 KA 的交付物是 skill：这个 skill 做什么用、谁来用、解决什么问题、大致输入/输出是什么，以及它帮助使用者做出什么判断或完成什么工作流。

如果某个字段缺失，记为 `未明确`；不要从附近文档脑补，除非 Epic 明确引用了那个来源。

## KB 用来做什么

KB 和只读 skill 用来：

- 判断关键 Ads 概念是否被正确命名和使用。
- 当 Epic 没定义关键名词时，查找定义。
- 检查 Epic 的业务链路和指标方向是否和已知 Ads 知识冲突。
- 判断 Epic 提出的证据补充或统计方式是否合理。
- 识别是否应该交给某个领域专门 skill 做更深入评审。

KB 的使用停留在概念层级。如果 target ROI、ADVV、GMV、ROAS、achievement rate 这类术语已经是 Ads 已知概念，并且 Epic 使用一致，不要要求 Epic 写出物理表、读取字段、单位或缺失字段行为。只有当 Epic 在定义新指标、改变数据契约，或者没有这些信息就无法理解概念时，才要求这些细节。

相关来源包括：

- `docs/common/**`，尤其是 index、README、Ads introduction、metric、experiment、rollout 和 domain glossary 文件。
- `docs/team/**`，但只在用 Epic 术语定向搜索并命中明显相关文档时使用。
- `skills/common/ads-kb`，用于 Ads 业务或指标概念。
- 本地文档不足且任务仍然只读时，可以用 Confluence 或 Ads knowledge QA skill。
- 当 Epic 依赖实验、rollout、表、指标、Kafka 或平台概念时，使用对应知识 skill。

## KB 不用来做什么

不要因为加载了 KB，就要求 Epic 必须已经提供：

- 精确 baseline 数值。
- 离线 replay 结果。
- 后续数据分析会决定的精确阈值。
- 已有概念的物理读取字段、表字段、精确单位或字段 owner。
- 已完成的实验结果。
- 贴在 Epic 里的具体证据数据。
- 源代码、SQL 正确性、模型公式或算法实现细节 review。
- 大型 `resource/`、CSV、xlsx、图片或外部平台数据。
- 完整的第四章 `TRD 文档列表` 或第五章 `KP 执行与状态`。

## 建议搜索方式

从 Epic 里的词开始：

- KP 标题词。
- 系统名，例如 `bid2x`、`MPC`、`ROI3`、`Graph Indexer`、`bidding_store`、`ultrav`。
- 指标名，例如 `ADVV`、`GMV`、`achievement rate`、`PCOC`、`v-profit`、`platform_gmv`。
- 模型、策略、表、label、实验或 rollout 名。

推荐命令：

```bash
rg -n "bid2x|MPC|ADVV|achievement rate" docs/common docs/team -g "*.md"
```

最多做两次宽泛关键词搜索，然后必须收窄。除非确实读取了本地文件或拿到了只读 skill 结果，否则不要声称有 KB 支撑。

## 证据表述

review 中要区分事实和推断：

- `Epic says`：目标 Epic 里直接写出的内容。
- `Evidence says`：实际读取过的附近证据、本地 KB、common skill 结果、SQL 摘要、实验摘要、rollout 文档或平台事实。
- `Reviewer infers`：reviewer 基于 Epic 内容和证据做出的推断。

单文件深度 review 时，如果证据或 KB log 有助于用户理解某个定义或链路判断，可以附一个简短 log。不要把 review 写成原始证据 dump。

建议 log 形态：

```markdown
| 类型 | 来源 | 查询词 / 目标 | 命中内容 | 对本 review 的作用 | 缺口 |
| --- | --- | --- | --- | --- | --- |
```

## 应该报告的证据缺口

以下情况要报告缺口：

- 关键术语在 Epic 中未定义，KB 中也找不到。
- 问题声明依赖某个事实，但 Epic 没解释如何衡量、分析或证明。
- 某个 KA 没有人类可观察的交付物。
- 某个 KA 的交付物是 skill，但 Epic 没说明这个 skill 做什么用、谁来用、解决什么问题。
- 功能或代码类交付物没有技术指标证明它 work。
- 分析报告或实验设计类交付物没有分析方向或实验设计大纲。
- 业务指标和声明的业务目标不一致。
- Epic 和 KB 的定义、指标含义或业务链路冲突。
- 第一、二、三章声称有阶段交付、rollout 或验证，但没有解释顺序、gate、cadence 或决策规则。
- 引用文档本地不存在，或相关只读 skill 无法访问。

不要因为 Epic 有具体数值占位符就报告缺口，只要它同时说明了分析维度和后续决策方式。例如：“连续下降次数 TBD，用历史样本分布确定”或“低 coef 持续时间后续按 region 分析”在 Epic TD 粒度是可以接受的。

不要只因为下面这些情况就报严重缺口：

- 缺精确 baseline 数字。
- 缺离线 replay。
- 具体阈值是留给后续数据分析的占位符。
- 已知 Ads 概念缺真实读取字段、单位、表字段或字段 owner。
- 实验还没完成。
- SQL 还没执行。
- 没把具体证据数据贴到 Epic 里。
- 没描述代码实现细节。
- 第四章 TRD 链接、第五章 owner / ETA / effort / status、rollout 记录、关键结论、问题讨论或 next step 缺失或过期。

## 批量模式证据限制

批量模式优先保证跨 KP 对比可读：

- 读取每个主 Epic 或 KP Markdown 文件，但只给元信息和第一、二、三章打分。
- 抽取八项 review 维度。
- 只有当关键定义或业务链路判断依赖 KB 时，才做小范围 `docs/common` 或 `ads-kb` 查询。
- 不检查 `memory/`、`resource/`、CSV、xlsx、图片、第四章 TRD 链接、第五章状态链接或外部引用，除非用户明确要求对某个 KP 做深度 review。
- 表格后用人话解释每个 `Fair`。

## 错误处理

- 文件不存在：请用户提供有效本地路径或更新 checkout。
- KP 标识没有匹配：说明没找到匹配 Epic，并请用户给路径或更大目录。
- KP 标识匹配多个：列出候选并停止。
- 章节缺失：继续 review，对受影响 checklist 项给 `Fair` 或 `Weak`。
- KB 未找到：写 `未找到相关 KB 支撑`。
- 相关 common skill 不可用：把缺失 skill 或被阻塞来源写成缺口。
- 证据太大：说明没有检查，并解释是因为大小或格式边界。
