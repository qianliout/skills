#!/usr/bin/env bash
# Generate OpenAPI 3.1.0 JSON for a single Gin interface.
# Deterministic pre-flight: validates input, locates project root, resolves output path.
# The subagent (SKILL.md) handles code analysis and JSON generation.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate.sh <METHOD> <PATH> [--output <filepath>]
       generate.sh <HANDLER_FUNC> [--output <filepath>]

  METHOD + PATH   HTTP method and route path (e.g. PUT /api/v2/scanner/detect/policy)
  HANDLER_FUNC    Handler function name (e.g. UserAPI.CreateUser)
  --output <path> Write to <path> instead of auto-naming

Examples:
  generate.sh PUT /api/v2/scanner/detect/policy
  generate.sh PUT /api/v2/scanner/detect/policy --output docs/policy.json
  generate.sh UserAPI.CreateUser
EOF
  exit 1
}

# ── parse arguments ────────────────────────────────────────────────
OUTPUT=""
SELECTOR=""
METHOD=""
PATH_SPEC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --output)
      [ $# -gt 1 ] || { echo "ERROR: --output requires a value" >&2; exit 1; }
      shift; OUTPUT="$1" ;;
    --help|-h) usage ;;
    -*)
      echo "ERROR: unknown flag: $1" >&2; usage ;;
    *)
      if [ -z "$SELECTOR" ]; then
        SELECTOR="$1"
      else
        # Two positional args = METHOD + PATH
        METHOD="$SELECTOR"
        PATH_SPEC="$1"
        SELECTOR="${METHOD} ${PATH_SPEC}"
      fi ;;
  esac
  shift
done

if [ -z "$SELECTOR" ]; then
  echo "ERROR: no interface selector specified" >&2
  usage
fi

# ── locate project root (go.mod) ───────────────────────────────────
PROJECT_ROOT=""
SEARCH_DIR="$PWD"
while [ "$SEARCH_DIR" != "/" ]; do
  if [ -f "$SEARCH_DIR/go.mod" ]; then
    PROJECT_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [ -z "$PROJECT_ROOT" ]; then
  echo "ERROR: go.mod not found in $PWD or any parent directory" >&2
  exit 2
fi

# ── resolve output path ────────────────────────────────────────────
if [ -n "$OUTPUT" ]; then
  # Make absolute if relative
  [[ "$OUTPUT" != /* ]] && OUTPUT="${PROJECT_ROOT}/${OUTPUT}"
else
  # Auto-generate filename from last 2-3 path segments or handler name
  SAFE_NAME="$(echo "${SELECTOR}" \
    | sed 's/^[A-Z]\+ //' \
    | tr '/' '.' \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9.]//g' \
    | tr '.' '\n' \
    | tail -3 \
    | tr '\n' '_' \
    | sed 's/_$//;s/__*/_/g')"

  [ -z "$SAFE_NAME" ] && SAFE_NAME="$(echo "${SELECTOR}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g;s/__*/_/g;s/^_//;s/_$//')"
  [ -z "$SAFE_NAME" ] && SAFE_NAME="interface"

  OUTPUT="${PROJECT_ROOT}/openapi_${SAFE_NAME}.json"
fi

# ensure parent directory exists
mkdir -p "$(dirname "$OUTPUT")"

# ── emit resolved config ───────────────────────────────────────────
printf '{\n'
printf '  "selector":      "%s",\n'  "$SELECTOR"
printf '  "output":        "%s",\n'  "$OUTPUT"
printf '  "project_root":  "%s"\n'    "$PROJECT_ROOT"
printf '}\n'
