#!/usr/bin/env bash
set -euo pipefail

BIN_DEST="${HOME}/.local/bin/dictate-toggle"
KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation/"
KEYBINDING_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEYBINDING_PATH}"

if command -v gsettings >/dev/null 2>&1; then
  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  updated="$(
    printf '%s' "$current" |
      sed "s#'${KEYBINDING_PATH}', ##g; s#, '${KEYBINDING_PATH}'##g; s#'${KEYBINDING_PATH}'##g"
  )"
  if [[ "$updated" == "[]" ]]; then
    updated="@as []"
  fi
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
  gsettings reset "$KEYBINDING_SCHEMA" name 2>/dev/null || true
  gsettings reset "$KEYBINDING_SCHEMA" command 2>/dev/null || true
  gsettings reset "$KEYBINDING_SCHEMA" binding 2>/dev/null || true
fi

rm -f "$BIN_DEST"
rm -rf "${XDG_RUNTIME_DIR:-/tmp}/dictation-${USER}"

echo "Removed dictation shortcut and $BIN_DEST."
echo "The model and logs were left in ~/.local/share/whisper.cpp and ~/.cache/dictation."
