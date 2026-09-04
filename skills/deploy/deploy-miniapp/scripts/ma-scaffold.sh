#!/usr/bin/env bash
# 读源码，写出 <out>/<env>/<svc>/{k8s,jenkins-piplines,secret,doc}。
# Usage: ma-scaffold.sh --env test --svc ainews --src /path/repo --out /path/add-srv
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ma-env.sh
source "${SCRIPT_DIR}/lib/ma-env.sh"

ENVNAME="" SVC_IN="" SRC="" OUT="" PORT="" GIT_URL="" BRANCH="" ECR_REPO="" BUILD_MODE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENVNAME="$2"; shift 2 ;;
    --svc) SVC_IN="$2"; shift 2 ;;
    --src) SRC="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --git-url) GIT_URL="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --ecr-repo) ECR_REPO="$2"; shift 2 ;;
    --build-mode) BUILD_MODE="$2"; shift 2 ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$ENVNAME" && -n "$SVC_IN" && -n "$SRC" && -n "$OUT" ]] || {
  echo "usage: $0 --env <test|prod> --svc <name> --src <repo> --out <add-srv>" >&2
  exit 2
}
[[ -d "$SRC" ]] || { echo "src not a directory: ${SRC}" >&2; exit 2; }

ma_load_env "$ENVNAME"
SVC="$(ma_normalize_svc "$SVC_IN")"
ADD="$(ma_add_root "$OUT" "$ENVNAME" "$SVC")"
RESOURCE="$(ma_resource "$SVC")"
HOST="$(ma_ingress_host "$SVC")"
JOB="$(ma_job_name "$ENVNAME" "$SVC")"
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"

mkdir -p "$ADD"/{k8s,jenkins-piplines,secret,doc}

PROBE_JSON="$(python3 "${SCRIPT_DIR}/ma/probe_src.py" --src "$SRC" --svc "$SVC")"
printf '%s\n' "$PROBE_JSON" > "$ADD/probe.json"

python3 - "$ADD/probe.json" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
d = json.loads(p.read_text())
need = ("port", "git_url", "binary", "src_subdir", "config_arg", "config_mount",
        "build_mode", "ecr_repo", "has_healthz", "config_file", "sql_files", "git_root")
missing = [k for k in need if k not in d]
if missing:
    raise SystemExit(f"probe missing {missing}")
print("probed", d.get("language") or d.get("framework"), "port", d["port"], "build", d["build_mode"])
PY

eval "$(python3 - "$ADD/probe.json" <<'PY'
import json, shlex, sys
d = json.loads(open(sys.argv[1]).read())
def exp(k, v):
    print(f"{k}={shlex.quote(str(v))}")
exp("P_PORT", d["port"])
exp("P_GIT_URL", d.get("git_url") or "")
exp("P_BINARY", d["binary"])
exp("P_SUBDIR", d["src_subdir"])
exp("P_CONFIG_ARG", d["config_arg"])
exp("P_CONFIG_MOUNT", d["config_mount"])
exp("P_BUILD", d["build_mode"])
exp("P_ECR", d["ecr_repo"])
exp("P_HEALTHZ", "1" if d.get("has_healthz") else "0")
exp("P_CONFIG", d.get("config_file") or "")
exp("P_GIT_ROOT", d.get("git_root") or "")
exp("P_LANG", d.get("language") or "unknown")
exp("P_NEED_DF", "1" if d.get("needs_dockerfile") else "0")
exp("P_DOCKERFILE", d.get("dockerfile") or "")
PY
)"

PORT="${PORT:-$P_PORT}"
GIT_URL="${GIT_URL:-$P_GIT_URL}"
ECR_REPO="${ECR_REPO:-$P_ECR}"
BUILD_MODE="${BUILD_MODE:-$P_BUILD}"
[[ -n "$GIT_URL" ]] || { echo "git url empty; pass --git-url" >&2; exit 1; }

RENDER_K8S=(
  python3 "${SCRIPT_DIR}/ma/render_k8s.py"
  --svc "$SVC" --ns "$NS" --port "$PORT"
  --registry "$ECR_REGISTRY" --ecr-repo "$ECR_REPO"
  --ingress-host "$HOST"
  --config-arg="$P_CONFIG_ARG" --config-mount "$P_CONFIG_MOUNT"
  --out "$ADD/k8s"
)
if [[ "$P_HEALTHZ" == "1" ]]; then
  RENDER_K8S+=(--healthz)
fi
"${RENDER_K8S[@]}"

if [[ -n "$P_CONFIG" ]]; then
  python3 "${SCRIPT_DIR}/ma/seed_configmap.py" \
    --src-config "$P_CONFIG" --svc "$SVC" --ns "$NS" --out "$ADD/k8s"
else
  python3 - "$ADD/k8s" "$SVC" "$NS" "$PORT" <<'PY'
from pathlib import Path
import sys
out, svc, ns, port = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
out.mkdir(parents=True, exist_ok=True)
body = f"""apiVersion: v1
kind: ConfigMap
metadata:
  name: zymix-{svc}-configmap
  namespace: {ns}
  labels:
    app: zymix-{svc}
data:
  config.yaml: |
    # 从源码配置改写成此环境。镜像里未必带配置，按源码读法写完整一份。
    server:
      address: ":{port}"
"""
(out / "00-configmap.local.yaml").write_text(body)
(out / "00-configmap.example.yaml").write_text(body)
print(out / "00-configmap.local.yaml")
PY
fi

RENDER_JENKINS=(
  python3 "${SCRIPT_DIR}/ma/render_jenkins.py"
  --svc "$SVC" --env "$ENVNAME" --ns "$NS"
  --agent "$JENKINS_AGENT" --branch "$BRANCH"
  --git-url "$GIT_URL" --git-credentials "$GIT_CREDENTIALS_ID"
  --registry "$ECR_REGISTRY" --aws-region "$AWS_REGION"
  --ecr-repo "$ECR_REPO" --kubeconfig "$KUBECONFIG_PATH"
  --binary "$P_BINARY" --src-subdir "$P_SUBDIR" --port "$PORT"
  --language "$P_LANG" --build-mode "$BUILD_MODE"
  --git-root "$P_GIT_ROOT"
  --out "$ADD/jenkins-piplines"
)
if [[ -n "${P_DOCKERFILE:-}" ]]; then
  RENDER_JENKINS+=(--dockerfile "$P_DOCKERFILE")
fi
"${RENDER_JENKINS[@]}"

python3 "${SCRIPT_DIR}/lib/job_xml.py" inject \
  "$ADD/jenkins-piplines/config.xml" \
  "$ADD/jenkins-piplines/Jenkinsfile" \
  -o "$ADD/jenkins-piplines/config.xml"

if [[ ! -f "$ADD/secret/db.secret.env.example" ]]; then
  cp "${SCRIPT_DIR}/../templates/db/db.secret.env.example" "$ADD/secret/db.secret.env.example"
fi

python3 - "$ADD/probe.json" "$ADD/schema-order.txt" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
files = d.get("sql_files") or []
Path(sys.argv[2]).write_text("".join(f"{x}\n" for x in files), encoding="utf-8")
PY

{
  echo "resource=${RESOURCE}"
  echo "job=${JOB}"
  echo "ingress=${HOST}"
  echo "ecr=${ECR_REGISTRY}/${ECR_REPO}"
  echo "ns=${NS}"
  echo "jump=${JUMP}"
} > "$ADD/doc/scaffold.txt"

if [[ "${P_NEED_DF:-0}" == "1" ]]; then
  echo "WARN: source had no usable Dockerfile; generated one into Jenkinsfile writeFile — review Build image stage" >&2
fi

echo "scaffolded ${ADD}"
echo "job ${JOB}  ingress ${HOST}  language ${P_LANG}"
