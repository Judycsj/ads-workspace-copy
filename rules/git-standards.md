# Git Standards

## Commit Conventions

Format: `<type>: <description>` or `<type>(<scope>): <description>`

Types: `feat` | `fix` | `docs` | `refactor` | `test` | `chore` | `style` | `perf` | `ci` | `build` | `revert`

- Imperative mood, first line ≤ 72 chars (hard limit 100), add body for non-trivial changes
- Git hooks auto-validate format and inject `Co-Authored-By` for AI tools
- LLM commits: body required, staged files re-checked
- GitLab MRs targeting `master` re-run `bash scripts/validate.sh`

## Branch Naming

Format: `<username>/<type>/<description>` — types: `feat`, `hotfix`, `fix`, `refactor`, `chore`, `debug`, `patch`. Also allowed: `revert-<description>`.

## Do NOT

- Use `--no-verify` to bypass git hooks
- Edit files on master/main — verify branch with `git branch --show-current` before first edit; prompt user to create dev branch if on master/main
- Modify `.githooks/` or `scripts/validate.sh` without running existing tests
- Commit credentials, secrets, or `.env` files
- Auto-push to remote without explicit confirmation
