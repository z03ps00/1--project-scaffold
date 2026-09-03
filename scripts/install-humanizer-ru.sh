#!/usr/bin/env bash
# Install comol/Humanizer_RU agent skill (skills/humanizer-ru/) locally or globally.
# Usage: install-humanizer-ru.sh /absolute/path/to/project local|global [--offline]
#
# Online: git clone --depth=1 comol/Humanizer_RU, copy skills/humanizer-ru/.
# Offline: copy from vendor/offline/1c-scaffold-deps.tar.gz (member humanizer-ru/).
# Does not overwrite an existing SKILL.md. Does not touch ~/.cursor/skills/humanizer/
# (a different skill). Does not install the Python linter.
# Prints: source=online|offline, humanizer_ru_commit=…, scope=local|global,
#         humanizer-ru: installed | already present
# Exit 2 = network / missing bundle / missing skill tree.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=offline-lib.sh
source "$SCRIPT_DIR/offline-lib.sh"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
scaffold_parse_offline_args "$@"

ROOT="${POSITIONAL[0]:-}"
SCOPE="${POSITIONAL[1]:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: install-humanizer-ru.sh /absolute/path/to/project local|global [--offline]" >&2
  exit 1
fi
case "$SCOPE" in
  local|global) ;;
  *)
    echo "usage: install-humanizer-ru.sh /absolute/path/to/project local|global [--offline]" >&2
    exit 1
    ;;
esac
ROOT="$(cd "$ROOT" && pwd)"

if [[ "$SCOPE" == "local" ]]; then
  DEST="$ROOT/.cursor/skills/humanizer-ru"
else
  DEST="${HOME}/.cursor/skills/humanizer-ru"
fi

SOURCE_URL="https://github.com/comol/Humanizer_RU.git"
COMMIT=""
TMP=""
cleanup() {
  if [[ -n "$TMP" && -d "$TMP" ]]; then
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT

if [[ -f "$DEST/SKILL.md" ]]; then
  if [[ "$OFFLINE" -eq 1 ]]; then
    echo "source=offline"
    MANIFEST="$(scaffold_offline_manifest "$SKILL_DIR")"
    if [[ -f "$MANIFEST" ]]; then
      echo "humanizer_ru_commit=$(scaffold_manifest_get "$MANIFEST" humanizer_ru_commit)"
    fi
  else
    echo "source=online"
  fi
  if [[ "$SCOPE" == "local" ]]; then
    echo "keep existing: .cursor/skills/humanizer-ru (already present — skip)"
  else
    echo "keep existing: ~/.cursor/skills/humanizer-ru (already present — skip)"
  fi
  echo "scope=${SCOPE}"
  echo "humanizer-ru: already present"
  exit 0
fi

if [[ "$OFFLINE" -eq 1 ]]; then
  scaffold_offline_require "$SKILL_DIR"
  BUNDLE="$(scaffold_offline_bundle "$SKILL_DIR")"
  MANIFEST="$(scaffold_offline_manifest "$SKILL_DIR")"
  COMMIT="$(scaffold_manifest_get "$MANIFEST" humanizer_ru_commit)"
  echo "source=offline"
  echo "humanizer_ru_commit=${COMMIT}"
  scaffold_offline_extract_dir "$BUNDLE" "humanizer-ru" "$DEST"
  if [[ ! -f "$DEST/SKILL.md" ]]; then
    echo "error: offline bundle member humanizer-ru/ has no SKILL.md" >&2
    rm -rf "$DEST"
    exit 2
  fi
else
  if ! command -v git >/dev/null 2>&1; then
    echo "error: git is required to clone comol/Humanizer_RU" >&2
    exit 2
  fi
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/humanizer-ru.XXXXXX")"
  echo "cloning comol/Humanizer_RU (depth=1)…"
  if ! git clone --depth=1 "$SOURCE_URL" "$TMP/repo"; then
    echo "error: git clone failed: $SOURCE_URL" >&2
    exit 2
  fi
  COMMIT="$(git -C "$TMP/repo" rev-parse HEAD)"
  SRC="$TMP/repo/skills/humanizer-ru"
  if [[ ! -f "$SRC/SKILL.md" ]]; then
    echo "error: missing skills/humanizer-ru/SKILL.md in clone" >&2
    exit 2
  fi
  echo "source=online"
  echo "humanizer_ru_commit=${COMMIT}"
  mkdir -p "$(dirname "$DEST")"
  cp -a "$SRC" "$DEST"
fi

if [[ "$SCOPE" == "local" ]]; then
  echo "wrote: .cursor/skills/humanizer-ru"
else
  echo "wrote: ~/.cursor/skills/humanizer-ru"
fi
echo "scope=${SCOPE}"
echo "humanizer-ru: installed"
