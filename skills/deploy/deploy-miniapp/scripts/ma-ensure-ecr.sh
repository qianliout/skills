#!/usr/bin/env bash
# 在 ap-east-1 建 zymix_mini_app/<repo>。已存在则跳过。
# Usage: ma-ensure-ecr.sh --env test --svc ainews --out /path/add-srv
#        ma-ensure-ecr.sh --env test --svc ainews --ecr-repo zymix_mini_app/foo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" OUT="" ECR_REPO=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --ecr-repo) ECR_REPO="$2"; shift 2 ;;
    -h|--help) sed -n '2,5p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> [--out <add-srv>|--ecr-repo <ns/name>]" >&2
  exit 2
}

ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
if [[ -z "$ECR_REPO" && -n "$OUT" ]]; then
  ADD="$(ma_add_root "$OUT" "$ENVNAME" "$SVC")"
  if [[ -f "${ADD}/probe.json" ]]; then
    ECR_REPO="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("ecr_repo",""))' "${ADD}/probe.json")"
  fi
fi
[[ -n "$ECR_REPO" ]] || ECR_REPO="${IMAGE_NS}/${SVC}"

ssh -o BatchMode=yes "$JUMP" "aws ecr describe-repositories --region '${AWS_REGION}' --repository-names '${ECR_REPO}' >/dev/null 2>&1 || aws ecr create-repository --region '${AWS_REGION}' --repository-name '${ECR_REPO}' --image-tag-mutability MUTABLE"
echo "ecr ${ECR_REGISTRY}/${ECR_REPO}"
