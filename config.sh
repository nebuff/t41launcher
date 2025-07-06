#!/bin/bash

STATUS_OPTIONS_FILE="status_options.json"

# Load or initialize options (1=Battery, 2=Network, 3=Time)
if [ ! -f "$STATUS_OPTIONS_FILE" ]; then
  echo "[1,2,3]" > "$STATUS_OPTIONS_FILE"
fi

# Helper to show current settings nicely
function show_status_options() {
  opts=$(cat "$STATUS_OPTIONS_FILE" 2>/dev/null)
  echo "Current status bar options:"
  [ "$(echo $opts | grep 1)" ] && echo " - Battery: ON" || echo " - Battery: OFF"
  [ "$(echo $opts | grep 2)" ] && echo " - Network: ON" || echo " - Network: OFF"
  [ "$(echo $opts | grep 3)" ] && echo " - Time: ON" || echo " - Time: OFF"
}

while true; do
  CHOICE=$(dialog --clear --backtitle "T41 Settings" --title "Status Bar Options" \
    --checklist "Toggle features ON/OFF:" 15 50 5 \
    1 "Battery" $(grep -q 1 "$STATUS_OPTIONS_FILE" && echo "on" || echo "off") \
    2 "Network" $(grep -q 2 "$STATUS_OPTIONS_FILE" && echo "on" || echo "off") \
    3 "Time" $(grep -q 3 "$STATUS_OPTIONS_FILE" && echo "on" || echo "off") \
    3>&1 1>&2 2>&3)

  RET=$?
  [ $RET -ne 0 ] && break

  # Save choices as JSON array
  if [ -z "$CHOICE" ]; then
    echo "[]" > "$STATUS_OPTIONS_FILE"
  else
    # Clean up quotes, split into array
    CHOICE_ARRAY=($CHOICE)
    JSON_ARRAY="["
    for val in "${CHOICE_ARRAY[@]}"; do
      JSON_ARRAY+="$val,"
    done
    JSON_ARRAY="${JSON_ARRAY%,}]"
    echo "$JSON_ARRAY" > "$STATUS_OPTIONS_FILE"
  fi

  dialog --msgbox "Settings saved." 6 30
done

clear
