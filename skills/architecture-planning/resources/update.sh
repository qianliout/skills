#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SOURCES="$ROOT/.sources"
CACHE_ROOT="$SOURCES/resource-cache"

sync_shallow_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    if git -C "$target" pull --ff-only; then
      return
    fi

    rm -rf "$target"
  elif [ -e "$target" ]; then
    rm -rf "$target"
  else
    mkdir -p "$(dirname "$target")"
  fi

  git clone --depth 1 "$url" "$target"
}

sync_sparse_path() {
  local target="$1"
  local url="$2"
  local source_path="$3"

  if [ -d "$target/.git" ]; then
    if git -C "$target" pull --ff-only; then
      return
    fi

    rm -rf "$target"
  elif [ -e "$target" ]; then
    rm -rf "$target"
  else
    mkdir -p "$(dirname "$target")"
  fi

  git clone --depth 1 --filter=blob:none --sparse "$url" "$target"
  git -C "$target" sparse-checkout set "$source_path"
}

sync_full_repo() {
  local target="$1"
  local url="$2"
  local source_path="${3:-}"

  if [ -n "$source_path" ]; then
    sync_sparse_path "$target" "$url" "$source_path"
    return
  fi

  sync_shallow_repo "$target" "$url"
}

resource_cache_dir() {
  local url="$1"
  local safe_name

  safe_name="$(printf '%s' "$url" | sed 's#^[A-Za-z][A-Za-z0-9+.-]*://##; s#[^A-Za-z0-9._-]#-#g')"
  printf '%s/%s\n' "$CACHE_ROOT" "$safe_name"
}

sync_subtree_from_cache() {
  local source_repo="$1"
  local source_path="$2"
  local local_dir="$3"
  local cache_dir

  cache_dir="$(resource_cache_dir "$source_repo")"
  sync_full_repo "$cache_dir" "$source_repo" "$source_path"

  if [ ! -d "$cache_dir/$source_path" ]; then
    if [ -d "$local_dir" ]; then
      printf 'warning: missing upstream path, keeping existing local resource: %s\n' "$cache_dir/$source_path" >&2
      return
    fi

    printf 'missing upstream path: %s\n' "$cache_dir/$source_path" >&2
    exit 1
  fi

  rm -rf "$local_dir"
  mkdir -p "$(dirname "$local_dir")"
  cp -R "$cache_dir/$source_path" "$local_dir"
}

mkdir -p "$SOURCES" "$CACHE_ROOT"

test -f "$ROOT/skills/architecture-planning/architecture-planning/references/architecture-decision-records.md"
test -f "$ROOT/skills/architecture-planning/architecture-planning/references/architecture-patterns.md"
test -f "$ROOT/skills/architecture-planning/architecture-planning/references/project-planner.md"

sync_subtree_from_cache \
  "https://github.com/wshobson/agents.git" \
  "plugins/documentation-generation/skills/architecture-decision-records" \
  "$ROOT/skills/architecture-planning/resources/architecture-decision-records"

sync_subtree_from_cache \
  "https://github.com/wshobson/agents.git" \
  "plugins/backend-development/skills/architecture-patterns" \
  "$ROOT/skills/architecture-planning/resources/architecture-patterns"

# project-planner 已在上游 2026-07-08 的 commit 26f859f 中被删除（不是路径迁移）。
# 下面这次调用预期会一直打印 "missing upstream path" 警告并保留本地镜像，这是已知的永久状态，不是需要修的 bug。
sync_subtree_from_cache \
  "https://github.com/shubhamsaboo/awesome-llm-apps.git" \
  "awesome_agent_skills/project-planner" \
  "$ROOT/skills/architecture-planning/resources/project-planner"
