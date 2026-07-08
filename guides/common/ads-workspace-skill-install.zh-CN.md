# 技能安装（ads-workspace-skill-install）使用指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-workspace-skill-install.zh-CN.md)
>
> **语言**：[English](ads-workspace-skill-install.md) | [中文](ads-workspace-skill-install.zh-CN.md)

从 `skills/team/`、`skills/personal/` 和 `sra-toolkit/skills/` 按需安装技能到项目本地 `.tooling/skills/` 镜像。如果目标 skill 声明了 `skill_dependencies`，安装脚本会自动安装这些依赖。依赖解析顺序：优先复用 `.tooling/skills/` 中已安装的 skill → 查找本地 `sra-toolkit` checkout → 从远程 `sra-toolkit` Git 仓库拉取。

**唤醒词**：「install skill」、「add skill」、「enable skill」、「安装技能」、「添加技能」、「启用技能」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含交互式安装流程 |
| `scripts/install_skill.py` | 用于列出和安装技能的 Python 脚本 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| uv | 工具 | 通过 `uv run` 运行 Python 脚本 |

---

## 使用场景

### 场景 1：交互式选择

> 「安装技能」或「install a skill」

列出 team、personal 和 sra-toolkit 中所有可用技能，提示你选择要安装的技能。

### 场景 2：按名称安装

> 「安装 sra-find-skills」

直接安装指定名称的技能，在 `.tooling/skills/` 中创建相对 symlink。

### 场景 3：按目录路径安装

> 「从 /path/to/skill-dir 安装 my-skill」

从任意目录路径安装技能（目录中必须包含 `SKILL.md`）。

---

## 命令行参考

```bash
# 列出可安装技能
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py list

# JSON 格式输出
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py list --json

# 按名称安装
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name>

# 按目录安装
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name> --dir <path>

# 强制覆盖已有链接
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install <name> --force
```

安装一个或多个技能后，统一运行一次仓库级 post-install hook 来刷新共享工具环境，
语义类似 `npx sra-toolkit update`：

```bash
bash scripts/post-install.sh
```

不要在每个单独的 `install_skill.py install` 调用内部触发这个 hook。
先完成本轮所有技能安装，再运行一次 hook。

`scripts/post-install.sh` 会记录 `sra-toolkit` 的 `release` 分支最新 commit；
如果该 commit 没变且安装产物完整，会自动跳过。需要强制刷新时使用：

```bash
ADS_WORKSPACE_FORCE_POST_INSTALL=1 bash scripts/post-install.sh
```

---

## 注意事项

- 只有 `skills/common/` 会自动加载 — team、personal 和 sra-toolkit 技能需手动安装
- 手动安装的链接在执行 `bash scripts/sync-project-skills.sh` 时会被保留
