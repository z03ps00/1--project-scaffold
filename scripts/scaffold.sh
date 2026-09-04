#!/usr/bin/env bash
# Scaffold the standard 1C working-directory layout.
# Usage: scaffold.sh [project-root] [--vanessa] [--kd]
# Does not create 1Cv8.1CD, does not overwrite src/cf contents.
# 1c-rules are installed separately by install-1c-rules.sh (see SKILL.md).
# --vanessa / --kd default off: do not create tests/, tools/vanessa,
# tools/neurofish-mcp, or tools/mcp-toolkit unless the matching flag is set.
set -euo pipefail

WITH_VANESSA=0
WITH_KD=0
ROOT=""
for arg in "$@"; do
  case "$arg" in
    --vanessa) WITH_VANESSA=1 ;;
    --kd) WITH_KD=1 ;;
    --*)
      echo "usage: scaffold.sh [project-root] [--vanessa] [--kd]" >&2
      echo "unknown flag: $arg" >&2
      exit 1
      ;;
    *)
      if [[ -n "$ROOT" ]]; then
        echo "usage: scaffold.sh [project-root] [--vanessa] [--kd]" >&2
        exit 1
      fi
      ROOT="$arg"
      ;;
  esac
done
ROOT="${ROOT:-.}"
ROOT="$(cd "$ROOT" && pwd)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TPL="$SKILL_DIR/templates"

echo "Project root: $ROOT"
echo "vanessa=${WITH_VANESSA} kd=${WITH_KD}"

dirs=(
  "src/cf"
  "src/cfe"
  "src/epf"
  "src/erf"
  "_INFOBASE"
  "_LOGS"
  "_archives"
  "build/_for_debug"
  "_tmp"
  "_handoffs"
  "_docs"
)
if [[ "$WITH_VANESSA" -eq 1 ]]; then
  dirs+=(
    "tests/features"
    "tests/fixtures"
    "tests/screenshots"
    "tests/reports"
    "tools/vanessa"
    "tools/neurofish-mcp"
  )
fi
if [[ "$WITH_KD" -eq 1 ]]; then
  dirs+=("tools/mcp-toolkit")
fi

for d in "${dirs[@]}"; do
  mkdir -p "$ROOT/$d"
  keep="$ROOT/$d/.gitkeep"
  if [[ ! -e "$keep" ]]; then
    touch "$keep"
  fi
done
if [[ ! -e "$ROOT/build/.gitkeep" ]]; then
  touch "$ROOT/build/.gitkeep"
fi

copy_if_missing() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    echo "keep existing: ${dest#$ROOT/}"
  else
    cp "$src" "$dest"
    echo "wrote: ${dest#$ROOT/}"
  fi
}

# Merge Vanessa artifact ignores into .gitignore (template copy is skip-if-exists).
ensure_vanessa_gitignore() {
  local gi="$ROOT/.gitignore"
  local marker="tests/screenshots/*"
  if [[ ! -f "$gi" ]]; then
    return 0
  fi
  if grep -qF "$marker" "$gi" 2>/dev/null; then
    echo "gitignore already has Vanessa artifact rules"
    return 0
  fi
  {
    echo ""
    echo "# Vanessa Automation — артефакты прогонов (features/fixtures в git)"
    echo "tests/screenshots/*"
    echo "!tests/screenshots/.gitkeep"
    echo "tests/reports/*"
    echo "!tests/reports/.gitkeep"
  } >> "$gi"
  echo "appended Vanessa artifact rules to .gitignore"
}

ensure_vanessa_cursorignore() {
  local ci="$ROOT/.cursorignore"
  local marker="tests/screenshots/"
  if [[ ! -f "$ci" ]]; then
    return 0
  fi
  if grep -qF "$marker" "$ci" 2>/dev/null; then
    echo "cursorignore already has Vanessa artifact rules"
    return 0
  fi
  {
    echo ""
    echo "# Vanessa run artifacts"
    echo "tests/screenshots/"
    echo "tests/reports/"
  } >> "$ci"
  echo "appended Vanessa artifact rules to .cursorignore"
}

copy_if_missing "$TPL/gitignore" "$ROOT/.gitignore"
copy_if_missing "$TPL/cursorignore" "$ROOT/.cursorignore"
if [[ "$WITH_VANESSA" -eq 1 ]]; then
  ensure_vanessa_gitignore
  ensure_vanessa_cursorignore
fi

detect_platform() {
  local p=""
  if [[ -d /opt/1cv8/x86_64 ]]; then
    p="$(ls -d /opt/1cv8/x86_64/8.3.* 2>/dev/null | sort -V | tail -1 || true)"
  fi
  if [[ -z "$p" && -d "/opt/1cv8/x86_64/8.3.27.2130" ]]; then
    p="/opt/1cv8/x86_64/8.3.27.2130"
  fi
  printf '%s' "$p"
}

patch_devenv() {
  local envf="$ROOT/.dev.env"
  if [[ ! -f "$envf" ]]; then
    echo "no .dev.env — skip path patch (install 1c-rules first, then re-run)"
    return 0
  fi
  local platform
  platform="$(detect_platform)"
  python3 - "$envf" "$ROOT" "$platform" <<'PY'
import pathlib, re, sys
path, root, platform = sys.argv[1], sys.argv[2], sys.argv[3]
text = pathlib.Path(path).read_text(encoding="utf-8")
updates = {
    "INFOBASE_KIND": "file",
    "INFOBASE_PATH": f"{root}/_INFOBASE",
    "EXPORT_PATH": f"{root}/src/cf",
    "EXTENSIONS_PATH": f"{root}/src/cfe",
    "RELEASE_PATH": f"{root}/build",
    "LOG_PATH": f"{root}/_LOGS/1cv8.log",
    "TMP_PATH": f"{root}/_tmp",
    "DOCS_PATH": f"{root}/_docs",
    "HANDOFFS_PATH": f"{root}/_handoffs",
    "ARCHIVES_PATH": f"{root}/_archives",
}
if platform:
    updates["PLATFORM_PATH"] = platform

def detect_platform_version(project_root):
    candidates = [
        pathlib.Path(project_root) / "src/cf/Configuration.xml",
        pathlib.Path(project_root) / "Configuration.xml",
    ]
    cfe = pathlib.Path(project_root) / "src/cfe"
    if cfe.is_dir():
        candidates.extend(sorted(cfe.glob("*/Configuration.xml")))
    for xml in candidates:
        if not xml.is_file():
            continue
        body = xml.read_text(encoding="utf-8", errors="replace")
        m = re.search(
            r"<CompatibilityMode>Version(\d+)_(\d+)_(\d+)</CompatibilityMode>",
            body,
        )
        if m:
            return f"{m.group(1)}.{m.group(2)}.{m.group(3)}"
    return ""

platform_version = detect_platform_version(root)
if platform_version:
    updates["PLATFORM_VERSION"] = platform_version

def upsert(key, value, src):
    pat = re.compile(rf"(?m)^{re.escape(key)}=.*$")
    if pat.search(src):
        return pat.sub(f"{key}={value}", src, count=1), False
    return src, True

missing = []
for k, v in updates.items():
    text, is_new = upsert(k, v, text)
    if is_new:
        missing.append((k, v))
if missing:
    if not text.endswith("\n"):
        text += "\n"
    text += "\n# =============================================================================\n"
    text += "# Scaffold layout paths (1c-project-scaffold; not in 1c-rules template)\n"
    text += "# =============================================================================\n"
    for k, v in missing:
        text += f"{k}={v}\n"
pathlib.Path(path).write_text(text, encoding="utf-8")
print("patched .dev.env:")
for k, v in updates.items():
    print(f"  {k}={v}")
if missing:
    print("appended keys:", ", ".join(k for k, _ in missing))
PY
}

patch_devenv

echo "done. Did not create 1Cv8.1CD, did not touch AGENTS.md / rules."
echo "Next: fill USER-RULES.md structure section (see SKILL.md)."
