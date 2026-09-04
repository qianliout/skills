#!/usr/bin/env bash
# 建库 / 灌 schema：幂等、默认 dry-run、永不 DROP。
#
# 三种连接拓扑（--mode）：
#   psql        本机或跳板机能直连 PG           （prod 腾讯云 CDB）
#   ssh-docker  ssh 到主机再 docker exec psql   （miniapp test 的 dev-postgres17）
#   jump-psql   ssh 跳板机后在跳板机上跑 psql   （只有跳板机能连到库时）
#
# 连接参数不写在脚本里，从连接文件读（文件名必须 *.secret.env，已被 .gitignore 挡住）：
#   MODE=psql|ssh-docker|jump-psql
#   PGHOST= PGPORT= PGUSER= PGPASSWORD= ADMIN_DB=postgres
#   SSH_HOST= SSH_USER= SSH_KEY= PG_CONTAINER=      # ssh-docker 用
#   JUMP_HOST=                                       # jump-psql 用
#
# 用法：
#   bash provision-db.sh --conn db.secret.env --class miniapp --env test --db rent_rewards --owner u_zymix
#   ... 看清楚计划后再加 --apply
#   bash provision-db.sh ... --apply --schema-dir ../sql --schema-list order.txt
#
# 退出码：0 ok / 2 用法错 / 3 被安全规则拦下 / 4 连不上库 / 5 schema 灌失败

set -euo pipefail

CONN="" CLASS="" ENV_NAME="" DB="" OWNER="" SCHEMA_DIR="" SCHEMA_LIST=""
APPLY=0 PROD_CONFIRM=0 ALLOW_NEW_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --conn) CONN="$2"; shift 2 ;;
    --class) CLASS="$2"; shift 2 ;;
    --env) ENV_NAME="$2"; shift 2 ;;
    --db) DB="$2"; shift 2 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --schema-dir) SCHEMA_DIR="$2"; shift 2 ;;
    --schema-list) SCHEMA_LIST="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --prod-confirm) PROD_CONFIRM=1; shift ;;
    --allow-new-database) ALLOW_NEW_DB=1; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$CONN" && -n "$CLASS" && -n "$ENV_NAME" && -n "$DB" ]] || { sed -n '2,25p' "$0" >&2; exit 2; }
[[ -f "$CONN" ]] || { echo "ERROR: 连接文件不存在: $CONN" >&2; exit 2; }
[[ "$CONN" == *.secret.env ]] || { echo "ERROR: 连接文件名必须以 .secret.env 结尾（否则会入库）" >&2; exit 3; }

# shellcheck source=/dev/null
set -a; source "$CONN"; set +a
MODE="${MODE:-psql}"
ADMIN_DB="${ADMIN_DB:-postgres}"
OWNER="${OWNER:-${PGUSER:-}}"

# ---- 安全规则 ----------------------------------------------------------
if [[ "$ENV_NAME" == "prod" && "$APPLY" -eq 1 && "$PROD_CONFIRM" -eq 0 ]]; then
  echo "ERROR: prod 写操作必须同时带 --prod-confirm" >&2; exit 3
fi

# ---- 连接封装 ----------------------------------------------------------
run_sql() {  # $1=dbname $2=sql
  local db="$1" sql="$2"
  case "$MODE" in
    psql)
      PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "${PGPORT:-5432}" -U "$PGUSER" \
        -d "$db" -v ON_ERROR_STOP=1 -tAc "$sql" ;;
    jump-psql)
      ssh "$JUMP_HOST" "PGPASSWORD='${PGPASSWORD}' psql -h '${PGHOST}' -p '${PGPORT:-5432}' \
        -U '${PGUSER}' -d '${db}' -v ON_ERROR_STOP=1 -tAc \"${sql}\"" ;;
    ssh-docker)
      ssh ${SSH_KEY:+-i "$SSH_KEY"} -o StrictHostKeyChecking=accept-new \
        "${SSH_USER}@${SSH_HOST}" \
        "sudo docker exec ${PG_CONTAINER} psql -U '${PGUSER}' -d '${db}' -v ON_ERROR_STOP=1 -tAc \"${sql}\"" ;;
    *) echo "ERROR: 未知 MODE=$MODE" >&2; exit 2 ;;
  esac
}

run_file() {  # $1=dbname $2=本地 sql 文件
  local db="$1" f="$2"
  case "$MODE" in
    psql)
      PGPASSWORD="$PGPASSWORD" psql -h "$PGHOST" -p "${PGPORT:-5432}" -U "$PGUSER" \
        -d "$db" -v ON_ERROR_STOP=1 -f "$f" ;;
    jump-psql)
      ssh "$JUMP_HOST" "PGPASSWORD='${PGPASSWORD}' psql -h '${PGHOST}' -p '${PGPORT:-5432}' \
        -U '${PGUSER}' -d '${db}' -v ON_ERROR_STOP=1 -f -" < "$f" ;;
    ssh-docker)
      ssh ${SSH_KEY:+-i "$SSH_KEY"} -o StrictHostKeyChecking=accept-new \
        "${SSH_USER}@${SSH_HOST}" \
        "sudo docker exec -i ${PG_CONTAINER} psql -U '${PGUSER}' -d '${db}' -v ON_ERROR_STOP=1 -f -" < "$f" ;;
  esac
}

# ---- 1. 连通性 ---------------------------------------------------------
echo "=== 连通性（${MODE} → ${ADMIN_DB}）==="
if ! run_sql "$ADMIN_DB" "SELECT 1" >/dev/null 2>&1; then
  echo "ERROR: 连不上 ${ADMIN_DB}。注意：密码以真实 TCP 认证为准，不要只看 docker inspect 的环境变量。" >&2
  exit 4
fi
echo "  ok"

# ---- 2. 是否已存在 -----------------------------------------------------
exists="$(run_sql "$ADMIN_DB" "SELECT 1 FROM pg_database WHERE datname='${DB}'" | tr -d '[:space:]')"

# ---- 3. 计划 -----------------------------------------------------------
declare -a SQL_FILES=()
if [[ -n "$SCHEMA_DIR" ]]; then
  if [[ -n "$SCHEMA_LIST" ]]; then
    [[ -f "$SCHEMA_LIST" ]] || { echo "ERROR: 顺序文件不存在: $SCHEMA_LIST" >&2; exit 2; }
    while IFS= read -r line; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      f="${SCHEMA_DIR}/${line}"
      if [[ -f "$f" ]]; then SQL_FILES+=("$f"); else echo "  跳过（不存在）: $line"; fi
    done < "$SCHEMA_LIST"
  else
    while IFS= read -r f; do SQL_FILES+=("$f"); done < <(find "$SCHEMA_DIR" -maxdepth 1 -name '*.sql' | sort)
  fi
fi

echo
echo "=== 计划 ==="
echo "  类别/环境 : ${CLASS} / ${ENV_NAME}"
echo "  目标库    : ${DB}  (owner=${OWNER})"
echo "  已存在    : $([[ "$exists" == "1" ]] && echo 是（跳过创建，不 DROP） || echo 否（将 CREATE DATABASE）)"
echo "  schema    : ${#SQL_FILES[@]} 个文件"
for f in "${SQL_FILES[@]}"; do echo "               $(basename "$f")"; done

if [[ "$APPLY" -eq 0 ]]; then
  echo
  echo "dry-run。确认后加 --apply$([[ "$ENV_NAME" == prod ]] && echo ' --prod-confirm')。"
  exit 0
fi

# ---- 4. 建库 -----------------------------------------------------------
echo
if [[ "$exists" == "1" ]]; then
  echo "=== 库已存在，跳过创建 ==="
else
  echo "=== CREATE DATABASE ${DB} ==="
  run_sql "$ADMIN_DB" "CREATE DATABASE ${DB}${OWNER:+ OWNER ${OWNER}}" >/dev/null
  echo "  已创建"
fi

# ---- 5. 灌 schema ------------------------------------------------------
if [[ "${#SQL_FILES[@]}" -gt 0 ]]; then
  echo "=== 灌 schema ==="
  for f in "${SQL_FILES[@]}"; do
    echo "  → $(basename "$f")"
    if ! run_file "$DB" "$f"; then
      echo "ERROR: $(basename "$f") 执行失败，已停止。库保持现状，未回滚。" >&2
      exit 5
    fi
  done
fi

# ---- 6. 验收 -----------------------------------------------------------
echo
echo "=== 验收 ==="
n="$(run_sql "$DB" "SELECT count(*) FROM information_schema.tables WHERE table_schema='public'" | tr -d '[:space:]')"
echo "  public schema 下表数：${n}"
if [[ "$n" == "0" ]]; then
  cat <<'WARN'
  !! 空库。若服务启动时要读配置表（如 sys_config），会直接 CrashLoopBackOff，
     且报错看起来像镜像/网络/密码问题。确认服务有自动 migrate，否则先灌 schema。
WARN
fi
