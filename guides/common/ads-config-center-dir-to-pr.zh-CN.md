# Config Center 目录转发布单（ads-config-center-dir-to-pr）使用指南

> **语言**：[English](ads-config-center-dir-to-pr.md) | [中文](ads-config-center-dir-to-pr.zh-CN.md)

把本地目录中的 JSON 文件，或 Git 仓库指定目录中的 JSON 文件，转换成 Config Center `create-pr --from-file` 草稿，并通过 `sp-config-center` 创建发布单。

**唤醒词**：「Config Center」、「create PR from directory」、「目录生成PR」、「from_file」、「本地配置生成发布单」、「git 目录生成发布单」、「config publish request」、「目录转 draft」、「create config pr」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义和使用流程 |
| `scripts/create_pr_from_dir.py` | 扫描本地或 Git 目录中的 JSON、生成按 zone 分组的草稿，并调用 `sp-config-center create-pr` 的脚本 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| `uv` | 工具 | 运行辅助脚本 |
| `space.bearer_token` | 凭证 | 访问 Config Center API |
| `sra-toolkit/skills/sp-config-center` | Skill 依赖 | 提供底层 `create-pr` CLI 能力 |

**要求 `sp-config-center` 具备以下能力**：
- 支持多 zone `create-pr`
- 支持按 zone 分组的 `--from-file` 顶层结构，例如 `global` / `latam`

如果最近更新过 `sra-toolkit`，使用本 skill 前请先刷新 `.tooling/skills`。

---

## 使用场景

### 场景 1：从本地目录预览生成的草稿

> 「先把这个目录生成草稿给我看看」

推荐先跑 `--dry-run`：

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --input-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --dry-run
```

脚本会：
1. 读取 namespace 各个 zone 的当前配置
2. 扫描 `input_dir` 第一层直接包含的 `*.json`
3. 用文件名去掉 `.json` 后的部分作为 Config Center key
4. 跳过 `--exclude-keys` 中列出的 key
5. 生成按 zone 分组的 `from_file` 草稿
6. 打印摘要和草稿文件路径

### 场景 2：从本地目录直接创建 live 发布单

> 「用这个目录直接创建 Config Center PR」

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --input-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --yes \
  --yes-live
```

这个命令会通过 `sp-config-center create-pr` 创建发布单。

### 场景 3：把导出的 Config Center 文件再转回发布草稿

> 「把之前从 Config Center 导出的文件目录重新转成发布草稿」

这个 skill 很适合和 `ads-config-center-compare-export` 配合：
- `ads-config-center-compare-export` 负责把 Config Center 配置按 item 导出成文件
- `ads-config-center-dir-to-pr` 负责把这个目录重新组装成按 zone 分组的草稿并创建 PR

### 场景 4：从 Git 仓库目录预览生成的草稿

> 「拉这个 repo 的指定目录，用里面的 JSON 文件生成草稿给我看看」

使用 `--git-repo`、`--git-ref`、`--git-path` 代替 `--input-dir`：

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --git-repo gitlab@git.garena.com:shopee/deep/paidads-bidding/ultrav-core-timewindow.git \
  --git-ref master \
  --git-path agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --dry-run
```

Git 输入模式下，脚本会把指定目录物化到 `/tmp`，打印解析出的 commit SHA，并在真正创建发布单时自动把 Git 来源信息追加到 description。

### 场景 5：从 Git 仓库目录创建 live 发布单

> 「拉这个 repo 的指定目录，用里面的 JSON 文件创建 Config Center live 发布单」

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-dir-to-pr/scripts/create_pr_from_dir.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --strategy-id 670 \
  --title "sync product_ads configs" \
  --git-repo gitlab@git.garena.com:shopee/deep/paidads-bidding/ultrav-core-timewindow.git \
  --git-ref master \
  --git-path agent_exp_configs/product_ads \
  --exclude-keys aggregation_config,group_key,metric_info \
  --yes \
  --yes-live
```

创建 live 发布单时必须带 `--yes-live`。如果没带，脚本会生成 draft，但会拒绝创建 live 发布单。

---

## 草稿生成规则

- 一个输入文件对应一个 Config Center 配置项。
- 只处理第一层的 `*.json` 文件；不会递归扫描子目录。
- 隐藏文件会被忽略。
- 文件名 stem 出现在 `--exclude-keys` 中的文件会被跳过。
- 同一份输入文件内容会作用到所有 zone。
- 脚本会自动把结果包成 **按 zone 分组** 的草稿。
- Git 输入会物化到 `/tmp`，且当 `--git-path` 不是 `.` 时使用 sparse checkout。
- `--input-dir` 不能和 Git 来源参数混用。
- Git 来源模式必须同时提供 `--git-repo`、`--git-ref`、`--git-path`。
- 生成的 draft 是增量模式：输入目录中的文件会新增或更新 item，但远端存在、输入目录中不存在的 item 会被保留。

生成出的 `from_file` 结构如下：

```json
{
  "global": {
    "config_key": {
      "type": "JSON",
      "text_value": "{...}",
      "sensitive": false
    }
  },
  "latam": {
    "config_key": {
      "type": "JSON",
      "text_value": "{...}",
      "sensitive": false
    }
  }
}
```

对每个 zone：
- 如果 key 在线上已存在，就复用该 zone 当前的 `type` 和 `sensitive`
- 如果 key 在线上不存在，就回退到 `--default-type` 和 `sensitive=false`
- 如果所有文件都被排除了，脚本会直接报错，不会生成空草稿

---

## 输出内容

脚本运行时会打印：
- 包含 project / namespace / env / strategy / excluded keys（如果传了）/ 草稿规模的摘要
- 生成的 draft 文件路径
- 如果使用 Git 输入，会打印已脱敏的 repo URL、请求的 ref、解析出的 commit、repo 内目录和物化目录

在 `--dry-run` 模式下：
- 不会创建 PR
- 会打印 draft keys 供检查

在真正创建模式下：
- 脚本会调用 `sp-config-center create-pr`
- 成功后打印 PR id 和 status

---

## 注意事项

- 这个 skill 的语义是：**一个目录 = 所有 zone 使用同样的本地内容**。
- 如果不希望把 `aggregation_config`、`group_key`、`metric_info` 带进草稿，可使用 `--exclude-keys aggregation_config,group_key,metric_info`。
- 如果你需要不同 zone 使用不同内容，请直接手写按 zone 分组的 `from_file`，然后调用 `sp-config-center create-pr`。
- 在 live 环境下，强烈建议先跑 `--dry-run`。
- 创建 live 发布单时必须带 `--yes-live`；否则脚本会生成 draft，但会拒绝创建 live 发布单。
- 生成的 draft 文件会保留在本地，并打印路径，便于调试。
- Git 来源建议优先使用 SSH URL 或本地 git credential。如果 HTTPS URL 中包含凭证，summary 会自动脱敏。
- 这个 skill 不会直接访问 `config.shopee.io`，而是复用 `sp-config-center`。

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `ads-config-center-compare-export` | 比较不同 zone 的配置并导出为本地 JSON 文件 |
| `sp-config-center` | 查询配置、创建 PR、approve、publish、close、revert |
