# 支持的提供商与使用示例/Supported Providers & Usage Examples

## 提供商列表/Provider List

| Provider | 默认模型 | 环境变量 | credential key |
|----------|---------|---------|----------------|
| `deepseek`（默认） | `deepseek-v4-pro` | `DEEPSEEK_API_KEY` | `deepseek.api_key` |
| `openai` | `gpt-4o-mini` | `OPENAI_API_KEY` | `openai.api_key` |
| `glm` | `glm-4-flash` | `GLM_API_KEY` | `glm.api_key` |
| `anthropic` | `claude-sonnet-4-20250514` | `ANTHROPIC_API_KEY` | `anthropic.api_key` |
| `gemini` | `gemini-2.0-flash` | `GEMINI_API_KEY` | `gemini.api_key` |
| `kimi` | `moonshot-v1-auto` | `KIMI_API_KEY` | `kimi.api_key` |

API Key 解析优先级：`--api-key` 参数 > 环境变量 > `~/.config/sra/credentials.json`

---

## 使用示例/Usage Examples

### 全量翻译新文档

> "翻译 docs/common/core-knowledge/05.ads-data/01.data-warehouse-overview.zh-CN.md"

→ 检测 `.zh-CN.md` → 目标 `01.data-warehouse-overview.md` 不存在 → 全量翻译 → 创建英文版

### 增量翻译已有文档

> "翻译 docs/common/core-knowledge/02.ads-strategy/05.ads-smart-voucher.zh-CN.md"

→ 目标 `05.ads-smart-voucher.md` 已存在 → git diff 发现 Section 3.2 修改 → 仅翻译 Section 3.2 → 更新英文版

### 指定 commit range

> "翻译 docs/common/index-synthesis.zh-CN.md --diff abc123..def456"

→ 使用指定 commit range 的 diff 进行增量翻译

### 英文翻译为中文

> "translate docs/team/00.paid-ads-dev/04.how-tos/01.getting-started/03.skill-routing.EN.md"

→ 检测 `.EN.md` → 目标 `03.skill-routing.md` → 翻译为中文

### 指定提供商

> "用 openai 翻译 docs/common/core-knowledge/05.ads-data/01.data-warehouse-overview.zh-CN.md"

→ 使用 `--provider openai` 调用 OpenAI API（默认模型 gpt-4o-mini）

> "用 anthropic 翻译 docs/common/index-synthesis.zh-CN.md"

→ 使用 `--provider anthropic` 调用 Anthropic API（默认模型 claude-sonnet-4-20250514）
