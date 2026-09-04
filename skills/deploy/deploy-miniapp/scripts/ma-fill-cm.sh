#!/usr/bin/env bash
# 从同 ns 现网 ConfigMap 回填 redis/pg 到 secret/shared.env。真值原样保留并可回显。
# 退出 0=全齐；2=有 MISSING，需用户补进 ConfigMap。
# Usage: ma-fill-cm.sh --env test --svc ainews --out /path/add-srv
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> --out <add-srv>" >&2
  exit 2
}

ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
ADD="$(ma_add_root "$OUT" "$ENVNAME" "$SVC")"
SKIP="$(ma_resource "$SVC")-configmap"
OUT_FILE="${ADD}/secret/shared.env"

set +e
ssh -o BatchMode=yes "$JUMP" \
  "kubectl --kubeconfig=${KUBECONFIG_PATH} -n ${NS} get configmap -o json" \
  | python3 "${SCRIPT_DIR}/ma/fill_cm.py" --out "$OUT_FILE" --skip-cm "$SKIP"
rc=$?
set -e

echo "wrote ${OUT_FILE} (real values, see VALUE lines above)"
if [[ "$rc" -eq 2 ]]; then
  echo "MISSING keys: copy from sibling CM into 00-configmap.yaml, or ask the user." >&2
fi
exit "$rc"
