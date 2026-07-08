# ads-workspace-copy

这是 Shopee Ads `ads-workspace` 的一个精简私有副本。

这份副本不追求还原完整内部开发环境，而是保留了 **workspace 架构**、**基础广告知识库**、**部分 AI-native 工作模块** 和 **个人可复用沉淀**，同时去掉了大部分 `OKR / rollout / TD-PRD 项目过程文档`、本地凭证，以及 `projects/` 下的内部代码仓依赖。

## 这份仓库是用来做什么的

- 理解一个大型 Ads AI workspace 的结构是怎么搭的
- 复用 Shopee Ads 的基础知识、口径和术语体系
- 学习 AI-native 团队工作方式在实践里是怎么组织的
- 作为个人私有参考仓，在未来新公司继续改造复用

## 这份仓库不是什么

- 不是完整的内部生产 workspace
- 不是所有项目文档的全量备份
- 不是 `projects/` 内部代码仓的可运行替代品

## 怎么使用这份仓库

### 1. 先看整体架构

这份仓库最值得学的，不是某一篇文档，而是它按职责拆层，而不是把同一主题堆在一个目录里。

- `docs/`：知识内容
- `guides/`：使用说明和工作规范
- `skills/`：AI skill 和 workflow
- `templates/`：固定输出模板
- `rules/`：共享规则
- `agents/`：agent 角色定义和入口说明

建议先看：
- [docs/README.md](docs/README.md)
- [agents/README.zh-CN.md](agents/README.zh-CN.md)
- [templates/README.zh-CN.md](templates/README.zh-CN.md)

### 2. 把它当作广告知识库来用

最重要的知识入口有这几层：

- [docs/common/core-knowledge](docs/common/core-knowledge)
  广告总览、策略、引擎、平台、数据等高层知识
- [docs/common/datamap](docs/common/datamap)
  数据表、口径、指标映射
- [docs/common/de-knowledge](docs/common/de-knowledge)
  偏指标和 ETL 的知识沉淀
- [docs/common/skill-knowledge](docs/common/skill-knowledge)
  偏 skill 使用和方法的知识沉淀
- [docs/common/sub-kb](docs/common/sub-kb)
  按主题拆分的子知识库
- [docs/team/20.paid-ads-dpm/ads_knowledge_base](docs/team/20.paid-ads-dpm/ads_knowledge_base)
  结构化的 Ads 业务/模块知识库

如果目标是快速建立 Shopee Ads 认知，建议顺序是：
1. `docs/common/core-knowledge`
2. `docs/team/20.paid-ads-dpm/ads_knowledge_base`
3. `docs/common/datamap`

### 3. 把它当作 AI-native workspace 的参考样本

这份副本也保留了足够多的模块，可以看出一个 AI-native 团队是怎么组织 workspace 的。

主要看这几类：

- `skills/common/`
  通用能力，比如知识问答、诊断、SQL/数据分析、实验分析、文档能力、知识库工具链
- `skills/team/...`
  保留了少量 team-level skill，作为真实工作流示例
- `templates/`
  各类固定模板，包括 `OKR`、`case study`、`rollout doc`、`report`、`memory`、`spec`
- `docs/team/09.ads-dev-sharing-session/`
  团队内部关于 AI-native 工作方式的分享材料

建议优先看：
- `skills/common/ads-knowledge-qa`
- `skills/common/ads-biz-diagnose`
- `skills/common/ads-diagnose`
- `skills/common/ads-data-sql-executor`
- `skills/team/04.product-algo/ads-okr-epic-review`
- `skills/team/04.product-algo/ads-roi3-analysis`
- `skills/team/01.ads-engineering/ads-db-viewer`
- `skills/team/02.ads-platform/ads-platform-overview-doc-generate`

### 4. 把它当作个人迁移底座

这份副本也保留了你自己的个人沉淀：

- [docs/personal/shijing.chen](docs/personal/shijing.chen)
- [guides/personal/shijing.chen](guides/personal/shijing.chen)
- `skills/personal/shijing.chen/`（如果有）

这些目录适合长期沉淀：
- 个人规则
- 产品/分析 workflow
- 和 AI 协作的固定方式
- 未来在新公司继续复用的 starter 材料

## 推荐阅读顺序

如果目标是 **理解虾皮广告**：
1. `docs/common/core-knowledge`
2. `docs/team/20.paid-ads-dpm/ads_knowledge_base`
3. `docs/common/datamap`

如果目标是 **理解 AI-native 团队工作方式**：
1. `docs/team/09.ads-dev-sharing-session`
2. `skills/common`
3. `skills/team`
4. `templates`

如果目标是 **为未来新公司搭自己的 workspace**：
1. `docs/personal/shijing.chen`
2. `guides/personal/shijing.chen`
3. `skills/personal/shijing.chen`
4. 再反过来挑 `skills/common` 和 `templates`

## 这份副本保留了什么

这份副本有意保留：
- workspace 的整体架构
- common ads knowledge
- 一部分通用和 team skill
- 一部分 AI-native 分享材料
- `shijing.chen` 的个人沉淀

这份副本有意去掉或不包含：
- 大部分 `OKR / rollout / TD / 项目过程文档`
- 日报、周报、DQC 等运营性材料
- 其他人的 personal 目录
- `projects/*` 下的内部代码仓
- 本地凭证和被 `.gitignore` 排除的产物

## 最值得复用的原则

这份仓库真正值得带走的，不是某个具体文档，而是它的组织方式：

- 先分 `common / team / personal`
- 再分 `knowledge / workflow / skill / template / agent`
- 只长期保留可复用资产，不把临时项目过程堆成主结构

这套结构本身，才是以后去新公司最值得直接复用的东西。
