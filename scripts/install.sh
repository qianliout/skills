#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HOME/.agents/skills"

"$ROOT/scripts/update-public.sh"

while IFS='|' read -r category name repository source_path; do
  test -f "$ROOT/.sources/$repository/$source_path/SKILL.md"
done < "$ROOT/skills/manifests/public-skills.txt"

"$ROOT/scripts/clean.sh"

find "$ROOT/skills" -type f -name SKILL.md \
  ! -path "$ROOT/skills/manifests/*" \
  ! -path "$ROOT/skills/*/resources/*" -print |
while IFS= read -r skill_file; do
  skill_dir="${skill_file%/SKILL.md}"
  cp -R "$skill_dir" "$TARGET/${skill_dir##*/}"
done

while IFS='|' read -r category name repository source_path; do
  cp -R "$ROOT/.sources/$repository/$source_path" "$TARGET/$name"
done < "$ROOT/skills/manifests/public-skills.txt"

printf 'installed: %s skills\n' "$(find "$TARGET" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
