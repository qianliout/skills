#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"
CURSOR_SKILLS="${CURSOR_HOME:-$HOME/.cursor}/skills"
TRAE_SKILLS="${TRAE_HOME:-$HOME/.trae}/skills"
ZED_SKILLS="${ZED_HOME:-$HOME/.zed}/skills"
WARP_SKILLS="${WARP_HOME:-$HOME/.warp}/skills"
REASONIX_SKILLS="${REASONIX_HOME:-$HOME/.reasonix}/skills"

DRY_RUN=0
LIST_ONLY=0
ONLY_SKILL=""

warn() {
  printf 'warn: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./agent-stack/link-local-skills.sh [options]

Copy every local skill folder in this repository to local AI tool skill directories.

Options:
  --dry-run          Print planned copies without writing files.
  --list             List detected local skills and target roots, then exit.
  --only <name>      Copy only one skill folder.
  -h, --help         Show this help.

Environment overrides:
  CODEX_HOME         Default: ~/.codex
  CURSOR_HOME        Default: ~/.cursor
  TRAE_HOME          Default: ~/.trae
  ZED_HOME           Default: ~/.zed
  WARP_HOME          Default: ~/.warp
  REASONIX_HOME      Default: ~/.reasonix
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    --only)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--only requires a skill name"
        exit 2
      fi
      ONLY_SKILL="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      warn "unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

canonical_path() {
  local path="$1"
  local parent
  local base

  if [[ -e "$path" ]]; then
    (cd "$path" && pwd -P)
    return
  fi

  parent="$(dirname "$path")"
  base="$(basename "$path")"
  if [[ -d "$parent" ]]; then
    printf '%s/%s\n' "$(cd "$parent" && pwd -P)" "$base"
    return
  fi

  printf '%s\n' "$path"
}

copy_path() {
  local source="$1"
  local destination="$2"
  local source_real
  local destination_real

  source_real="$(canonical_path "$source")"
  destination_real="$(canonical_path "$destination")"

  if [[ "$source_real" == "$destination_real" ]]; then
    warn "skip $destination: source and destination are the same path"
    return 0
  fi

  case "$destination_real" in
    "$source_real"/*)
      warn "skip $destination: destination is inside source"
      return 0
      ;;
  esac

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: %s <= %s\n' "$destination" "$source"
    return 0
  fi

  if ! mkdir -p "$(dirname "$destination")"; then
    warn "skip $destination: cannot create parent directory"
    return 0
  fi

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

TARGET_NAMES=(
  "codex"
  "cursor"
  "trae"
  "zed"
  "warp"
  "reasonix"
)

TARGET_ROOTS=(
  "$CODEX_SKILLS"
  "$CURSOR_SKILLS"
  "$TRAE_SKILLS"
  "$ZED_SKILLS"
  "$WARP_SKILLS"
  "$REASONIX_SKILLS"
)

if [[ "$LIST_ONLY" -eq 1 ]]; then
  printf 'skills:\n'
  for skill_dir in "$ROOT"/*; do
    [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue
    skill_name="$(basename "$skill_dir")"
    if [[ -n "$ONLY_SKILL" && "$skill_name" != "$ONLY_SKILL" ]]; then
      continue
    fi
    printf '  - %s\n' "$skill_name"
  done

  printf 'targets:\n'
  for i in "${!TARGET_ROOTS[@]}"; do
    printf '  - %s: %s\n' "${TARGET_NAMES[$i]}" "${TARGET_ROOTS[$i]}"
  done
  exit 0
fi

for i in "${!TARGET_ROOTS[@]}"; do
  target_root="${TARGET_ROOTS[$i]}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: target %s => %s\n' "${TARGET_NAMES[$i]}" "$target_root"
  elif ! mkdir -p "$target_root"; then
    warn "skip $target_root: cannot create target root"
  fi
done

found_skill=0

for skill_dir in "$ROOT"/*; do
  [[ -d "$skill_dir" && -f "$skill_dir/SKILL.md" ]] || continue

  skill_name="$(basename "$skill_dir")"
  if [[ -n "$ONLY_SKILL" && "$skill_name" != "$ONLY_SKILL" ]]; then
    continue
  fi

  found_skill=1

  for target_root in "${TARGET_ROOTS[@]}"; do
    copy_path "$skill_dir" "$target_root/$skill_name"
  done
done

if [[ "$found_skill" -eq 0 ]]; then
  if [[ -n "$ONLY_SKILL" ]]; then
    warn "no skill named $ONLY_SKILL found under $ROOT"
  else
    warn "no skill folders with SKILL.md found under $ROOT"
  fi
  exit 1
fi
