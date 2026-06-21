#!/usr/bin/env bash
set -eu

TARGET="$HOME/.agents/skills"

rm -rf "$TARGET"
mkdir -p "$TARGET"

printf 'cleaned: %s\n' "$TARGET"
