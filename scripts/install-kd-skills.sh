#!/usr/bin/env bash
# Copy vendored KD / MCP-toolkit skills into a project root (and ~/.cursor/skills if missing).
# Appends port keys to .dev.env when absent. Does not write into _docs/
# (skill docs live in vendor/1c-mcp-toolkit/docs/integration.md).
# Usage: install-kd-skills.sh /absolute/path/to/project kd2|kd31|both
# Does not overwrite existing SKILL.md copies. Does not download the EPF
# (that is download-mcp-toolkit.sh, only after an explicit KD choice).
set -euo pipefail

ROOT="${1:-}"
MODE="${2:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: install-kd-skills.sh /absolute/path/to/project kd2|kd31|both" >&2
  exit 1
fi
case "$MODE" in
  kd2|kd31|both) ;;
  *)
    echo "usage: install-kd-skills.sh /absolute/path/to/project kd2|kd31|both" >&2
    exit 1
    ;;
esac
ROOT="$(cd "$ROOT" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOME_SKILLS="${HOME}/.cursor/skills"

copy_skill() {
  local name="$1"
  local src="$SKILL_DIR/vendor/$name"
  local dest="$ROOT/.cursor/skills/$name"
  local home_dest="$HOME_SKILLS/$name"
  local status="installed"

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "$name: skipped (no vendor)"
    echo "${name}_status=skipped (no vendor)"
    return 0
  fi

  if [[ -f "$dest/SKILL.md" ]]; then
    echo "keep existing: .cursor/skills/$name (already present — skip)"
    status="already present"
  else
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "wrote: .cursor/skills/$name"
  fi

  if [[ -f "$home_dest/SKILL.md" ]]; then
    echo "keep existing: ~/.cursor/skills/$name"
  else
    mkdir -p "$(dirname "$home_dest")"
    cp -a "$src" "$home_dest"
    echo "wrote: ~/.cursor/skills/$name"
  fi

  echo "$name: $status"
  echo "${name}_status=$status"
}

copy_skill "1c-mcp-toolkit"
case "$MODE" in
  kd2)  copy_skill "kd2-rules" ;;
  kd31) copy_skill "kd31-rules" ;;
  both)
    copy_skill "kd2-rules"
    copy_skill "kd31-rules"
    ;;
esac

# Append port keys to .dev.env if the file exists and keys are absent.
ENVF="$ROOT/.dev.env"
if [[ -f "$ENVF" ]]; then
  python3 - "$ENVF" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
keys = [
    ("MCP_TOOLKIT_PORT", "6003"),
    ("KD2_PORT", "7003"),
    ("KD31_PORT", "6011"),
]
missing = []
for k, v in keys:
    if not re.search(rf"(?m)^{re.escape(k)}=", text):
        missing.append((k, v))
if missing:
    if not text.endswith("\n"):
        text += "\n"
    text += "\n# =============================================================================\n"
    text += "# MCP Toolkit / Конвертация данных (1c-project-scaffold)\n"
    text += "# =============================================================================\n"
    for k, v in missing:
        text += f"{k}={v}\n"
    path.write_text(text, encoding="utf-8")
    print("patched .dev.env:", ", ".join(k for k, _ in missing))
else:
    print("keep existing: .dev.env KD/toolkit port keys")
PY
else
  echo "no .dev.env — skip KD port keys"
fi

echo "kd-skills: ok"
