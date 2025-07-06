#!/bin/bash

MENU_JSON="menu.json"
APPS_DIR="$HOME/t41launcher/apps"
GITHUB_API_URL="https://api.github.com/repos/nebuff/t41launcher/contents/apps"
GITHUB_RAW_BASE="https://raw.githubusercontent.com/nebuff/t41launcher/refs/heads/main/apps"

mkdir -p "$APPS_DIR"

# Load current menu apps into an array for quick lookup
load_installed_apps() {
  INSTALLED_APPS=()
  while IFS= read -r app; do
    INSTALLED_APPS+=("$app")
  done < <(jq -r '.[].name' "$MENU_JSON" 2>/dev/null || echo "")
}

# Save updated apps list to menu.json
save_menu_json() {
  local apps=("$@")
  jq -n --argjson arr "$(printf '%s\n' "${apps[@]}" | jq -R . | jq -s .)" \
    '[$arr[] | {name: ., description: ., command: ("./apps/" + .), prompt_args: false, pause_after: true, sudo: false, confirm: false}]' > "$MENU_JSON"
}

# Add app to menu.json and apps directory
add_app() {
  # Get available apps from GitHub API
  local json apps_list=()
  json=$(curl -fsSL "$GITHUB_API_URL") || { dialog --msgbox "Failed to fetch app list." 6 40; return; }
  while IFS= read -r appname; do
    # Skip if already installed
    if [[ " ${INSTALLED_APPS[*]} " == *" $appname "* ]]; then continue; fi
    apps_list+=("$appname" "$appname")
  done < <(echo "$json" | jq -r '.[] | select(.name | endswith(".sh")) | .name')

  if [ ${#apps_list[@]} -eq 0 ]; then
    dialog --msgbox "No new apps available to add." 6 40
    return
  fi

  local selected_app=$(dialog --menu "Select an app to add:" 20 50 10 "${apps_list[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  # Download selected app
  curl -fsSL "$GITHUB_RAW_BASE/$selected_app" -o "$APPS_DIR/$selected_app" || {
    dialog --msgbox "Failed to download $selected_app" 6 40
    return
  }
  chmod +x "$APPS_DIR/$selected_app"

  # Update menu.json
  INSTALLED_APPS+=("$selected_app")
  save_menu_json "${INSTALLED_APPS[@]}"

  dialog --msgbox "$selected_app added and menu.json updated." 6 50
}

# List installed apps
list_apps() {
  local list=()
  for app in "${INSTALLED_APPS[@]}"; do
    list+=("$app" "$app")
  done

  if [ ${#list[@]} -eq 0 ]; then
    dialog --msgbox "No apps installed." 6 40
    return
  fi

  dialog --menu "Installed apps:" 20 50 10 "${list[@]}" 20 50 10
}

# Delete app
delete_app() {
  local list=()
  for app in "${INSTALLED_APPS[@]}"; do
    list+=("$app" "$app")
  done

  if [ ${#list[@]} -eq 0 ]; then
    dialog --msgbox "No apps installed to delete." 6 40
    return
  fi

  local selected_app=$(dialog --menu "Select app to delete:" 20 50 10 "${list[@]}" 3>&1 1>&2 2>&3)
  [ $? -ne 0 ] && return

  dialog --yesno "Are you sure you want to delete $selected_app?" 7 50
  [ $? -ne 0 ] && return

  rm -f "$APPS_DIR/$selected_app"

  # Remove from installed apps array
  local new_apps=()
  for a in "${INSTALLED_APPS[@]}"; do
    if [ "$a" != "$selected_app" ]; then
      new_apps+=("$a")
    fi
  done
  INSTALLED_APPS=("${new_apps[@]}")

  # Update menu.json
  save_menu_json "${INSTALLED_APPS[@]}"

  dialog --msgbox "$selected_app deleted and menu.json updated." 6 50
}

# Main loop
while true; do
  load_installed_apps

  choice=$(dialog --menu "T41 App Manager" 15 50 4 \
    1 "Add App" \
    2 "List Installed Apps" \
    3 "Delete App" \
    4 "Exit" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && break

  case $choice in
    1) add_app ;;
    2) list_apps ;;
    3) delete_app ;;
    4) break ;;
  esac
done

clear
