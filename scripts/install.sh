#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$HOME/.agents/skills"

"$ROOT/scripts/update-public.sh"

while IFS='|' read -r category name repository source_path; do
  test -f "$ROOT/.sources/$repository/$source_path/SKILL.md"
done < "$ROOT/manifests/public-skills.txt"

"$ROOT/scripts/clean.sh"

find "$ROOT/skills" -mindepth 4 -maxdepth 4 -type f -name SKILL.md -print |
while IFS= read -r skill_file; do
  skill_dir="${skill_file%/SKILL.md}"
  cp -R "$skill_dir" "$TARGET/${skill_dir##*/}"
done

while IFS='|' read -r category name repository source_path; do
  cp -R "$ROOT/.sources/$repository/$source_path" "$TARGET/$name"
done < "$ROOT/manifests/public-skills.txt"

printf 'installed: %s skills\n' "$(find "$TARGET" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
