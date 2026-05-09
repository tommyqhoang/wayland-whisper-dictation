#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Dictation Toggle"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="${PROJECT_DIR}/bin/dictate-toggle"
BIN_DEST="${HOME}/.local/bin/dictate-toggle"
MODEL_DIR="${HOME}/.local/share/whisper.cpp/models"
MODEL_NAME="${DICTATION_MODEL_NAME:-ggml-base.en.bin}"
MODEL_URL="${DICTATION_MODEL_URL:-https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}}"
MODEL_DEST="${MODEL_DIR}/${MODEL_NAME}"
KEYBINDING_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dictation/"
KEYBINDING_SCHEMA="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEYBINDING_PATH}"
DEFAULT_BINDING="${DICTATION_BINDING:-<Super><Shift>d}"

need() {
  command -v "$1" >/dev/null 2>&1
}

install_packages() {
  if ! need apt-get; then
    echo "apt-get not found. This installer is intended for Debian or Debian-based systems." >&2
    return 1
  fi

  local packages=(
    alsa-utils
    curl
    gnome-session-canberra
    libnotify-bin
    perl
    wl-clipboard
    whisper.cpp
  )

  echo "Installing Debian packages: ${packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

install_model() {
  mkdir -p "$MODEL_DIR"
  if [[ -s "$MODEL_DEST" ]]; then
    echo "Model already present: $MODEL_DEST"
    return 0
  fi

  echo "Downloading Whisper model: $MODEL_NAME"
  curl -L --fail --continue-at - --output "$MODEL_DEST" "$MODEL_URL"
}

install_script() {
  mkdir -p "${HOME}/.local/bin"
  install -m 0755 "$BIN_SRC" "$BIN_DEST"
  echo "Installed $BIN_DEST"
}

install_gnome_shortcut() {
  if ! need gsettings; then
    echo "gsettings not found; skipping GNOME shortcut setup."
    return 0
  fi

  local current updated
  current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
  if [[ "$current" == "@as []" ]]; then
    updated="['${KEYBINDING_PATH}']"
  elif [[ "$current" == *"'${KEYBINDING_PATH}'"* ]]; then
    updated="$current"
  else
    updated="${current%]}', '${KEYBINDING_PATH}']"
  fi

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
  gsettings set "$KEYBINDING_SCHEMA" name "$APP_NAME"
  gsettings set "$KEYBINDING_SCHEMA" command "$BIN_DEST"
  gsettings set "$KEYBINDING_SCHEMA" binding "$DEFAULT_BINDING"
  echo "Installed GNOME shortcut: $DEFAULT_BINDING"
}

main() {
  if [[ "${1:-}" != "--no-packages" ]]; then
    install_packages
  else
    echo "Skipping package installation."
  fi

  install_model
  install_script
  install_gnome_shortcut

  echo
  echo "Done. Press Super+Shift+D once to record, then again to stop and copy."
}

main "$@"
