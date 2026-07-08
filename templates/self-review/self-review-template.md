# Self-Review Template

> Each section includes writing guidelines. Delete the guidelines and fill in your actual content.

---

## Basic Info

| Field | Value |
| --- | --- |
| Name |     |
| Team |     |
| Department |     |
| Review Period |     |

---

## 1. Core Objectives & Deliverables

### 1.1 Achievement Summary

<!-- Writing guidelines:
- Summarize your overall contribution in one sentence, format: "{key metric} {change} (scope)"
- Scope clarification is critical — readers need to know what the number covers
- Algorithm example: "Ads rev +5.12% (all regions, all scenes)"
- Engineering example: "Ad serving P99 latency reduced by 40% (all regions)", "Core service availability improved from 99.95% to 99.99%"
-->

**Summary:** {metric} {change} ({scope})

### 1.2 Delivery List

<!-- Writing guidelines:
- List all deliverables completed during this review period
- Delivery types are not limited to experiment rollouts; they include but are not limited to:
  - Experiment rollout
  - Module development & launch
  - Requirement delivery (product or internal requirements)
  - Infrastructure / tooling delivery
  - Technical design implementation
- Each deliverable should include the following fields:
  1. Project name — short and recognizable
  2. Type — delivery type (rollout / module dev / requirement / infra / other)
  3. Description — 1-3 sentences on what was done and why
  4. Related docs — Confluence/Google Doc links (if any; list separately for multi-phase projects)
  5. Outcome — prefer quantitative results ("metric +X%"); use qualitative description for non-quantifiable deliverables (e.g., "launched and running stable")
- Order projects by importance / impact (descending)
-->

**Project 1:** {project name}
- **Type:** {rollout / module dev / requirement / infra / other}
- **Description:** {1-3 sentences on project goal and approach}
- **Related docs:** {link, or / if none}
- **Outcome:** {quantitative metrics or qualitative description}

**Project 2:** {project name}
- **Type:** {rollout / module dev / requirement / infra / other}
- **Description:** {1-3 sentences on project goal and approach}
- **Related docs:** {link, or / if none}
- **Outcome:** {quantitative metrics or qualitative description}

<!-- Add more projects as needed, using the same format -->

### 1.3 Collaboration Value

<!-- Writing guidelines:
- Describe your contributions in cross-team / cross-functional collaboration
- Must include:
  1. Supporting project name — the main project you contributed to
  2. Outcomes — use bullet points, each covering one dimension of results
- Outcome description principles:
  - Timeline: key milestones and actual completion dates
  - Quantitative metrics: core metric performance during collaboration
  - Baseline comparison: compared to before the collaboration
- Algorithm focus: business metrics (rev/GMV uplift), product metrics (target achievement rate, retention, etc.)
- Engineering focus: system metrics (latency, throughput, availability), delivery quality (bug count, production incidents), release cadence
-->

**Supporting project:** {project name}

**Outcomes:**
- {Timeline and cadence}
- {Core metric performance (business or system metrics)}
- {Delivery quality and stability}
- {Other key results}

---

## 2. Technical Depth & Innovation

### 2.1 Technical Breakthroughs

<!-- Writing guidelines:
- List breakthrough technical achievements during this period; fill in as applicable:
  - Papers: title and core innovation (1-2 sentences)
  - Algorithm innovation: new methods, models, or frameworks — explain what problem was solved
  - Architecture / engineering innovation: system architecture improvements, performance optimization, new tech stack adoption, etc.
  - Hard problem solved: critical technical challenges tackled (e.g., high concurrency, data consistency, complex pipeline optimization)
- For each item, explain "what was done" and "what problem was solved / what improvement was achieved"
- If none, write "/" — do not fabricate
-->

- **Paper / Algorithm innovation:** {description} or /
- **Architecture / Engineering innovation:** {description} or /
- **Hard problem solved:** {description} or /

### 2.2 Infrastructure Contributions

<!-- Writing guidelines:
- Tools / platform building: list tools, platforms, or systems you built or significantly improved
  - Include accessible links (if any)
  - Briefly describe purpose and beneficiaries
  - Algorithm typical: experiment dashboards, monitoring panels, data reports
  - Engineering typical: CI/CD pipelines, deployment tools, test frameworks, ops platforms, SDKs/middleware
- Methodology documentation: list methodology docs, best practices, SOPs you produced
  - If none, write "/"
-->

- **Tools / platform building:**
  - {tool name}: {brief description of purpose}
    - Link: {URL}
  - {tool name}: {brief description of purpose}
    - Link: {URL}
- **Methodology documentation:** {description} or /

---

## 3. AI Agent Adoption & Reflections

### 3.1 Use Cases & Tools

<!-- Writing guidelines:
- List scenarios where you used AI agents to assist your work during this period
- Each scenario should include:
  1. Scenario name — brief description of the application area (e.g., code development, data analysis, documentation, troubleshooting)
  2. Tool used — specific tool name (e.g., Claude Code, Cursor, ChatGPT, Copilot)
  3. How it was used — brief description of what problem was solved
- Examples:
  - Algorithm: "Used Claude Code to write bidding strategy code and unit tests, reducing new module development time from 3 days to 1 day"
  - Algorithm: "Used AI to write complex SQL and interpret experiment data, improving daily data investigation efficiency by ~50%"
  - Engineering: "Used Copilot for CRUD and middleware integration code, reducing boilerplate coding time by 60%"
  - Engineering: "Used AI to troubleshoot production issues, quickly locating root causes from logs and monitoring — reduced debugging time from 2 hours to 30 minutes"
  - General: "Used AI to generate initial drafts of TD/rollout docs, reducing repetitive writing time"
-->

- **Scenario 1:** {scenario name}
  - **Tool:** {tool name}
  - **How it was used:** {what problem was solved}
  - **Impact:** {quantitative or qualitative efficiency gain}

- **Scenario 2:** {scenario name}
  - **Tool:** {tool name}
  - **How it was used:** {what problem was solved}
  - **Impact:** {quantitative or qualitative efficiency gain}

<!-- Add more scenarios as needed -->

### 3.2 Efficiency Gains Summary

<!-- Writing guidelines:
- Summarize the overall efficiency gains from AI agent adoption
- Measure across the following dimensions:
  1. Time saved — certain tasks reduced from X hours/days to Y hours/days
  2. Quality improvement — code quality, documentation quality improvements from AI assistance
  3. Expanded coverage — able to handle more tasks that previously lacked bandwidth for
- Concrete data is best; if no precise data, provide reasonable estimates and label them as "estimated"
- Avoid vague statements like "improved efficiency" — be specific with scenarios and comparisons
-->

{Overall efficiency summary with quantitative data or estimates}

### 3.3 Lessons & Reflections

<!-- Writing guidelines:
- Share lessons learned and reflections from using AI agents
- Recommended coverage:
  1. Where AI works well — which tasks are suitable for AI, and why
  2. Where AI falls short — limitations encountered, pitfalls experienced
  3. Best practices — effective usage patterns you discovered (e.g., prompt techniques, workflow design)
  4. Team adoption recommendations — which practices are worth promoting to the team
- Be honest — no need to exaggerate AI's impact; lessons from failures are equally valuable
- Examples:
  - "AI excels at pattern-clear tasks (SQL writing, template code, config generation) but still requires human judgment for decisions requiring deep business understanding"
  - "By packaging common troubleshooting workflows as AI skills, reduced case investigation time from an average of 2 hours to 30 minutes"
  - "AI-generated code needs careful review — encountered subtle bugs from improper edge case handling"
-->

- **Where AI works well:** {which tasks benefit most from AI}
- **Limitations:** {where it falls short, pitfalls encountered}
- **Best practices:** {effective usage patterns you discovered}
- **Team adoption recommendations:** {which practices are worth promoting}

---

## 4. Gap Analysis & Future Plans

### 4.1 Gap Analysis

<!-- Writing guidelines:
- List 2-3 major gaps from this review period
- Each gap should include:
  1. Specific description of the problem (avoid being vague)
  2. Impact it caused (e.g., low efficiency, slow progress)
- Avoid overly broad descriptions (e.g., "insufficient communication") — be specific to scenarios
- Example: "For cases with frequent business feedback, there is no standardized investigation process, resulting in excessive time spent on case troubleshooting"
-->

- {Gap 1: specific problem + impact}
- {Gap 2: specific problem + impact}

### 4.2 Next 6-Month Plan

#### a) Technical Growth

<!-- Writing guidelines:
- Targeted improvement plans for technical gaps identified this period
- New technology / domain learning goals (e.g., models, frameworks, system design areas)
- Code quality or system design capability evolution targets
-->

- {Technical skill to improve + specific plan}
- {New technology / domain to explore + learning approach}

#### b) Soft Skills Growth

<!-- Writing guidelines:
- Project execution and priority management
- Cross-team communication and collaboration efficiency
- Documentation and communication clarity (TD, proposals, upward reporting)
- Any interpersonal or leadership skills you want to develop
-->

- {Soft skill to improve + specific plan}
- {Soft skill to improve + specific plan}

#### c) Business Planning

<!-- Writing guidelines:
- Response to gap analysis — improvement plans addressing the gaps identified above
- Current project wrap-up — closing out in-progress work and handoff plans
- Next half-year's key business directions and expected deliverables / milestones
- Granularity: no need to be precise to the week, but include clear deliverables or milestones per phase
-->

- {Business direction 1}
  - {Specific plan a}
  - {Specific plan b}
- {Business direction 2}
  - {Specific plan a}
  - {Specific plan b}
