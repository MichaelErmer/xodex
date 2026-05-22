#!/usr/bin/env bash
set -euo pipefail

REPO="${XODEX_REPO:-${CODEX_SWITCH_REPO:-MichaelErmer/xodex}}"
BIN_NAME="xodex"
LEGACY_BIN_NAME="codex-switch"
INSTALL_DIR="${XODEX_INSTALL_DIR:-${CODEX_SWITCH_INSTALL_DIR:-$HOME/.codex/bin}}"

decode_base64() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    base64 --decode
  else
    base64 -D
  fi
}

path_has_dir() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}

find_source() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  if [ -f "$script_dir/$BIN_NAME" ]; then
    printf '%s/%s\n' "$script_dir" "$BIN_NAME"
    return 0
  fi

  command -v gh >/dev/null 2>&1 || {
    printf 'install.sh: gh is required when installing without a local checkout\n' >&2
    return 1
  }

  local tmp
  tmp="$(mktemp)"
  gh api "repos/$REPO/contents/$BIN_NAME" --jq .content | decode_base64 > "$tmp"
  chmod 0755 "$tmp"
  printf '%s\n' "$tmp"
}

link_into_path() {
  local installed="$1"
  local dir

  if path_has_dir "$INSTALL_DIR"; then
    return 0
  fi

  for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    [ -d "$dir" ] || continue
    path_has_dir "$dir" || continue
    [ -w "$dir" ] || continue
    if [ -e "$dir/$BIN_NAME" ] && [ ! -L "$dir/$BIN_NAME" ]; then
      continue
    fi
    ln -sfn "$installed" "$dir/$BIN_NAME"
    printf 'Linked %s -> %s\n' "$dir/$BIN_NAME" "$installed"
    return 0
  done

  printf 'Installed %s, but %s is not on PATH.\n' "$installed" "$INSTALL_DIR"
  printf 'Add this to your shell profile:\n'
  printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
}

remove_legacy_command() {
  local dir
  local legacy_path

  legacy_path="$INSTALL_DIR/$LEGACY_BIN_NAME"
  if [ -e "$legacy_path" ] || [ -L "$legacy_path" ]; then
    rm -f "$legacy_path"
    printf 'Removed legacy %s\n' "$legacy_path"
  fi

  for dir in /opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    [ -L "$dir/$LEGACY_BIN_NAME" ] || continue
    rm -f "$dir/$LEGACY_BIN_NAME"
    printf 'Removed legacy %s\n' "$dir/$LEGACY_BIN_NAME"
  done
}

main() {
  local source
  local installed

  source="$(find_source)"
  mkdir -p "$INSTALL_DIR"
  install -m 0755 "$source" "$INSTALL_DIR/$BIN_NAME"
  installed="$INSTALL_DIR/$BIN_NAME"

  remove_legacy_command
  link_into_path "$installed"
  printf 'Installed %s\n' "$installed"
}

main "$@"
