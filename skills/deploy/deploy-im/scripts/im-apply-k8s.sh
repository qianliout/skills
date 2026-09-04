#!/usr/bin/env bash
# apply ConfigMap / Deployment / Service。Secret 走 im-create-secret.sh。
# Usage: im-apply-k8s.sh --env test --svc activity --out /path/add-srv
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
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
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
K8S="${ADD}/k8s"

for f in 00-configmap.yaml 01-deployment.yaml 02-service.yaml; do
  [[ -f "${K8S}/${f}" ]] || { echo "missing ${K8S}/${f}" >&2; exit 1; }
done

if grep -q 'TODO' "${K8S}/00-configmap.yaml"; then
  echo "00-configmap.yaml still has TODO; write config from source first" >&2
  exit 1
fi

ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} -n ${NS} get deploy,svc,cm,secret | grep -w cloud-${SVC} && echo EXISTS || echo NEW"

for f in 00-configmap.yaml 01-deployment.yaml 02-service.yaml; do
  echo "apply ${f}"
  ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} apply -f -" < "${K8S}/${f}"
done
echo "applied k8s for cloud-${SVC} in ${NS}"
