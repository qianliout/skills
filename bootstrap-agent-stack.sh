#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERNAL_DIR="$ROOT/agent-stack"

RUN_LOCAL_SKILLS=1
RUN_COMMUNITY_SKILLS=1
RUN_MCP=1
DRY_RUN=0
MCP_TARGET_FLAG="--global"

usage() {
  cat <<'EOF'
Usage: ./bootstrap-agent-stack.sh [options]

One command to:
  1. Sync local skills from this repository
  2. Install curated community skills
  3. Generate or merge MCP config

Options:
  --dry-run               Print planned actions without changing files.
  --no-local-skills       Skip local repository skill sync.
  --no-community-skills   Skip community skill installation.
  --no-mcp                Skip MCP config sync.
  --project               Write MCP config to ./.mcp.json.
  --global                Write MCP config to ~/.claude/mcp.json. Default.
  -h, --help              Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-local-skills)
      RUN_LOCAL_SKILLS=0
      shift
      ;;
    --no-community-skills)
      RUN_COMMUNITY_SKILLS=0
      shift
      ;;
    --no-mcp)
      RUN_MCP=0
      shift
      ;;
    --project)
      MCP_TARGET_FLAG="--project"
      shift
      ;;
    --global)
      MCP_TARGET_FLAG="--global"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'warn: unknown option: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$RUN_LOCAL_SKILLS" -eq 1 ]]; then
  printf 'step: sync local skills\n'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    "$INTERNAL_DIR/link-local-skills.sh" --dry-run
  else
    "$INTERNAL_DIR/link-local-skills.sh"
  fi
fi

if [[ "$RUN_COMMUNITY_SKILLS" -eq 1 ]]; then
  printf 'step: install community skills\n'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    "$INTERNAL_DIR/install-community-skills.sh" --dry-run
  else
    "$INTERNAL_DIR/install-community-skills.sh"
  fi
fi

if [[ "$RUN_MCP" -eq 1 ]]; then
  printf 'step: sync mcp config\n'
  if [[ "$DRY_RUN" -eq 1 ]]; then
    "$INTERNAL_DIR/sync-mcp-config.sh" "$MCP_TARGET_FLAG" --dry-run
  else
    "$INTERNAL_DIR/sync-mcp-config.sh" "$MCP_TARGET_FLAG"
  fi
fi

printf 'done: review ~/.claude/mcp.json or your explicit target file before first use\n'
