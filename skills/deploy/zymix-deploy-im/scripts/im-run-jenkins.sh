#!/usr/bin/env bash
# test：主 Job + selective 都跑。stage：只跑 selective。
# prod：直接拒绝。agent 不得以任何方式触发 prod Job。
# Usage: im-run-jenkins.sh --env test --svc activity
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

if [[ "$ENVNAME" == "prod" || "$JOB_MAIN" == prod-* || "$JOB_SEL" == prod-* ]]; then
  echo "REFUSE: prod Jenkins must not be triggered by this skill (no jcli build, no replay, no click)." >&2
  exit 3
fi

im_require_jcli

run_sel() {
  echo "build ${JOB_SEL} SELECTED_SERVICES=${SVC} BRANCH=${DEFAULT_BRANCH}"
  jcli build "$JOB_SEL" -s -v -p "BRANCH=${DEFAULT_BRANCH}" -p "SELECTED_SERVICES=${SVC}"
}

if [[ "$ENVNAME" == "test" ]]; then
  echo "build ${JOB_MAIN} BRANCH=${DEFAULT_BRANCH}"
  jcli build "$JOB_MAIN" -s -v -p "BRANCH=${DEFAULT_BRANCH}"
  run_sel
  exit 0
fi

run_sel
