#!/usr/bin/env bash
# Download latest MCP_Toolkit.epf (ROCTUP) into a project root.
# Usage: download-mcp-toolkit.sh /absolute/path/to/project [--offline]
#
# Online: GitHub /releases/latest (no version hardcoded).
# Offline: copy OS asset from vendor/offline/1c-scaffold-deps.tar.gz (no network).
# Picks OS asset:
#   Linux  → MCP_Toolkit_linux.epf
#   Darwin → MCP_Toolkit_macos.epf
#   else   → MCP_Toolkit.epf (Windows x64)
# Saves as tools/mcp-toolkit/MCP_Toolkit.epf. Does not overwrite an existing
# *.epf. Does not load anything into an infobase.
# Writes tools/mcp-toolkit/VERSION.txt (git-tracked).
# Exit 0 = file present (downloaded, copied, or kept). Exit 2 = network / GitHub / missing asset / missing bundle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=offline-lib.sh
source "$SCRIPT_DIR/offline-lib.sh"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
scaffold_parse_offline_args "$@"

ROOT="${POSITIONAL[0]:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: download-mcp-toolkit.sh /absolute/path/to/project [--offline]" >&2
  exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"

DEST_DIR="$ROOT/tools/mcp-toolkit"
DEST_EPF="$DEST_DIR/MCP_Toolkit.epf"
mkdir -p "$DEST_DIR"

write_kv() {
  local dest="$1"
  shift
  {
    for pair in "$@"; do
      printf '%s\n' "$pair"
    done
  } >"$dest"
}

if [[ "$OFFLINE" -eq 1 ]]; then
  scaffold_offline_require "$SKILL_DIR"
  BUNDLE="$(scaffold_offline_bundle "$SKILL_DIR")"
  MANIFEST="$(scaffold_offline_manifest "$SKILL_DIR")"
  case "$(uname -s)" in
    Linux)  WANT_ASSET="MCP_Toolkit_linux.epf"; MAN_PREFIX="mcp_toolkit_linux" ;;
    Darwin) WANT_ASSET="MCP_Toolkit_macos.epf"; MAN_PREFIX="mcp_toolkit_macos" ;;
    *)      WANT_ASSET="MCP_Toolkit.epf"; MAN_PREFIX="mcp_toolkit_windows" ;;
  esac
  TAG="$(scaffold_manifest_get "$MANIFEST" mcp_toolkit_tag)"
  NAME="$(scaffold_manifest_get "$MANIFEST" "${MAN_PREFIX}_artifact")"
  URL="$(scaffold_manifest_get "$MANIFEST" "${MAN_PREFIX}_url")"
  DIGEST="$(scaffold_manifest_get "$MANIFEST" "${MAN_PREFIX}_sha256")"
  PACKED_AT="$(scaffold_manifest_get "$MANIFEST" packed_at)"

  EPF_EXISTS=0
  [[ -f "$DEST_EPF" ]] && EPF_EXISTS=1

  if [[ "$EPF_EXISTS" -eq 1 ]]; then
    echo "keep existing: tools/mcp-toolkit/MCP_Toolkit.epf"
  else
    echo "copying $NAME from offline bundle ($TAG)…"
    scaffold_offline_extract_file "$BUNDLE" "mcp-toolkit/${WANT_ASSET}" "$DEST_EPF"
    echo "wrote: tools/mcp-toolkit/MCP_Toolkit.epf"
  fi

  if [[ ! -f "$DEST_DIR/VERSION.txt" ]] || [[ "$EPF_EXISTS" -eq 0 ]]; then
    write_kv "$DEST_DIR/VERSION.txt" \
      "source=offline" \
      "packed_at=${PACKED_AT}" \
      "release=${TAG}" \
      "artifact=${NAME}" \
      "saved_as=MCP_Toolkit.epf" \
      "url=${URL}" \
      "sha256=${DIGEST}" \
      "os_asset=${WANT_ASSET}" \
      "purpose=EPF for live-IB HTTP API (open in 1C client; do not load into configuration)" \
      "note=copied from 1c-project-scaffold vendor/offline bundle; *.epf is gitignored"
  fi

  echo "source=offline"
  echo "mcp-toolkit_tag=${TAG}"
  echo "mcp-toolkit_asset=${NAME}"
  echo "mcp-toolkit_url=${URL}"
  echo "mcp-toolkit-deps: ok"
  echo "mcp-toolkit-deps: tools/mcp-toolkit/MCP_Toolkit.epf"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to download MCP Toolkit" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to parse GitHub release JSON" >&2
  exit 2
fi

case "$(uname -s)" in
  Linux)  WANT_ASSET="MCP_Toolkit_linux.epf" ;;
  Darwin) WANT_ASSET="MCP_Toolkit_macos.epf" ;;
  *)      WANT_ASSET="MCP_Toolkit.epf" ;;
esac

TMP="$(mktemp -d "${TMPDIR:-/tmp}/mcp-toolkit.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "fetching latest release from GitHub (ROCTUP/1c-mcp-toolkit)…"

if ! curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: 1c-project-scaffold" \
  "https://api.github.com/repos/ROCTUP/1c-mcp-toolkit/releases/latest" \
  >"$TMP/release.json"
then
  echo "error: GitHub API failed: ROCTUP/1c-mcp-toolkit/releases/latest" >&2
  exit 2
fi

if ! python3 - "$TMP/release.json" "$WANT_ASSET" "$TMP/asset.tsv" <<'PY'
import json, sys
from pathlib import Path

data_path, want, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(Path(data_path).read_text(encoding="utf-8"))
if "message" in data and "assets" not in data:
    raise SystemExit(f"GitHub API error: {data.get('message')}")
tag = data.get("tag_name") or ""
asset = None
for a in data.get("assets") or []:
    if a.get("name") == want:
        asset = a
        break
if not asset:
    names = ", ".join(a.get("name") or "" for a in (data.get("assets") or []))
    raise SystemExit(f"missing asset {want} on latest release (have: {names})")
digest = asset.get("digest") or ""
if isinstance(digest, str) and digest.startswith("sha256:"):
    digest = digest.split(":", 1)[1]
else:
    digest = ""
Path(out_path).write_text(
    "\t".join([tag, asset["name"], asset["browser_download_url"], digest]) + "\n",
    encoding="utf-8",
)
PY
then
  echo "error: could not parse GitHub release JSON (missing asset or API error)" >&2
  exit 2
fi

IFS=$'\t' read -r TAG NAME URL DIGEST <"$TMP/asset.tsv"

sha256_of() {
  local f="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$f" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$f" | awk '{print $1}'
  else
    python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$f"
  fi
}

EPF_EXISTS=0
[[ -f "$DEST_EPF" ]] && EPF_EXISTS=1

if [[ "$EPF_EXISTS" -eq 1 ]]; then
  echo "keep existing: tools/mcp-toolkit/MCP_Toolkit.epf"
else
  echo "downloading $NAME ($TAG)…"
  if ! curl -fL --retry 3 --retry-delay 2 -o "$DEST_EPF" "$URL"; then
    echo "error: download failed: $URL" >&2
    rm -f "$DEST_EPF"
    exit 2
  fi
  echo "wrote: tools/mcp-toolkit/MCP_Toolkit.epf"
fi

got=""
[[ -f "$DEST_EPF" ]] && got="$(sha256_of "$DEST_EPF")"
if [[ "$EPF_EXISTS" -eq 0 && -n "$DIGEST" && -n "$got" && "$DIGEST" != "$got" ]]; then
  echo "warning: GitHub digest ${DIGEST} != computed ${got}" >&2
fi

if [[ ! -f "$DEST_DIR/VERSION.txt" ]] || [[ "$EPF_EXISTS" -eq 0 ]]; then
  write_kv "$DEST_DIR/VERSION.txt" \
    "source=https://github.com/ROCTUP/1c-mcp-toolkit" \
    "release=${TAG}" \
    "artifact=${NAME}" \
    "saved_as=MCP_Toolkit.epf" \
    "url=${URL}" \
    "sha256=${got}" \
    "os_asset=${WANT_ASSET}" \
    "purpose=EPF for live-IB HTTP API (open in 1C client; do not load into configuration)" \
    "note=*.epf is gitignored — keep local or re-run download-mcp-toolkit.sh"
fi

echo "source=online"
echo "mcp-toolkit_tag=${TAG}"
echo "mcp-toolkit_asset=${NAME}"
echo "mcp-toolkit_url=${URL}"
echo "mcp-toolkit-deps: ok"
echo "mcp-toolkit-deps: tools/mcp-toolkit/MCP_Toolkit.epf"
