#!/usr/bin/env bash
# Create a file infobase (empty or from a .cf/.dt template) and register it
# in the 1C starter list.
# Usage: create-empty-ib.sh /absolute/path/to/project [list-name] [template-file]
#
# Linux CREATEINFOBASE: the File= token must contain quotes around a path
# with spaces/Cyrillic. Do not use db-create.ps1 here — $TEMP is empty and
# File="path" quotes become literal argv. /UseTemplate is a separate argv.
set -euo pipefail

ROOT="${1:-}"
if [[ -z "$ROOT" || ! -d "$ROOT" ]]; then
  echo "usage: create-empty-ib.sh /absolute/path/to/project [list-name] [template-file]" >&2
  exit 1
fi
ROOT="$(cd "$ROOT" && pwd)"
LIST_NAME="${2:-$(basename "$ROOT")}"
TEMPLATE="${3:-}"

read_devenv() {
  local key="$1"
  local envf="$ROOT/.dev.env"
  [[ -f "$envf" ]] || return 0
  grep -E "^${key}=" "$envf" | head -1 | cut -d= -f2- || true
}

PLATFORM_PATH="$(read_devenv PLATFORM_PATH)"
INFOBASE_PATH="$(read_devenv INFOBASE_PATH)"

if [[ -z "$PLATFORM_PATH" && -d /opt/1cv8/x86_64 ]]; then
  PLATFORM_PATH="$(ls -d /opt/1cv8/x86_64/8.3.* 2>/dev/null | sort -V | tail -1 || true)"
fi
if [[ -z "$INFOBASE_PATH" ]]; then
  INFOBASE_PATH="$ROOT/_INFOBASE"
fi

if [[ -n "$TEMPLATE" ]]; then
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "error: template file not found: $TEMPLATE" >&2
    exit 1
  fi
  case "${TEMPLATE,,}" in
    *.dt|*.cf) ;;
    *) echo "error: template must be .dt or .cf: $TEMPLATE" >&2; exit 1 ;;
  esac
fi

BIN="$PLATFORM_PATH/1cv8"
if [[ ! -x "$BIN" ]]; then
  echo "error: 1cv8 not found at $BIN" >&2
  exit 1
fi

mkdir -p "$INFOBASE_PATH"
IB_FILE="$INFOBASE_PATH/1Cv8.1CD"
if [[ -f "$IB_FILE" && -s "$IB_FILE" ]]; then
  echo "keep existing: $IB_FILE (non-empty) — skip create"
  exit 0
fi

mapfile -t extras < <(find "$INFOBASE_PATH" -mindepth 1 -maxdepth 1 ! -name '.gitkeep')
if [[ ${#extras[@]} -gt 0 ]]; then
  echo "error: $INFOBASE_PATH is not empty (besides .gitkeep):" >&2
  printf '  %s\n' "${extras[@]}" >&2
  exit 1
fi

GITKEEP=""
if [[ -e "$INFOBASE_PATH/.gitkeep" ]]; then
  GITKEEP="$(mktemp)"
  mv "$INFOBASE_PATH/.gitkeep" "$GITKEEP"
fi

restore_gitkeep() {
  if [[ -n "${GITKEEP:-}" && -e "$GITKEEP" ]]; then
    mv -f "$GITKEEP" "$INFOBASE_PATH/.gitkeep"
  fi
}
trap restore_gitkeep EXIT

LOG_DIR="$ROOT/_LOGS"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/create_empty_ib.log"

set +e
if [[ -n "$TEMPLATE" ]]; then
  echo "template: $TEMPLATE"
  "$BIN" CREATEINFOBASE "File=\"${INFOBASE_PATH}\";" /UseTemplate "$TEMPLATE" /AddToList "$LIST_NAME" /L ru /DisableStartupDialogs /Out "$LOG"
else
  "$BIN" CREATEINFOBASE "File=\"${INFOBASE_PATH}\";" /AddToList "$LIST_NAME" /L ru /DisableStartupDialogs /Out "$LOG"
fi
rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  echo "error: CREATEINFOBASE exit $rc" >&2
  [[ -f "$LOG" ]] && cat "$LOG" >&2
  exit "$rc"
fi

if [[ ! -s "$IB_FILE" ]]; then
  echo "error: 1Cv8.1CD missing or empty at $INFOBASE_PATH" >&2
  [[ -f "$LOG" ]] && cat "$LOG" >&2
  exit 1
fi

V8I="${HOME}/.1C/1cestart/ibases.v8i"
if [[ -f "$V8I" ]] && grep -qF "[${LIST_NAME}]" "$V8I"; then
  echo "registered: [$LIST_NAME] in $V8I"
else
  echo "warn: [$LIST_NAME] not found in $V8I — check $LOG" >&2
fi

echo "created: $IB_FILE ($(stat -c%s "$IB_FILE") bytes)"
echo "list name: $LIST_NAME"
[[ -n "$TEMPLATE" ]] && echo "from template: $TEMPLATE"
[[ -f "$LOG" ]] && cat "$LOG"
