# miniapp 部署环境矩阵。被本 skill 的 ma-*.sh 引用。不依赖任何外部仓库。
# shellcheck shell=bash

ma_normalize_svc() {
  local raw="${1:-}"
  raw="${raw#zymix-}"
  raw="${raw%/}"
  if [[ -z "$raw" ]]; then
    echo "empty service name" >&2
    return 2
  fi
  echo "$raw"
}

ma_env_ok() {
  case "${1:-}" in
    test|prod) return 0 ;;
    *) echo "env must be test|prod (miniapp has no stage)" >&2; return 2 ;;
  esac
}

# 导出：NS JUMP KUBECONFIG_PATH AWS_REGION ECR_REGISTRY IMAGE_NS
# JOB_NAME DEFAULT_BRANCH JENKINS_AGENT INGRESS_SUFFIX VIEW
ma_load_env() {
  local envname="$1"
  ma_env_ok "$envname" || return 2
  KUBECONFIG_PATH=/opt/jenkins-scripts/config/miniapp_config
  AWS_REGION=ap-east-1
  ECR_REGISTRY=483898562971.dkr.ecr.ap-east-1.amazonaws.com
  IMAGE_NS=zymix_mini_app
  VIEW=app-game
  GIT_CREDENTIALS_ID="${GIT_CREDENTIALS_ID:-6fe66442-6059-46ed-bf55-cde9561b7f80}"
  case "$envname" in
    test)
      NS=zymix-dev
      JUMP=test-jenkins
      DEFAULT_BRANCH=test
      JENKINS_AGENT=dev
      INGRESS_SUFFIX="-test.zymix.io"
      ;;
    prod)
      NS=zymix-prod
      JUMP=prod-jenkins
      DEFAULT_BRANCH=prod
      JENKINS_AGENT=built-in
      INGRESS_SUFFIX=".zymix.io"
      ;;
  esac
}

ma_job_name() {
  local envname="$1" svc="$2"
  echo "${envname}-${svc}"
}

ma_resource() {
  local svc="$1"
  echo "zymix-${svc}"
}

ma_ingress_host() {
  local svc="$1"
  echo "${svc}${INGRESS_SUFFIX}"
}

ma_add_root() {
  local out="$1" envname="$2" svc="$3"
  echo "${out%/}/${envname}/${svc}"
}

ma_require_jcli() {
  if ! command -v jcli >/dev/null 2>&1; then
    echo "jcli not found in PATH" >&2
    return 1
  fi
}
