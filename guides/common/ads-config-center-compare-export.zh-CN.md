# Config Center 配置比较与导出（ads-config-center-compare-export）使用指南

> **语言**：[English](ads-config-center-compare-export.md) | [中文](ads-config-center-compare-export.zh-CN.md)

比较 Config Center 某个 namespace 在一个或多个 zone 下的最新配置状态；只有在比较结果一致时，才把指定 zone 的配置项导出成本地 JSON 文件。

**唤醒词**：「Config Center」、「compare zones」、「zone compare」、「global latam compare」、「export config」、「compare and export」、「导出配置」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义和使用流程 |
| `scripts/compare_export.py` | 拉取各 zone 最新状态、执行比较并导出按 item 拆分 JSON 的脚本 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| `uv` | 工具 | 运行辅助脚本 |
| `space.bearer_token` | 凭证 | 访问 Config Center API |
| `sra-toolkit/skills/sp-config-center` | Skill 依赖 | 提供底层 Config Center 查询 CLI |

这个 skill 不会直接访问 `config.shopee.io`，而是复用 `sp-config-center`。

---

## 使用场景

### 场景 1：用临时目录做比较

> 「先帮我比较 `global` 和 `latam`，如果一致就先导出到临时目录」

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --output-dir /tmp/ads-config-center-compare-export-check \
  --exclude-keys aggregation_config,group_key,metric_info
```

脚本会：
1. 先通过 `sp-config-center` 读取每个 zone 的最新版本号
2. 再读取对应精确版本的完整配置状态
3. 如果设置了 `--exclude-keys`，先把这些配置项过滤掉
4. 对剩余配置执行跨 zone 比较
5. 输出 `CONSISTENT` 或 `MISMATCH`
6. 如果一致，就把文件导出到给定的输出目录

### 场景 2：比较后一致则导出

> 「如果一致，就把指定 zone 的配置导出成文件」

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --exclude-keys aggregation_config,group_key,metric_info \
  --output-dir paidads_git/ultrav-core-timewindow/agent_exp_configs/product_ads
```

只有当比较结果一致时，这条命令才会把每个配置项分别导出成一个 JSON 文件。
如果 `--zones` 中包含 `global`，就导出 `global`；否则导出 `--zones` 里的第一个 zone。

### 场景 3：获取机器可读结果

> 「我想拿结构化 JSON 结果做自动化处理」

```bash
env UV_CACHE_DIR=/tmp/uv-cache uv run skills/common/ads-config-center-compare-export/scripts/compare_export.py \
  --project ads_bidding \
  --namespace product_ads_bidding_timewindow_config \
  --env live \
  --zones global,latam \
  --output-dir /tmp/ads-config-center-compare-export-check \
  --exclude-keys aggregation_config,group_key,metric_info \
  --json
```

---

## 比较规则

- 脚本比较的是每个请求 zone 的最新状态。
- `--zones` 可以只传 1 个 zone，也可以传多个 zone。
- 如果设置了 `--exclude-keys`，这些 item key 会先被过滤掉，再参与比较和导出。
- 一致性比较包含：
  - zone 最新 `status`
  - 配置项 key 集合
  - 每个 item 的 `type`
  - 每个 item 的 `sensitive`
  - 每个 item 的 `text_value`
- zone 的 `version` 会展示在摘要里，但 **version 不同本身不会导致 mismatch**。
- 如果只传了 1 个 zone，就不会做跨 zone 比较，这次运行会退化成单 zone 导出流程。

如果发现不一致：
- 不会导出任何文件
- 会列出不一致的 zone 和 item 级原因

如果全部一致：
- 只导出自动选中的 export zone
- 每个配置项导出为一个独立 JSON 文件

---

## 导出规则

- 一个导出文件对应一个 Config Center 配置项。
- 如果输出目录不存在，脚本会自动创建。
- 导出的文件不包含 Config Center 的 meta 信息，例如：
  - `version`
  - `status`
  - `type`
  - `sensitive`
  - `key`
- 如果某个 item 的 `text_value` 是合法 JSON，就导出解析后的 JSON。
- 如果 `text_value` 不是合法 JSON，就把它当作 JSON 字符串导出，确保输出文件仍然是合法 JSON。
- 导出完成后，脚本会校验输出目录是否存在，以及生成文件数是否符合预期。

---

## 输出内容

脚本会打印：
- 每个 zone 的摘要，包括 `version`、`status`、`item_count`
- 如果设置了 `--exclude-keys`，会打印 `excluded_keys`
- 比较结果：
  - `CONSISTENT`
  - `Comparison Skipped: only one zone provided`
  - 或 `MISMATCH`
- 如果成功导出，还会打印导出路径和写入文件数

在 `--json` 模式下，脚本会返回结构化 JSON，包含：
- `zone_summaries`
- `comparison_mode`
- `consistent`
- `zone_diffs`
- `exclude_keys`
- `written_files`

---

## 注意事项

- `--exclude-keys` 只是在 `ads-config-center-compare-export` 内部做过滤；`sp-config-center` 仍然会先拉取全量 zone state。
- 只有确认一致后，才会执行导出。
- `--output-dir` 现在是必填参数；只要比较结果一致，就会自动导出到这个目录。
- export zone 直接从 `--zones` 推导：如果包含 `global`，就用 `global`；否则用第一个 zone。
- 如果只传单个 zone，例如 `--zones global`，脚本会打印 `Comparison Skipped: only one zone provided`，然后继续尝试导出该 zone。
- 这个 skill 很适合和 `ads-config-center-dir-to-pr` 配合：
  - 先用本 skill 从 Config Center 比较并导出
  - 再用 `ads-config-center-dir-to-pr` 把目录重新组装成 Config Center draft

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `ads-config-center-dir-to-pr` | 把本地配置 JSON 目录重新组装成 Config Center create-pr draft |
| `sp-config-center` | 查询配置状态、版本以及管理发布单 |
