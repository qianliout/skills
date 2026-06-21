#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCES="$ROOT/.sources"

sync_shallow_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only
    return
  fi

  git clone --depth 1 "$url" "$target"
}

mkdir -p "$SOURCES"

while IFS='|' read -r name url; do
  sync_shallow_repo "$SOURCES/$name" "$url"
done < "$ROOT/skills/manifests/public-repositories.txt"

find "$ROOT/skills" -type f -path '*/resources/update.sh' | sort |
while IFS= read -r update_script; do
  bash "$update_script"
done
