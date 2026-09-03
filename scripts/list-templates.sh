#!/usr/bin/env bash
# List 1C configuration templates from .mft files.
# Usage: list-templates.sh [tmplts-dir]
# stdout: TSV  n<TAB>catalog<TAB>file
# stderr: tmplts=<path> or tmplts=not found
# Always exits 0 (empty list is valid).
set -euo pipefail

resolve_tmplts() {
  local cfg="${HOME}/.1C/1cestart/1cestart.cfg"
  local from_cfg=""
  if [[ -f "$cfg" ]]; then
    from_cfg="$(grep -E '^ConfigurationTemplatesLocation=' "$cfg" | head -1 | cut -d= -f2- || true)"
  fi
  if [[ -n "$from_cfg" && -d "$from_cfg" ]]; then
    printf '%s' "$from_cfg"
    return 0
  fi
  local fallback="${HOME}/.1cv8/1C/1cv8/tmplts"
  if [[ -d "$fallback" ]]; then
    printf '%s' "$fallback"
    return 0
  fi
  return 1
}

TMPLTS="${1:-}"
if [[ -n "$TMPLTS" ]]; then
  if [[ ! -d "$TMPLTS" ]]; then
    echo "tmplts=not found" >&2
    echo "error: not a directory: $TMPLTS" >&2
    exit 0
  fi
else
  if ! TMPLTS="$(resolve_tmplts)"; then
    echo "tmplts=not found" >&2
    exit 0
  fi
fi

echo "tmplts=$TMPLTS" >&2

n=0
# NUL-safe walk; .mft / .MFT
while IFS= read -r -d '' mft; do
  dir="$(dirname "$mft")"
  catalog=""
  source=""
  flush() {
    [[ -n "$source" ]] || return 0
    local f="$dir/$source"
    if [[ ! -f "$f" ]]; then
      # case-insensitive fallback (1Cv8.dt vs 1cv8.dt)
      local hit
      hit="$(find "$dir" -maxdepth 1 -iname "$source" -type f | head -1 || true)"
      [[ -n "$hit" && -f "$hit" ]] || return 0
      f="$hit"
    fi
    local label="${catalog:-$source}"
    label="${label//$'\t'/ }"
    n=$((n + 1))
    printf '%s\t%s\t%s\n' "$n" "$label" "$f"
  }
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    if [[ "$line" =~ ^\[Config ]]; then
      flush
      catalog=""
      source=""
      continue
    fi
    case "$line" in
      Catalog=*) catalog="${line#Catalog=}" ;;
      Source=*) source="${line#Source=}" ;;
    esac
  done < "$mft"
  flush
done < <(find "$TMPLTS" \( -iname '*.mft' \) -type f -print0 | sort -z)

exit 0
