#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_PATH="$ROOT/agent-stack/manifests/community-skills.txt"

DRY_RUN=0
LIST_ONLY=0
ONLY_SKILL=""
SKILLS_BIN="npx"
DEFAULT_AGENTS=("codex" "trae" "cursor" "zed" "warp" "reasonix")
TARGET_AGENTS=("${DEFAULT_AGENTS[@]}")

warn() {
  printf 'warn: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./agent-stack/install-community-skills.sh [options]

Install curated community skills from agent-stack/manifests/community-skills.txt.

Options:
  --dry-run          Print planned installs without running them.
  --list             List manifest entries, then exit.
  --only <name>      Install one matching manifest entry.
  --manifest <path>  Use a custom manifest file.
  --bin <command>    Override install command. Default: npx
  --agents <list>    Comma-separated agents. Default: codex,trae,cursor,zed,warp,reasonix
  -h, --help         Show this help.

Manifest format:
  One skill package per line.
  Empty lines and lines starting with # are ignored.
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
    --manifest)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--manifest requires a file path"
        exit 2
      fi
      MANIFEST_PATH="$2"
      shift 2
      ;;
    --bin)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--bin requires a command"
        exit 2
      fi
      SKILLS_BIN="$2"
      shift 2
      ;;
    --agents)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--agents requires a comma-separated value"
        exit 2
      fi
      IFS=',' read -r -a TARGET_AGENTS <<< "$2"
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

if [[ ! -f "$MANIFEST_PATH" ]]; then
  warn "manifest not found: $MANIFEST_PATH"
  exit 1
fi

matches_only() {
  local entry="$1"

  if [[ -z "$ONLY_SKILL" ]]; then
    return 0
  fi

  if [[ "$entry" == "$ONLY_SKILL" ]]; then
    return 0
  fi

  if [[ "$entry" == *"@$ONLY_SKILL" ]]; then
    return 0
  fi

  return 1
}

resolve_entry() {
  local entry="$1"
  local resolved

  if [[ "$entry" == *"@"* ]]; then
    printf '%s\n' "$entry"
    return 0
  fi

  resolved="$("$SKILLS_BIN" skills find "$entry" | perl -pe 's/\e\[[0-9;]*[[:alpha:]]//g' | awk '$1 ~ /@/ { print $1; exit }')"
  if [[ -z "$resolved" ]]; then
    warn "cannot resolve short skill name: $entry"
    return 1
  fi

  printf '%s\n' "$resolved"
}

run_install() {
  local entry="$1"
  local install_target

  install_target="$(resolve_entry "$entry")"

  if [[ "$entry" != "$install_target" ]]; then
    printf 'resolved: %s => %s\n' "$entry" "$install_target"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: %s skills add %s -y -g --agent %s\n' "$SKILLS_BIN" "$install_target" "${TARGET_AGENTS[*]}"
    return 0
  fi

  printf 'install: %s\n' "$install_target"
  "$SKILLS_BIN" skills add "$install_target" -y -g --agent "${TARGET_AGENTS[@]}" || warn "failed to install: $install_target"
}

found=0

while IFS= read -r line || [[ -n "$line" ]]; do
  entry="${line#"${line%%[![:space:]]*}"}"
  entry="${entry%"${entry##*[![:space:]]}"}"

  [[ -n "$entry" ]] || continue
  [[ "$entry" == \#* ]] && continue

  if ! matches_only "$entry"; then
    continue
  fi

  found=1

  if [[ "$LIST_ONLY" -eq 1 ]]; then
    printf '%s\n' "$entry"
    continue
  fi

  run_install "$entry"
done < "$MANIFEST_PATH"

if [[ "$found" -eq 0 ]]; then
  if [[ -n "$ONLY_SKILL" ]]; then
    warn "no manifest entry matches: $ONLY_SKILL"
  else
    warn "no installable entries found in manifest"
  fi
  exit 1
fi

if [[ "$LIST_ONLY" -eq 0 ]]; then
  printf 'done: restart Claude Code or your agent client to reload installed skills\n'
fi
