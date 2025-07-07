#!/bin/bash

INSTALL_DIR="$HOME/t41launcher"
REPO_BASE="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main"
FILES=(
  "launcher.sh"
  "config.sh"
  "menu.json"
  "status_options.json"
  "apps/drivemanager.sh"
  "apps/updater.sh"
  "apps/app-manager.sh"
)

echo "Installing T41 Launcher to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR/apps"

for file in "${FILES[@]}"; do
  echo "Downloading $file..."
  curl -fsSL "$REPO_BASE/$file" -o "$INSTALL_DIR/$file"
done

echo "Setting scripts as executable..."
chmod +x "$INSTALL_DIR"/*.sh
chmod +x "$INSTALL_DIR"/apps/*.sh

echo "Creating alias..."
SHELL_RC=""
if [[ $SHELL == */bash ]]; then
  SHELL_RC="$HOME/.bashrc"
elif [[ $SHELL == */zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ $SHELL == */fish ]]; then
  SHELL_RC="$HOME/.config/fish/config.fish"
  echo "alias t41='bash $INSTALL_DIR/launcher.sh'" >> "$SHELL_RC"
  echo "T41 Launcher installed. Type 't41' to launch!"
  exit 0
fi

if [ -n "$SHELL_RC" ]; then
  echo "alias t41='bash $INSTALL_DIR/launcher.sh'" >> "$SHELL_RC"
  echo "T41 Launcher installed. Type 't41' to launch!"
else
  echo "Could not detect shell to create alias. Add manually: alias t41='bash $INSTALL_DIR/launcher.sh'"
fi
