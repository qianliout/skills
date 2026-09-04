#!/usr/bin/env bash
# 人提供 secret/db.secret.env 后自动建库。默认 dry-run，--apply 才执行。永不 DROP。
# Usage: ma-provision-db.sh --env test --svc ainews --out /path/add-srv [--db name] [--owner role] [--apply]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" OUT="" DB="" OWNER="" APPLY=0 SCHEMA_DIR="" SCHEMA_LIST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --db) DB="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --schema-dir) SCHEMA_DIR="$2"; shift 2 ;;
    --schema-list) SCHEMA_LIST="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> --out <add-srv> [--apply]" >&2
  exit 2
}

ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
ADD="$(ma_add_root "$OUT" "$ENVNAME" "$SVC")"
CONN="${ADD}/secret/db.secret.env"
[[ -f "$CONN" ]] || { echo "missing ${CONN}; scaffold 应已生成 secret/db.secret.env，向用户要连接后填入" >&2; exit 1; }

if [[ -z "$DB" ]]; then
  DB="${SVC//-/_}"
fi

if [[ -z "$SCHEMA_LIST" && -f "${ADD}/schema-order.txt" ]]; then
  SCHEMA_LIST="${ADD}/schema-order.txt"
fi
if [[ -z "$SCHEMA_DIR" && -f "${ADD}/probe.json" ]]; then
  SCHEMA_DIR="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("git_root",""))' "${ADD}/probe.json")"
fi

args=(
  --conn "$CONN"
  --class miniapp
  --env "$ENVNAME"
  --db "$DB"
)
[[ -n "$OWNER" ]] && args+=(--owner "$OWNER")
[[ -n "$SCHEMA_DIR" ]] && args+=(--schema-dir "$SCHEMA_DIR")
[[ -n "$SCHEMA_LIST" ]] && args+=(--schema-list "$SCHEMA_LIST")
if [[ "$APPLY" -eq 1 ]]; then
  args+=(--apply)
  if [[ "$ENVNAME" == "prod" ]]; then
    args+=(--prod-confirm)
  fi
fi

bash "${SCRIPT_DIR}/lib/provision-db.sh" "${args[@]}"
