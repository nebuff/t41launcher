#!/bin/bash

# Base install directory
INSTALL_DIR="$HOME/t41launcher"
mkdir -p "$INSTALL_DIR"

# List of files to download
FILES=(
  "launcher.sh"
  "menu.json"
  "config.sh"
  "status_options.json"
  "app-manager.sh"
  "app-store.sh"
)

echo "Installing T41 Launcher to $INSTALL_DIR..."

for file in "${FILES[@]}"; do
  url="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main/$file"
  echo "Downloading $file..."
  curl -fsSL "$url" -o "$INSTALL_DIR/$file"
  if [ $? -ne 0 ]; then
    echo "Failed to download $file from $url"
    exit 1
  fi
  chmod +x "$INSTALL_DIR/$file"
done

# Create apps folder
mkdir -p "$INSTALL_DIR/apps"

# Add alias to shell configs (only if not already present)
ALIASES=(
  "alias t41='$INSTALL_DIR/launcher.sh'"
  "alias t41config='$INSTALL_DIR/config.sh'"
  "alias t41apps='$INSTALL_DIR/app-manager.sh'"
  "alias t41store='$INSTALL_DIR/app-store.sh'"
)

for shellrc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish"; do
  [ -f "$shellrc" ] || continue
  for alias_cmd in "${ALIASES[@]}"; do
    if ! grep -Fq "$alias_cmd" "$shellrc"; then
      echo "$alias_cmd" >> "$shellrc"
    fi
  done
done

echo "Installation complete! Use 't41' to launch the launcher."
