# 代码规范/Code Standards

## Shell

- `set -euo pipefail`，引用变量，`[[ ]]` 而非 `[ ]`

## Python 依赖（uv + PEP 723）/Python Dependencies

- 入口脚本必须用 PEP 723 内联元数据：
  ```python
  # /// script
  # requires-python = ">=3.10"
  # dependencies = [
  #   "httpx>=0.27",
  # ]
  # ///
  ```
- 辅助模块（无 `__main__`）不需要 PEP 723 头
- 用 `uv run script.py`（不用 `python3`）；新 skill 不创建 `requirements.txt`
- 版本约束用 `>=`；不允许裸包名

## Skill 代码审查/Skill Code Review

- 提交前用 `scripts/validate.sh` 校验
- 验证 `references/`/`scripts/` 路径存在、跨 skill 引用路径正确、无损坏软链接
