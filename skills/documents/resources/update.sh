#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SOURCES="$ROOT/.sources"
CACHE_ROOT="$SOURCES/resource-cache"

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
  printf '%s/%s\n' "$CACHE_ROOT" "$safe_name"
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

mkdir -p "$SOURCES" "$CACHE_ROOT"

test -f "$ROOT/skills/documents/documents/references/lark-markdown.md"
test -f "$ROOT/skills/documents/documents/references/obsidian-markdown.md"

sync_subtree_from_cache \
  "https://github.com/larksuite/cli.git" \
  "skills/lark-markdown" \
  "$ROOT/skills/documents/resources/lark-markdown"

sync_subtree_from_cache \
  "https://github.com/kepano/obsidian-skills.git" \
  "skills/obsidian-markdown" \
  "$ROOT/skills/documents/resources/obsidian-markdown"
