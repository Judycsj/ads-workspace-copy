<!-- ads-workspace-gdoc-sync: gdoc_id=1a3jG-PodovmV88IwaA4c6xsbUpE3RDuvJnDPDDVLVqo gdoc_url=https://docs.google.com/document/d/1a3jG-PodovmV88IwaA4c6xsbUpE3RDuvJnDPDDVLVqo/edit -->

# Graph Manager Conf

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [开发规范](#开发规范)
- [配置说明](#配置说明)
- [部署](#部署)
- [监控](#监控)
- [业务术语表](#业务术语表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

## 项目概述

`graph-manager-conf` 是 Graph Manager 使用的 DAG 配置仓库，负责集中维护 Ads 相关业务域的算子定义、图定义和注册清单。仓库本身不承载服务运行逻辑，也不包含绘图引擎实现，而是作为配置源被 Graph Manager 页面和相关工具链读取。

基于当前仓库中的 `config.yaml`，项目目前注册了：

- 12 个业务域
- 79 个图配置
- 4 个带 `_DEPRECATED` 后缀的废弃业务域

仓库远端为 `https://git.garena.com/shopee/deep/searchads/graph-manager-conf`。与之直接相关的上游工具仓库是 `https://git.garena.com/shopee/deep/searchads/graph-manager`，后者负责图展示、在线编辑入口和工具升级流程。

## 核心功能

- 以业务域目录为单位维护 `opdef.yaml` 和具体 graph YAML 文件。
- 通过根目录 `config.yaml` 统一注册所有业务域、图路径和默认绘图方向。
- 为 Graph Manager 提供可枚举的服务列表、图列表和图文件路径。
- 通过 `validate.py` 批量遍历图配置并执行 `tool draw --check` 合法性校验。
- 通过 `.gitlab-ci.yml` 在 CI 中复用同一套校验入口。
- 在部分业务域配置中记录对应上游 GitLab 仓库地址，例如 `retrieval` 和 `featureserver`。
- 明确保留废弃目录配置，方便历史 DAG 继续被查询或兼容，但通过 `_DEPRECATED` 标识区分状态。

## 项目架构

仓库由三类核心配置组成：

- 业务域目录：如 `adsengine/`、`retrieval/`、`indexer/`，每个目录通常包含一个 `opdef.yaml` 和若干 graph YAML。
- 根目录注册表 `config.yaml`：声明每个业务域名称、可选 `gitlab` 地址、`opdef` 路径、每个 graph 的文件路径和可选方向。
- 校验脚本 `validate.py`：递归扫描仓库内的 YAML 图文件，调用外部 `tool` 命令做基础检查。

运行关系如下：

1. `config.yaml` 作为统一入口，被 Graph Manager 或其他工具读取，用来展示可选业务域和图。
2. 业务域下的 `opdef.yaml` 描述可用算子接口，具体 graph YAML 描述 DAG 节点与连线关系。
3. `validate.py` 针对每一个非 `opdef.yaml`、非 `config.yaml` 的 YAML 文件，执行 `tool draw --opdef <dir>/opdef.yaml --graph <graph.yaml> --check`。
4. `.gitlab-ci.yml` 只调用 `python3 validate.py`，因此本地校验和 CI 校验共用同一入口。

当前活跃和废弃目录都保留在同一仓库中，状态主要通过 `config.yaml` 中的名字区分，而不是通过目录结构隔离。

## 目录结构

```text
.
├── adsengine/
├── attribution/
├── featureserver/
├── indexer/
├── ohmyemb/
├── prerank/
├── query_understand/
├── relevance/
├── retrieval/
├── searchads/
├── searchadsgear/
├── tracking/
├── config.yaml
├── validate.py
├── README.md
├── README_EN.md
└── .gitlab-ci.yml
```

主要目录与当前注册情况如下：

| 目录 | 当前注册图数 | 说明 |
| --- | ---: | --- |
| `adsengine/` | 21 | Ads Engine 的 recall、info、bid、deduction、unified 流程 |
| `retrieval/` | 16 | 检索、召回与推荐相关 DAG |
| `indexer/` | 16 | 决策、采集、下沉与属性更新流程 |
| `attribution/` | 5 | 归因与 tracking 相关流程 |
| `ohmyemb/` | 3 | Embedding 离线与在线流程 |
| `featureserver/` | 1 | Feature Server 图配置 |
| `query_understand/` | 1 | Query Understand 流程 |
| `tracking/` | 1 | Tracking Runner 流程 |
| `searchads/` | 5 | 废弃的 Search Ads 配置 |
| `prerank/` | 4 | 废弃的 Prerank 配置 |
| `searchadsgear/` | 4 | 废弃的 Search Ads Gear 配置 |
| `relevance/` | 2 | 废弃的 Relevance 配置 |

根目录关键文件：

- `config.yaml`：配置注册入口。
- `validate.py`：本地与 CI 共用的批量校验脚本。
- `.gitlab-ci.yml`：GitLab CI 入口，目前只执行 `python3 validate.py`。
- `README.md` / `README_EN.md`：中英文说明文档。

## 开发规范

### 代码风格

- 仓库核心内容是 YAML 配置，Python 只用于批量校验。
- `config.yaml` 中每个业务域条目都采用统一结构：`name`、可选 `gitlab`、`opdef`、`graphs`。
- graph 文件命名通常直接反映业务含义，例如 `ads_recall_base.yaml`、`tracking_runner.yaml`、`brand_max_retrieval.yaml`。

### 项目结构

- 每个业务域目录通常以一个 `opdef.yaml` 配多个图文件。
- 根目录不再拆分额外层级，所有业务域目录与统一注册表并列。
- 废弃业务域并未从仓库删除，而是继续通过 `_DEPRECATED` 域名注册。

### 命名规范

- 业务域名称由 `config.yaml` 中的顶层 `name` 决定。
- 图名称由 `graphs[].name` 决定，不要求与文件名完全一致，但当前仓库绝大多数保持一致或一一对应。
- 绘图方向由 `graphs[].direction` 控制，当前仓库中可见的取值主要为 `TB` 和 `LR`。
- 废弃业务域统一以 `_DEPRECATED` 后缀标记。

### 错误处理

- `validate.py` 使用 `subprocess.run(..., capture_output=True, text=True)` 调用外部命令，不直接中断单个文件处理。
- 只要某个 graph 的校验命令产生标准输出，就会打印失败信息并把整体状态标记为失败。
- 当至少有一个文件失败时，脚本最终以 `sys.exit(1)` 返回非零退出码。

### 单元测试

- 仓库中没有单元测试框架，也没有 Python 或 YAML 层面的独立测试用例。
- 当前唯一内置质量门禁是 `validate.py` 驱动的图合法性检查。

### Code Review & Git Workflow

- 修改 graph 时通常需要同步考虑 `opdef.yaml`、对应 graph YAML，以及 `config.yaml` 注册信息。
- 新图如果没有注册到 `config.yaml`，Graph Manager 就无法从统一入口发现它。
- CI 足够轻量，意味着评审时应重点检查图定义本身、算子接口兼容性和废弃目录误用风险。

## 配置说明

### 配置文件

仓库的配置体系由以下几类文件组成：

- `config.yaml`：顶层注册表，列出每个业务域的 `opdef` 和 graph 列表。
- `<domain>/opdef.yaml`：业务域级算子定义，供本域图文件引用。
- `<domain>/*.yaml`：具体 graph 文件，描述 DAG 节点、参数、输入输出和依赖关系。
- `validate.py`：遍历所有 graph 文件并执行合法性检查。
- `.gitlab-ci.yml`：将 `validate.py` 接入 GitLab CI。

一个最小注册示例如下：

```yaml
- name: example_domain
  opdef: example_domain/opdef.yaml
  graphs:
    - name: example_graph
      path: example_domain/example_graph.yaml
      direction: LR
```

从当前仓库可验证的字段语义如下：

- `name`：业务域名或图名。
- `gitlab`：可选的关联仓库地址，仅在部分业务域声明。
- `opdef`：业务域算子定义文件路径。
- `path`：graph 文件路径。
- `direction`：可选的绘图方向。

### SPEX 与 spcli 配置

仓库中没有发现 SPEX SDK、spcli 命令、SPEX 发布配置或相关脚本。当前可确认的外部工具依赖只有：

- `tool`：由 `validate.py` 调用的图绘制与校验命令。
- `python3`：用于执行 `validate.py`。
- Graph Manager：作为本仓库配置的主要消费方和展示入口。

## 部署

### 生产构建

这个仓库本身不是独立服务，没有可执行的生产构建产物。基于代码可验证的本地使用方式只有校验：

```bash
python3 validate.py
```

执行前需要确保环境中存在 `tool` 命令，否则校验无法完成。

### 发布流程

仓库中没有部署脚本、镜像构建脚本或服务发布定义。当前可确认的“发布”动作主要是配置提交和校验：

1. 修改业务域下的 `opdef.yaml` 和或 graph YAML。
2. 如新增图，更新 `config.yaml` 注册信息。
3. 本地执行 `python3 validate.py`。
4. 提交到 GitLab，由 `.gitlab-ci.yml` 再执行一次同样的校验。

仓库中没有记录灰度策略或 SPEX 发布流程，因此 README 不扩展未在代码中出现的发布细节。

## 监控

当前仓库中没有监控代码、Prometheus 指标、监控面板链接或告警规则。可观察性能力主要依赖外部系统：

- 本地执行 `validate.py` 时的控制台输出
- GitLab CI 中 `python3 validate.py` 的执行结果
- Graph Manager 页面在加载和展示这些配置时的表现

因此这里不编写无法从仓库中验证的监控信息。

## 业务术语表

- Graph Manager：消费本仓库配置并提供图展示与编辑入口的工具。
- Domain：`config.yaml` 顶层的业务域条目，例如 `adsengine`、`retrieval`。
- OpDef：Operator Definition，定义某个业务域中可用的算子接口。
- Graph：某个业务域下的 DAG 配置文件，对应 `graphs[].name` 和 `graphs[].path`。
- Direction：图展示方向，当前仓库中主要使用 `TB` 和 `LR`。
- Deprecated Domain：名称以 `_DEPRECATED` 结尾的历史业务域，表示该域仍被保留但不建议继续扩展。

## 参考资料

- Graph Manager 仓库：`https://git.garena.com/shopee/deep/searchads/graph-manager`
- 当前仓库地址：`https://git.garena.com/shopee/deep/searchads/graph-manager-conf`
- `retrieval` 关联仓库：`https://git.garena.com/shopee/deep/paidads-recall`
- `featureserver` 关联仓库：`https://git.garena.com/shopee/deep/searchads/feature-server`
- `searchads_DEPRECATED` 关联仓库：`https://git.garena.com/shopee/deep/search-ads/`
- `searchadsgear_DEPRECATED` 关联仓库：`https://git.garena.com/shopee/deep/searchads/search-ads-gear`
- `relevance_DEPRECATED` 关联仓库：`https://git.garena.com/shopee/deep/paidads-relevance`

## 常见问题

### 1. 这个仓库和 `graph-manager` 是什么关系？

`graph-manager-conf` 只负责存储配置，`graph-manager` 负责读取这些配置并提供可视化和编辑入口。

### 2. 一个新图最少需要改哪些文件？

通常至少需要新增或修改所在业务域的 graph YAML；如果用到了新算子，还要改对应 `opdef.yaml`；最后把新图注册到 `config.yaml`。

### 3. 为什么新增了 YAML 文件但在 Graph Manager 里看不到？

最常见原因是没有把它注册到根目录 `config.yaml` 的对应业务域下。

### 4. `validate.py` 会校验哪些文件？

它会递归遍历所有 `.yaml` 文件，但跳过 `opdef.yaml` 和 `config.yaml`，只对具体 graph 文件执行校验。

### 5. 校验失败的判定标准是什么？

当前脚本把 `tool draw --check` 的标准输出视为失败信号，只要有输出就会打印失败信息并最终返回非零状态码。

### 6. 本地执行校验为什么会失败提示找不到 `tool`？

因为 `tool` 不是本仓库自带的文件，而是外部工具链提供的命令。没有这个命令时，`validate.py` 无法正常工作。

### 7. 仓库里为什么保留废弃目录？

因为 `config.yaml` 仍然注册了这些历史业务域，保留它们有助于兼容旧图和历史查询。

### 8. 当前哪些业务域图最多？

从 `config.yaml` 看，`adsengine` 注册了 21 个图，`retrieval` 和 `indexer` 各注册了 16 个图。

### 9. CI 做了哪些检查？

当前 `.gitlab-ci.yml` 只有一个非常轻量的检查，就是运行 `python3 validate.py`。

### 10. 这个仓库有部署或监控配置吗？

没有。它是配置仓库，不是独立服务仓库，当前仓库里没有可验证的部署脚本或监控定义。

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
