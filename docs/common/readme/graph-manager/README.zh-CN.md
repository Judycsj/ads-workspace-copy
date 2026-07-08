<!-- ads-workspace-gdoc-sync: gdoc_id=1JsXgzwtHmPeQ0eW7-d634ZTQazOsgKT5V1tWv9G3Qh8 gdoc_url=https://docs.google.com/document/d/1JsXgzwtHmPeQ0eW7-d634ZTQazOsgKT5V1tWv9G3Qh8/edit -->

# Graph Manager

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

Graph Manager 是一个用于查看、编辑和校验 Ads DAG 图配置的轻量工具，线上入口为 `https://graphmanager.shopee.io`。仓库同时包含两部分能力：

- 基于 Streamlit 的 Web 界面，用于加载 `graph-manager-conf` 中的 `opdef` 与 graph YAML，调用本地 `bin/tool` 渲染 SVG，并支持导出 PNG。
- 基于 Go 的 SDK，用于从本地 `graph-manager-conf/config.yaml` 读取指定服务与图配置，或从 Redis 读取调试用 graph 内容。

仓库远端为 `https://git.garena.com/shopee/deep/searchads/graph-manager`，依赖的图配置仓库和渲染工具仓库分别在脚本中固定为 `graph-manager-conf` 和 `graph-engine`。

## 核心功能

- 在 Web 页面中按 `service` 和 `graph` 选择图配置，并支持通过 URL query 参数回填选择状态。
- 使用 `streamlit-ace` 在线编辑 `opdef` 和 graph YAML。
- 调用 `./bin/tool draw` 生成 DAG SVG，支持方向切换和 `--check` 校验模式。
- 将生成后的 SVG 转换为 PNG 并提供下载。
- 提供跳转到 `graph-manager-conf` GitLab 编辑页的入口，便于手动提交 Merge Request。
- 提供 Go SDK `GetGraph(service, graph)`，直接从本地配置目录读取图内容。
- 提供 Go SDK `GetGraphDebug(service, graph, key)`，从 Redis 读取调试图，并上报 Prometheus 计数器。
- 支持通过 `?maintain=upgrade` 或首次启动时执行升级流程，拉取依赖仓库并重新编译工具。

## 项目架构

整体架构由以下组件组成：

- `app.py`：Streamlit 应用入口，负责页面布局、配置读取、编辑器渲染、图生成、PNG 导出和维护模式控制。
- `bin/tool`：由 `graph-engine/tool` 编译得到的本地可执行文件，实际执行 DAG 绘图和校验。
- `graph-manager-conf`：运行时依赖的外部仓库，提供 `config.yaml`、`opdef` 文件和各 graph YAML 文件；Web 界面和 Go SDK 都从这里读取配置。
- `graph_manager.go`：Go SDK，封装本地配置读取和 Redis 调试读取逻辑。
- `exporter.go`：注册 `paidads_graph_manager_debug_conf_counter` Prometheus CounterVec，标签为 `service`、`graph`、`key`。
- Redis：`GetGraphDebug` 固定连接 `s1bij.elasticredis.cloud.shopee.io:9854`，读取键名 `service-graph-key` 对应的调试配置。
- GitLab：页面中的 Merge Request 按钮会跳转到 `graph-manager-conf` 仓库对应文件的在线编辑页；升级脚本也通过 Git 拉取三个仓库的最新代码。

交互关系如下：

1. 用户在 Streamlit 页面选择服务与图后，`app.py` 从 `graph-manager-conf/config.yaml` 找到目标 `opdef` 和 graph 文件。
2. 页面将编辑后的 YAML 写入临时目录，调用 `./bin/tool draw` 生成 SVG 和日志。
3. 若生成成功，页面展示 SVG，并通过 `cairosvg` 与 Pillow 导出 PNG。
4. 若使用 Go SDK 的调试接口，程序会访问 Redis 读取调试图，同时把访问次数记录到 Prometheus 指标。

## 目录结构

```text
.
├── app.py
├── exporter.go
├── graph_manager.go
├── go.mod
├── go.sum
├── requirements.txt
├── script/
│   └── upgrade.sh
└── doc/
    ├── allow.png
    └── img.png
```

- `app.py`：Web 应用入口。
- `graph_manager.go`：Go SDK 与调试读取逻辑。
- `exporter.go`：Prometheus 指标注册。
- `script/upgrade.sh`：升级、拉取依赖仓库、编译工具的脚本。
- `doc/`：界面截图资源。

## 开发规范

### 代码风格

- Python 代码以脚本式组织，直接在 `__main__` 中启动 Streamlit 应用。
- Go 代码统一放在 `graphmanager` package 中，对外暴露 `GetGraph` 和 `GetGraphDebug`。
- YAML 是图配置的核心格式，编辑与读取逻辑都围绕 YAML 文件展开。

### 项目结构

- 当前仓库只包含 UI、SDK 和升级脚本，不内置 `graph-manager-conf` 与 `graph-engine` 源码。
- 运行时目录依赖由 `script/upgrade.sh` 拉取到仓库根目录下。
- Web 页面与 Go SDK 共享 `graph-manager-conf` 目录作为配置源。

### 命名规范

- 服务名与图名来自 `graph-manager-conf/config.yaml` 中的 `name` 字段。
- Redis 调试键格式固定为 `service-graph-key`。
- Prometheus 指标命名为 `paidads_graph_manager_debug_conf_counter`。

### 错误处理

- Web 侧主要通过 Streamlit 的 `st.error`、`st.stop` 和提示消息展示错误。
- `GetGraph` 和 `GetGraphDebug` 在关键初始化失败时会 `panic`，例如配置文件缺失、YAML 解析失败或 Redis 连通性异常。
- 图渲染阶段把 `tool draw` 的标准输出写入临时日志文件，再回显到页面。

### 单元测试

- 仓库中当前没有测试文件，也没有 `go test` 或 Python 测试入口。
- 现有校验方式主要依赖页面中的 `OpDef Check / 校验` 选项以及图渲染结果。

### Code Review & Git Workflow

- 页面提供了直接跳转到 `graph-manager-conf` 在线编辑页面的按钮，当前流程偏向“在页面修改后手动复制到 GitLab 并提交 MR”。
- `script/upgrade.sh` 会对依赖仓库执行 `git fetch` 和 `git reset --hard`，适合部署环境同步最新代码，不适合作为本地未提交修改的工作流。

## 配置说明

### 配置文件

运行这个项目至少需要以下文件或目录：

- `requirements.txt`：Python 依赖，包括 `streamlit`、`streamlit-ace`、`pyyaml`、`redis`、`cairosvg`。
- `go.mod`：Go 依赖，包括 `github.com/go-redis/redis/v8`、`github.com/prometheus/client_golang`、`gopkg.in/yaml.v3`。
- `graph-manager-conf/config.yaml`：服务列表入口，定义每个服务关联的 `opdef` 和 graph 文件。
- `graph-manager-conf/<path>`：具体的 `opdef` 与 graph YAML 文件。
- `bin/tool`：由 `graph-engine/tool` 编译出的绘图工具。
- `.maintain`：维护模式标记文件，存在时页面会直接停止服务并显示维护中。

### SPEX 与 spcli 配置

仓库代码中没有发现 SPEX SDK、spcli 命令或相关配置文件，当前项目的启动、升级和发布流程都不依赖 SPEX 或 spcli。与外部系统的实际集成方式主要是：

- 通过 Git 拉取 `graph-manager-conf` 与 `graph-engine`。
- 通过 GitLab 在线编辑页提交配置变更。
- 通过 Redis 读取调试图配置。

## 部署

### 生产构建

本地启动方式以当前 README 和依赖文件为准：

```bash
pip install -r requirements.txt
streamlit run app.py
```

首次启动或需要升级时，应用会触发以下流程：

```bash
bash script/upgrade.sh
```

该脚本会执行：

- 创建 `.maintain`，阻止并发访问。
- 更新当前仓库代码。
- 安装 Python 依赖。
- 克隆或更新 `graph-manager-conf`。
- 克隆或更新 `graph-engine`，在 `graph-engine/tool` 下执行 `go build .`。
- 将生成的 `tool` 复制到 `bin/tool`。
- 删除 `.maintain`。

### 发布流程

仓库中没有找到独立的发布平台配置、灰度脚本或 SPEX 发布定义。基于代码可以确认的流程只有：

1. 通过 `script/upgrade.sh` 拉取当前仓库、`graph-manager-conf` 和 `graph-engine` 的最新代码。
2. 重新构建 `graph-engine/tool` 并替换本地 `bin/tool`。
3. Web 页面支持通过 `?maintain=upgrade` 触发同一套升级流程。

仓库中没有记录灰度发布策略；如果线上环境存在灰度能力，当前仓库未提供对应实现或说明。

## 监控

代码中已实现的监控能力只有一个 Prometheus 计数器：

- 指标名：`paidads_graph_manager_debug_conf_counter`
- 类型：`CounterVec`
- 标签：`service`、`graph`、`key`
- 用途：统计 `GetGraphDebug` 被调用的次数

仓库中没有监控大盘链接、告警规则文件或告警阈值定义，因此 README 不扩展未在代码中出现的监控信息。

## 业务术语表

- Graph：某个服务下的一份 DAG 图配置，在 `config.yaml` 中由 `graphs[].name` 标识。
- OpDef：Operator Definition，对应某个服务的算子定义 YAML。
- Service：图配置所属业务服务，在 `config.yaml` 中由顶层 `name` 标识。
- Debug Graph：写入 Redis、通过 `GetGraphDebug` 读取的临时调试配置，仅用于调试。
- Direction：绘图方向，页面中支持 `TB`、`LR`、`RL`、`BT`。

## 参考资料

- 在线入口：`https://graphmanager.shopee.io`
- 图配置说明 Wiki：`https://git.garena.com/shopee/deep/searchads/graph-manager/-/wikis/How-to-define-graph-conf`
- 召回队列命名表：`https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk`
- 仓库地址：`https://git.garena.com/shopee/deep/searchads/graph-manager`
- 配置仓库：`https://git.garena.com/shopee/deep/searchads/graph-manager-conf`
- 绘图工具来源仓库：`gitlab@git.garena.com:shopee/deep/searchads/graph-engine.git`

## 常见问题

### 1. 启动页面前最少需要准备什么？

需要先安装 `requirements.txt` 里的 Python 依赖，并确保仓库根目录下存在 `graph-manager-conf` 和 `bin/tool`。如果这两个目录或文件不存在，可以执行 `bash script/upgrade.sh`。

### 2. 页面里的配置来自哪里？

服务列表、`opdef` 路径和 graph 路径都来自 `graph-manager-conf/config.yaml`，实际内容文件也都从 `graph-manager-conf` 目录读取。

### 3. 页面上修改 YAML 后会自动提交到仓库吗？

不会。页面只负责编辑和预览，提交方式是点击 Merge Request 按钮跳到 GitLab 在线编辑页，再手动粘贴内容并提交 MR。

### 4. `OpDef Check / 校验` 做了什么？

它会在执行 `./bin/tool draw` 时额外带上 `--check` 参数，用于在生成图时做额外校验。

### 5. `GetGraph` 和 `GetGraphDebug` 有什么区别？

`GetGraph` 从本地文件系统读取正式配置；`GetGraphDebug` 从 Redis 读取调试配置，适合临时验证，不会修改正式文件。

### 6. 调试图数据存在哪里？

调试图读取自 Redis `s1bij.elasticredis.cloud.shopee.io:9854`，键名格式为 `service-graph-key`。

### 7. 为什么 README 没有写更完整的部署平台或监控大盘？

因为当前仓库里没有对应配置或文档引用。这里仅记录代码中能验证的启动、升级和监控信息。

### 8. 维护模式如何触发？

当仓库根目录存在 `.maintain` 文件时，页面会直接提示 `Under maintenance` 并停止；升级脚本会在执行期间创建这个文件。

### 9. 为什么升级脚本风险比较高？

因为它会对当前仓库、`graph-manager-conf` 和 `graph-engine` 执行 `git reset --hard`，会覆盖未提交修改。

### 10. PNG 下载是怎么生成的？

页面先生成 SVG，再通过 `cairosvg.svg2png` 转成 PNG，最后用 Streamlit 的下载按钮返回给用户。

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
