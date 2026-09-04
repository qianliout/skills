#!/usr/bin/env bash
# apply ConfigMap / Deployment / Service / Ingress。
# Usage: ma-apply-k8s.sh --env test --svc ainews --out /path/add-srv
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
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
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
K8S="${ADD}/k8s"
RESOURCE="$(ma_resource "$SVC")"

CM="${K8S}/00-configmap.yaml"
[[ -f "$CM" ]] || { echo "missing configmap (want 00-configmap.yaml)" >&2; exit 1; }

for f in 01-deployment.yaml 02-service.yaml 03-ingress.yaml; do
  [[ -f "${K8S}/${f}" ]] || { echo "missing ${K8S}/${f}" >&2; exit 1; }
done

if grep -Eq 'REPLACE_ME|TODO|\{\{[A-Z][A-Z0-9_]*\}\}' "$CM" "${K8S}/01-deployment.yaml" "${K8S}/03-ingress.yaml"; then
  echo "placeholders still in k8s yaml; finish config first" >&2
  exit 1
fi

ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} -n ${NS} get deploy,svc,cm,ingress | grep -w ${RESOURCE} && echo EXISTS || echo NEW"

echo "apply $(basename "$CM")"
ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} apply -f -" < "$CM"
for f in 01-deployment.yaml 02-service.yaml 03-ingress.yaml; do
  echo "apply ${f}"
  ssh -o BatchMode=yes "$JUMP" "kubectl --kubeconfig=${KUBECONFIG_PATH} apply -f -" < "${K8S}/${f}"
done
echo "applied ${RESOURCE} in ${NS}"
