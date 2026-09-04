#!/usr/bin/env bash
# 新建或更新一服务一 Job。默认 dry-run，--apply 才写入。
# Usage: ma-create-job.sh --env test --svc ainews --out /path/add-srv [--apply]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" OUT="" APPLY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> --out <add-srv> [--apply]" >&2
  exit 2
}

ma_require_jcli
ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
ADD="$(ma_add_root "$OUT" "$ENVNAME" "$SVC")"
JOB="$(ma_job_name "$ENVNAME" "$SVC")"
XML="${ADD}/jenkins-piplines/config.xml"
JF="${ADD}/jenkins-piplines/Jenkinsfile"

[[ -f "$XML" && -f "$JF" ]] || { echo "missing Jenkinsfile or config.xml in ${ADD}/jenkins-piplines" >&2; exit 1; }

if grep -Eq '\{\{[A-Z][A-Z0-9_]*\}\}' "$JF"; then
  echo "Jenkinsfile still has unfilled placeholders" >&2
  exit 1
fi

exists=0
if jcli get-job "$JOB" >/dev/null 2>&1; then
  exists=1
fi

echo "=== ${JOB} ==="
echo "  xml: ${XML}"
if [[ "$exists" -eq 1 ]]; then
  echo "  exists: will update-job"
else
  echo "  missing: will create-job"
fi
echo "  view: ${VIEW}"

if [[ "$APPLY" -eq 0 ]]; then
  echo "  dry-run (pass --apply to write)"
  exit 0
fi

if [[ "$exists" -eq 1 ]]; then
  tmp="$(mktemp)"
  jcli get-job "$JOB" > "$tmp"
  python3 "${SCRIPT_DIR}/lib/job_xml.py" inject "$tmp" "$JF" -o "$tmp.out"
  jcli update-job "$JOB" < "$tmp.out"
  rm -f "$tmp" "$tmp.out"
  echo "  updated"
else
  jcli create-job "$JOB" < "$XML"
  echo "  created"
fi

if jcli view add-job "$VIEW" "$JOB" >/dev/null 2>&1; then
  echo "  added to view ${VIEW}"
else
  echo "  WARN: add to view ${VIEW} failed; add it in Jenkins UI" >&2
fi
