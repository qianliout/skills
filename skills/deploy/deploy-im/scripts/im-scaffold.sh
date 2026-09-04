#!/usr/bin/env bash
# 创建 <out>/<env>/<svc>/{k8s,jenkins-piplines,secret,doc}，渲染 Deployment / Service。
# Usage: im-scaffold.sh --env test --svc activity --port 9008 --out /path/add-srv [--kafka]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/im-env.sh
source "${SCRIPT_DIR}/lib/im-env.sh"

ENVNAME="" SVC_IN="" PORT="" OUT="" KAFKA=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --kafka) KAFKA=1; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$PORT" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|stage|prod> --svc <name> --port <rpc> --out <add-srv> [--kafka]" >&2
  exit 2
}

im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
ADD="$(im_add_root "$OUT" "$ENVNAME" "$SVC")"

mkdir -p "$ADD"/{k8s,jenkins-piplines/cloud-im-go-server,jenkins-piplines/cloud-im-go-server-selective,secret,doc}

python3 "${SCRIPT_DIR}/im/render_k8s.py" \
  --env "$ENVNAME" --svc "$SVC" --port "$PORT" \
  --ns "$NS" --registry "$ECR_REGISTRY" --image-ns "$IMAGE_NS" \
  ${KAFKA:+--kafka} \
  --out "$ADD/k8s"

if [[ ! -f "$ADD/secret/${SVC}.secret.env" ]]; then
  printf '%s\n' "# 真值文件：${SVC}.secret.env（审批产物，真值原样保留）" "# KEY=VALUE" \
    > "$ADD/secret/${SVC}.secret.env"
fi

if [[ ! -f "$ADD/k8s/00-configmap.yaml" ]]; then
  cat > "$ADD/k8s/00-configmap.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: cloud-config-${SVC}
  namespace: ${NS}
  labels:
    app: cloud-${SVC}
data:
  config.yaml: |
    # 从源码 app/${SVC}/configs/config.yaml 改写成此环境
    # 敏感位只写 \${VAR}
EOF
fi

echo "scaffolded ${ADD}"
