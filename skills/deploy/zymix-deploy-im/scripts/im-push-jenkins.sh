#!/usr/bin/env bash
# 把 add-srv 里改过的 Jenkinsfile 推回线上。默认 dry-run，--apply 才写入。
# Usage: im-push-jenkins.sh --env test --svc activity --out /path/add-srv [--apply]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/im-env.sh
source "${SCRIPT_DIR}/lib/im-env.sh"

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
  echo "usage: $0 --env <test|stage|prod> --svc <name> --out <add-srv> [--apply]" >&2
  exit 2
}

im_require_jcli
im_load_env "$ENVNAME"
SVC="$(im_normalize_svc "$SVC_IN")"
ADD="$(im_add_root "$OUT" "$ENVNAME" "$SVC")"
JF_DIR="${ADD}/jenkins-piplines"

push_one() {
  local job="$1" jf="$2"
  [[ -f "$jf" ]] || { echo "missing ${jf}" >&2; return 1; }
  if [[ -f "${jf}.orig" ]]; then
    if ! diff -u "${jf}.orig" "$jf" | grep -Eq '^\+[^+]'; then
      echo "WARN ${job}: no added lines vs pulled original" >&2
    fi
    if diff -u "${jf}.orig" "$jf" | grep -Eq '^-[^-]'; then
      echo "ERROR ${job}: diff has deletions; re-pull and add only" >&2
      return 1
    fi
  fi
  local tmp xml out
  tmp="$(mktemp -d)"
  xml="${tmp}/in.xml"
  out="${tmp}/out.xml"
  jcli get-job "$job" > "$xml"
  python3 "${SCRIPT_DIR}/lib/job_xml.py" inject "$xml" "$jf" -o "$out"
  echo "=== ${job} ==="
  echo "  jenkinsfile: ${jf}"
  if [[ "$APPLY" -eq 0 ]]; then
    echo "  dry-run (pass --apply to update-job)"
    rm -rf "$tmp"
    return 0
  fi
  jcli update-job "$job" < "$out"
  echo "  updated"
  rm -rf "$tmp"
}

push_one "$JOB_MAIN" "${JF_DIR}/cloud-im-go-server/Jenkinsfile"
push_one "$JOB_SEL" "${JF_DIR}/cloud-im-go-server-selective/Jenkinsfile"
