#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS_TARGET="$HOME/.agents"
SKILLS_TARGET="$AGENTS_TARGET/skills"
MCPS_TARGET="$AGENTS_TARGET/mcps"
OPERATIONS_SKILLS="$ROOT/skills/manifests/operations-skills.txt"
PUBLIC_SKILLS="$ROOT/skills/manifests/public-skills.txt"

install_mcps() {
  mkdir -p "$MCPS_TARGET"

  find "$ROOT/mcps" -mindepth 1 -maxdepth 1 -print |
  while IFS= read -r mcp_path; do
    cp -R "$mcp_path" "$MCPS_TARGET/"
  done
}

lookup_local_skill() {
  local name="$1"

  find "$ROOT/skills" -type f -name SKILL.md \
    ! -path "$ROOT/skills/manifests/*" \
    ! -path "$ROOT/skills/*/resources/*" -print |
  while IFS= read -r skill_file; do
    skill_dir="${skill_file%/SKILL.md}"
    if [ "${skill_dir##*/}" = "$name" ]; then
      printf '%s\n' "$skill_dir"
      return
    fi
  done
}

install_skill() {
  local name="$1"
  local local_skill_dir public_entry repository source_path

  local_skill_dir="$(lookup_local_skill "$name")"
  if [ -n "$local_skill_dir" ]; then
    cp -R "$local_skill_dir" "$SKILLS_TARGET/$name"
    return
  fi

  public_entry="$(
    awk -F'|' -v wanted="$name" 'NF && $0 !~ /^#/ && $2 == wanted {print $3 "|" $4; exit}' "$PUBLIC_SKILLS"
  )"
  repository="${public_entry%%|*}"
  source_path="${public_entry#*|}"

  cp -R "$ROOT/.sources/$repository/$source_path" "$SKILLS_TARGET/$name"
}

"$ROOT/scripts/update-public.sh"
"$ROOT/scripts/check.sh"
"$ROOT/scripts/clean.sh"

while IFS= read -r name; do
  case "$name" in
    '' | '#'*)
      continue
      ;;
  esac

  install_skill "$name"
done < "$OPERATIONS_SKILLS"

install_mcps

printf 'installed operations skills: %s, mcp entries: %s\n' \
  "$(find "$SKILLS_TARGET" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" \
  "$(find "$MCPS_TARGET" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
