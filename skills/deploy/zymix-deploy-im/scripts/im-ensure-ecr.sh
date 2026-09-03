#!/usr/bin/env bash
# 在对应环境的 AWS ECR 建好仓库。已存在则跳过。
# Usage: im-ensure-ecr.sh --env test --svc activity
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/im-env.sh
source "${SCRIPT_DIR}/lib/im-env.sh"

ENVNAME="" SVC_IN=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" ]] || {
  echo "usage: $0 --env <test|stage|prod> --svc <name>" >&2
  exit 2
}

im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
REPO="${IMAGE_NS}/${SVC}"

ssh -o BatchMode=yes "$JUMP" "aws ecr describe-repositories --region '${AWS_REGION}' --repository-names '${REPO}' >/dev/null 2>&1 || aws ecr create-repository --region '${AWS_REGION}' --repository-name '${REPO}'"
echo "ecr ${ECR_REGISTRY}/${REPO}"
