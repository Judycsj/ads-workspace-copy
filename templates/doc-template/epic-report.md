<!-- epic-report.md 由 scripts/generate_epic_report.py 从 epic-report-meta.json 渲染生成。
     LLM 仅补充 meta.json 中的判断字段（ka_progress 等），不直接编辑本文件。 -->
### [${kp_id}](${epic_file_relpath}): [${kp_title}](${epic_file_gitlab_url})

> 报告范围：${range_start} ~ ${range_end} | 生成时间：${generated_date}

#### 项目概览/Project Overview
<!-- 前 7 字段由 kr-file.md 同步覆盖，请在 kr-file.md 中修改。 -->

- **KP ID**：${kp_id}, [epic-file](${epic_file_path}), [gitlab](${gitlab_url}) <!-- 格式：Ox-KRy-KPz-YYYYMMDDHHMM, [epic-file](相对路径), [gitlab](绝对URL) | eg: O1-KR2-KP1-202605091457, [epic-file](...), [gitlab](...) -->
- **KP Title**：${kp_title} <!-- 格式：中文标题（双语时只保留中文） | eg: 统计模型因子化均值方案 -->
- **KP Type**：${kp_type} <!-- 格式：greenfield / problem-driven / incremental / refactor | eg: incremental -->
- **Owner**：${owner} <!-- 格式：username | eg: jirong.you -->
- **Why Do**：${why_do} <!-- 格式：一句话业务动因 | eg: 提升统计模型预估精度，降低 PCOC 偏差 -->
- **交付目标/Deliverable**：${deliverable} <!-- 格式：【收益】量化指标目标；【执行】确定性交付物 | eg: 【收益】rev +5%；【执行】完成模型开发并上线 -->
- **Phase**：${phase} <!-- 格式：Waiting / TD / Dev / Int / UAT / Done / Close | eg: Dev -->
- **阶段日期/Phase Begin Date**：${phase_begin_date} <!-- 格式：Phase[MMDD]\|... | eg: Waiting[-]\|TD[0423]\|Dev[0510]\|Int[-]\|UAT[-]\|Done[-]\|Close[-] -->
- **Contributor**：${contributor} <!-- 格式：username，多人逗号分隔 | eg: jirong.you, alice -->
- **TD 步骤/TD Step**：${step} <!-- 格式：数字（0-6） | eg: 6 -->
- **工作量/Effort**：${effort} <!-- 格式：数字+单位 | eg: 21d -->
- **最终ETA/Final ETA**：${final_eta} <!-- 格式：MMDD | eg: 0614 -->
- **开始时间/Start**：${start} <!-- 格式：MMDD | eg: 0507 -->
- **最后更新/Last Update**：${last_update} <!-- 格式：YYYY-MM-DD | eg: 2026-06-04 -->
- **KA 完成率/Done Count / Total Count**：${done_count}/${total_count} <!-- 格式：已完成/总数 | eg: 3/5 -->
- **关键进展/Key Progress**：${key_progress} <!-- 格式：LLM 推理文本 | eg: 【全流量】KA1 BR/PH 全量完成，KA3 TW 小流量中 -->
- **KA 进度汇总/KA Progress Summary**：${ka_progress_summary} <!-- 格式：LLM 推理文本 | eg: KA1-KA3 已完成，KA4 开发中，KA5 待启动 -->
- **实验汇总/Experiment Summary**：${experiment_summary} <!-- 格式：LLM 推理文本 | eg: KA3 TW 实验中，rev +1.2%，继续观察 -->
- **风险汇总/Risk Summary**：${risk_summary} <!-- 格式：LLM 推理文本 | eg: KA4 ETA 已过期，需重新评估排期 -->
- **下一步汇总/Next Steps Summary**：${next_steps_summary} <!-- 格式：LLM 推理文本 | eg: KA3 等待全量决策；KA4 提交代码 review -->
- **状态汇总/Status Summary**：${status_summary} <!-- 格式：emoji + 状态 | eg: 🟢 OnTrack -->
- **状态原因/Reason Summary**：${reason_summary} <!-- 格式：文本 | eg: 正常推进中 -->
- **质量检测/Quality Comments**：${quality_comments} <!-- 格式：逗号分隔列表 | eg: R3: KA2 缺少 Phase 前缀, R7: KA3 描述模糊 -->
- **Epic 文件/Epic File**：[Markdown](${epic_file_relpath}) / [GitLab](${epic_file_gitlab_url}) <!-- eg: [Markdown](epic-file.md) / [GitLab](https://git.garena.com/...) -->
- **Epic 报告/Epic Report**：[Markdown](${epic_report_relpath}) / [GitLab](${epic_report_gitlab_url}) <!-- eg: [Markdown](epic-report.md) / [GitLab](https://git.garena.com/...) -->


#### 执行与状态详情变更/KP Execution & Status Details Change

<!-- **last_modified**：${last_modified}  格式：YYYY-MM-DD（git blame 最后修改日期） | eg: 2026-06-10 -->

<!-- **change**：${change}  格式：字段名：[旧值] -> [新值]；新行为"新增"；无变更为"-" | eg: Start：[-] -> [0610]; ETA：[0630] -> [0715] -->

##### 里程碑进度/Milestone Progress

<!-- **ka_progress**：${ka_progress}  格式：KA行硬模板 | eg: 【小流量】KA3（调控实验）：1x 方向成立但收益偏温和，1.5x 完成开桶。 -->

<!-- **risk**：${risk}  格式：节奏风险 + 效果风险；无风险写"暂无" | eg: 节奏风险：ETA 已过期；效果风险：暂无 -->

<!-- **next_steps**：${next_steps}  格式：能改变状态的动作 | eg: KA3 观察 rev/advv 7 天，达标则提交全量 review -->

<!-- **status**：${status}  格式：emoji + 状态（per-KA） | eg: 🟢 OnTrack -->

<!-- **reason**：${reason}  格式：文本 | eg: 正常推进中 -->

| ID        | <占位符>                                                     | last_modified    | change    | ka_progress    | risk | next_steps | status | reason |
| --------- | ------------------------------------------------------------ | ---------------- | --------- | -------------- | ---- | ---------- | ------ | ------ |
| ${row_id} | ${来源于epic file section5 里程碑进度/Milestone Progress 对应表格列} | ${last_modified} | ${change} | ${ka_progress} | ${risk} | ${next_steps} | ${status} | ${reason} |

##### 实验与全量/Experiments & Rollouts

| ID        | <占位符>                               | last_modified    | change    |
| --------- | -------------------------------------- | ---------------- | --------- |
| ${row_id} | ${来源于epic file section5 对应表格列} | ${last_modified} | ${change} |

##### 关键发现/Key Findings（${range_start} ~ ${range_end}）

| ID        | <占位符>                               | last_modified    | change    |
| --------- | -------------------------------------- | ---------------- | --------- |
| ${row_id} | ${来源于epic file section5 对应表格列} | ${last_modified} | ${change} |

##### 问题与讨论/Problems & Discussion（${range_start} ~ ${range_end}）

| ID        | <占位符>                               | last_modified    | change    |
| --------- | -------------------------------------- | ---------------- | --------- |
| ${row_id} | ${来源于epic file section5 对应表格列} | ${last_modified} | ${change} |

##### 下一步计划/Next Steps

| ID        | <占位符>                               | last_modified    | change    |
| --------- | -------------------------------------- | ---------------- | --------- |
| ${row_id} | ${来源于epic file section5 对应表格列} | ${last_modified} | ${change} |

---

<!-- 以下为字段定义与数据产出规则，供脚本开发和 LLM 推理参考 -->

#### 附录 A：字段更新逻辑/Field Update Logic

> meta.json 分 5 个顶层 section：`KP-Info` / `KP-Info-EN` / `KAs-Info` / `KAs-Info-EN` / `Rows-Info`。
> 内部 Key 使用 snake_case（如 `kp_id`），报告显示名见上方 Overview List。

##### KP-Info（KP 级字段）

| Key | 更新逻辑 | 产出方 | 格式 | Demo |
|---|---|---|---|---|
| `kp_id` | 从 epic-file KP ID 行提取 | extract（脚本） | Ox-KRy-KPz-YYYYMMDDHHMM, [epic-file](...), [gitlab](...) | O1-KR2-KP1-202605091457, [epic-file](...), [gitlab](...) |
| `kp_title` | epic-file H1 标题；LLM 规范化为标准中文（双语时只保留中文） | epic-td → extract | 中文标题 | 统计模型因子化均值方案 |
| `kp_type` | 从 epic-file `KP Type` 行提取；值域 `greenfield` / `problem-driven` / `incremental` / `refactor` | epic-td → extract | 枚举值 | incremental |
| `owner` | 从 epic-file `Owner` 行提取；缺失时取 5.1 表最常见 KA owner | epic-td → extract | username | jirong.you |
| `contributor` | 从 epic-file `Contributors` 行提取 | extract | username，多人逗号分隔 | jirong.you, alice |
| `why_do` | 从 epic-file `Why Do` 行提取；LLM 规范化为标准中文 | epic-td → extract | 一句话业务动因 | 提升统计模型预估精度，降低 PCOC 偏差 |
| `deliverable` | 从 epic-file `交付目标/Deliverable` 行提取；结构为【收益】+【执行】 | epic-td → extract | 【收益】量化指标目标；【执行】确定性交付物 | 【收益】rev +5%；【执行】完成模型开发并上线 |
| `close_summary` | 从 epic-file Section 5.6 结项总结提取；默认值 `-` | extract | 文本 | - |
| `phase` | 从 epic-file `Phase` 行提取；值域 `Waiting` / `TD` / `Dev` / `Int` / `UAT` / `Done` / `Close` | epic-td → memory-sync → extract | 枚举值 | Dev |
| `phase_begin_date` | 从 5.1 表 KA Start 日期和 Phase 前缀实时计算 | extract（从 5.1 计算） | Phase[MMDD]\|... | Waiting[-]\|TD[0423]\|Dev[0510]\|Int[-]\|UAT[-]\|Done[-]\|Close[-] |
| `epic_file_relpath` | 相对于 kp_dir 的路径 | extract | 相对路径 | epic-file.md |
| `epic_file_gitlab_url` | GITLAB_BASE + 文件相对路径拼接 | extract | URL | https://git.garena.com/.../epic-file.md |
| `epic_report_relpath` | 相对于 kp_dir 的路径 | extract | 相对路径 | epic-report.md |
| `epic_report_gitlab_url` | GITLAB_BASE + 文件相对路径拼接 | extract | URL | https://git.garena.com/.../epic-report.md |
| `quality_comments` | Phase 1 质量检测产出 | extract（Phase 1） | 逗号分隔列表 | R3: KA2 缺少 Phase 前缀, R7: KA3 描述模糊 |
| `step` | 从 `<!-- epic-td-progress: step=N` HTML 注释提取 | epic-td → extract | 数字（0-6） | 6 |
| `start` | 从 KP 目录名时间戳（`YYYYMMDDHHMI`）提取月日 | extract | MMDD | 0507 |
| `last_update` | epic-file.md 的文件系统 mtime（YYYY-MM-DD） | extract | YYYY-MM-DD | 2026-06-04 |
| `effort` | 5.1 表所有有效 KA 的 Effort 求和 | extract | 数字+单位 | 21d |
| `done_count` | 5.1 表 Done 列有日期的有效 KA 计数 | extract | 数字 | 3 |
| `total_count` | 5.1 表 KA 编号可解析为 `KA{N}` 的行数 | extract | 数字 | 5 |
| `final_eta` | 优先取编号最大有效 KA 的 ETA；缺失时取所有有效 KA 最晚 ETA | extract | MMDD | 0614 |
| `status_summary` | 由全部 KA 的 per-KA status 汇总推导，见 [OKR Status Model](../../specs/common/okr/03-core-concepts.md) | extract | emoji + 状态 | 🟢 OnTrack |
| `reason_summary` | 与 `status_summary` 同时推导 | extract | 文本 | 正常推进中 |
| `generated_date` | `--today` 参数或当天日期 | extract（生成时设置） | YYYY-MM-DD | 2026-06-14 |
| `range_start` | `--today` 减去 `--range` 天数 | extract（生成时设置） | YYYY-MM-DD | 2026-06-07 |
| `range_end` | `--today` | extract（生成时设置） | YYYY-MM-DD | 2026-06-14 |
| `key_progress` | 从全部 KA 的 `ka_progress` 中筛选关键进展 | LLM Step 3b | LLM 推理文本 | 【全流量】KA1 BR/PH 全量完成，KA3 TW 小流量中 |
| `ka_progress_summary` | 从全部 KA 的 `ka_progress` 汇总 | LLM Step 3b | LLM 推理文本 | KA1-KA3 已完成，KA4 开发中，KA5 待启动 |
| `experiment_summary` | 从全部 KA 的 `experiment` 汇总 | LLM Step 3b | LLM 推理文本 | KA3 TW 实验中，rev +1.2%，继续观察 |
| `risk_summary` | 从全部 KA 的 `risk` 汇总 | LLM Step 3b | LLM 推理文本 | KA4 ETA 已过期，需重新评估排期 |
| `next_steps_summary` | 从全部 KA 的 `next_steps` 汇总 | LLM Step 3b | LLM 推理文本 | KA3 等待全量决策；KA4 提交代码 review |

##### KP-Info-EN（KP 级英文翻译）

所有字段由 LLM Step 3b 从对应中文字段翻译生成。

| Key | 源字段 | 翻译规则 | 格式 | Demo |
|---|---|---|---|---|
| `kp_title_en` | `kp_title` | 若含 ` / ` 分隔符取后半 | English title | Statistical Model Factorized Mean Scheme |
| `deliverable_en` | `deliverable` | 直译 | [Benefit]...; [Execution]... | [Benefit] rev +5%; [Execution] Complete model development and launch |
| `why_do_en` | `why_do` | 直译 | English text | Improve statistical model prediction accuracy, reduce PCOC bias |
| `close_summary_en` | `close_summary` | 直译 | English text | - |
| `key_progress_en` | `key_progress` | 标签用 `[Full Rollout]` / `[A/B Test]` / `[Delivered]` / `[Completed]` | English text | [Full Rollout] KA1 BR/PH fully rolled out; [A/B Test] KA3 TW in experiment |
| `ka_progress_summary_en` | `ka_progress_summary` | 阶段标签映射 | English text | KA1-KA3 delivered, KA4 in development, KA5 not started |
| `experiment_summary_en` | `experiment_summary` | 直译 | English text | KA3 TW in experiment, rev +1.2%, continue monitoring |
| `risk_summary_en` | `risk_summary` | 直译 | English text | KA4 ETA overdue, need to reassess schedule |
| `next_steps_summary_en` | `next_steps_summary` | 直译 | English text | KA3 awaiting full rollout decision; KA4 submit code review |

##### KAs-Info（per-KA 字段）

`KAs-Info` dict 按 KA 编号（如 `"KA1"`, `"KA2"`）展开。每行必须绑定到具体 KA，KA 列为"全部"/"All"或无法解析为 `KA{N}` 的行会被跳过并警告。

| Key | 更新逻辑 | 产出方 | 格式 | Demo |
|---|---|---|---|---|
| `status` | per-KA 状态推导，值域 Close/Done/DDL/Risk/Warning/Waiting/OnTrack，规则见 [OKR Status Model](../../specs/common/okr/03-core-concepts.md) | extract（脚本） | emoji + 状态 | 🟢 OnTrack |
| `reason` | 与 `status` 同时推导的原因说明 | extract（脚本） | 文本 | 正常推进中 |
| `ka_progress` | 进度摘要，使用 KA 行硬模板 | LLM Step 3b | KA 行硬模板 | 【小流量】KA3（调控实验）：1x 方向成立但收益偏温和，1.5x 完成开桶。 |
| `experiment` | 实验摘要：KA 编号、实验名/链接、区域/流量、核心指标和结论 | LLM Step 3b | LLM 推理文本 | KA3 TW 实验中，rev +1.2% |
| `risk` | 风险摘要，固定拆 `节奏风险` + `效果风险` | LLM Step 3b | 节奏风险 + 效果风险 | 节奏风险：ETA 已过期；效果风险：暂无 |
| `next_steps` | 下一步动作，优先写能改变状态的动作 | LLM Step 3b | LLM 推理文本 | KA3 观察 rev/advv 7 天，达标则提交全量 review |

##### KAs-Info-EN（per-KA 英文翻译）

所有字段由 LLM Step 3b 从对应中文字段翻译生成。

| Key | 源字段 | 翻译规则 | 格式 | Demo |
|---|---|---|---|---|
| `ka_progress_en` | `ka_progress` | 阶段标签：待启动→not started、TD中→design、开发中→development、测试中→integration、验收中→acceptance testing、小流量→A/B testing、全流量→full rollout、已交付→delivered、已完成→completed、Close→[Close] | English text | [A/B Test] KA3 (bid control): 1x direction validated but modest gain, 1.5x bucketed. |
| `experiment_en` | `experiment` | 直译 | English text | KA3 TW in experiment, rev +1.2% |
| `risk_en` | `risk` | 直译 | English text | Schedule risk: ETA overdue; Impact risk: none |
| `next_steps_en` | `next_steps` | 直译 | English text | KA3 monitor rev/advv for 7 days, submit full rollout review if on target |

##### Rows-Info（per-row 变更信息）

扁平 dict，Key 为行 ID（如 `"5.1.1"`、`"5.2.3"`），仅包含报告范围内有变更的行。
渲染 epic-report 详情表时，从 epic-file Section 5 读取行数据，按行 ID 匹配 Rows-Info append `last_modified` 和 `change` 列。

| Key | 含义 | 产出方 | 格式 | Demo |
|---|---|---|---|---|
| `last_modified` | git blame 最后修改日期 | extract（脚本） | YYYY-MM-DD | 2026-06-10 |
| `change` | 该行在报告范围内的变化描述 | extract（脚本） | 字段名：[旧值] -> [新值] | Start：[-] -> [0610]; ETA：[0630] -> [0715] |

---

> Per-KA status 判定规则和 Epic 级状态汇总规则见 [OKR Status Model](../../specs/common/okr/03-core-concepts.md)。
