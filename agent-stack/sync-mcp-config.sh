#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PATH="$ROOT/agent-stack/manifests/mcp-servers.json"
TARGET_PATH="${CLAUDE_HOME:-$HOME/.claude}/mcp.json"
DRY_RUN=0
LIST_ONLY=0
BACKUP=1

warn() {
  printf 'warn: %s\n' "$*" >&2
}

usage() {
  cat <<'EOF'
Usage: ./agent-stack/sync-mcp-config.sh [options]

Merge curated MCP server definitions into an MCP config JSON file.

Options:
  --dry-run           Print target and server names without writing files.
  --list              List source servers, then exit.
  --source <path>     Use a custom source JSON file.
  --target <path>     Write to a specific target JSON file.
  --project           Write to ./.mcp.json under this repository root.
  --global            Write to ~/.claude/mcp.json.
  --no-backup         Do not create a .bak file before overwriting.
  -h, --help          Show this help.

Notes:
  Existing target JSON is preserved and merged by mcpServers key.
  Source server names overwrite target server names when they match.
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
    --source)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--source requires a file path"
        exit 2
      fi
      SOURCE_PATH="$2"
      shift 2
      ;;
    --target)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--target requires a file path"
        exit 2
      fi
      TARGET_PATH="$2"
      shift 2
      ;;
    --project)
      TARGET_PATH="$ROOT/.mcp.json"
      shift
      ;;
    --global)
      TARGET_PATH="${CLAUDE_HOME:-$HOME/.claude}/mcp.json"
      shift
      ;;
    --no-backup)
      BACKUP=0
      shift
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

if [[ ! -f "$SOURCE_PATH" ]]; then
  warn "source file not found: $SOURCE_PATH"
  exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  python3 - "$SOURCE_PATH" <<'PY'
import json
import sys

source_path = sys.argv[1]
with open(source_path, "r", encoding="utf-8") as f:
    data = json.load(f)

for name in data.get("mcpServers", {}):
    print(name)
PY
  exit 0
fi

target_parent="$(dirname "$TARGET_PATH")"
if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'dry-run: target => %s\n' "$TARGET_PATH"
else
  mkdir -p "$target_parent"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  python3 - "$SOURCE_PATH" <<'PY'
import json
import sys

source_path = sys.argv[1]
with open(source_path, "r", encoding="utf-8") as f:
    data = json.load(f)

for name in data.get("mcpServers", {}):
    print(f"dry-run: merge server => {name}")
PY
  exit 0
fi

if [[ "$BACKUP" -eq 1 && -f "$TARGET_PATH" ]]; then
  cp "$TARGET_PATH" "$TARGET_PATH.bak"
  printf 'backup: %s.bak\n' "$TARGET_PATH"
fi

python3 - "$SOURCE_PATH" "$TARGET_PATH" <<'PY'
import json
import os
import sys

source_path = sys.argv[1]
target_path = sys.argv[2]

with open(source_path, "r", encoding="utf-8") as f:
    source = json.load(f)

if os.path.exists(target_path):
    with open(target_path, "r", encoding="utf-8") as f:
        target = json.load(f)
else:
    target = {}

if not isinstance(target, dict):
    raise SystemExit(f"target JSON root must be an object: {target_path}")

target_servers = target.setdefault("mcpServers", {})
source_servers = source.get("mcpServers", {})

if not isinstance(target_servers, dict):
    raise SystemExit(f"target mcpServers must be an object: {target_path}")
if not isinstance(source_servers, dict):
    raise SystemExit(f"source mcpServers must be an object: {source_path}")

target_servers.update(source_servers)

with open(target_path, "w", encoding="utf-8") as f:
    json.dump(target, f, ensure_ascii=False, indent=2)
    f.write("\n")

for name in source_servers:
    print(f"merged: {name}")
PY

printf 'done: %s\n' "$TARGET_PATH"
printf 'next: update placeholder paths, tokens, and restart Claude Code\n'
