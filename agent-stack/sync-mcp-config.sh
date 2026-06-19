#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PATH="$ROOT/agent-stack/manifests/mcp-servers.json"
PROFILE_PATH="$ROOT/agent-stack/manifests/mcp-sync-profiles.json"
TARGET_PATH="${CLAUDE_HOME:-$HOME/.claude}/mcp.json"
TARGET_FORMAT="json"
TARGET_CLIENT="claude"
DRY_RUN=0
LIST_ONLY=0

warn() {
  printf 'warn: %s\n' "$*" >&2
}

load_env_file() {
  local env_file="$1"

  if [[ -f "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    . "$env_file"
    set +a
  fi
}

load_env_file "$ROOT/.env"
load_env_file "$ROOT/.env.local"

usage() {
  cat <<'EOF'
Usage: ./agent-stack/sync-mcp-config.sh [options]

Merge curated MCP server definitions into an MCP config file.

Options:
  --dry-run           Print target and server names without writing files.
  --list              List source servers, then exit.
  --source <path>     Use a custom source JSON file.
  --profiles <path>   Use a custom MCP sync profile JSON file.
  --target <path>     Write to a specific target file.
  --global            Write to ~/.claude/mcp.json. Default.
  --claude            Write to ~/.claude/mcp.json.
  --reasonix          Write to ~/.reasonix/mcp.json.
  --codex             Write to ~/.codex/config.toml.
  --cursor            Write to ~/.cursor/mcp.json.
  -h, --help          Show this help.

Notes:
  Only servers enabled for the selected client profile are synced.
  JSON targets remove previously managed servers before writing the filtered set.
  Codex TOML target is updated through a managed block under [mcp_servers.*].
  Strings like ${VAR_NAME} are expanded from environment variables.
  Servers with unresolved required variables are skipped.
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
    --profiles)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--profiles requires a file path"
        exit 2
      fi
      PROFILE_PATH="$2"
      shift 2
      ;;
    --target)
      if [[ $# -lt 2 || -z "$2" ]]; then
        warn "--target requires a file path"
        exit 2
      fi
      TARGET_PATH="$2"
      case "$TARGET_PATH" in
        *.toml)
          TARGET_FORMAT="codex_toml"
          ;;
        *)
          TARGET_FORMAT="json"
          ;;
      esac
      shift 2
      ;;
    --global)
      TARGET_PATH="${CLAUDE_HOME:-$HOME/.claude}/mcp.json"
      TARGET_FORMAT="json"
      TARGET_CLIENT="claude"
      shift
      ;;
    --claude)
      TARGET_PATH="${CLAUDE_HOME:-$HOME/.claude}/mcp.json"
      TARGET_FORMAT="json"
      TARGET_CLIENT="claude"
      shift
      ;;
    --reasonix)
      TARGET_PATH="${REASONIX_HOME:-$HOME/.reasonix}/mcp.json"
      TARGET_FORMAT="json"
      TARGET_CLIENT="reasonix"
      shift
      ;;
    --codex)
      TARGET_PATH="${CODEX_HOME:-$HOME/.codex}/config.toml"
      TARGET_FORMAT="codex_toml"
      TARGET_CLIENT="codex"
      shift
      ;;
    --cursor)
      TARGET_PATH="${CURSOR_HOME:-$HOME/.cursor}/mcp.json"
      TARGET_FORMAT="json"
      TARGET_CLIENT="cursor"
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

if [[ ! -f "$PROFILE_PATH" ]]; then
  warn "profile file not found: $PROFILE_PATH"
  exit 1
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  python3 - "$SOURCE_PATH" "$PROFILE_PATH" "$TARGET_CLIENT" <<'PY'
import json
import os
import re
import sys

source_path = sys.argv[1]
profile_path = sys.argv[2]
target_client = sys.argv[3]

with open(source_path, "r", encoding="utf-8") as f:
    source = json.load(f)
with open(profile_path, "r", encoding="utf-8") as f:
    profiles = json.load(f)

all_servers = source.get("mcpServers", {})
client_servers = profiles.get("clients", {}).get(target_client, [])

pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")

def resolve(value, missing):
    if isinstance(value, str):
        def repl(match):
            env_name = match.group(1)
            env_value = os.environ.get(env_name, "")
            if not env_value:
                missing.add(env_name)
                return match.group(0)
            return env_value
        return pattern.sub(repl, value)
    if isinstance(value, list):
        return [resolve(item, missing) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item, missing) for key, item in value.items()}
    return value

for name in client_servers:
    config = all_servers.get(name)
    if config is None:
        continue
    missing = set()
    resolve(config, missing)
    if missing:
        continue
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
  python3 - "$SOURCE_PATH" "$PROFILE_PATH" "$TARGET_CLIENT" <<'PY'
import copy
import json
import os
import re
import sys

source_path = sys.argv[1]
profile_path = sys.argv[2]
target_client = sys.argv[3]

with open(source_path, "r", encoding="utf-8") as f:
    source = json.load(f)
with open(profile_path, "r", encoding="utf-8") as f:
    profiles = json.load(f)

all_servers = source.get("mcpServers", {})
client_servers = profiles.get("clients", {}).get(target_client, [])
pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")

def resolve(value, missing):
    if isinstance(value, str):
        def repl(match):
            env_name = match.group(1)
            env_value = os.environ.get(env_name, "")
            if not env_value:
                missing.add(env_name)
                return match.group(0)
            return env_value
        return pattern.sub(repl, value)
    if isinstance(value, list):
        return [resolve(item, missing) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item, missing) for key, item in value.items()}
    return value

print(f"dry-run: client => {target_client}")
for name in client_servers:
    config = all_servers.get(name)
    if config is None:
        print(f"dry-run: skip server => {name} (missing from source manifest)")
        continue
    missing = set()
    resolve(copy.deepcopy(config), missing)
    if missing:
        joined = ", ".join(sorted(missing))
        print(f"dry-run: skip server => {name} (missing env: {joined})")
        continue
    print(f"dry-run: merge server => {name}")
PY
  exit 0
fi

if [[ "$TARGET_FORMAT" == "codex_toml" ]]; then
  python3 - "$SOURCE_PATH" "$PROFILE_PATH" "$TARGET_CLIENT" "$TARGET_PATH" <<'PY'
import copy
import json
import os
import re
import sys

source_path = sys.argv[1]
profile_path = sys.argv[2]
target_client = sys.argv[3]
target_path = sys.argv[4]

with open(source_path, "r", encoding="utf-8") as f:
    source = json.load(f)
with open(profile_path, "r", encoding="utf-8") as f:
    profiles = json.load(f)

all_servers = source.get("mcpServers", {})
if not isinstance(all_servers, dict):
    raise SystemExit(f"source mcpServers must be an object: {source_path}")

if os.path.exists(target_path):
    with open(target_path, "r", encoding="utf-8") as f:
        target_text = f.read()
else:
    target_text = ""

client_servers = profiles.get("clients", {}).get(target_client)
if not isinstance(client_servers, list):
    raise SystemExit(f"client profile not found: {target_client}")

pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")

def resolve(value, missing):
    if isinstance(value, str):
        def repl(match):
            env_name = match.group(1)
            env_value = os.environ.get(env_name, "")
            if not env_value:
                missing.add(env_name)
                return match.group(0)
            return env_value
        return pattern.sub(repl, value)
    if isinstance(value, list):
        return [resolve(item, missing) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item, missing) for key, item in value.items()}
    return value

source_servers = {}
for name in client_servers:
    config = all_servers.get(name)
    if config is None:
        print(f"skipped: {name} (missing from source manifest)")
        continue
    missing = set()
    resolved = resolve(copy.deepcopy(config), missing)
    if missing:
        joined = ", ".join(sorted(missing))
        print(f"skipped: {name} (missing env: {joined})")
        continue
    source_servers[name] = resolved

block_lines = ["# >>> skills-mcp managed >>>"]
for name, config in source_servers.items():
    quoted_name = json.dumps(name, ensure_ascii=False)
    block_lines.append(f"[mcp_servers.{quoted_name}]")
    block_lines.append(f"command = {json.dumps(config['command'], ensure_ascii=False)}")

    args = config.get("args", [])
    if args:
        block_lines.append(f"args = {json.dumps(args, ensure_ascii=False)}")

    env = config.get("env", {})
    if env:
        block_lines.append(f"[mcp_servers.{quoted_name}.env]")
        for env_key, env_value in env.items():
            block_lines.append(f"{env_key} = {json.dumps(env_value, ensure_ascii=False)}")

    block_lines.append("")

block_lines.append("# <<< skills-mcp managed <<<")
block_text = "\n".join(block_lines).rstrip() + "\n"

target_text = re.sub(
    r"\n?# >>> skills-mcp managed >>>.*?# <<< skills-mcp managed <<<\n?",
    "\n",
    target_text,
    flags=re.S,
)

if target_text and not target_text.endswith("\n"):
    target_text += "\n"

if target_text:
    target_text += "\n"

with open(target_path, "w", encoding="utf-8") as f:
    f.write(target_text)
    f.write(block_text)

for name in source_servers:
    print(f"merged: {name}")
PY
else
  python3 - "$SOURCE_PATH" "$PROFILE_PATH" "$TARGET_CLIENT" "$TARGET_PATH" <<'PY'
import copy
import json
import os
import re
import sys

source_path = sys.argv[1]
profile_path = sys.argv[2]
target_client = sys.argv[3]
target_path = sys.argv[4]

with open(source_path, "r", encoding="utf-8") as f:
    source = json.load(f)
with open(profile_path, "r", encoding="utf-8") as f:
    profiles = json.load(f)

if os.path.exists(target_path):
    with open(target_path, "r", encoding="utf-8") as f:
        target = json.load(f)
else:
    target = {}

if not isinstance(target, dict):
    raise SystemExit(f"target JSON root must be an object: {target_path}")

target_servers = target.setdefault("mcpServers", {})
all_servers = source.get("mcpServers", {})
client_servers = profiles.get("clients", {}).get(target_client)

if not isinstance(target_servers, dict):
    raise SystemExit(f"target mcpServers must be an object: {target_path}")
if not isinstance(all_servers, dict):
    raise SystemExit(f"source mcpServers must be an object: {source_path}")
if not isinstance(client_servers, list):
    raise SystemExit(f"client profile not found: {target_client}")

pattern = re.compile(r"\$\{([A-Z0-9_]+)\}")

def resolve(value, missing):
    if isinstance(value, str):
        def repl(match):
            env_name = match.group(1)
            env_value = os.environ.get(env_name, "")
            if not env_value:
                missing.add(env_name)
                return match.group(0)
            return env_value
        return pattern.sub(repl, value)
    if isinstance(value, list):
        return [resolve(item, missing) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item, missing) for key, item in value.items()}
    return value

for name in all_servers:
    target_servers.pop(name, None)

source_servers = {}
for name in client_servers:
    config = all_servers.get(name)
    if config is None:
        print(f"skipped: {name} (missing from source manifest)")
        continue
    missing = set()
    resolved = resolve(copy.deepcopy(config), missing)
    if missing:
        joined = ", ".join(sorted(missing))
        print(f"skipped: {name} (missing env: {joined})")
        continue
    source_servers[name] = resolved

target_servers.update(source_servers)

with open(target_path, "w", encoding="utf-8") as f:
    json.dump(target, f, ensure_ascii=False, indent=2)
    f.write("\n")

for name in source_servers:
    print(f"merged: {name}")
PY
fi

printf 'done: %s\n' "$TARGET_PATH"
printf 'next: update placeholder paths, env values, and restart the target client\n'
