#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=agent-links.sh
. "$ROOT/scripts/agent-links.sh"

AGENTS_TARGET="$HOME/.agents"
SKILLS_TARGET="$AGENTS_TARGET/skills"
MCPS_TARGET="$AGENTS_TARGET/mcps"

install_mcps() {
  mkdir -p "$MCPS_TARGET"

  find "$ROOT/mcps" -mindepth 1 -maxdepth 1 -print |
  while IFS= read -r mcp_path; do
    cp -R "$mcp_path" "$MCPS_TARGET/"
  done
}

"$ROOT/scripts/update-public.sh"
"$ROOT/scripts/check.sh"

while IFS='|' read -r category name repository source_path; do
  test -f "$ROOT/.sources/$repository/$source_path/SKILL.md"
done < "$ROOT/skills/manifests/public-skills.txt"

"$ROOT/scripts/clean.sh"

find "$ROOT/skills" -type f -name SKILL.md \
  ! -path "$ROOT/skills/manifests/*" \
  ! -path "$ROOT/skills/*/resources/*" -print |
while IFS= read -r skill_file; do
  skill_dir="${skill_file%/SKILL.md}"
  cp -R "$skill_dir" "$SKILLS_TARGET/${skill_dir##*/}"
done

while IFS='|' read -r category name repository source_path; do
  case "$category" in
    '' | '#'*)
      continue
      ;;
  esac

  cp -R "$ROOT/.sources/$repository/$source_path" "$SKILLS_TARGET/$name"
done < "$ROOT/skills/manifests/public-skills.txt"

install_mcps
link_agent_skills

printf 'installed: %s skills, %s mcp entries\n' \
  "$(find "$SKILLS_TARGET" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" \
  "$(find "$MCPS_TARGET" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
