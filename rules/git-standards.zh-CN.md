# Git 规范/Git Standards

## 提交规范/Commit Conventions

格式：`<type>: <description>` 或 `<type>(<scope>): <description>`

Types：`feat` | `fix` | `docs` | `refactor` | `test` | `chore` | `style` | `perf` | `ci` | `build` | `revert`

- 祈使语气，首行 ≤ 72 字符（硬限制 100），非平凡变更加正文说明原因
- Git hook 自动校验格式并为 AI 工具注入 `Co-Authored-By`
- LLM 提交：正文必填，暂存文件重新检查
- 目标为 `master` 的 GitLab MR 会复跑 `bash scripts/validate.sh`

## 分支命名/Branch Naming

格式：`<username>/<type>/<description>` — type 可选：`feat`、`hotfix`、`fix`、`refactor`、`chore`、`debug`、`patch`。另外 `revert-<description>` 也是合法格式。

## 禁止事项/Do NOT

- 用 `--no-verify` 绕过 git hook
- 在 master/main 上编辑文件 — 首次编辑前 `git branch --show-current` 确认分支；若在 master/main，提示用户创建开发分支
- 未跑测试就修改 `.githooks/` 或 `scripts/validate.sh`
- 提交凭证、密钥或 `.env` 文件
- 未经确认自动 push 到远端
