#!/usr/bin/env bash
# 为单个 Gin 接口生成 OpenAPI 3.1.0 JSON 的预检配置。
# 校验输入、定位项目根目录并确定输出路径；SKILL.md 负责代码分析与 JSON 生成。
set -euo pipefail

usage() {
  cat <<'EOF'
用法：generate.sh <METHOD> <PATH> [--output <filepath>]
      generate.sh <HANDLER_FUNC> [--output <filepath>]

  METHOD + PATH   HTTP 方法和路由路径（例如 PUT /api/v2/scanner/detect/policy）
  HANDLER_FUNC    handler 函数名（例如 UserAPI.CreateUser）
  --output <path> 写入指定路径，不使用自动命名

示例：
  generate.sh PUT /api/v2/scanner/detect/policy
  generate.sh PUT /api/v2/scanner/detect/policy --output docs/policy.json
  generate.sh UserAPI.CreateUser
EOF
  exit 1
}

# 解析参数。
OUTPUT=""
SELECTOR=""
METHOD=""
PATH_SPEC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --output)
      [ $# -gt 1 ] || { echo "错误：--output 需要一个值" >&2; exit 1; }
      shift; OUTPUT="$1" ;;
    --help|-h) usage ;;
    -*)
      echo "错误：未知选项：$1" >&2; usage ;;
    *)
      if [ -z "$SELECTOR" ]; then
        SELECTOR="$1"
      else
        # 两个位置参数代表 METHOD + PATH。
        METHOD="$SELECTOR"
        PATH_SPEC="$1"
        SELECTOR="${METHOD} ${PATH_SPEC}"
      fi ;;
  esac
  shift
done

if [ -z "$SELECTOR" ]; then
  echo "错误：未指定接口选择器" >&2
  usage
fi

# 向上查找包含 go.mod 的项目根目录。
PROJECT_ROOT=""
SEARCH_DIR="$PWD"
while [ "$SEARCH_DIR" != "/" ]; do
  if [ -f "$SEARCH_DIR/go.mod" ]; then
    PROJECT_ROOT="$SEARCH_DIR"
    break
  fi
  SEARCH_DIR="$(dirname "$SEARCH_DIR")"
done

if [ -z "$PROJECT_ROOT" ]; then
  echo "错误：在 $PWD 或其父目录中未找到 go.mod" >&2
  exit 2
fi

# 确定输出路径。
if [ -n "$OUTPUT" ]; then
  # 相对路径以项目根目录为基准。
  [[ "$OUTPUT" != /* ]] && OUTPUT="${PROJECT_ROOT}/${OUTPUT}"
else
  # 使用路径末尾 2 至 3 段或 handler 名生成文件名。
  SAFE_NAME="$(echo "${SELECTOR}" \
    | sed 's/^[A-Z]\+ //' \
    | tr '/' '.' \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9.]//g' \
    | tr '.' '\n' \
    | tail -3 \
    | tr '\n' '_' \
    | sed 's/_$//;s/__*/_/g')"

  [ -z "$SAFE_NAME" ] && SAFE_NAME="$(echo "${SELECTOR}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g;s/__*/_/g;s/^_//;s/_$//')"
  [ -z "$SAFE_NAME" ] && SAFE_NAME="interface"

  OUTPUT="${PROJECT_ROOT}/openapi_${SAFE_NAME}.json"
fi

# 确保输出目录存在。
mkdir -p "$(dirname "$OUTPUT")"

# 输出解析后的配置，供调用方读取。
printf '{\n'
printf '  "selector":      "%s",\n'  "$SELECTOR"
printf '  "output":        "%s",\n'  "$OUTPUT"
printf '  "project_root":  "%s"\n'    "$PROJECT_ROOT"
printf '}\n'
