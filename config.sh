#!/bin/bash

MENU_JSON="menu.json"
STATUS_OPTIONS_FILE="status_options.json"

while true; do
  choice=$(dialog --backtitle "T41 Launcher Settings" --title "Settings" \
    --menu "Choose a category:" 18 50 6 \
    1 "Connectivity" \
    2 "Desktop Settings" \
    3 "Launcher Settings" \
    4 "System Info" \
    5 "About T41" \
    6 "Exit" \
    3>&1 1>&2 2>&3)

  [ $? -ne 0 ] && break

  case $choice in
    1)
      # Connectivity submenu
      conn_choice=$(dialog --backtitle "T41 Settings" --title "Connectivity" \
        --menu "Select:" 18 50 6 \
        1 "List Interfaces" \
        2 "Connect to Internet" \
        3 "Wi-Fi Settings" \
        4 "Bluetooth Settings" \
        5 "Back" \
        3>&1 1>&2 2>&3)

      case $conn_choice in
        1)
          interface_list=""
          while IFS= read -r line; do
            iface=$(echo "$line" | awk -F': ' '{print $2}')
            [ "$iface" = "lo" ] && continue
            ip=$(ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
            status="${ip:-Offline}"
            interface_list+="$iface: $status\n"
          done < <(ip -o link show)
          echo -e "$interface_list" > /tmp/interfaces.txt
          dialog --title "Interfaces" --textbox /tmp/interfaces.txt 20 60
          ;;
        2)
          interfaces=()
          while IFS= read -r line; do
            iface=$(echo "$line" | awk -F': ' '{print $2}')
            [ "$iface" = "lo" ] && continue
            interfaces+=("$iface" "Select to connect")
          done < <(ip -o link show)

          if [ ${#interfaces[@]} -eq 0 ]; then
            dialog --msgbox "No network interfaces found." 8 40
          else
            selected_iface=$(dialog --title "Connect to Internet" --menu "Choose interface:" 15 50 6 "${interfaces[@]}" 3>&1 1>&2 2>&3)
            if [ -n "$selected_iface" ]; then
              sudo dhclient -v "$selected_iface" > /tmp/connect_output 2>&1
              if ip a show "$selected_iface" | grep -q "inet "; then
                dialog --msgbox "Connected to internet via $selected_iface!" 8 40
              else
                dialog --textbox /tmp/connect_output 20 60
              fi
            fi
          fi
          ;;
        3)
          dialog --msgbox "This would manage /etc/wpa_supplicant/wpa_supplicant.conf." 10 50
          ;;
        4)
          if command -v bluetoothctl >/dev/null; then
            echo "Bluetooth devices:\n\n$(bluetoothctl devices)" > /tmp/bt.txt
            dialog --title "Bluetooth Devices" --textbox /tmp/bt.txt 20 60
          else
            dialog --msgbox "Bluetooth not supported or bluetoothctl not installed." 10 50
          fi
          ;;
      esac
      ;;
    2)
      # Desktop settings submenu
      desk_choice=$(dialog --backtitle "T41 Settings" --title "Desktop Settings" \
        --menu "Select setting:" 15 50 5 \
        1 "Set Keyboard Layout" \
        2 "Set Timezone" \
        3 "Enable/Disable SSH" \
        4 "Back" \
        3>&1 1>&2 2>&3)

      case $desk_choice in
        1)
          layout=$(dialog --inputbox "Enter layout (e.g. us, uk, de):" 8 40 "us" 3>&1 1>&2 2>&3)
          if [ -n "$layout" ]; then
            sudo localectl set-keymap "$layout"
            dialog --msgbox "Keyboard layout set to $layout" 7 40
          fi
          ;;
        2)
          tz=$(dialog --inputbox "Enter timezone (e.g. America/New_York):" 8 40 "UTC" 3>&1 1>&2 2>&3)
          if [ -n "$tz" ]; then
            sudo timedatectl set-timezone "$tz"
            dialog --msgbox "Timezone set to $tz" 7 40
          fi
          ;;
        3)
          ssh_choice=$(dialog --menu "SSH Service:" 10 40 2 \
            1 "Enable SSH" \
            2 "Disable SSH" \
            3>&1 1>&2 2>&3)
          if [ "$ssh_choice" = "1" ]; then
            sudo systemctl enable ssh && sudo systemctl start ssh
            dialog --msgbox "SSH enabled and started." 6 40
          elif [ "$ssh_choice" = "2" ]; then
            sudo systemctl disable ssh && sudo systemctl stop ssh
            dialog --msgbox "SSH disabled and stopped." 6 40
          fi
          ;;
      esac
      ;;
    3)
      launcher_choice=$(dialog --backtitle "T41 Settings" --title "Launcher Settings" \
        --menu "Select option:" 15 50 4 \
        1 "Edit Applications (menu.json)" \
        2 "Toggle Status Bar Elements" \
        3 "Back" \
        3>&1 1>&2 2>&3)

      case $launcher_choice in
        1)
          sudo nano "$MENU_JSON"
          ;;
        2)
          dialog --checklist "Toggle status bar items:" 15 60 6 \
            1 "Battery" on \
            2 "Network" on \
            3 "Time" on \
            2> /tmp/status_opts
          cp /tmp/status_opts "$STATUS_OPTIONS_FILE"
          dialog --msgbox "Status bar options saved." 6 40
          ;;
      esac
      ;;
    4)
      info=$(uname -a; echo ""; lsb_release -a 2>/dev/null; echo ""; free -h; echo ""; df -h /)
      echo "$info" > /tmp/t41info.txt
      dialog --textbox /tmp/t41info.txt 20 70
      ;;
    5)
      dialog --msgbox "T41 Launcher\n\nA text-based OS UI for old and low-resource devices.\nBuilt by fRitz 🔧" 10 50
      ;;
    6) break ;;
  esac
done
