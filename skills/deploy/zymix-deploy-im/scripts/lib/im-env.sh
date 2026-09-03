# IM 部署环境矩阵。被本 skill 的 im-*.sh 引用。不依赖任何外部仓库。
# shellcheck shell=bash

im_normalize_svc() {
  local raw="${1:-}"
  raw="${raw#cloud-}"
  raw="${raw%/}"
  if [[ -z "$raw" ]]; then
    echo "empty service name" >&2
    return 2
  fi
  case "$raw" in
    *-svc|*-gateway) echo "$raw" ;;
    *) echo "${raw}-svc" ;;
  esac
}

im_env_ok() {
  case "${1:-}" in
    test|stage|prod) return 0 ;;
    *) echo "env must be test|stage|prod" >&2; return 2 ;;
  esac
}

# 导出：NS JUMP KUBECONFIG_PATH AWS_REGION ECR_REGISTRY IMAGE_NS
# JOB_MAIN JOB_SEL DEFAULT_BRANCH KUBE_VAR
im_load_env() {
  local envname="$1"
  im_env_ok "$envname" || return 2
  case "$envname" in
    test)
      NS=zymix-test
      JUMP=test-jenkins
      KUBECONFIG_PATH=/opt/jenkins-scripts/config/test_config
      AWS_REGION=ap-east-1
      ECR_REGISTRY=483898562971.dkr.ecr.ap-east-1.amazonaws.com
      IMAGE_NS=siu
      JOB_MAIN=test-cloud-im-go-server
      JOB_SEL=test-cloud-im-go-server-selective
      DEFAULT_BRANCH=test
      KUBE_VAR=kubedev
      ;;
    stage)
      NS=zymix-stage
      JUMP=test-jenkins
      KUBECONFIG_PATH=/opt/jenkins-scripts/config/stage_config
      AWS_REGION=eu-west-2
      ECR_REGISTRY=483898562971.dkr.ecr.eu-west-2.amazonaws.com
      IMAGE_NS=zymix
      JOB_MAIN=stage-cloud-im-go-server
      JOB_SEL=stage-cloud-im-go-server-selective
      DEFAULT_BRANCH=stage
      KUBE_VAR=kubestage
      ;;
    prod)
      NS=zymix-prod
      JUMP=prod-jenkins
      KUBECONFIG_PATH=/opt/jenkins-scripts/config/prod_config
      AWS_REGION=eu-west-2
      ECR_REGISTRY=483898562971.dkr.ecr.eu-west-2.amazonaws.com
      IMAGE_NS=zymix
      JOB_MAIN=prod-cloud-im-go-server
      JOB_SEL=prod-cloud-im-go-server-selective
      DEFAULT_BRANCH=master
      KUBE_VAR=kubeprod
      ;;
  esac
}

im_add_root() {
  local out="$1" envname="$2" svc="$3"
  echo "${out%/}/${envname}/${svc}"
}

im_require_jcli() {
  if ! command -v jcli >/dev/null 2>&1; then
    echo "jcli not found in PATH" >&2
    return 1
  fi
}
