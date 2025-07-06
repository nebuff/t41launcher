#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main"
INSTALL_DIR="$HOME/t41launcher"

# List of core files to update
FILES_ALL=("launcher.sh" "config.sh" "menu.json" "status_options.json")
FILES_CONFIG=("config.sh" "menu.json" "status_options.json")
FILES_LAUNCHER=("launcher.sh")

choice=$(dialog --backtitle "T41 Updater" --title "Update Options" \
  --menu "Select what to update:" 15 50 4 \
  1 "Launcher Only" \
  2 "Config Only" \
  3 "All Files" \
  4 "Cancel" \
  3>&1 1>&2 2>&3)

[ $? -ne 0 ] && exit 0

case $choice in
  1)
    files=("${FILES_LAUNCHER[@]}")
    ;;
  2)
    files=("${FILES_CONFIG[@]}")
    ;;
  3)
    files=("${FILES_ALL[@]}")
    ;;
  4)
    exit 0
    ;;
esac

echo "Updating files..."
for file in "${files[@]}"; do
  curl -fsSL "$REPO_URL/$file" -o "$INSTALL_DIR/$file"
  chmod +x "$INSTALL_DIR/$file"
done

dialog --msgbox "Update completed successfully!" 7 40
