---
name: "{{SKILL_NAME}}"
description: >
  <What the skill does — one sentence, bilingual proper nouns>.
  TRIGGER when: <keywords in English and Chinese>.
  DO NOT TRIGGER when: <false-positive exclusions>.
# category: platform          # optional: platform | workflow
# tags: []                    # optional: human indexing only, does NOT affect AI matching
# credentials:                # optional: declare credentials this skill reads
#   - name: service.token     # key path in ~/.config/sra/credentials.json
#     description: "How to obtain this credential"  # optional helper text shown in CLI
---

<!-- Skill Template — copy this directory into skills/common/, skills/team/<team>/, or skills/personal/<email-name>/ and edit -->

# {{SKILL_NAME}}

<!-- ## Overview -->
<!-- Brief description of what this skill provides. Real skills in this repo should use the ads- prefix and live in a scoped skill root. -->

<!-- ## Usage / Workflow -->
<!-- Step-by-step instructions the AI should follow when this skill is triggered. -->
<!-- Use imperative mood: "Step 1: Query the API..." -->
<!-- Python scripts: use `uv run scripts/xxx.py` (not python3). -->
<!-- Dependencies: declare inline via PEP 723 metadata in the script, not requirements.txt. -->

<!-- ## References -->
<!-- Link to detailed docs in references/ subdirectory if needed. -->
<!-- - `references/api-guide.md` — API reference -->
<!-- - `scripts/query.py` — helper script (run with `uv run`) -->
