#!/bin/bash

# Directory to use for mounting drives (make sure user can access)
MOUNT_BASE="$HOME/mnt"
mkdir -p "$MOUNT_BASE"

while true; do
  # Get all block devices with partitions
  drives=()
  # List partitions (exclude loop, ram, and removable by default)
  mapfile -t drives < <(lsblk -lnpo NAME,SIZE,TYPE,MOUNTPOINT | grep 'part' | awk '{print $1}')

  # Prepare dialog menu items
  menu_items=()
  for dev in "${drives[@]}"; do
    size=$(lsblk -ndo SIZE "$dev")
    mp=$(lsblk -ndo MOUNTPOINT "$dev")
    label="$dev ($size)"
    if [ -n "$mp" ]; then
      label+=" [Mounted at $mp]"
    else
      label+=" [Unmounted]"
    fi
    menu_items+=("$dev" "$label")
  done

  choice=$(dialog --clear --backtitle "T41 Drive Manager" --title "Manage Drives" \
    --menu "Select drive/partition:" 20 70 12 \
    "${menu_items[@]}" \
    3>&1 1>&2 2>&3)

  ret=$?
  [ $ret -ne 0 ] && break

  # Submenu for actions on selected drive
  while true; do
    mpath=$(lsblk -ndo MOUNTPOINT "$choice")
    size=$(lsblk -ndo SIZE "$choice")

    if [ -z "$mpath" ]; then
      m_status="Unmounted"
      options=(1 "Mount drive" 2 "Back")
    else
      m_status="Mounted at $mpath"
      options=(1 "Unmount drive" 2 "Browse drive" 3 "Back")
    fi

    action=$(dialog --backtitle "T41 Drive Manager" --title "Drive: $choice ($size)" \
      --menu "Status: $m_status\nSelect action:" 15 50 4 "${options[@]}" 3>&1 1>&2 2>&3)

    case $action in
      1)
        if [ -z "$mpath" ]; then
          # Mount the drive - ask for mount point
          default_mp="$MOUNT_BASE/$(basename $choice)"
          mount_point=$(dialog --inputbox "Enter mount point directory (will be created if needed):" 8 60 "$default_mp" 3>&1 1>&2 2>&3)
          if [ -n "$mount_point" ]; then
            mkdir -p "$mount_point"
            sudo mount "$choice" "$mount_point" 2>/tmp/mount_error
            if [ $? -eq 0 ]; then
              dialog --msgbox "Mounted $choice at $mount_point" 6 50
              break
            else
              err=$(cat /tmp/mount_error)
              dialog --msgbox "Failed to mount:\n$err" 8 60
            fi
          fi
        else
          # Unmount drive
          sudo umount "$choice" 2>/tmp/umount_error
          if [ $? -eq 0 ]; then
            dialog --msgbox "Unmounted $choice from $mpath" 6 50
            break
          else
            err=$(cat /tmp/umount_error)
            dialog --msgbox "Failed to unmount:\n$err" 8 60
          fi
        fi
        ;;
      2)
        if [ -z "$mpath" ]; then
          break
        else
          # Browse mounted directory
          while true; do
            entries=()
            mapfile -t files < <(ls -A "$mpath")
            [ ${#files[@]} -eq 0 ] && dialog --msgbox "Directory is empty." 6 40 && break

            # Build list with indices to handle dialog selection
            for i in "${!files[@]}"; do
              f="${files[$i]}"
              if [ -d "$mpath/$f" ]; then
                entries+=("$i" "[DIR] $f")
              else
                entries+=("$i" "$f")
              fi
            done

            sel=$(dialog --menu "Browsing: $mpath\nSelect file or directory:" 20 70 15 "${entries[@]}" 3>&1 1>&2 2>&3)
            [ $? -ne 0 ] && break

            selfile="${files[$sel]}"
            fullpath="$mpath/$selfile"

            if [ -d "$fullpath" ]; then
              # Enter directory
              mpath="$fullpath"
            else
              # Show file content (first 100 lines)
              dialog --textbox "$fullpath" 20 70
            fi
          done
        fi
        ;;
      3)
        # Back
        break
        ;;
      *)
        break
        ;;
    esac
  done
done

clear
