<!-- epic-report.EN.md is rendered by scripts/generate_epic_report.py from epic-report-meta.json.
     LLM only fills judgment fields (ka_progress etc.) in meta.json, does not edit this file directly. -->
### [${kp_id}](${epic_file_relpath}): [${kp_title_en}](${epic_file_gitlab_url})

> Report Range: ${range_start} ~ ${range_end} | Generated: ${generated_date}

#### Project Overview
<!-- First 7 fields synced from kr-file.md — edit there, not here. -->

- **KP ID**：${kp_id}, [epic-file](${epic_file_path}), [gitlab](${gitlab_url}) <!-- format: Ox-KRy-KPz-YYYYMMDDHHMM, [epic-file](relative-path), [gitlab](absolute-url) | eg: O1-KR2-KP1-202605091457, [epic-file](...), [gitlab](...) -->
- **KP Title**：${kp_title_en} <!-- format: English title | eg: Statistical Model Factorized Mean Scheme -->
- **KP Type**：${kp_type} <!-- format: greenfield / problem-driven / incremental / refactor | eg: incremental -->
- **Owner**：${owner} <!-- format: username | eg: jirong.you -->
- **Why Do**：${why_do_en} <!-- format: one-sentence business motivation | eg: Improve statistical model prediction accuracy, reduce PCOC bias -->
- **Deliverable**：${deliverable_en} <!-- format: [Benefit]...; [Execution]... | eg: [Benefit] rev +5%; [Execution] Complete model development and launch -->
- **Phase**：${phase} <!-- format: Waiting / TD / Dev / Int / UAT / Done / Close | eg: Dev -->
- **Phase Begin Date**：${phase_begin_date} <!-- format: Phase[MMDD]\|... | eg: Waiting[-]\|TD[0423]\|Dev[0510]\|Int[-]\|UAT[-]\|Done[-]\|Close[-] -->

- **Contributor**：${contributor} <!-- format: username, comma-separated | eg: jirong.you, alice -->
- **TD Step**：${step} <!-- format: number (0-6) | eg: 6 -->
- **Effort**：${effort} <!-- format: number+unit | eg: 21d -->
- **Final ETA**：${final_eta} <!-- format: MMDD | eg: 0614 -->
- **Start**：${start} <!-- format: MMDD | eg: 0507 -->
- **Last Update**：${last_update} <!-- format: YYYY-MM-DD | eg: 2026-06-04 -->
- **Done Count / Total Count**：${done_count}/${total_count} <!-- format: completed/total | eg: 3/5 -->
- **Key Progress**：${key_progress_en} <!-- format: LLM inference text | eg: [Full Rollout] KA1 BR/PH fully rolled out; [A/B Test] KA3 TW in experiment -->
- **KA Progress Summary**：${ka_progress_summary_en} <!-- format: LLM inference text | eg: KA1-KA3 delivered, KA4 in development, KA5 not started -->
- **Experiment Summary**：${experiment_summary_en} <!-- format: LLM inference text | eg: KA3 TW in experiment, rev +1.2%, continue monitoring -->
- **Risk Summary**：${risk_summary_en} <!-- format: LLM inference text | eg: KA4 ETA overdue, need to reassess schedule -->
- **Next Steps Summary**：${next_steps_summary_en} <!-- format: LLM inference text | eg: KA3 awaiting full rollout decision; KA4 submit code review -->
- **Status Summary**：${status_summary} <!-- format: emoji + status | eg: 🟢 OnTrack -->
- **Reason Summary**：${reason_summary} <!-- format: text | eg: On track -->
- **Quality Comments**：${quality_comments} <!-- format: comma-separated list | eg: R3: KA2 missing Phase prefix, R7: KA3 description vague -->
- **Epic File**：[Markdown](${epic_file_relpath}) / [GitLab](${epic_file_gitlab_url}) <!-- eg: [Markdown](epic-file.md) / [GitLab](https://git.garena.com/...) -->
- **Epic Report**：[Markdown](${epic_report_relpath}) / [GitLab](${epic_report_gitlab_url}) <!-- eg: [Markdown](epic-report.md) / [GitLab](https://git.garena.com/...) -->


#### KP Execution & Status Details Change

<!-- **last_modified**：${last_modified}  format: YYYY-MM-DD (git blame last modified date) | eg: 2026-06-10 -->

<!-- **change**：${change}  format: field_name: [old_value] -> [new_value]; new rows = "New"; no change = "-" | eg: Start: [-] -> [0610]; ETA: [0630] -> [0715] -->

##### Milestone Progress

<!-- **ka_progress**：${ka_progress_en}  format: KA line template | eg: [A/B Test] KA3 (bid control): 1x direction validated but modest gain, 1.5x bucketed. -->

<!-- **risk**：${risk_en}  format: schedule risk + impact risk; none = "None" | eg: Schedule risk: ETA overdue; Impact risk: none -->

<!-- **next_steps**：${next_steps_en}  format: action that changes status | eg: KA3 monitor rev/advv for 7 days, submit full rollout review if on target -->

<!-- **status**：${status}  format: emoji + status (per-KA) | eg: 🟢 OnTrack -->

<!-- **reason**：${reason}  format: text | eg: On track -->

| ID        | <placeholder>                                                | last_modified    | change    | ka_progress    | risk | next_steps | status | reason |
| --------- | ------------------------------------------------------------ | ---------------- | --------- | -------------- | ---- | ---------- | ------ | ------ |
| ${row_id} | ${from epic file section5 Milestone Progress table columns}  | ${last_modified} | ${change} | ${ka_progress} | ${risk} | ${next_steps} | ${status} | ${reason} |

##### Experiments & Rollouts

| ID        | <placeholder>                                  | last_modified    | change    |
| --------- | ---------------------------------------------- | ---------------- | --------- |
| ${row_id} | ${from epic file section5 corresponding table} | ${last_modified} | ${change} |

##### Key Findings (${range_start} ~ ${range_end})

| ID        | <placeholder>                                  | last_modified    | change    |
| --------- | ---------------------------------------------- | ---------------- | --------- |
| ${row_id} | ${from epic file section5 corresponding table} | ${last_modified} | ${change} |

##### Problems & Discussion (${range_start} ~ ${range_end})

| ID        | <placeholder>                                  | last_modified    | change    |
| --------- | ---------------------------------------------- | ---------------- | --------- |
| ${row_id} | ${from epic file section5 corresponding table} | ${last_modified} | ${change} |

##### Next Steps

| ID        | <placeholder>                                  | last_modified    | change    |
| --------- | ---------------------------------------------- | ---------------- | --------- |
| ${row_id} | ${from epic file section5 corresponding table} | ${last_modified} | ${change} |

---

<!-- Field definitions and data production rules below, for script development and LLM inference reference -->

#### Appendix A: Field Update Logic

> meta.json has 5 top-level sections: `KP-Info` / `KP-Info-EN` / `KAs-Info` / `KAs-Info-EN` / `Rows-Info`.
> Internal keys use snake_case (e.g. `kp_id`). Display names are shown in the Overview List above.

##### KP-Info (KP-level fields)

| Key | Update Logic | Producer | Format | Demo |
|---|---|---|---|---|
| `kp_id` | Extract from epic-file KP ID line | extract (script) | Ox-KRy-KPz-YYYYMMDDHHMM, [epic-file](...), [gitlab](...) | O1-KR2-KP1-202605091457, [epic-file](...), [gitlab](...) |
| `kp_title` | epic-file H1 title; LLM normalizes to standard Chinese | epic-td → extract | Chinese title | 统计模型因子化均值方案 |
| `kp_type` | From epic-file `KP Type` line; enum: `greenfield` / `problem-driven` / `incremental` / `refactor` | epic-td → extract | Enum value | incremental |
| `owner` | From epic-file `Owner` line; fallback to most common KA owner in 5.1 | epic-td → extract | username | jirong.you |
| `contributor` | From epic-file `Contributors` line | extract | username, comma-separated | jirong.you, alice |
| `why_do` | From epic-file `Why Do` line; LLM normalizes to standard Chinese | epic-td → extract | One-sentence motivation | 提升统计模型预估精度，降低 PCOC 偏差 |
| `deliverable` | From epic-file `Deliverable` line; structure: 【收益】+【执行】 | epic-td → extract | 【收益】target;【执行】deliverable | 【收益】rev +5%；【执行】完成模型开发并上线 |
| `close_summary` | From epic-file Section 5.6 Close Summary; default `-` | extract | Text | - |
| `phase` | From epic-file `Phase` line; enum: `Waiting` / `TD` / `Dev` / `Int` / `UAT` / `Done` / `Close` | epic-td → memory-sync → extract | Enum value | Dev |
| `phase_begin_date` | Computed from 5.1 KA Start dates and Phase prefixes at extraction time | extract (computed from 5.1) | Phase[MMDD]\|... | Waiting[-]\|TD[0423]\|Dev[0510]\|Int[-]\|UAT[-]\|Done[-]\|Close[-] |
| `epic_file_relpath` | Relative path from kp_dir | extract | Relative path | epic-file.md |
| `epic_file_gitlab_url` | GITLAB_BASE + relative file path | extract | URL | https://git.garena.com/.../epic-file.md |
| `epic_report_relpath` | Relative path from kp_dir | extract | Relative path | epic-report.md |
| `epic_report_gitlab_url` | GITLAB_BASE + relative file path | extract | URL | https://git.garena.com/.../epic-report.md |
| `quality_comments` | Phase 1 quality check output | extract (Phase 1) | Comma-separated list | R3: KA2 missing Phase prefix, R7: KA3 description vague |
| `step` | From `<!-- epic-td-progress: step=N` HTML comment | epic-td → extract | Number (0-6) | 6 |
| `start` | Extract month-day from KP directory timestamp (`YYYYMMDDHHMI`) | extract | MMDD | 0507 |
| `last_update` | epic-file.md filesystem mtime (YYYY-MM-DD) | extract | YYYY-MM-DD | 2026-06-04 |
| `effort` | Sum of all valid KA Effort in 5.1 table | extract | Number+unit | 21d |
| `done_count` | Count of valid KAs with Done date in 5.1 | extract | Number | 3 |
| `total_count` | Count of rows with parseable `KA{N}` in 5.1 | extract | Number | 5 |
| `final_eta` | Prefer highest-numbered valid KA's ETA; fallback to latest ETA | extract | MMDD | 0614 |
| `status_summary` | Aggregated from per-KA status, see [OKR Status Model](../../specs/common/okr/03-core-concepts.md) | extract | Emoji + status | 🟢 OnTrack |
| `reason_summary` | Derived with `status_summary` | extract | Text | On track |
| `generated_date` | `--today` param or current date | extract (at generation) | YYYY-MM-DD | 2026-06-14 |
| `range_start` | `--today` minus `--range` days | extract (at generation) | YYYY-MM-DD | 2026-06-07 |
| `range_end` | `--today` | extract (at generation) | YYYY-MM-DD | 2026-06-14 |
| `key_progress` | Filter key progress from all KA `ka_progress` | LLM Step 3b | LLM inference text | 【全流量】KA1 BR/PH fully rolled out, KA3 TW in A/B test |
| `ka_progress_summary` | Summarize all KA `ka_progress` | LLM Step 3b | LLM inference text | KA1-KA3 已完成，KA4 开发中，KA5 待启动 |
| `experiment_summary` | Summarize all KA `experiment` | LLM Step 3b | LLM inference text | KA3 TW 实验中，rev +1.2%，继续观察 |
| `risk_summary` | Summarize all KA `risk` | LLM Step 3b | LLM inference text | KA4 ETA 已过期，需重新评估排期 |
| `next_steps_summary` | Summarize all KA `next_steps` | LLM Step 3b | LLM inference text | KA3 等待全量决策；KA4 提交代码 review |

##### KP-Info-EN (KP-level English translations)

All fields translated from corresponding Chinese fields by LLM Step 3b.

| Key | Source | Translation Rule | Format | Demo |
|---|---|---|---|---|
| `kp_title_en` | `kp_title` | If contains ` / `, take second half | English title | Statistical Model Factorized Mean Scheme |
| `deliverable_en` | `deliverable` | Direct translation | [Benefit]...; [Execution]... | [Benefit] rev +5%; [Execution] Complete model development and launch |
| `why_do_en` | `why_do` | Direct translation | English text | Improve statistical model prediction accuracy, reduce PCOC bias |
| `close_summary_en` | `close_summary` | Direct translation | English text | - |
| `key_progress_en` | `key_progress` | Tags: `[Full Rollout]` / `[A/B Test]` / `[Delivered]` / `[Completed]` | English text | [Full Rollout] KA1 BR/PH fully rolled out; [A/B Test] KA3 TW in experiment |
| `ka_progress_summary_en` | `ka_progress_summary` | Phase tag mapping | English text | KA1-KA3 delivered, KA4 in development, KA5 not started |
| `experiment_summary_en` | `experiment_summary` | Direct translation | English text | KA3 TW in experiment, rev +1.2%, continue monitoring |
| `risk_summary_en` | `risk_summary` | Direct translation | English text | KA4 ETA overdue, need to reassess schedule |
| `next_steps_summary_en` | `next_steps_summary` | Direct translation | English text | KA3 awaiting full rollout decision; KA4 submit code review |

##### KAs-Info (per-KA fields)

`KAs-Info` dict keyed by KA ID (e.g. `"KA1"`, `"KA2"`). Each row must bind to a specific KA; rows with KA="All" or unparseable IDs are skipped with warnings.

| Key | Update Logic | Producer | Format | Demo |
|---|---|---|---|---|
| `status` | Per-KA status derivation, enum: Close/Done/DDL/Risk/Warning/Waiting/OnTrack, rules in [OKR Status Model](../../specs/common/okr/03-core-concepts.md) | extract (script) | Emoji + status | 🟢 OnTrack |
| `reason` | Derived with `status` | extract (script) | Text | On track |
| `ka_progress` | Progress summary, using KA line template | LLM Step 3b | KA line template | 【小流量】KA3（调控实验）：1x 方向成立但收益偏温和，1.5x 完成开桶。 |
| `experiment` | Experiment summary: KA ID, experiment name/link, region/traffic, key metrics and conclusions | LLM Step 3b | LLM inference text | KA3 TW 实验中，rev +1.2% |
| `risk` | Risk summary, fixed split: `节奏风险` + `效果风险` | LLM Step 3b | Schedule risk + impact risk | 节奏风险：ETA 已过期；效果风险：暂无 |
| `next_steps` | Next actions, prioritize status-changing actions | LLM Step 3b | LLM inference text | KA3 观察 rev/advv 7 天，达标则提交全量 review |

##### KAs-Info-EN (per-KA English translations)

All fields translated from corresponding Chinese fields by LLM Step 3b.

| Key | Source | Translation Rule | Format | Demo |
|---|---|---|---|---|
| `ka_progress_en` | `ka_progress` | Phase tags: 待启动→not started, TD中→design, 开发中→development, 测试中→integration, 验收中→acceptance testing, 小流量→A/B testing, 全流量→full rollout, 已交付→delivered, 已完成→completed, Close→[Close] | English text | [A/B Test] KA3 (bid control): 1x direction validated but modest gain, 1.5x bucketed. |
| `experiment_en` | `experiment` | Direct translation | English text | KA3 TW in experiment, rev +1.2% |
| `risk_en` | `risk` | Direct translation | English text | Schedule risk: ETA overdue; Impact risk: none |
| `next_steps_en` | `next_steps` | Direct translation | English text | KA3 monitor rev/advv for 7 days, submit full rollout review if on target |

##### Rows-Info (per-row change info)

Flat dict keyed by row ID (e.g. `"5.1.1"`, `"5.2.3"`), only includes rows with changes within the report range.
When rendering epic-report detail tables, read row data from epic-file Section 5, match by row ID to Rows-Info and append `last_modified` and `change` columns.

| Key | Description | Producer | Format | Demo |
|---|---|---|---|---|
| `last_modified` | git blame last modified date | extract (script) | YYYY-MM-DD | 2026-06-10 |
| `change` | Row change description within report range | extract (script) | field_name: [old_value] -> [new_value] | Start: [-] -> [0610]; ETA: [0630] -> [0715] |

---

> Per-KA status rules and Epic-level status aggregation rules: see [OKR Status Model](../../specs/common/okr/03-core-concepts.md).
