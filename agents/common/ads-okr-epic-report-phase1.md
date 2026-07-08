---
name: ads-okr-epic-report-phase1
description: >
  ads-okr-epic-report Phase 1 子任务执行器。调用脚本提取 epic-file.md 数据到 JSON（per-KA 结构），
  再由 LLM 基于 JSON kas dict 补充判断字段，最后调用脚本一次性生成 epic-report.md。
  TRIGGER when: ads-okr-epic-report 策略 B 并行生成单个 KP 的 epic-report。
  DO NOT TRIGGER when: 直接调用，应由 ads-okr-epic-report skill 委托启动。
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
model: sonnet
readonly: false
---

# Epic Report Phase 1 子任务执行器

为单个 KP 生成 `epic-report-meta.json` 和 `epic-report.md`。

## 执行步骤

1. **Step 2.5（格式预检与自动修正）**：`Bash` 调用脚本检测 epic-file.md 提取质量：
   ```bash
   uv run skills/common/ads-okr-epic-report/scripts/extract_epic_data.py \
     --kp-dir {kp_dir} --range {range} --today {today} --diagnostics
   ```
   解析 stdout JSON 中的 `diagnostics` 字段：
   - 若 `diagnostics.needs_autofix == false`：跳过修正，直接进入 Step 3a（不带 `--diagnostics`）
   - 若 `diagnostics.needs_autofix == true`（quality_score < 0.8 或 total_count == 0 或 missing_metadata 非空）：
     a. `Bash` 备份：`cp {kp_dir}/epic-file.md {kp_dir}/epic-file.md.autofix-bak`
     b. `Read` `skills/common/ads-okr-epic-td/SKILL.md`，定位到 `## 工作流：Check 模式（--check）` 部分
     c. 按 epic-td check mode 的 Step 3（KP Metadata 检查）→ Step 4（Section 5 检查）→ Step 5（自动 format 写入）对 `{kp_dir}/epic-file.md` 执行修正。注意：
        - 仅执行 Step 5 中的"自动 format 规则（直接执行）"部分
        - 跳过"必须用户确认"部分（report 流程无交互，不补充 Owner/ETA/Effort、不拆分多 KA 行、不填 Start/Done 日期、不补结项总结）
        - 跳过 Step 6（不输出 check 报告）
     d. 重新运行带 `--diagnostics` 的提取脚本，验证改善
     e. 若 quality_score 提升且 missing_metadata 减少：保留修正，继续 Step 3a
     f. 若未提升或更差：`Bash` 还原备份 `cp {kp_dir}/epic-file.md.autofix-bak {kp_dir}/epic-file.md`，用原文件继续 Step 3a
2. **Step 3a（脚本提取）**：`Bash` 调用脚本提取机械字段到 JSON（per-KA 结构）：
   ```bash
   uv run skills/common/ads-okr-epic-report/scripts/extract_epic_data.py \
     --kp-dir {kp_dir} --range {range} --today {today}
   ```
   脚本输出 JSON summary 到 stdout，写入 `{kp_dir}/epic-report-meta.json`（含 KP 元信息、VN Info、frontier、status、`kas` dict with per-KA table rows、`table_headers`、`Rows-Info` 含脚本生成的字段级 change diff）。
3. **Step 3a.5（生成带占位符的报告）**：`Bash` 调用脚本生成 epic-report.md（LLM 字段尚未填充，显示为 `-`）：
   ```bash
   uv run skills/common/ads-okr-epic-report/scripts/generate_epic_report.py \
     --meta {kp_dir}/epic-report-meta.json --output {kp_dir}/epic-report.md
   ```
4. **Step 3b（LLM 推理）**：`Read` `{kp_dir}/epic-report.md` 全文，一次性推理所有字段：
   - 所有 KA 的 4 个 per-KA 字段：`ka_progress`、`experiment`、`risk`、`next_steps`（+ `_en` 翻译）
   - 项目级字段（写入顶层）：`key_progress`（+ `key_progress_en`）、`ka_progress_summary`（+ `_en`）、`experiment_summary`（+ `_en`）、`risk_summary`（+ `_en`）、`next_steps_summary`（+ `_en`）、`kp_title_en`、`deliverable_en`、`why_do_en`、`close_summary_en`
   - 用 `Edit` 将所有判断字段更新到 `{kp_dir}/epic-report-meta.json`
5. **Step 4（脚本生成完整报告）**：`Bash` 再次调用脚本生成完整 epic-report.md（此时所有字段已填充）：
   ```bash
   uv run skills/common/ads-okr-epic-report/scripts/generate_epic_report.py \
     --meta {kp_dir}/epic-report-meta.json --output {kp_dir}/epic-report.md
   ```

---

## Step 3b 推理规则

`Read` `{kp_dir}/epic-report.md` 全文。报告中已包含项目概览、5.1 里程碑表（含 status/reason/change 列）、5.2-5.5 详情表（含 change 列，由脚本生成的字段级 diff）。

一次性推理所有 per-KA 字段（experiment → risk → next_steps → ka_progress），再汇总 KP 级字段，再规范化元信息 + 翻译。

### 中文术语约束

| 禁用/少用词 | 推荐表达 |
| --- | --- |
| readout | 数据复盘、实验读数、实验结论 |
| go/no-go | 是否推进、是否放量、上线判断 |
| rollout | 推全、扩量、发布、全量 |
| gate | 放行条件、判断条件、验收条件 |

指标名如 `platform_gmv_995_v2`、`advv`、`rev` 保持原样。

### 写作原则

所有字段服务周会同步——先给判断，再给依据；能一句话讲明白，不写两句话；不要把排查过程流水账塞进概览。

### Per-KA 字段规则

#### `ka_progress`（最后推理）

使用 KA 行硬模板，四段必须齐全：

```text
【状态前缀】KAx（KA是要做什么高度概要描述）：KA进度一句话描述。
```

1. `【状态前缀】`：只能是 `【待启动】`/`【TD中】`/`【开发中】`/`【测试中】`/`【小流量】`/`【验收中】`/`【全流量】`/`【已交付】`/`【已完成】`/`【Close】`
2. `KAx`：KA 编号
3. `（...）`：中文全角括号，4-12 字短说明，去掉实现细节
4. `：...。`：中文全角冒号，一句话讲清当前进展

**状态前缀推导规则**：从 5.1 表 KA 描述的 Phase 前缀 + Start/Done/Close 列值机械推导，不自由发挥。完整规则见 [03-core-concepts.md 3.3 节 KA 进展前缀](../../../../specs/common/okr/03-core-concepts.md#ka-进展前缀--ka-progress-prefixes)。

简表：

| 完成状态 | [TD] | [Dev] | [Int] | [UAT] 实验KA | [UAT] 非实验KA |
| --- | --- | --- | --- | --- | --- |
| Start & Done 均空 | 【待启动】 | 【待启动】 | 【待启动】 | 【待启动】 | 【待启动】 |
| Start 非空 & Done 空 | 【TD中】 | 【开发中】 | 【测试中】 | 【小流量】 | 【验收中】 |
| Start & Done 均非空 | 【已完成】 | 【已完成】 | 【已完成】 | 【全流量】 | 【已交付】 |
| Close | 【Close】 | 【Close】 | 【Close】 | 【Close】 | 【Close】 |

若 5.1 和 5.2 冲突，以更接近真实推进状态的信息为准。

#### `experiment`（per-KA）

每个 KA 一行实验摘要：KA 编号、实验/版本名或 shareId/expId、区域/流量、核心指标和结论。无线上实验时写 `暂无线上实验` 或 `该 KA 不适用 AB 实验`。

#### `risk`（per-KA）

每个 KA 一行风险摘要，固定拆两类：`节奏风险` + `效果风险`。已关闭问题不进入。无风险写 `暂无`。

#### `next_steps`（per-KA）

每个 KA 一行下一步动作，优先写能改变状态的动作。避免只写"继续观察"——必须说明观察哪些指标及推进/暂停/回滚条件。

### KP 元信息规范化

对 `kp_title`、`deliverable`、`why_do`、`close_summary` 四个字段执行：
- **规范化中文**：双语只保留中文；全英文翻译为中文；覆写原字段
- **`deliverable` 结构化**：若不含【收益】/【执行】结构，尝试拆分——量化指标归【收益】、具体做什么归【执行】；无法拆分保留原文
- **`close_summary` 结项检查**：若所有 KA 已 Done/Close，对照 1.3 验收标准总结
- **翻译英文**：写入 `kp_title_en`、`deliverable_en`、`why_do_en`、`close_summary_en`

### 汇总顶层字段

5 个顶层字段从 per-KA 对应字段汇总，每个字段一段话，不分行不用 bullet list。先整体判断，再补关键 KA 依据。

#### `key_progress`

只收两类：(1) 进入/完成关键阶段（小流量/全流量/已交付/已完成）；(2) 需要讨论/决策的卡点。普通开发进度不入。无关键进展填 `-`。

分类规则（从 ka_progress 状态前缀判定，不检查 experiment_rows）：

| 优先级 | 类型 | 判定条件 | 输出格式 |
| --- | --- | --- | --- |
| 1 | 【全流量】 | ka_progress 中有 KA 前缀为【全流量】 | `（N）【全流量】{kp_id_short}, {标题}，{text}` |
| 2 | 【小流量】 | ka_progress 中有 KA 前缀为【小流量】 | `（N）【小流量】...` |
| 3 | 【已交付】 | ka_progress 中有 KA 前缀为【已交付】，且无全流量/小流量 | `（N）【已交付】...` |
| 4 | 【已完成】 | ka_progress 中有 KA 前缀为【已完成】，且无以上类型 | `（N）【已完成】...` |
| 5 | 无 | 不在关键进展中列出 | — |

#### 其他 4 个汇总字段

- `ka_progress_summary`：概括各 KA 当前推进状态
- `experiment_summary`：概括实验整体情况；无实验写"暂无线上实验"
- `risk_summary`：概括主要风险；无风险写"暂无"
- `next_steps_summary`：概括下一步重点动作

### `_en` 翻译规则

**per-KA**：

| 中文字段 | 英文字段 | 翻译说明 |
| --- | --- | --- |
| `ka_progress` | `ka_progress_en` | 阶段标签：待启动→not started、方案设计→design、开发→development、联调→integration、验收→acceptance testing、小流量→A/B testing、全流量→full rollout、已交付→delivered、已完成→completed、Close→[Close] |
| `experiment` | `experiment_en` | 直译 |
| `risk` | `risk_en` | 直译 |
| `next_steps` | `next_steps_en` | 直译 |

**项目级**：

| 中文字段 | 英文字段 | 翻译说明 |
| --- | --- | --- |
| `key_progress` | `key_progress_en` | 标签：全流量→[Full Rollout]、小流量→[A/B Test]、已交付→[Delivered]、已完成→[Completed] |
| `ka_progress_summary` | `ka_progress_summary_en` | 阶段标签映射 |
| `experiment_summary` | `experiment_summary_en` | 直译 |
| `risk_summary` | `risk_summary_en` | 直译 |
| `next_steps_summary` | `next_steps_summary_en` | 直译 |
| `kp_title` | `kp_title_en` | 从规范化中文翻译 |
| `deliverable` | `deliverable_en` | 从规范化中文翻译 |
| `why_do` | `why_do_en` | 从规范化中文翻译 |
| `close_summary` | `close_summary_en` | 从中文翻译 |

保留专有名词不翻译。

## 输出

返回 `KP{z} done: {status_icon}` 表示完成。
