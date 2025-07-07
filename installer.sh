#!/bin/bash

INSTALL_DIR="$HOME/t41launcher"
REPO_BASE="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main"

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

FILES=(
  "launcher.sh"
  "config.sh"
  "menu.json"
  "status_options.json"
  "app-manager.sh"
)

echo "Downloading T41 Launcher files..."

for file in "${FILES[@]}"; do
  echo "Installing $file..."
  curl -fsSL "$REPO_BASE/$file" -o "$file"
  chmod +x "$file"
done

mkdir -p "$INSTALL_DIR/apps"

echo "✅ T41 Launcher installed in $INSTALL_DIR"
echo "Run with: bash $INSTALL_DIR/launcher.sh"
