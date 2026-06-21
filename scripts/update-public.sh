#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCES="$ROOT/.sources"
DOCUMENTS_RESOURCES="$ROOT/skills/documents/resources"
DOCUMENTS_RESOURCES_README="$DOCUMENTS_RESOURCES/README.md"

sync_shallow_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only
    return
  fi

  git clone --depth 1 "$url" "$target"
}

sync_full_repo() {
  local target="$1"
  local url="$2"

  if [ -d "$target/.git" ]; then
    git -C "$target" pull --ff-only
    return
  fi

  git clone "$url" "$target"
}

mkdir -p "$SOURCES" "$DOCUMENTS_RESOURCES"

while IFS='|' read -r name url; do
  sync_shallow_repo "$SOURCES/$name" "$url"
done < "$ROOT/skills/manifests/public-repositories.txt"

python3 - "$DOCUMENTS_RESOURCES_README" <<'PY' |
import re
import sys

readme_path = sys.argv[1]
skill_name = None
source_repo = None

with open(readme_path, encoding="utf-8") as handle:
    for raw_line in handle:
        line = raw_line.strip()

        match = re.match(r"###\s+([A-Za-z0-9._-]+)$", line)
        if match:
            if skill_name and source_repo:
                print(f"{skill_name}|{source_repo}")
            skill_name = match.group(1)
            source_repo = None
            continue

        if not skill_name:
            continue

        match = re.match(r"-\s+Source Repository:\s+`([^`]+)`$", line)
        if match:
            source_repo = match.group(1)

if skill_name and source_repo:
    print(f"{skill_name}|{source_repo}")
PY
while IFS='|' read -r name url; do
  sync_full_repo "$DOCUMENTS_RESOURCES/$name" "$url"
done
