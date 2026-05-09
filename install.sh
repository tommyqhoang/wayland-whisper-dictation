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

  local base_packages=(
    alsa-utils
    build-essential
    ca-certificates
    cmake
    curl
    git
    gnome-session-canberra
    libnotify-bin
    perl
    wl-clipboard
  )

  echo "Installing Debian packages: ${base_packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${base_packages[@]}"
  install_whisper
}

install_whisper() {
  if need whisper-cli; then
    echo "whisper-cli already installed: $(command -v whisper-cli)"
    return 0
  fi

  if apt-cache show whisper.cpp >/dev/null 2>&1; then
    echo "Installing Debian package: whisper.cpp"
    if sudo apt-get install -y whisper.cpp; then
      return 0
    fi
    echo "Debian package install failed; falling back to source build."
  else
    echo "Debian package whisper.cpp not available; falling back to source build."
  fi

  install_whisper_from_source
}

install_whisper_from_source() {
  local src_dir="${HOME}/.local/opt/whisper.cpp"
  local bin_path="${src_dir}/build/bin/whisper-cli"

  if [[ -x "$bin_path" ]]; then
    echo "Source-built whisper-cli already present: $bin_path"
    return 0
  fi

  mkdir -p "${HOME}/.local/opt"
  if [[ -d "$src_dir/.git" ]]; then
    echo "Updating whisper.cpp source in $src_dir"
    git -C "$src_dir" pull --ff-only
  elif [[ -e "$src_dir" ]]; then
    echo "$src_dir exists but is not a git checkout; remove it or set DICTATION_WHISPER_BIN." >&2
    return 1
  else
    echo "Cloning whisper.cpp source into $src_dir"
    git clone --depth 1 https://github.com/ggerganov/whisper.cpp.git "$src_dir"
  fi

  echo "Building whisper-cli from source"
  cmake -S "$src_dir" -B "$src_dir/build" -DCMAKE_BUILD_TYPE=Release -DWHISPER_SDL2=OFF
  cmake --build "$src_dir/build" --config Release --target whisper-cli -j"$(nproc)"

  if [[ ! -x "$bin_path" ]]; then
    echo "Build finished, but whisper-cli was not found at $bin_path." >&2
    return 1
  fi

  echo "Built whisper-cli: $bin_path"
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
