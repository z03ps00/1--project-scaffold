#!/usr/bin/env bash
# Merge Vanessa MCP URL into .cursor/mcp.json.
# Usage: install-vanessa-config.sh /absolute/path/to/project
#
# Does not write _docs/ (setup guide lives in vendor/vanessa-mcp/docs/integration.md).
# Does not overwrite an existing vanessaAutomation MCP entry; merges the key if
# mcp.json exists without it. Does not invent AWG / docker-gateway URLs.
set -euo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: install-vanessa-config.sh /absolute/path/to/project" >&2
  exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SKILL_DIR/templates"

MCP_TPL="$TPL/mcp.json"
MCP_DEST="$ROOT/.cursor/mcp.json"

if [[ ! -f "$MCP_TPL" ]]; then
  echo "error: missing template $MCP_TPL" >&2
  exit 1
fi

mkdir -p "$ROOT/.cursor"

MCP_STATUS="$(python3 - "$MCP_TPL" "$MCP_DEST" <<'PY'
import json, sys
from pathlib import Path

tpl_path, dest_path = Path(sys.argv[1]), Path(sys.argv[2])
tpl = json.loads(tpl_path.read_text(encoding="utf-8"))
entry = tpl["mcpServers"]["vanessaAutomation"]

if not dest_path.is_file():
    dest_path.write_text(
        json.dumps(tpl, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("wrote")
    raise SystemExit(0)

raw = dest_path.read_text(encoding="utf-8")
try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"error: .cursor/mcp.json is not valid JSON: {e}", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(data, dict):
    print("error: .cursor/mcp.json root is not an object", file=sys.stderr)
    raise SystemExit(1)

servers = data.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    print("error: mcpServers is not an object", file=sys.stderr)
    raise SystemExit(1)

if "vanessaAutomation" in servers or "VanessaAutomation" in servers:
    print("already present")
    raise SystemExit(0)

servers["vanessaAutomation"] = entry
dest_path.write_text(
    json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print("merged")
PY
)"

case "$MCP_STATUS" in
  wrote) echo "wrote: .cursor/mcp.json (vanessaAutomation → http://127.0.0.1:5431/mcp)" ;;
  merged) echo "merged vanessaAutomation into existing .cursor/mcp.json" ;;
  "already present") echo "keep existing: .cursor/mcp.json vanessaAutomation entry" ;;
  *) echo "error: unexpected mcp.json status: $MCP_STATUS" >&2; exit 1 ;;
esac

echo "vanessa-config: mcp.json=${MCP_STATUS}"
