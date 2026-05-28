# Skill Sync

Codex plugin and CLI for syncing local `SKILL.md` directories into other AI coding tool formats.

## Quick Start

Preview:

```bash
./sync-skills --dry-run
```

Sync:

```bash
./sync-skills
```

The root `sync-skills` command defaults to syncing the current skills repository into Cursor, Codex, and Trae.

Defaults:

- `cursor` writes `<project>/.cursor/rules/<skill-name>.mdc`.
- `codex` writes `$CODEX_HOME/skills/<skill-name>` or `~/.codex/skills/<skill-name>`.
- `trae` writes `<project>/.trae/skills/<skill-name>.md`.

Useful options:

```bash
python3 skill-sync/scripts/sync_skills.py /path/to/skills --project /path/to/project --targets cursor,trae
python3 skill-sync/scripts/sync_skills.py . --targets cursor --target-root cursor=/tmp/project/.cursor/rules
python3 skill-sync/scripts/sync_skills.py . --targets cursor,trae --remove-stale
```

Additional built-in targets are `claude`, `windsurf`, and `copilot`.
