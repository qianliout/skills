#!/usr/bin/env bash
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'test failed: %s\n' "$1" >&2
  exit 1
}

copy_scripts() {
  local fixture_root="$1"

  mkdir -p "$fixture_root/scripts"
  cp "$REPO_ROOT"/scripts/*.sh "$fixture_root/scripts/"
}

write_fixture_repo() {
  local fixture_root="$1"

  mkdir -p \
    "$fixture_root/skills/manifests" \
    "$fixture_root/skills/local/local-one" \
    "$fixture_root/skills/local/local-two" \
    "$fixture_root/skills/local/public/only-docs" \
    "$fixture_root/mcps/public/playwright" \
    "$fixture_root/mcps/private/private-tool"

  cat > "$fixture_root/skills/manifests/public-repositories.txt" <<'EOF'
EOF
  cat > "$fixture_root/skills/manifests/public-skills.txt" <<'EOF'
EOF
  cat > "$fixture_root/skills/manifests/operations-skills.txt" <<'EOF'
local-one
EOF

  cat > "$fixture_root/skills/local/local-one/SKILL.md" <<'EOF'
---
name: local-one
description: Local one fixture
---

# Local One
EOF
  cat > "$fixture_root/skills/local/local-two/SKILL.md" <<'EOF'
---
name: local-two
description: Local two fixture
---

# Local Two
EOF
  cat > "$fixture_root/skills/local/public/only-docs/README.md" <<'EOF'
# only-docs

Public stub fixture; must not be installed.
EOF

  cat > "$fixture_root/mcps/profiles.json" <<'EOF'
{
  "clients": {
    "codex": ["playwright"]
  }
}
EOF
  cat > "$fixture_root/mcps/README.md" <<'EOF'
# MCP fixture
EOF
  cat > "$fixture_root/mcps/public/README.md" <<'EOF'
# Public MCP fixture
EOF
  cat > "$fixture_root/mcps/private/README.md" <<'EOF'
# Private MCP fixture
EOF
  cat > "$fixture_root/mcps/public/playwright/config.json" <<'EOF'
{"command":"npx","args":["-y","@playwright/mcp@latest"]}
EOF
  cat > "$fixture_root/mcps/public/playwright/README.md" <<'EOF'
# Playwright
EOF
  cat > "$fixture_root/mcps/private/private-tool/config.json" <<'EOF'
{"command":"private-tool"}
EOF
  cat > "$fixture_root/mcps/private/private-tool/README.md" <<'EOF'
# Private Tool
EOF
}

assert_path_exists() {
  test -e "$1" || fail "missing path: $1"
}

assert_path_absent() {
  test ! -e "$1" || fail "unexpected path exists: $1"
}

assert_file_count() {
  local dir="$1"
  local expected="$2"
  local actual

  actual="$(find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  test "$actual" = "$expected" || fail "expected $expected directories in $dir, got $actual"
}

assert_symlink_to() {
  local link="$1"
  local expected="$2"
  local actual

  test -L "$link" || fail "expected symlink: $link"
  actual="$(readlink "$link")"
  test "$actual" = "$expected" || fail "expected $link -> $expected, got $actual"
}

assert_agent_dir_links() {
  local home="$1"
  local agents_skills="$home/.agents/skills"
  local rel

  for rel in .claude/skills .trae/skills .reasonix/skills; do
    assert_symlink_to "$home/$rel" "$agents_skills"
  done
}

assert_cursor_skill_copies() {
  local home="$1"
  shift
  local skill_name

  test ! -L "$home/.cursor/skills" || fail "cursor skills should be a real directory, not a symlink"
  assert_path_exists "$home/.cursor/skills"
  for skill_name in "$@"; do
    assert_path_exists "$home/.cursor/skills/$skill_name/SKILL.md"
    test ! -L "$home/.cursor/skills/$skill_name" || fail "cursor skill should be a copy, not a symlink: $skill_name"
  done
}

assert_codex_skill_links() {
  local home="$1"
  shift
  local skill_name

  assert_path_exists "$home/.codex/skills/.system"
  for skill_name in "$@"; do
    assert_symlink_to "$home/.codex/skills/$skill_name" "$home/.agents/skills/$skill_name"
  done
}

FIXTURE_ROOT="$TMP_DIR/repo"
TEST_HOME="$TMP_DIR/home"
mkdir -p "$FIXTURE_ROOT" "$TEST_HOME/.codex/skills/.system"
copy_scripts "$FIXTURE_ROOT"
write_fixture_repo "$FIXTURE_ROOT"

HOME="$TEST_HOME" "$FIXTURE_ROOT/scripts/install.sh" >/tmp/skills-install-test.log
assert_path_exists "$TEST_HOME/.agents/skills/local-one/SKILL.md"
assert_path_exists "$TEST_HOME/.agents/skills/local-two/SKILL.md"
assert_path_absent "$TEST_HOME/.agents/skills/only-docs"
assert_file_count "$TEST_HOME/.agents/skills" "2"
assert_path_exists "$TEST_HOME/.agents/mcps/profiles.json"
assert_path_exists "$TEST_HOME/.agents/mcps/public/playwright/config.json"
assert_path_exists "$TEST_HOME/.agents/mcps/private/private-tool/config.json"
assert_agent_dir_links "$TEST_HOME"
assert_cursor_skill_copies "$TEST_HOME" local-one local-two
assert_codex_skill_links "$TEST_HOME" local-one local-two

HOME="$TEST_HOME" "$FIXTURE_ROOT/scripts/clean.sh" >/tmp/skills-clean-test.log
assert_path_exists "$TEST_HOME/.agents/skills"
assert_path_exists "$TEST_HOME/.agents/mcps"
assert_file_count "$TEST_HOME/.agents/skills" "0"
assert_file_count "$TEST_HOME/.agents/mcps" "0"
assert_path_absent "$TEST_HOME/.claude/skills"
assert_path_absent "$TEST_HOME/.cursor/skills"
assert_path_absent "$TEST_HOME/.trae/skills"
assert_path_absent "$TEST_HOME/.reasonix/skills"
assert_path_exists "$TEST_HOME/.codex/skills/.system"
assert_path_absent "$TEST_HOME/.codex/skills/local-one"
assert_path_absent "$TEST_HOME/.codex/skills/local-two"

HOME="$TEST_HOME" "$FIXTURE_ROOT/scripts/install-operations.sh" >/tmp/skills-operations-install-test.log
assert_path_exists "$TEST_HOME/.agents/skills/local-one/SKILL.md"
assert_path_absent "$TEST_HOME/.agents/skills/local-two"
assert_path_absent "$TEST_HOME/.agents/skills/only-docs"
assert_file_count "$TEST_HOME/.agents/skills" "1"
assert_path_exists "$TEST_HOME/.agents/mcps/profiles.json"
assert_path_exists "$TEST_HOME/.agents/mcps/public/playwright/config.json"
assert_agent_dir_links "$TEST_HOME"
assert_cursor_skill_copies "$TEST_HOME" local-one
assert_path_absent "$TEST_HOME/.cursor/skills/local-two"
assert_codex_skill_links "$TEST_HOME" local-one
assert_path_absent "$TEST_HOME/.codex/skills/local-two"

printf 'script tests passed\n'
