#!/bin/bash

# SketchyVim (skvim) Service Script
# Security-hardened script to start skvim with allowlist functionality

BINARY_PATH="/opt/homebrew/bin/skvim"
CONFIG_DIR="$HOME/.config/skvim"
LOG_FILE="$HOME/.local/log/skvim.log"

# Create directories if they don't exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Check if allowlist exists
if [ ! -f "$CONFIG_DIR/allowlist" ]; then
    echo "Error: Allowlist not found at $CONFIG_DIR/allowlist"
    echo "Please create the allowlist file with your desired applications."
    echo "Example:"
    echo "  Safari"
    echo "  com.apple.Safari"
    echo "  TextEdit"
    echo "  com.apple.TextEdit"
    exit 1
fi

# Start skvim
echo "Starting skvim (SketchyVim)..."
exec "$BINARY_PATH" 2>&1 | tee "$LOG_FILE"