#!/bin/bash

APPS_DIR="$HOME/t41launcher/apps"
MENU_JSON="$HOME/t41launcher/menu.json"
REPO_URL="https://raw.githubusercontent.com/nebuff/t41launcher/main/apps"

mkdir -p "$APPS_DIR"

while true; do
  choice=$(dialog --clear --backtitle "T41 App Manager" --title "Manage Applications" \
    --menu "Select an option:" 15 50 6 \
    1 "Add App from Repo" \
    2 "List Installed Apps" \
    3 "Remove App" \
    4 "Update App" \
    5 "Exit" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && break

  case $choice in
    1)
      app_name=$(dialog --inputbox "Enter app name to add:" 8 40 "" 3>&1 1>&2 2>&3)
      [ -z "$app_name" ] && continue

      # Check if file exists in repo
      if curl --silent --fail "$REPO_URL/$app_name.sh" > /dev/null; then
        curl -s "$REPO_URL/$app_name.sh" -o "$APPS_DIR/$app_name.sh"
        chmod +x "$APPS_DIR/$app_name.sh"

        dialog --msgbox "$app_name installed." 6 40

        # Add to menu.json if not exists
        if ! jq -e ".[] | select(.name == \"$app_name\")" "$MENU_JSON" > /dev/null; then
          jq ". += [{\"name\": \"$app_name\", \"command\": \"$APPS_DIR/$app_name.sh\"}]" "$MENU_JSON" > /tmp/menu.json && mv /tmp/menu.json "$MENU_JSON"
        fi
      else
        dialog --msgbox "App not found in repo." 6 40
      fi
      ;;

    2)
      apps=$(ls "$APPS_DIR" 2>/dev/null)
      echo "$apps" > /tmp/apps.txt
      dialog --textbox /tmp/apps.txt 20 60
      ;;

    3)
      mapfile -t app_files < <(ls "$APPS_DIR" 2>/dev/null | sed 's/\.sh$//')
      [ ${#app_files[@]} -eq 0 ] && dialog --msgbox "No apps installed." 6 40 && continue

      menu_items=()
      for app in "${app_files[@]}"; do
        menu_items+=("$app" "")
      done

      to_remove=$(dialog --menu "Select app to remove:" 20 50 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
      [ -z "$to_remove" ] && continue

      rm -f "$APPS_DIR/$to_remove.sh"
      jq "del(.[] | select(.name == \"$to_remove\"))" "$MENU_JSON" > /tmp/menu.json && mv /tmp/menu.json "$MENU_JSON"
      dialog --msgbox "$to_remove removed." 6 40
      ;;

    4)
      mapfile -t app_files < <(ls "$APPS_DIR" 2>/dev/null | sed 's/\.sh$//')
      [ ${#app_files[@]} -eq 0 ] && dialog --msgbox "No apps to update." 6 40 && continue

      menu_items=()
      for app in "${app_files[@]}"; do
        menu_items+=("$app" "")
      done

      to_update=$(dialog --menu "Select app to update:" 20 50 10 "${menu_items[@]}" 3>&1 1>&2 2>&3)
      [ -z "$to_update" ] && continue

      if curl --silent --fail "$REPO_URL/$to_update.sh" > /dev/null; then
        curl -s "$REPO_URL/$to_update.sh" -o "$APPS_DIR/$to_update.sh"
        chmod +x "$APPS_DIR/$to_update.sh"
        dialog --msgbox "$to_update updated." 6 40
      else
        dialog --msgbox "App not found in repo." 6 40
      fi
      ;;

    5) break ;;
  esac
done

clear
