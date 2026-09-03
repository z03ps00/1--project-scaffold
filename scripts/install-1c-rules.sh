#!/usr/bin/env bash
# Install comol/ai_rules_1c into a project root (PowerShell channel of AGENT-INSTALL.md).
# Usage: install-1c-rules.sh /absolute/path/to/project [tool,tool...] [--offline]
# Default tool: cursor. Skips if .ai-rules.json already exists. Does not vendor the clone
# into the project. --offline uses vendor/offline/1c-scaffold-deps.tar.gz (no git clone).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=offline-lib.sh
source "$SCRIPT_DIR/offline-lib.sh"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
scaffold_parse_offline_args "$@"

ROOT="${POSITIONAL[0]:-.}"
ROOT="$(cd "$ROOT" && pwd)"
TOOLS_CSV="${POSITIONAL[1]:-cursor}"
SOURCE_URL="https://github.com/comol/ai_rules_1c.git"
CACHE="${TMPDIR:-/tmp}/1c-rules-cache/1c-rules"

if [[ -f "$ROOT/.ai-rules.json" ]]; then
  echo "keep existing: .ai-rules.json (1c-rules already installed — skip init)"
  exit 0
fi

if [[ "$OFFLINE" -eq 1 ]]; then
  scaffold_offline_require "$SKILL_DIR"
  BUNDLE="$(scaffold_offline_bundle "$SKILL_DIR")"
  MANIFEST="$(scaffold_offline_manifest "$SKILL_DIR")"
  echo "source=offline"
  echo "ai_rules_1c_commit=$(scaffold_manifest_get "$MANIFEST" ai_rules_1c_commit)"
  mkdir -p "$(dirname "$CACHE")"
  scaffold_offline_extract_dir "$BUNDLE" "ai_rules_1c" "$CACHE"
  echo "offline_ai_rules_source=$CACHE"
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "pwsh not found — follow AGENT-INSTALL.md lean placement from offline snapshot: $CACHE" >&2
    exit 2
  fi
else
  if ! command -v git >/dev/null 2>&1; then
    echo "git not found — cannot clone comol/ai_rules_1c" >&2
    exit 1
  fi
  if ! command -v pwsh >/dev/null 2>&1; then
    echo "pwsh not found — follow AGENT-INSTALL.md lean placement (agent-driven channel)" >&2
    exit 2
  fi
  mkdir -p "$(dirname "$CACHE")"
  if [[ -d "$CACHE/.git" ]]; then
    git -C "$CACHE" fetch --depth=1 origin main
    git -C "$CACHE" reset --hard FETCH_HEAD
  else
    git clone --depth=1 "$SOURCE_URL" "$CACHE"
  fi
  echo "source=online"
fi

IFS=',' read -ra TOOL_ARR <<< "$TOOLS_CSV"

echo "Installing 1c-rules into $ROOT (tools: ${TOOL_ARR[*]})"
pwsh -NoProfile -File "$CACHE/install.ps1" init \
  -Tools "${TOOL_ARR[@]}" \
  -NonInteractive \
  -ProjectRoot "$ROOT" \
  -Source "$CACHE"
