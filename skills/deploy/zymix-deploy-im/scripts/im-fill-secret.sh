#!/usr/bin/env bash
# 从同 namespace 现网 cloud-*-secret 回填 secret.env。只打印 key 名和来源，不打印值。
# 退出 0=全齐；2=有 MISSING，需用户补。
# Usage: im-fill-secret.sh --env test --svc activity --out /path/add-srv
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/im-env.sh
source "${SCRIPT_DIR}/lib/im-env.sh"

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
  echo "usage: $0 --env <test|stage|prod> --svc <name> --out <add-srv>" >&2
  exit 2
}

im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
ADD="$(im_add_root "$OUT" "$ENVNAME" "$SVC")"
CM="${ADD}/k8s/00-configmap.yaml"
ENV_FILE="${ADD}/secret/${SVC}.secret.env"
SECRET="cloud-${SVC}-secret"

[[ -f "$CM" ]] || { echo "missing ${CM}" >&2; exit 1; }

# 值不经过终端：ssh 的 json 只进 python stdin，stdout 只有 key 状态。
set +e
ssh -o BatchMode=yes "$JUMP" \
  "kubectl --kubeconfig=${KUBECONFIG_PATH} -n ${NS} get secret -o json" \
  | python3 "${SCRIPT_DIR}/im/fill_secret.py" \
      --cm "$CM" --out "$ENV_FILE" --skip-secret "$SECRET"
rc=$?
set -e

echo "wrote ${ENV_FILE} (values not printed)"
if [[ "$rc" -eq 2 ]]; then
  echo "MISSING keys need user values. Re-run create after they are in ${ENV_FILE}." >&2
fi
exit "$rc"
