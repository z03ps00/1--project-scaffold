#!/usr/bin/env bash
# Download current GitHub latest + ai_rules_1c + Humanizer_RU snapshot into vendor/offline.
# Usage: pack-offline-bundle.sh
# Writes vendor/offline/MANIFEST.txt and vendor/offline/1c-scaffold-deps.tar.gz
# Requires network, curl, python3, git, tar.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$SKILL_DIR/vendor/offline"
BUNDLE="$OUT_DIR/1c-scaffold-deps.tar.gz"
MANIFEST="$OUT_DIR/MANIFEST.txt"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required to pack the offline bundle" >&2
  exit 2
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is required to pack the offline bundle" >&2
  exit 2
fi
if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required to snapshot comol/ai_rules_1c" >&2
  exit 2
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "error: tar is required to write 1c-scaffold-deps.tar.gz" >&2
  exit 2
fi

github_latest() {
  local repo="$1"
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: 1c-project-scaffold" \
    "https://api.github.com/repos/${repo}/releases/latest"
}

download_file() {
  local url="$1" dest="$2"
  echo "downloading $(basename "$dest")…"
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

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/pack-offline.XXXXXX")"
cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

mkdir -p "$STAGING/vanessa" "$STAGING/neurofish" "$STAGING/mcp-toolkit" "$OUT_DIR"

echo "cloning comol/ai_rules_1c (depth=1)…"
git clone --depth=1 "https://github.com/comol/ai_rules_1c.git" "$STAGING/ai_rules_1c"
AI_COMMIT="$(git -C "$STAGING/ai_rules_1c" rev-parse HEAD)"
AI_REF="$(git -C "$STAGING/ai_rules_1c" rev-parse --abbrev-ref HEAD)"
rm -rf "$STAGING/ai_rules_1c/.git"

echo "cloning comol/Humanizer_RU (depth=1)…"
git clone --depth=1 "https://github.com/comol/Humanizer_RU.git" "$STAGING/Humanizer_RU"
HUMANIZER_COMMIT="$(git -C "$STAGING/Humanizer_RU" rev-parse HEAD)"
if [[ ! -f "$STAGING/Humanizer_RU/skills/humanizer-ru/SKILL.md" ]]; then
  echo "error: missing skills/humanizer-ru/SKILL.md in comol/Humanizer_RU clone" >&2
  exit 2
fi
cp -a "$STAGING/Humanizer_RU/skills/humanizer-ru" "$STAGING/humanizer-ru"
rm -rf "$STAGING/Humanizer_RU"

echo "fetching latest GitHub releases…"
if ! github_latest "1c-neurofish/onec-client-mcp-devkit" >"$STAGING/neurofish.json"; then
  echo "error: GitHub API failed: 1c-neurofish/onec-client-mcp-devkit/releases/latest" >&2
  exit 2
fi
if ! github_latest "Pr-Mex/vanessa-automation" >"$STAGING/vanessa.json"; then
  echo "error: GitHub API failed: Pr-Mex/vanessa-automation/releases/latest" >&2
  exit 2
fi
if ! github_latest "ROCTUP/1c-mcp-toolkit" >"$STAGING/toolkit.json"; then
  echo "error: GitHub API failed: ROCTUP/1c-mcp-toolkit/releases/latest" >&2
  exit 2
fi

if ! python3 - "$STAGING/neurofish.json" "$STAGING/vanessa.json" "$STAGING/toolkit.json" "$STAGING/assets.tsv" <<'PY'
import json, sys
from pathlib import Path

neuro_path, vanessa_path, toolkit_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
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

tk = load(toolkit_path)
tag_t = tk.get("tag_name") or ""
want = {
    "toolkit_linux": "MCP_Toolkit_linux.epf",
    "toolkit_macos": "MCP_Toolkit_macos.epf",
    "toolkit_windows": "MCP_Toolkit.epf",
}
found = {}
for a in tk.get("assets") or []:
    name = a.get("name") or ""
    for key, want_name in want.items():
        if name == want_name:
            found[key] = a
            break
missing = [want[k] for k in want if k not in found]
if missing:
    names = ", ".join(a.get("name") or "" for a in (tk.get("assets") or []))
    raise SystemExit(f"missing MCP Toolkit assets {missing} (have: {names})")
for key in ("toolkit_linux", "toolkit_windows", "toolkit_macos"):
    a = found[key]
    rows.append((key, tag_t, a["name"], a["browser_download_url"], digest_of(a)))

Path(out_path).write_text(
    "".join("\t".join(r) + "\n" for r in rows), encoding="utf-8"
)
PY
then
  echo "error: could not parse GitHub release JSON (missing asset or API error)" >&2
  exit 2
fi

NEURO_TAG="" NEURO_NAME="" NEURO_URL="" NEURO_SHA=""
VANESSA_TAG="" VANESSA_ZIP_NAME="" VANESSA_ZIP_URL="" VANESSA_EPF_SHA=""
VAEXT_NAME="" VAEXT_URL="" VAEXT_SHA=""
TK_TAG=""
TK_LINUX_NAME="" TK_LINUX_URL="" TK_LINUX_SHA=""
TK_WIN_NAME="" TK_WIN_URL="" TK_WIN_SHA=""
TK_MAC_NAME="" TK_MAC_URL="" TK_MAC_SHA=""

while IFS=$'\t' read -r key tag name url digest; do
  case "$key" in
    neurofish)
      dest="$STAGING/neurofish/client_mcp.cfe"
      download_file "$url" "$dest"
      NEURO_TAG="$tag"
      NEURO_NAME="$name"
      NEURO_URL="$url"
      NEURO_SHA="$(sha256_of "$dest")"
      if [[ -n "$digest" && "$digest" != "$NEURO_SHA" ]]; then
        echo "warning: GitHub digest ${digest} != computed ${NEURO_SHA}" >&2
      fi
      ;;
    single_zip)
      zip_path="$STAGING/$name"
      download_file "$url" "$zip_path"
      python3 - "$zip_path" "$STAGING/vanessa/vanessa-automation-single.epf" <<'PY'
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
      rm -f "$zip_path"
      VANESSA_TAG="$tag"
      VANESSA_ZIP_NAME="$name"
      VANESSA_ZIP_URL="$url"
      VANESSA_EPF_SHA="$(sha256_of "$STAGING/vanessa/vanessa-automation-single.epf")"
      ;;
    vaextension)
      dest="$STAGING/vanessa/VAExtension.cfe"
      download_file "$url" "$dest"
      VANESSA_TAG="${VANESSA_TAG:-$tag}"
      VAEXT_NAME="$name"
      VAEXT_URL="$url"
      VAEXT_SHA="$(sha256_of "$dest")"
      if [[ -n "$digest" && "$digest" != "$VAEXT_SHA" ]]; then
        echo "warning: GitHub digest ${digest} != computed ${VAEXT_SHA}" >&2
      fi
      ;;
    toolkit_linux)
      dest="$STAGING/mcp-toolkit/MCP_Toolkit_linux.epf"
      download_file "$url" "$dest"
      TK_TAG="$tag"
      TK_LINUX_NAME="$name"
      TK_LINUX_URL="$url"
      TK_LINUX_SHA="$(sha256_of "$dest")"
      if [[ -n "$digest" && "$digest" != "$TK_LINUX_SHA" ]]; then
        echo "warning: GitHub digest ${digest} != computed ${TK_LINUX_SHA}" >&2
      fi
      ;;
    toolkit_windows)
      dest="$STAGING/mcp-toolkit/MCP_Toolkit.epf"
      download_file "$url" "$dest"
      TK_TAG="${TK_TAG:-$tag}"
      TK_WIN_NAME="$name"
      TK_WIN_URL="$url"
      TK_WIN_SHA="$(sha256_of "$dest")"
      if [[ -n "$digest" && "$digest" != "$TK_WIN_SHA" ]]; then
        echo "warning: GitHub digest ${digest} != computed ${TK_WIN_SHA}" >&2
      fi
      ;;
    toolkit_macos)
      dest="$STAGING/mcp-toolkit/MCP_Toolkit_macos.epf"
      download_file "$url" "$dest"
      TK_TAG="${TK_TAG:-$tag}"
      TK_MAC_NAME="$name"
      TK_MAC_URL="$url"
      TK_MAC_SHA="$(sha256_of "$dest")"
      if [[ -n "$digest" && "$digest" != "$TK_MAC_SHA" ]]; then
        echo "warning: GitHub digest ${digest} != computed ${TK_MAC_SHA}" >&2
      fi
      ;;
  esac
done <"$STAGING/assets.tsv"

PACKED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

write_manifest() {
  local dest="$1"
  {
    echo "packed_at=${PACKED_AT}"
    echo "mode=offline"
    echo "ai_rules_1c_commit=${AI_COMMIT}"
    echo "ai_rules_1c_ref=${AI_REF}"
    echo "ai_rules_1c_url=https://github.com/comol/ai_rules_1c"
    echo "humanizer_ru_commit=${HUMANIZER_COMMIT}"
    echo "humanizer_ru_url=https://github.com/comol/Humanizer_RU"
    echo "neurofish_tag=${NEURO_TAG}"
    echo "neurofish_artifact=${NEURO_NAME}"
    echo "neurofish_url=${NEURO_URL}"
    echo "neurofish_sha256=${NEURO_SHA}"
    echo "vanessa_tag=${VANESSA_TAG}"
    echo "vanessa_zip=${VANESSA_ZIP_NAME}"
    echo "vanessa_zip_url=${VANESSA_ZIP_URL}"
    echo "vanessa_epf=vanessa-automation-single.epf"
    echo "vanessa_epf_sha256=${VANESSA_EPF_SHA}"
    echo "vaextension_artifact=${VAEXT_NAME}"
    echo "vaextension_url=${VAEXT_URL}"
    echo "vaextension_sha256=${VAEXT_SHA}"
    echo "mcp_toolkit_tag=${TK_TAG}"
    echo "mcp_toolkit_url=https://github.com/ROCTUP/1c-mcp-toolkit"
    echo "mcp_toolkit_linux_artifact=${TK_LINUX_NAME}"
    echo "mcp_toolkit_linux_url=${TK_LINUX_URL}"
    echo "mcp_toolkit_linux_sha256=${TK_LINUX_SHA}"
    echo "mcp_toolkit_windows_artifact=${TK_WIN_NAME}"
    echo "mcp_toolkit_windows_url=${TK_WIN_URL}"
    echo "mcp_toolkit_windows_sha256=${TK_WIN_SHA}"
    echo "mcp_toolkit_macos_artifact=${TK_MAC_NAME}"
    echo "mcp_toolkit_macos_url=${TK_MAC_URL}"
    echo "mcp_toolkit_macos_sha256=${TK_MAC_SHA}"
  } >"$dest"
}

write_manifest "$STAGING/MANIFEST.txt"

echo "writing $BUNDLE…"
tar -czf "$BUNDLE" -C "$STAGING" \
  MANIFEST.txt \
  ai_rules_1c \
  humanizer-ru \
  vanessa \
  neurofish \
  mcp-toolkit

cp -a "$STAGING/MANIFEST.txt" "$MANIFEST"

echo "packed: $BUNDLE"
echo "manifest: $MANIFEST"
echo "ai_rules_1c_commit=${AI_COMMIT}"
echo "humanizer_ru_commit=${HUMANIZER_COMMIT}"
echo "neurofish_tag=${NEURO_TAG}"
echo "vanessa_tag=${VANESSA_TAG}"
echo "mcp_toolkit_tag=${TK_TAG}"
ls -lh "$BUNDLE" "$MANIFEST"
echo "pack-offline-bundle: ok"
