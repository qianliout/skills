#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCES="$ROOT/.sources"

mkdir -p "$SOURCES"

while IFS='|' read -r name url; do
  if [ -d "$SOURCES/$name/.git" ]; then
    git -C "$SOURCES/$name" pull --ff-only
  else
    git clone --depth 1 "$url" "$SOURCES/$name"
  fi
done < "$ROOT/manifests/public-repositories.txt"
