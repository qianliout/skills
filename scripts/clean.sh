#!/usr/bin/env bash
set -eu

TARGET="$HOME/.agents"

rm -rf "$TARGET/skills" "$TARGET/mcps"
mkdir -p "$TARGET/skills" "$TARGET/mcps"

printf 'cleaned: %s\n' "$TARGET"
