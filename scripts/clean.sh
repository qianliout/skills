#!/usr/bin/env bash
set -eu

TARGET="$HOME/.agents"

/bin/rm -rf "$TARGET/skills" "$TARGET/mcps"
mkdir -p "$TARGET/skills" "$TARGET/mcps"

printf 'cleaned: %s\n' "$TARGET"
