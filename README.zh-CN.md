# 广告团队 AI Workspace / Ads Team AI Workspace

广告产研团队的一站式 AI 工作空间。克隆打开，立即开始 vibe working。

- **开箱即用**：用 Claude Code / Cursor / Codex 打开本仓库，common 技能自动加载，无需额外配置
- **技能共创**：把你的工作流打包成技能贡献给团队；每个共享的技能都在抬高所有人的底线
- **文档即共享上下文**：业务与技术文档迁移到 `docs/` Markdown，`/ads-knowledge-qa` 和其他 AI agent 可直接读写

---

## 你的顿悟时刻 / Aha Moment

克隆并打开本仓库后，试试这几件事：

**不用开文档，直接问：**
```
/ads-knowledge-qa 广告竞价流程是怎样的？
```

**线上问题不翻代码，直接诊断：**
```
/ads-diagnose 排查 ads_id=12345 最近出价异常偏低的原因
```

---

## 快速开始 / Quick Start

```bash
git clone --recursive gitlab@git.garena.com:shopee/search_recommend/ai-copilot/ads-workspace.git
cd ads-workspace
bash scripts/bootstrap.sh
```

完成后用 Claude Code / Cursor / Codex 打开本目录，`common` 技能**自动加载**。

> 完整配置指南（凭证、遥测、手动安装技能等）请参见 [Workspace 快速入门](docs/team/00.paid-ads-dev/04.how-tos/01.getting-started/02.workspace-quickstart.md)。

---

## 了解更多 / Learn More

- [使用手册索引](docs/team/00.paid-ads-dev/04.how-tos/README.zh-CN.md) — 所有 workspace 指南和教程
- [技能创建与贡献](docs/team/00.paid-ads-dev/04.how-tos/09.skill-contribution/01.skill-contribution.md) — 创建和贡献自定义技能
- [Skills README](skills/README.zh-CN.md) — 技能目录规范和命名标准
- [CLAUDE.md](CLAUDE.md) — 项目指令和编码规范
