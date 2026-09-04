#!/usr/bin/env bash
# test 和 prod 都可以跑 Job。
# Usage: ma-run-jenkins.sh --env test --svc ainews [--branch test]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" BRANCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> [--branch <name>]" >&2
  exit 2
}

ma_require_jcli
ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
JOB="$(ma_job_name "$ENVNAME" "$SVC")"
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

echo "build ${JOB} BRANCH=${BRANCH}"
jcli build "$JOB" -s -v -p "BRANCH=${BRANCH}"
