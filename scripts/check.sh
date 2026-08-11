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

# --- Go skills consolidation invariants ---
GO_DEV="$ROOT/skills/go-development"
if [ -d "$GO_DEV" ]; then
  allowed_go_skills='go
go-api-layer
go-code-style
go-gin-openapi-json
go-model-hierarchy
go-query-dal
go-service-layer
go-test-writer'

  forbidden_go_dirs='go-comment-style
go-logging'
  while IFS= read -r d; do
    test -n "$d" || continue
    test ! -e "$GO_DEV/$d" || fail "forbidden go skill directory still present: go-development/$d"
  done <<< "$forbidden_go_dirs"

  test ! -e "$ROOT/skills/gin-openapi-json" || fail "forbidden standalone skill still present: skills/gin-openapi-json"
  test ! -e "$ROOT/scripts/go-reference-pairs.txt" || fail "forbidden sync map still present: scripts/go-reference-pairs.txt"

  test ! -d "$GO_DEV/go/references" || fail "go must not contain references/ (thin router only)"
  test ! -d "$GO_DEV/go/assets" || fail "go must not contain assets/ (OpenAPI assets live under go-gin-openapi-json)"

  go_skill_dirs="$(find "$GO_DEV" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
  while IFS= read -r d; do
    test -n "$d" || continue
    printf '%s\n' "$allowed_go_skills" | grep -Fx "$d" >/dev/null ||
      fail "unexpected go-development skill directory: $d"
  done <<< "$go_skill_dirs"

  while IFS= read -r d; do
    test -n "$d" || continue
    test -f "$GO_DEV/$d/SKILL.md" || fail "missing SKILL.md for go-development/$d"
  done <<< "$allowed_go_skills"

  test -f "$GO_DEV/go-code-style/references/code-style.md" || fail "missing go-code-style/references/code-style.md"
  test -f "$GO_DEV/go-code-style/references/comment-style.md" || fail "missing go-code-style/references/comment-style.md"
  test -f "$GO_DEV/go-code-style/references/logging.md" || fail "missing go-code-style/references/logging.md"
  test -f "$GO_DEV/go-gin-openapi-json/scripts/generate.sh" || fail "missing go-gin-openapi-json/scripts/generate.sh"
  test -f "$GO_DEV/go-gin-openapi-json/assets/openapi.json" || fail "missing go-gin-openapi-json/assets/openapi.json"

  # 叶子不得再持有 *-conventions.md；go 除外已无 references
  conv_hits="$(find "$GO_DEV" -type f -name '*-conventions.md' | sort)"
  test -z "$conv_hits" || fail "conventions files must be merged away: $conv_hits"

  # go-* 不得再要求读取或加载已删除的 go/references 副本；禁止性说明可以提及该路径。
  go_reference_guidance="$(
    rg -n -P '^(?!.*(?:禁止|不得|不要|不可|不应|无需|不再).*go/references/).*(?:读取|加载)(?:(?!\n).)*go/references/' \
      "$GO_DEV" --glob 'SKILL.md' --glob '*.md' || true
  )"
  test -z "$go_reference_guidance" ||
    fail "Go skills must not instruct loading go/references/: $go_reference_guidance"
fi

printf 'check passed\n'
