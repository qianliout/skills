#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"
CURSOR_SKILLS="${CURSOR_HOME:-$HOME/.cursor}/skills"
TRAE_SKILLS="${TRAE_HOME:-$HOME/.trae}/skills"

link_path() {
  local source="$1"
  local destination="$2"

  mkdir -p "$(dirname "$destination")"
  rm -rf "$destination"
  ln -s "$source" "$destination"
  printf '%s -> %s\n' "$destination" "$source"
}

mkdir -p "$CODEX_SKILLS" "$CURSOR_SKILLS" "$TRAE_SKILLS"

for skill_dir in "$ROOT"/*; do
  [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue

  skill_name="$(basename "$skill_dir")"

  link_path "$skill_dir" "$CODEX_SKILLS/$skill_name"
  link_path "$skill_dir" "$CURSOR_SKILLS/$skill_name"
  link_path "$skill_dir" "$TRAE_SKILLS/$skill_name"
done
