#!/bin/bash

MENU_JSON="$HOME/t41launcher/menu.json"
APPS_DIR="$HOME/t41launcher/apps"
REPO_JSON="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main/apps/apps.json"
mkdir -p "$APPS_DIR"

add_app() {
  app_data=$(curl -fsSL "$REPO_JSON")
  if [ -z "$app_data" ]; then
    dialog --msgbox "Failed to retrieve app list." 6 40
    return
  fi

  mapfile -t app_names < <(echo "$app_data" | jq -r '.[].name')
  mapfile -t descriptions < <(echo "$app_data" | jq -r '.[].description')

  menu_items=()
  for i in "${!app_names[@]}"; do
    menu_items+=("${app_names[$i]}" "${descriptions[$i]}")
  done

  selected_app=$(dialog --menu "Available Apps:" 20 60 15 "${menu_items[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  app_entry=$(echo "$app_data" | jq -c ".[] | select(.name == \"$selected_app\")")
  app_url=$(echo "$app_entry" | jq -r '.file')
  script_name=$(basename "$app_url")
  local_path="$APPS_DIR/$script_name"

  curl -fsSL "$app_url" -o "$local_path"
  chmod +x "$local_path"

  # Construct new menu entry
  new_entry=$(echo "$app_entry" | jq --arg cmd "bash $local_path" 'del(.file) | .command = $cmd')

  # Check if the app already exists in menu.json
  if jq -e ".[] | select(.name == \"$selected_app\")" "$MENU_JSON" > /dev/null; then
    dialog --msgbox "App already exists in menu.json." 6 40
    return
  fi

  tmp_file=$(mktemp)
  jq ". + [\$new_entry]" "$MENU_JSON" --argjson new_entry "$new_entry" > "$tmp_file" && mv "$tmp_file" "$MENU_JSON"

  dialog --msgbox "$selected_app installed and added to launcher." 6 50
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
