#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SOURCES="$ROOT/.sources"
RESOURCE_CACHE_ROOT="$SOURCES/resource-cache"

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
  printf '%s/%s\n' "$RESOURCE_CACHE_ROOT" "$safe_name"
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

mkdir -p "$SOURCES" "$RESOURCE_CACHE_ROOT"

test -f "$ROOT/skills/code-quality/code-quality/references/code-review-expert.md"
test -f "$ROOT/skills/code-quality/code-quality/references/requesting-code-review.md"

sync_subtree_from_cache \
  "https://github.com/sanyuan0704/code-review-expert.git" \
  "skills/code-review-expert" \
  "$ROOT/skills/code-quality/resources/code-review-expert"

sync_subtree_from_cache \
  "https://github.com/obra/superpowers.git" \
  "skills/requesting-code-review" \
  "$ROOT/skills/code-quality/resources/requesting-code-review"
