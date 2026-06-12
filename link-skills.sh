#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"
CURSOR_SKILLS="${CURSOR_HOME:-$HOME/.cursor}/skills"
TRAE_SKILLS="${TRAE_HOME:-$HOME/.trae}/skills"
ZED_SKILLS="${ZED_HOME:-$HOME/.agents}/skills"

warn() {
  printf 'warn: %s\n' "$*" >&2
}

copy_path() {
  local source="$1"
  local destination="$2"

  if ! mkdir -p "$(dirname "$destination")"; then
    warn "skip $destination: cannot create parent directory"
    return 0
  fi

  # 先清理旧软链接，再替换已有目录，避免工具继续识别为链接。
  if [[ -L "$destination" ]]; then
    if ! rm -f "$destination"; then
      warn "skip $destination: cannot remove existing symlink"
      return 0
    fi
  elif [[ -e "$destination" ]]; then
    if ! rm -rf "$destination"; then
      warn "skip $destination: cannot remove existing path"
      return 0
    fi
  fi

  if ! cp -R "$source" "$destination"; then
    warn "skip $destination: copy failed"
    return 0
  fi

  printf '%s <= %s\n' "$destination" "$source"
}

TARGET_ROOTS=(
  "$CODEX_SKILLS"
  "$CURSOR_SKILLS"
  "$TRAE_SKILLS"
  "$ZED_SKILLS"
)

for target_root in "${TARGET_ROOTS[@]}"; do
  if ! mkdir -p "$target_root"; then
    warn "skip $target_root: cannot create target root"
  fi
done

for skill_dir in "$ROOT"/*; do
  [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue

  skill_name="$(basename "$skill_dir")"

  for target_root in "${TARGET_ROOTS[@]}"; do
    copy_path "$skill_dir" "$target_root/$skill_name"
  done
done
