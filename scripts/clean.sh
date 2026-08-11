#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=agent-links.sh
. "$ROOT/scripts/agent-links.sh"

TARGET="$HOME/.agents"

clean_agent_skill_links

/bin/rm -rf "$TARGET/skills" "$TARGET/mcps"
mkdir -p "$TARGET/skills" "$TARGET/mcps"

printf 'cleaned: %s\n' "$TARGET"
