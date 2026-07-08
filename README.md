# 广告团队 AI Workspace / Ads Team AI Workspace

One-stop AI workspace for the Ads product and engineering team. Clone, open, and start vibe working immediately.

- **Out of the box**: Open this repo in Claude Code / Cursor / Codex — common skills load automatically, zero configuration required
- **Skill co-creation**: Package your workflows as skills and share them with the team; every shared skill raises the floor for everyone
- **Docs as shared context**: Migrate business and technical docs to `docs/` Markdown so `/ads-knowledge-qa` and other AI agents can read and write them directly

---

## 你的顿悟时刻 / Aha Moment

After cloning and opening this repo, try these:

**Ask without opening a browser:**
```
/ads-knowledge-qa How does the Ads bidding pipeline work?
```

**Diagnose production issues without reading code:**
```
/ads-diagnose Why is ads_id=12345 bidding abnormally low recently?
```

---

## 快速开始 / Quick Start

```bash
git clone --recursive gitlab@git.garena.com:shopee/search_recommend/ai-copilot/ads-workspace.git
cd ads-workspace
bash scripts/bootstrap.sh
```

Then open this directory in Claude Code / Cursor / Codex — `common` skills **load automatically**.

> For the complete setup guide (credentials, telemetry, manual skill installation, etc.), see [Workspace Quickstart](docs/team/00.paid-ads-dev/04.how-tos/01.getting-started/02.workspace-quickstart.EN.md).

---

## 了解更多 / Learn More

- [How-Tos Index](docs/team/00.paid-ads-dev/04.how-tos/README.md) — all workspace guides and tutorials
- [Skill Creation & Contribution](docs/team/00.paid-ads-dev/04.how-tos/09.skill-contribution/01.skill-contribution.EN.md) — build and share your own skills
- [Skills README](skills/README.md) — skill directory conventions and naming standards
- [CLAUDE.md](CLAUDE.md) — project instructions and coding conventions
