#!/usr/bin/env bash
# 从 secret.env 建 Secret。不打印值。已存在则拒绝，除非 --force。
# Usage: im-create-secret.sh --env test --svc activity --out /path/add-srv [--force]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/im-env.sh
source "${SCRIPT_DIR}/lib/im-env.sh"

ENVNAME="" SVC_IN="" OUT="" FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|stage|prod> --svc <name> --out <add-srv> [--force]" >&2
  exit 2
}

im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
ADD="$(im_add_root "$OUT" "$ENVNAME" "$SVC")"
ENV_FILE="${ADD}/secret/${SVC}.secret.env"
SECRET="cloud-${SVC}-secret"

[[ -f "$ENV_FILE" ]] || { echo "missing ${ENV_FILE}" >&2; exit 1; }
if grep -Eq '=[[:space:]]*<.*>[[:space:]]*$|REPLACE_ME' "$ENV_FILE"; then
  echo "placeholder still in $(basename "$ENV_FILE")" >&2
  exit 1
fi
if ! awk -F= 'NF>1 && $0 !~ /^#/ && length($2)==0 { print "empty: " $1; found=1 } END { exit found?1:0 }' "$ENV_FILE"; then
  echo "fix empty values" >&2
  exit 1
fi

yaml="$(python3 - "$ENV_FILE" "$NS" "$SECRET" "$SVC" <<'PY'
import base64, pathlib, sys
env_file, ns, secret, svc = sys.argv[1:5]
data = {}
for raw in pathlib.Path(env_file).read_text().splitlines():
    if not raw or raw.lstrip().startswith("#") or "=" not in raw:
        continue
    k, v = raw.split("=", 1)
    data[k.strip()] = base64.b64encode(v.encode()).decode()
print("apiVersion: v1")
print("kind: Secret")
print("metadata:")
print(f"  name: {secret}")
print(f"  namespace: {ns}")
print(f"  labels:")
print(f"    app: cloud-{svc}")
print("type: Opaque")
print("data:")
for k in sorted(data):
    print(f"  {k}: {data[k]}")
PY
)"

exists="$(ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} -n ${NS} get secret ${SECRET} >/dev/null 2>&1 && echo yes || echo no")"
if [[ "$exists" == "yes" && "$FORCE" -ne 1 ]]; then
  echo "secret ${SECRET} already exists; use --force" >&2
  exit 1
fi

printf '%s\n' "$yaml" | ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} apply -f -"
echo "secret ${SECRET} applied in ${NS} (values not printed)"
