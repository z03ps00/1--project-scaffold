#!/usr/bin/env bash
# Download latest Vanessa + neurofish binaries into a project root.
# Usage: download-vanessa-deps.sh /absolute/path/to/project [--offline]
#
# Online: GitHub /releases/latest (no version hardcoded).
# Offline: copy from vendor/offline/1c-scaffold-deps.tar.gz (no network).
# Does not overwrite existing *.epf / *.cfe. Does not load anything into an infobase.
# Writes tools/vanessa/VERSION.txt and tools/neurofish-mcp/VERSION.txt.
# Exit 0 = files present (downloaded, copied, or kept). Exit 2 = network / GitHub / missing asset / missing bundle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=offline-lib.sh
source "$SCRIPT_DIR/offline-lib.sh"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
scaffold_parse_offline_args "$@"

ROOT="${POSITIONAL[0]:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: download-vanessa-deps.sh /absolute/path/to/project [--offline]" >&2
  exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"

VANESSA_DIR="$ROOT/tools/vanessa"
NEURO_DIR="$ROOT/tools/neurofish-mcp"
mkdir -p "$VANESSA_DIR" "$NEURO_DIR"

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
  PACKED_AT="$(scaffold_manifest_get "$MANIFEST" packed_at)"
  NEURO_TAG="$(scaffold_manifest_get "$MANIFEST" neurofish_tag)"
  NEURO_NAME="$(scaffold_manifest_get "$MANIFEST" neurofish_artifact)"
  NEURO_URL="$(scaffold_manifest_get "$MANIFEST" neurofish_url)"
  NEURO_SHA="$(scaffold_manifest_get "$MANIFEST" neurofish_sha256)"
  VANESSA_TAG="$(scaffold_manifest_get "$MANIFEST" vanessa_tag)"
  VANESSA_ZIP_NAME="$(scaffold_manifest_get "$MANIFEST" vanessa_zip)"
  VANESSA_ZIP_URL="$(scaffold_manifest_get "$MANIFEST" vanessa_zip_url)"
  VANESSA_EPF_SHA="$(scaffold_manifest_get "$MANIFEST" vanessa_epf_sha256)"
  VAEXT_NAME="$(scaffold_manifest_get "$MANIFEST" vaextension_artifact)"
  VAEXT_URL="$(scaffold_manifest_get "$MANIFEST" vaextension_url)"
  VAEXT_SHA="$(scaffold_manifest_get "$MANIFEST" vaextension_sha256)"

  NEURO_EPF_EXISTS=0
  VANESSA_EPF_EXISTS=0
  VAEXT_EXISTS=0
  [[ -f "$NEURO_DIR/client_mcp.cfe" ]] && NEURO_EPF_EXISTS=1
  [[ -f "$VANESSA_DIR/vanessa-automation-single.epf" ]] && VANESSA_EPF_EXISTS=1
  if [[ -f "$VANESSA_DIR/VAExtension.cfe" ]] || compgen -G "$VANESSA_DIR/VAExtension*.cfe" >/dev/null 2>&1; then
    VAEXT_EXISTS=1
  fi

  if [[ "$NEURO_EPF_EXISTS" -eq 1 ]]; then
    echo "keep existing: tools/neurofish-mcp/client_mcp.cfe"
  else
    echo "copying $NEURO_NAME from offline bundle ($NEURO_TAG)…"
    scaffold_offline_extract_file "$BUNDLE" "neurofish/client_mcp.cfe" "$NEURO_DIR/client_mcp.cfe"
    echo "wrote: tools/neurofish-mcp/client_mcp.cfe"
  fi
  echo "neurofish: ${NEURO_TAG} ${NEURO_NAME}"
  echo "neurofish_tag=${NEURO_TAG}"
  echo "neurofish_url=${NEURO_URL}"

  if [[ "$VANESSA_EPF_EXISTS" -eq 1 ]]; then
    echo "keep existing: tools/vanessa/vanessa-automation-single.epf"
  else
    echo "copying vanessa-automation-single.epf from offline bundle ($VANESSA_TAG)…"
    scaffold_offline_extract_file "$BUNDLE" "vanessa/vanessa-automation-single.epf" \
      "$VANESSA_DIR/vanessa-automation-single.epf"
    echo "wrote: tools/vanessa/vanessa-automation-single.epf"
  fi
  echo "vanessa_tag=${VANESSA_TAG}"
  echo "vanessa_zip=${VANESSA_ZIP_NAME}"
  echo "vanessa_zip_url=${VANESSA_ZIP_URL}"

  if [[ "$VAEXT_EXISTS" -eq 1 ]]; then
    echo "keep existing: tools/vanessa/VAExtension.cfe"
  else
    echo "copying $VAEXT_NAME from offline bundle ($VANESSA_TAG)…"
    scaffold_offline_extract_file "$BUNDLE" "vanessa/VAExtension.cfe" "$VANESSA_DIR/VAExtension.cfe"
    echo "wrote: tools/vanessa/VAExtension.cfe"
    echo "vaextension: ${VANESSA_TAG} ${VAEXT_NAME}"
  fi
  echo "vaextension_tag=${VANESSA_TAG}"
  echo "vaextension_name=${VAEXT_NAME}"
  echo "vaextension_url=${VAEXT_URL}"

  if [[ ! -f "$NEURO_DIR/VERSION.txt" ]] || [[ "$NEURO_EPF_EXISTS" -eq 0 ]]; then
    write_kv "$NEURO_DIR/VERSION.txt" \
      "source=offline" \
      "packed_at=${PACKED_AT}" \
      "release=${NEURO_TAG}" \
      "artifact=${NEURO_NAME}" \
      "url=${NEURO_URL}" \
      "sha256=${NEURO_SHA}" \
      "purpose=CFE for Vanessa MCP (test manager IB); start MCP from extension" \
      "note=copied from 1c-project-scaffold vendor/offline bundle; *.cfe is gitignored"
  fi
  if [[ ! -f "$VANESSA_DIR/VERSION.txt" ]] || [[ "$VANESSA_EPF_EXISTS" -eq 0 || "$VAEXT_EXISTS" -eq 0 ]]; then
    write_kv "$VANESSA_DIR/VERSION.txt" \
      "source=offline" \
      "packed_at=${PACKED_AT}" \
      "release=${VANESSA_TAG}" \
      "artifact_epf=vanessa-automation-single.epf" \
      "artifact_zip=${VANESSA_ZIP_NAME}" \
      "url_zip=${VANESSA_ZIP_URL}" \
      "sha256_epf=${VANESSA_EPF_SHA}" \
      "artifact_cfe=${VAEXT_NAME}" \
      "url_cfe=${VAEXT_URL}" \
      "sha256_cfe=${VAEXT_SHA}" \
      "note=copied from 1c-project-scaffold vendor/offline bundle; *.epf and *.cfe are gitignored"
  fi

  echo "source=offline"
  echo "vanessa-deps: ok"
  echo "vanessa-deps: tools/vanessa/vanessa-automation-single.epf + VAExtension.cfe; tools/neurofish-mcp/client_mcp.cfe"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to download Vanessa dependencies" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to parse GitHub release JSON" >&2
  exit 2
fi

github_latest() {
  local repo="$1"
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: 1c-project-scaffold" \
    "https://api.github.com/repos/${repo}/releases/latest"
}

TMP="$(mktemp -d "${TMPDIR:-/tmp}/vanessa-deps.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "fetching latest releases from GitHub…"

if ! github_latest "1c-neurofish/onec-client-mcp-devkit" >"$TMP/neurofish.json"; then
  echo "error: GitHub API failed: 1c-neurofish/onec-client-mcp-devkit/releases/latest" >&2
  exit 2
fi
if ! github_latest "Pr-Mex/vanessa-automation" >"$TMP/vanessa.json"; then
  echo "error: GitHub API failed: Pr-Mex/vanessa-automation/releases/latest" >&2
  exit 2
fi

# Prints: key<TAB>tag<TAB>name<TAB>url<TAB>digest
if ! python3 - "$TMP/neurofish.json" "$TMP/vanessa.json" "$TMP/assets.tsv" <<'PY'
import json, sys
from pathlib import Path

neuro_path, vanessa_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
rows = []

def digest_of(asset):
    d = asset.get("digest") or ""
    if isinstance(d, str) and d.startswith("sha256:"):
        return d.split(":", 1)[1]
    return ""

def load(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if "message" in data and "assets" not in data:
        raise SystemExit(f"GitHub API error: {data.get('message')}")
    return data

neuro = load(neuro_path)
tag_n = neuro.get("tag_name") or ""
cfe = None
for a in neuro.get("assets") or []:
    if a.get("name") == "client_mcp.cfe":
        cfe = a
        break
if not cfe:
    raise SystemExit("missing asset client_mcp.cfe on neurofish latest release")
rows.append(("neurofish", tag_n, cfe["name"], cfe["browser_download_url"], digest_of(cfe)))

va = load(vanessa_path)
tag_v = va.get("tag_name") or ""
single = None
vaext = None
for a in va.get("assets") or []:
    name = a.get("name") or ""
    if name.startswith("vanessa-automation-single") and name.endswith(".zip"):
        single = a
    elif name.startswith("VAExtension") and name.endswith(".cfe"):
        vaext = a
if not single:
    raise SystemExit("missing asset vanessa-automation-single*.zip on Pr-Mex latest release")
if not vaext:
    raise SystemExit("missing asset VAExtension*.cfe on Pr-Mex latest release")
rows.append(("single_zip", tag_v, single["name"], single["browser_download_url"], digest_of(single)))
rows.append(("vaextension", tag_v, vaext["name"], vaext["browser_download_url"], digest_of(vaext)))

Path(out_path).write_text(
    "".join("\t".join(r) + "\n" for r in rows), encoding="utf-8"
)
PY
then
  echo "error: could not parse GitHub release JSON (missing asset or API error)" >&2
  exit 2
fi

download_file() {
  local url="$1" dest="$2"
  if ! curl -fL --retry 3 --retry-delay 2 -o "$dest" "$url"; then
    echo "error: download failed: $url" >&2
    exit 2
  fi
}

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

NEURO_EPF_EXISTS=0
VANESSA_EPF_EXISTS=0
VAEXT_EXISTS=0
[[ -f "$NEURO_DIR/client_mcp.cfe" ]] && NEURO_EPF_EXISTS=1
[[ -f "$VANESSA_DIR/vanessa-automation-single.epf" ]] && VANESSA_EPF_EXISTS=1
if [[ -f "$VANESSA_DIR/VAExtension.cfe" ]] || compgen -G "$VANESSA_DIR/VAExtension*.cfe" >/dev/null 2>&1; then
  VAEXT_EXISTS=1
fi

while IFS=$'\t' read -r key tag name url digest; do
  case "$key" in
    neurofish)
      dest="$NEURO_DIR/client_mcp.cfe"
      if [[ "$NEURO_EPF_EXISTS" -eq 1 ]]; then
        echo "keep existing: tools/neurofish-mcp/client_mcp.cfe"
      else
        echo "downloading $name ($tag)…"
        download_file "$url" "$dest"
        got="$(sha256_of "$dest")"
        write_kv "$NEURO_DIR/VERSION.txt" \
          "source=https://github.com/1c-neurofish/onec-client-mcp-devkit" \
          "release=${tag}" \
          "artifact=${name}" \
          "url=${url}" \
          "sha256=${got}" \
          "purpose=CFE for Vanessa MCP (test manager IB); start MCP from extension" \
          "note=*.cfe is gitignored — keep local or re-run download-vanessa-deps.sh"
        echo "wrote: tools/neurofish-mcp/client_mcp.cfe"
        echo "neurofish: ${tag} ${name}"
        if [[ -n "$digest" && "$digest" != "$got" ]]; then
          echo "warning: GitHub digest ${digest} != computed ${got}" >&2
        fi
      fi
      echo "neurofish_tag=${tag}"
      echo "neurofish_url=${url}"
      ;;
    single_zip)
      dest="$VANESSA_DIR/vanessa-automation-single.epf"
      if [[ "$VANESSA_EPF_EXISTS" -eq 1 ]]; then
        echo "keep existing: tools/vanessa/vanessa-automation-single.epf"
      else
        echo "downloading $name ($tag)…"
        zip_path="$TMP/$name"
        download_file "$url" "$zip_path"
        python3 - "$zip_path" "$dest" <<'PY'
import sys, zipfile, tempfile, shutil
from pathlib import Path
zip_path, dest = Path(sys.argv[1]), Path(sys.argv[2])
with tempfile.TemporaryDirectory() as td:
    with zipfile.ZipFile(zip_path) as z:
        z.extractall(td)
    epfs = list(Path(td).rglob("*.epf"))
    if not epfs:
        raise SystemExit(f"no .epf inside {zip_path.name}")
    preferred = [p for p in epfs if "single" in p.name.lower()]
    src = preferred[0] if preferred else epfs[0]
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dest)
    print(f"extracted: {src.name} -> {dest}")
PY
        echo "wrote: tools/vanessa/vanessa-automation-single.epf"
      fi
      echo "vanessa_tag=${tag}"
      echo "vanessa_zip=${name}"
      echo "vanessa_zip_url=${url}"
      VANESSA_TAG="$tag"
      VANESSA_ZIP_NAME="$name"
      VANESSA_ZIP_URL="$url"
      ;;
    vaextension)
      dest="$VANESSA_DIR/VAExtension.cfe"
      if [[ "$VAEXT_EXISTS" -eq 1 ]]; then
        echo "keep existing: tools/vanessa/VAExtension.cfe"
      else
        echo "downloading $name ($tag)…"
        download_file "$url" "$dest"
        got="$(sha256_of "$dest")"
        echo "wrote: tools/vanessa/VAExtension.cfe"
        echo "vaextension: ${tag} ${name}"
        VAEXT_NAME="$name"
        VAEXT_URL="$url"
        VAEXT_SHA="$got"
        if [[ -n "$digest" && "$digest" != "$got" ]]; then
          echo "warning: GitHub digest ${digest} != computed ${got}" >&2
        fi
      fi
      echo "vaextension_tag=${tag}"
      echo "vaextension_name=${name}"
      echo "vaextension_url=${url}"
      VAEXT_NAME="${VAEXT_NAME:-$name}"
      VAEXT_URL="${VAEXT_URL:-$url}"
      VANESSA_TAG="${VANESSA_TAG:-$tag}"
      ;;
  esac
done <"$TMP/assets.tsv"

# Always refresh VERSION.txt for Vanessa dir when we know latest tags
# (even if files were kept — record what latest *is*, plus local note).
if [[ ! -f "$VANESSA_DIR/VERSION.txt" ]] || [[ "$VANESSA_EPF_EXISTS" -eq 0 || "$VAEXT_EXISTS" -eq 0 ]]; then
  epf_sha=""
  vaext_sha=""
  [[ -f "$VANESSA_DIR/vanessa-automation-single.epf" ]] && epf_sha="$(sha256_of "$VANESSA_DIR/vanessa-automation-single.epf")"
  [[ -f "$VANESSA_DIR/VAExtension.cfe" ]] && vaext_sha="$(sha256_of "$VANESSA_DIR/VAExtension.cfe")"
  write_kv "$VANESSA_DIR/VERSION.txt" \
    "source=https://github.com/Pr-Mex/vanessa-automation" \
    "release=${VANESSA_TAG:-unknown}" \
    "artifact_epf=vanessa-automation-single.epf" \
    "artifact_zip=${VANESSA_ZIP_NAME:-}" \
    "url_zip=${VANESSA_ZIP_URL:-}" \
    "sha256_epf=${epf_sha}" \
    "artifact_cfe=${VAEXT_NAME:-VAExtension.cfe}" \
    "url_cfe=${VAEXT_URL:-}" \
    "sha256_cfe=${vaext_sha}" \
    "note=*.epf and *.cfe are gitignored — keep local or re-run download-vanessa-deps.sh"
fi

if [[ "$NEURO_EPF_EXISTS" -eq 1 && ! -f "$NEURO_DIR/VERSION.txt" ]]; then
  write_kv "$NEURO_DIR/VERSION.txt" \
    "source=https://github.com/1c-neurofish/onec-client-mcp-devkit" \
    "artifact=client_mcp.cfe" \
    "note=existing file kept; tag unknown — re-run download after removing the cfe to refresh"
fi

echo "source=online"
echo "vanessa-deps: ok"
echo "vanessa-deps: tools/vanessa/vanessa-automation-single.epf + VAExtension.cfe; tools/neurofish-mcp/client_mcp.cfe"
