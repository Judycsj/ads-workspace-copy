# ads-workspace-skill-opt — Skill 审查与优化

扫描 skill 的 10 个质量维度，生成结构化优化建议，并可逐项执行优化。

## 快速开始

```
/ads-workspace-skill-opt           # 交互模式
审查 ads-okr-memory-update        # 审查指定 skill
批量扫描 common skills             # 批量扫描所有 common skills
```

## 10 个审查维度

| # | 维度 | 自动检查 | LLM 审查 |
|---|------|---------|---------|
| D1 | 可读性 | 行数、重复文本 | Phase/Step 结构 |
| D2 | 交互效率 | AskUserQuestion 次数 | Confirm-Once 机会 |
| D3 | 代码化 | scripts/ 存在性、PEP 723 | 可脚本化的文件操作 |
| D4 | 复用与去重 | 常见模式检测 | 跨 skill 共享逻辑 |
| D5 | 错误处理 | 错误模式计数 | action mapping 完整性 |
| D6 | Frontmatter | 必填字段 | 最小权限 |
| D7 | Token 效率 | body 大小、代码块 | references/ 拆分 |
| D8 | 安全性 | 硬编码密钥 | 破坏性操作 |
| D9 | 可测试性 | argparse 使用 | 独立测试入口 |
| D10 | 文档完整性 | Guide 存在性 | 示例覆盖 |

## 脚本用法

```bash
# 扫描单个 skill
uv run skills/common/ads-workspace-skill-opt/scripts/audit.py scan \
  --skill-dir "skills/common/ads-xxx/" --project-cwd "$(pwd)"

# 批量扫描
uv run skills/common/ads-workspace-skill-opt/scripts/audit.py batch-scan \
  --scope common --top 10 --project-cwd "$(pwd)"
```

## 优化优先级

1. **Quick Wins**（≤10 min）：Frontmatter 修复、PEP 723 header
2. **Medium Effort**（1-2h）：Confirm-Once、body 拆分到 references/
3. **Large Refactor**（半天+）：全面脚本化、共享库抽取
