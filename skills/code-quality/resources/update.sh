#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SOURCES="$ROOT/.sources"
RESOURCE_CACHE_ROOT="$SOURCES/resource-cache"

sync_full_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only
    return
  fi

  git clone "$url" "$target"
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
  sync_full_repo "$cache_dir" "$source_repo"

  if [ ! -d "$cache_dir/$source_path" ]; then
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
