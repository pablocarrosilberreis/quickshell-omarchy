#!/usr/bin/env bash
# Install the QuickShell bar on a fresh Omarchy setup.
# Run once after `git clone`; safe to re-run.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/quickshell"
BIN_DIR="$HOME/.local/bin"
AUTOSTART="$HOME/.config/hypr/autostart.lua"
BINDINGS="$HOME/.config/hypr/bindings.lua"
TOGGLE_DIR="$HOME/.local/state/omarchy/toggles"

# ── 1. QuickShell package ─────────────────────────────────────────────────────
if ! command -v qs &>/dev/null; then
  echo "==> Installing quickshell from AUR..."
  if command -v yay &>/dev/null; then
    yay -S --noconfirm quickshell-git
  elif command -v paru &>/dev/null; then
    paru -S --noconfirm quickshell-git
  else
    echo "ERROR: yay or paru required to install quickshell-git" >&2
    exit 1
  fi
fi

# ── 2. Config files ───────────────────────────────────────────────────────────
if [ "$REPO_DIR" != "$CONFIG_DIR" ]; then
  echo "==> Copying QML config to $CONFIG_DIR"
  mkdir -p "$CONFIG_DIR"
  cp -r "$REPO_DIR"/. "$CONFIG_DIR/"
fi

# ── 3. Helper scripts ─────────────────────────────────────────────────────────
echo "==> Installing helper scripts to $BIN_DIR"
mkdir -p "$BIN_DIR"

# Bundled scripts the bar depends on (sysinfo, audio/wifi/bluetooth/weather/kb).
if [ -d "$REPO_DIR/bin" ]; then
  echo "==> Installing bundled scripts from bin/ to $BIN_DIR"
  cp "$REPO_DIR"/bin/* "$BIN_DIR/"
  chmod +x "$BIN_DIR"/omarchy-* 2>/dev/null || true
fi

cat > "$BIN_DIR/omarchy-toggle-quickshell" <<'EOF'
#!/bin/bash
# omarchy:summary=Toggle the QuickShell bar visibility
qs ipc call bar toggle
EOF

cat > "$BIN_DIR/omarchy-restart-quickshell" <<'EOF'
#!/bin/bash
# omarchy:summary=Restart the QuickShell bar (waits for old process to die)
pkill -x qs 2>/dev/null
pkill -x quickshell 2>/dev/null
while pgrep -x qs > /dev/null 2>&1 || pgrep -x quickshell > /dev/null 2>&1; do
  sleep 0.1
done
setsid uwsm-app -- qs >/dev/null 2>&1 &
EOF

chmod +x "$BIN_DIR/omarchy-toggle-quickshell" "$BIN_DIR/omarchy-restart-quickshell"

# ── 4. Suppress Waybar ───────────────────────────────────────────────────────
echo "==> Disabling Waybar via omarchy toggle"
mkdir -p "$TOGGLE_DIR"
touch "$TOGGLE_DIR/waybar-off"

# ── 5. Autostart: add qs if not already present ───────────────────────────────
if [ -f "$AUTOSTART" ]; then
  if ! grep -q 'launch_on_start("qs")' "$AUTOSTART"; then
    echo "==> Adding qs to $AUTOSTART"
    printf '\n-- QuickShell bar (replaces waybar; waybar is suppressed via the waybar-off toggle).\no.launch_on_start("qs")\n' >> "$AUTOSTART"
  else
    echo "==> autostart.lua already has qs, skipping"
  fi
else
  echo "WARNING: $AUTOSTART not found — add 'o.launch_on_start(\"qs\")' manually." >&2
fi

# ── 6. Keybindings ───────────────────────────────────────────────────────────
if [ -f "$BINDINGS" ]; then
  if ! grep -q 'omarchy-toggle-quickshell' "$BINDINGS"; then
    echo "==> Adding QuickShell keybindings to $BINDINGS"
    cat >> "$BINDINGS" <<'LUA'

-- QuickShell bar overrides (replaces waybar).
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle top bar", "omarchy-toggle-quickshell")
-- Drop the waybar position binds (QuickShell bar is top-only).
hl.unbind("SUPER + SHIFT + CTRL + UP")
hl.unbind("SUPER + SHIFT + CTRL + DOWN")
hl.unbind("SUPER + SHIFT + CTRL + LEFT")
hl.unbind("SUPER + SHIFT + CTRL + RIGHT")
LUA
  else
    echo "==> bindings.lua already has quickshell binds, skipping"
  fi
else
  echo "WARNING: $BINDINGS not found — add keybindings manually (see README)." >&2
fi

echo ""
echo "Done. Log out and back in (or restart Hyprland) for the bar to start."
echo "To start immediately without rebooting: uwsm-app -- qs &"
