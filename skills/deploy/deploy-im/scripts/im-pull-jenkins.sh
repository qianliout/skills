#!/usr/bin/env bash
# 用本机 jcli 拉线上两条 Job 的 Jenkinsfile 到 <out>/<env>/<svc>/jenkins-piplines/。
# Usage: im-pull-jenkins.sh --env test --svc activity --out /path/add-srv
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

im_require_jcli
im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
ADD="$(im_add_root "$OUT" "$ENVNAME" "$SVC")"
JF_DIR="${ADD}/jenkins-piplines"
mkdir -p "${JF_DIR}/cloud-im-go-server" "${JF_DIR}/cloud-im-go-server-selective"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pull_one() {
  local job="$1" dest="$2"
  echo "pull ${job}"
  jcli get-job "$job" > "${tmp}/${job}.xml"
  python3 "${SCRIPT_DIR}/lib/job_xml.py" extract "${tmp}/${job}.xml" > "$dest"
  cp "$dest" "${dest}.orig"
}

pull_one "$JOB_MAIN" "${JF_DIR}/cloud-im-go-server/Jenkinsfile"
pull_one "$JOB_SEL" "${JF_DIR}/cloud-im-go-server-selective/Jenkinsfile"
echo "pulled into ${JF_DIR}"
