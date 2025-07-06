#!/bin/bash

MENU_JSON="menu.json"
STATUS_OPTIONS_FILE="status_options.json"

print_status_bar() {
  BAR=""
  OPTIONS=$(cat "$STATUS_OPTIONS_FILE" 2>/dev/null)

  if echo "$OPTIONS" | grep -q 1; then
    BATT_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    BATT_ICON="🔋"
    BAR+="$BATT_ICON${BATT_LEVEL:-??}%  "
  fi

  if echo "$OPTIONS" | grep -q 2; then
    IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    TYPE_ICON="🌐"
    BAR+="$TYPE_ICON${IFACE:-Offline}  "
  fi

  if echo "$OPTIONS" | grep -q 3; then
    TIME_NOW=$(date +%H:%M)
    BAR+="🕒 $TIME_NOW"
  fi

  echo "$BAR"
}

while true; do
  TITLE="$(print_status_bar)"

  ITEMS=()
  while IFS= read -r app; do
    name=$(echo "$app" | jq -r '.name')
    desc=$(echo "$app" | jq -r '.description // .command')
    ITEMS+=("$name" "$desc")
  done < <(jq -c '.[]' "$MENU_JSON" 2>/dev/null)

  SELECTED=$(dialog --backtitle "T41 Launcher" --title "$TITLE" \
    --menu "Select an app:" 20 50 10 "${ITEMS[@]}" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && break

  APP=$(jq -c ".[] | select(.name == \"$SELECTED\")" "$MENU_JSON")
  CMD=$(echo "$APP" | jq -r '.command')
  PROMPT_ARGS=$(echo "$APP" | jq -r '.prompt_args // false')
  PAUSE_AFTER=$(echo "$APP" | jq -r '.pause_after // false')
  REQUIRE_SUDO=$(echo "$APP" | jq -r '.sudo // false')
  CONFIRM_FIRST=$(echo "$APP" | jq -r '.confirm // false')

  if [ "$PROMPT_ARGS" = "true" ]; then
    USER_ARGS=$(dialog --inputbox "Enter arguments for $SELECTED:" 8 50 "" 3>&1 1>&2 2>&3)
    CMD+=" $USER_ARGS"
  fi

  if [ "$CONFIRM_FIRST" = "true" ]; then
    dialog --yesno "Are you sure you want to run '$SELECTED'?" 7 50
    [ $? -ne 0 ] && continue
  fi

  if [ "$REQUIRE_SUDO" = "true" ]; then
    CMD="sudo $CMD"
  fi

  if [ -n "$CMD" ]; then
    clear
    bash -c "$CMD"
    if [ "$PAUSE_AFTER" = "true" ]; then
      read -p "Press ENTER to return to launcher..."
    fi
  fi

done
