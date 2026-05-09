# Wayland Whisper Dictation

Global push-to-toggle dictation for Debian GNOME on Wayland.

Press `Super+Shift+D` once to start recording. Press it again to stop, transcribe with `whisper.cpp`, and copy the text to the Wayland clipboard.

## Requirements

- Debian or a Debian-based desktop
- GNOME with `gsettings`
- Wayland clipboard through `wl-clipboard`
- A working microphone through ALSA/PipeWire
- `sudo` for package installation

## Install

```bash
cd ~/GitHub/wayland-whisper-dictation
./install.sh
```

The installer:

- Installs Debian packages with `apt-get`
- Installs `whisper.cpp` from Debian when available
- Falls back to building `whisper.cpp` from source under `~/.local/opt/whisper.cpp`
- Downloads `ggml-base.en.bin`
- Installs `dictate-toggle` to `~/.local/bin`
- Registers the GNOME shortcut `Super+Shift+D`

If packages are already installed, skip `apt-get`:

```bash
./install.sh --no-packages
```

## Use

1. Press `Super+Shift+D`.
2. Speak.
3. Press `Super+Shift+D` again.
4. Paste anywhere with `Ctrl+V`.

The latest transcript is also saved at:

```text
~/.cache/dictation/last.txt
```

Logs are saved at:

```text
~/.cache/dictation/dictation.log
~/.cache/dictation/worker.log
```

## Configuration

Set these environment variables before running the script if you need overrides:

```bash
DICTATION_MODEL=~/.local/share/whisper.cpp/models/ggml-base.en.bin
DICTATION_LANGUAGE=en
DICTATION_BINDING='<Super><Shift>d'
DICTATION_WHISPER_BIN=/usr/bin/whisper-cli
DICTATION_WL_COPY=/usr/bin/wl-copy
```

To install a different shortcut:

```bash
DICTATION_BINDING='<Super><Shift>v' ./install.sh --no-packages
```

To use a different Whisper model:

```bash
DICTATION_MODEL_NAME=ggml-small.en.bin ./install.sh
```

## Uninstall

```bash
./uninstall.sh
```

The uninstaller removes the shortcut and `~/.local/bin/dictate-toggle`. It leaves the downloaded model and logs in place.

## Notes

This is intentionally simple: no daemon, no tray icon, no cloud service, and no automatic paste. It records locally, transcribes locally, and copies locally.

The script filters common Whisper silence hallucinations like `(music)` so quiet clips do not overwrite the clipboard with noise.

If Debian does not package `whisper.cpp` for your release, `install.sh` builds it from source. That fallback needs `git`, `cmake`, and `build-essential`, which the installer includes in its base package set.
