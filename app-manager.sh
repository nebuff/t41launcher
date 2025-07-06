#!/bin/bash

MENU_JSON="$HOME/t41launcher/menu.json"
APPS_DIR="$HOME/t41launcher/apps"
REPO_BASE="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main/apps"
mkdir -p "$APPS_DIR"

add_app() {
  # Get app list from GitHub directory
  app_list=$(curl -s https://github.com/nebuff/t41launcher/tree/main/apps | grep -oP '>([^<]+?\.sh)<' | sed 's/[><]//g')
  mapfile -t apps <<< "$app_list"

  if [ ${#apps[@]} -eq 0 ]; then
    dialog --msgbox "No apps available." 6 40
    return
  fi

  menu_items=()
  for app in "${apps[@]}"; do
    appname=$(basename "$app")
    menu_items+=("$appname" "Install $appname")
  done

  selected_app=$(dialog --menu "Available Apps:" 20 60 15 "${menu_items[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  # Download the selected app
  curl -fsSL "$REPO_BASE/$selected_app" -o "$APPS_DIR/$selected_app"
  chmod +x "$APPS_DIR/$selected_app"

  # Check if app already in menu.json
  if jq -e ".[] | select(.name == \"$selected_app\")" "$MENU_JSON" > /dev/null; then
    dialog --msgbox "App already exists in menu.json." 6 40
    return
  fi

  # Append to menu.json
  jq ". + [{
    \"name\": \"$selected_app\",
    \"description\": \"$selected_app\",
    \"command\": \"./apps/$selected_app\",
    \"prompt_args\": false,
    \"pause_after\": true,
    \"sudo\": false,
    \"confirm\": false
  }]" "$MENU_JSON" > /tmp/menu_tmp.json && mv /tmp/menu_tmp.json "$MENU_JSON"

  dialog --msgbox "$selected_app installed and added to menu.json." 6 50
}

list_apps() {
  mapfile -t apps < <(ls "$APPS_DIR")
  dialog --msgbox "Installed Apps:\n\n${apps[*]}" 20 50
}

delete_app() {
  mapfile -t apps < <(ls "$APPS_DIR")
  [ ${#apps[@]} -eq 0 ] && dialog --msgbox "No apps installed." 6 40 && return

  menu_items=()
  for app in "${apps[@]}"; do
    menu_items+=("$app" "Remove $app")
  done

  selected=$(dialog --menu "Remove which app?" 20 60 15 "${menu_items[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  rm -f "$APPS_DIR/$selected"
  # Remove from menu.json
  jq "map(select(.name != \"$selected\"))" "$MENU_JSON" > /tmp/menu_tmp.json && mv /tmp/menu_tmp.json "$MENU_JSON"
  dialog --msgbox "$selected removed from system and menu." 6 40
}

while true; do
  choice=$(dialog --backtitle "T41 Launcher App Manager" --title "App Manager" \
    --menu "Select an option:" 15 50 6 \
    1 "Add App from GitHub" \
    2 "List Installed Apps" \
    3 "Delete App" \
    4 "Exit" \
    3>&1 1>&2 2>&3)

  case $choice in
    1) add_app ;;
    2) list_apps ;;
    3) delete_app ;;
    *) break ;;
  esac
done

clear
