#!/usr/bin/env bash
# Shared helpers for linking installed skills into agent-specific directories.
# Expects HOME to be set; safe to source from other scripts.

AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
CURSOR_SKILLS_DIR="${CURSOR_SKILLS_DIR:-$HOME/.cursor/skills}"

# Whole-directory symlink targets (relative to $HOME).
# Cursor is excluded: it does not reliably discover skills via directory/skill
# symlinks, so we copy into a real ~/.cursor/skills directory instead.
AGENT_DIR_LINK_TARGETS=(
  ".claude/skills"
  ".trae/skills"
  ".reasonix/skills"
)

clean_agent_skill_links() {
  local rel target

  for rel in "${AGENT_DIR_LINK_TARGETS[@]}"; do
    target="$HOME/$rel"
    /bin/rm -rf "$target"
  done

  /bin/rm -rf "$CURSOR_SKILLS_DIR"

  mkdir -p "$CODEX_SKILLS_DIR"
  find "$CODEX_SKILLS_DIR" -mindepth 1 -maxdepth 1 ! -name '.system' -exec /bin/rm -rf {} +
}

link_agent_skills() {
  local rel target skill_path skill_name

  mkdir -p "$AGENTS_SKILLS_DIR"

  for rel in "${AGENT_DIR_LINK_TARGETS[@]}"; do
    target="$HOME/$rel"
    mkdir -p "$(dirname "$target")"
    /bin/rm -rf "$target"
    ln -sfn "$AGENTS_SKILLS_DIR" "$target"
  done

  # Cursor: real directory + copied skills (symlink discovery is unreliable).
  /bin/rm -rf "$CURSOR_SKILLS_DIR"
  mkdir -p "$CURSOR_SKILLS_DIR"
  find "$AGENTS_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print |
  while IFS= read -r skill_path; do
    skill_name="${skill_path##*/}"
    cp -R "$skill_path" "$CURSOR_SKILLS_DIR/$skill_name"
  done

  mkdir -p "$CODEX_SKILLS_DIR"
  find "$CODEX_SKILLS_DIR" -mindepth 1 -maxdepth 1 ! -name '.system' -exec /bin/rm -rf {} +

  find "$AGENTS_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print |
  while IFS= read -r skill_path; do
    skill_name="${skill_path##*/}"
    ln -sfn "$skill_path" "$CODEX_SKILLS_DIR/$skill_name"
  done
}
