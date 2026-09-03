#!/usr/bin/env bash
# Copy vendored vanessa-mcp into a project root (and into ~/.cursor/skills if missing).
# Usage: install-vanessa-mcp.sh /absolute/path/to/project
# Does not overwrite an existing project or home copy. Does not write .cursor/mcp.json
# (that is install-vanessa-config.sh, only after an explicit Vanessa=yes).
# Prints: vanessa-mcp: installed | already present | skipped (no vendor)
set -euo pipefail

ROOT="${1:-.}"
ROOT="$(cd "$ROOT" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$SKILL_DIR/vendor/vanessa-mcp"
DEST="$ROOT/.cursor/skills/vanessa-mcp"
HOME_DEST="${HOME}/.cursor/skills/vanessa-mcp"

if [[ ! -f "$VENDOR/SKILL.md" ]]; then
  echo "vanessa-mcp: skipped (no vendor)"
  exit 0
fi

copy_tree() {
  local src="$1" dest="$2"
  mkdir -p "$dest/docs"
  cp "$src/SKILL.md" "$dest/SKILL.md"
  cp "$src/docs/tools.md" "$dest/docs/tools.md"
  cp "$src/docs/write-loop.md" "$dest/docs/write-loop.md"
  cp "$src/docs/integration.md" "$dest/docs/integration.md"
}

PROJECT_STATUS="installed"
if [[ -f "$DEST/SKILL.md" ]]; then
  echo "keep existing: .cursor/skills/vanessa-mcp (already present — skip)"
  PROJECT_STATUS="already present"
else
  mkdir -p "$(dirname "$DEST")"
  copy_tree "$VENDOR" "$DEST"
  echo "wrote: .cursor/skills/vanessa-mcp"
fi

if [[ -f "$HOME_DEST/SKILL.md" ]]; then
  echo "keep existing: ~/.cursor/skills/vanessa-mcp"
else
  mkdir -p "$(dirname "$HOME_DEST")"
  copy_tree "$VENDOR" "$HOME_DEST"
  echo "wrote: ~/.cursor/skills/vanessa-mcp"
fi

echo "vanessa-mcp: $PROJECT_STATUS"
