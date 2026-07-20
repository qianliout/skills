#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBLIC_REPOS="$ROOT/skills/manifests/public-repositories.txt"
PUBLIC_SKILLS="$ROOT/skills/manifests/public-skills.txt"
OPERATIONS_SKILLS="$ROOT/skills/manifests/operations-skills.txt"

fail() {
  printf 'check failed: %s\n' "$1" >&2
  exit 1
}

require_file() {
  test -f "$1" || fail "missing file: $1"
}

require_file "$PUBLIC_REPOS"
require_file "$PUBLIC_SKILLS"
require_file "$OPERATIONS_SKILLS"

duplicate_public_repos="$(
  awk -F'|' 'NF && $0 !~ /^#/ {print $1}' "$PUBLIC_REPOS" | sort | uniq -d
)"
test -z "$duplicate_public_repos" || fail "duplicate public repository names: $duplicate_public_repos"

duplicate_public_skills="$(
  awk -F'|' 'NF && $0 !~ /^#/ {print $2}' "$PUBLIC_SKILLS" | sort | uniq -d
)"
test -z "$duplicate_public_skills" || fail "duplicate public skill names: $duplicate_public_skills"

public_repo_names="$(
  awk -F'|' 'NF && $0 !~ /^#/ {print $1}' "$PUBLIC_REPOS" | sort
)"

while IFS='|' read -r category name repository source_path; do
  test -n "$category" || fail "empty category in public skill manifest"
  test -n "$name" || fail "empty skill name in public skill manifest"
  test -n "$repository" || fail "empty repository for public skill: $name"
  test -n "$source_path" || fail "empty source path for public skill: $name"

  printf '%s\n' "$public_repo_names" | grep -Fx "$repository" >/dev/null ||
    fail "public skill references unknown repository: $name -> $repository"

  if [ -d "$ROOT/.sources/$repository" ]; then
    test -f "$ROOT/.sources/$repository/$source_path/SKILL.md" ||
      fail "missing upstream SKILL.md: .sources/$repository/$source_path/SKILL.md"
  fi
done < "$PUBLIC_SKILLS"

local_skill_names="$(
  find "$ROOT/skills" -type f -name SKILL.md \
    ! -path "$ROOT/skills/manifests/*" \
    ! -path "$ROOT/skills/*/resources/*" -print |
  while IFS= read -r skill_file; do
    basename "${skill_file%/SKILL.md}"
  done | sort
)"

duplicate_local_skills="$(
  printf '%s\n' "$local_skill_names" | sed '/^$/d' | uniq -d
)"
test -z "$duplicate_local_skills" || fail "duplicate local skill directory names: $duplicate_local_skills"

overlapping_installs="$(
  comm -12 \
    <(awk -F'|' 'NF && $0 !~ /^#/ {print $2}' "$PUBLIC_SKILLS" | sort) \
    <(printf '%s\n' "$local_skill_names" | sed '/^$/d' | sort)
)"
test -z "$overlapping_installs" || fail "local and public install names overlap: $overlapping_installs"

duplicate_operations_skills="$(
  awk 'NF && $0 !~ /^#/ {print $1}' "$OPERATIONS_SKILLS" | sort | uniq -d
)"
test -z "$duplicate_operations_skills" || fail "duplicate operations skill names: $duplicate_operations_skills"

all_install_names="$(
  {
    printf '%s\n' "$local_skill_names"
    awk -F'|' 'NF && $0 !~ /^#/ {print $2}' "$PUBLIC_SKILLS"
  } | sed '/^$/d' | sort
)"

while IFS= read -r operations_skill; do
  case "$operations_skill" in
    '' | '#'*)
      continue
      ;;
  esac

  printf '%s\n' "$all_install_names" | grep -Fx "$operations_skill" >/dev/null ||
    fail "operations skill references unknown install name: $operations_skill"
done < "$OPERATIONS_SKILLS"

find "$ROOT/skills" -mindepth 2 -maxdepth 2 -type d | sort |
while IFS= read -r category_dir; do
  resources_dir="$category_dir/resources"
  if [ -d "$resources_dir" ]; then
    require_file "$resources_dir/README.md"
    require_file "$resources_dir/update.sh"
  fi
done

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  gitlinks="$(
    git -C "$ROOT" ls-files -s | awk '$1 == "160000" {print $4}'
  )"
  test -z "$gitlinks" || fail "gitlinks are not allowed; use resource-cache + subtree sync: $gitlinks"
fi

printf 'check passed\n'
