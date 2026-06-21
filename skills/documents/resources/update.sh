#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"

sync_full_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only
    return
  fi

  git clone "$url" "$target"
}

test -f "$ROOT/skills/documents/documents/references/lark-markdown.md"
test -f "$ROOT/skills/documents/documents/references/obsidian-markdown.md"

sync_full_repo \
  "$ROOT/skills/documents/resources/lark-markdown" \
  "https://github.com/larksuite/cli.git"

sync_full_repo \
  "$ROOT/skills/documents/resources/obsidian-markdown" \
  "https://github.com/kepano/obsidian-skills.git"
