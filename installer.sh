#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main"
INSTALL_DIR="$HOME/t41launcher"
BIN_LINK="/usr/local/bin/t41launcher"

# Create the installation directory
mkdir -p "$INSTALL_DIR"

# List of files to fetch from the repo
FILES=(
  "launcher.sh"
  "menu.json"
  "status_options.json"
  "config.sh"
)

# Download each file
echo "Downloading files..."
for FILE in "${FILES[@]}"; do
  curl -fsSL "$REPO_URL/$FILE" -o "$INSTALL_DIR/$FILE"
  chmod +x "$INSTALL_DIR/$FILE"
done

# Create symlink
echo "Creating launcher symlink at $BIN_LINK"
sudo ln -sf "$INSTALL_DIR/launcher.sh" "$BIN_LINK"

echo "Done! You can now launch the T41 Launcher by running:"
echo "  t41launcher"
