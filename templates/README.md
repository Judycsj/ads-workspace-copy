# Templates / 模板

Starter scaffolding for new skills. Copy a template into the correct scope to begin.

## Available Templates

| Template | Contents | Use for |
|----------|----------|---------|
| `skill-template/` | `SKILL.md` skeleton with required frontmatter | Any new skill |

## How to Use

```bash
# Copy into your target scope
cp -r templates/skill-template skills/common/ads-<your-skill>
cp -r templates/skill-template skills/team/01.ads-engineering/ads-<your-skill>
cp -r templates/skill-template skills/personal/<email>/ads-<your-skill>

# Then edit SKILL.md: fill in name, description (TRIGGER when / DO NOT TRIGGER when), and body
```

> Do not create skills directly inside `templates/` — they will not be discovered by the project-local mirror or `sra-skills`.

## Adding New Templates

Place new templates as top-level directories here (e.g. `templates/agent-template/`).
Keep templates minimal — detailed conventions belong in `CLAUDE.md` and `skills/README.md`.
