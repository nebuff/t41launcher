#!/bin/bash

MOUNT_BASE="$HOME/mnt"
mkdir -p "$MOUNT_BASE"

while true; do
  drives=()
  mapfile -t drives < <(lsblk -lnpo NAME,SIZE,TYPE,MOUNTPOINT | grep 'part' | awk '{print $1}')

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

  while true; do
    mpath=$(lsblk -ndo MOUNTPOINT "$choice")
    size=$(lsblk -ndo SIZE "$choice")

    options=(1 "Mount / Unmount")
    if [ -n "$mpath" ]; then
      options+=(2 "Browse")
    fi
    options+=(3 "Format Drive" 4 "Other Options" 5 "Back")

    action=$(dialog --backtitle "T41 Drive Manager" --title "Drive: $choice ($size)" \
      --menu "Status: ${mpath:-Unmounted}\nSelect action:" 18 60 10 "${options[@]}" 3>&1 1>&2 2>&3)

    case $action in
      1)
        if [ -z "$mpath" ]; then
          default_mp="$MOUNT_BASE/$(basename $choice)"
          mount_point=$(dialog --inputbox "Enter mount point directory:" 8 60 "$default_mp" 3>&1 1>&2 2>&3)
          [ -z "$mount_point" ] && continue
          mkdir -p "$mount_point"
          sudo mount "$choice" "$mount_point" 2>/tmp/mount_error
          if [ $? -eq 0 ]; then
            dialog --msgbox "Mounted $choice at $mount_point" 6 50
            break
          else
            err=$(cat /tmp/mount_error)
            dialog --msgbox "Failed to mount:\n$err" 8 60
          fi
        else
          sudo umount "$choice" 2>/tmp/umount_error
          if [ $? -eq 0 ]; then
            dialog --msgbox "Unmounted $choice" 6 40
            break
          else
            err=$(cat /tmp/umount_error)
            dialog --msgbox "Failed to unmount:\n$err" 8 60
          fi
        fi
        ;;
      2)
        [ -z "$mpath" ] && continue
        while true; do
          entries=()
          mapfile -t files < <(ls -A "$mpath")
          [ ${#files[@]} -eq 0 ] && dialog --msgbox "Directory is empty." 6 40 && break
          for i in "${!files[@]}"; do
            f="${files[$i]}"
            if [ -d "$mpath/$f" ]; then
              entries+=("$i" "[DIR] $f")
            else
              entries+=("$i" "$f")
            fi
          done
          sel=$(dialog --menu "Browsing: $mpath\nSelect:" 20 70 15 "${entries[@]}" 3>&1 1>&2 2>&3)
          [ $? -ne 0 ] && break
          selfile="${files[$sel]}"
          fullpath="$mpath/$selfile"
          if [ -d "$fullpath" ]; then
            mpath="$fullpath"
          else
            dialog --textbox "$fullpath" 20 70
          fi
        done
        ;;
      3)
        confirm=$(dialog --yesno "Are you sure you want to format $choice?\nAll data will be lost!" 8 60)
        if [ $? -eq 0 ]; then
          fstype=$(dialog --inputbox "Enter filesystem type (e.g. ext4, vfat):" 8 40 "ext4" 3>&1 1>&2 2>&3)
          [ -z "$fstype" ] && continue
          sudo mkfs."$fstype" "$choice" 2>/tmp/format_err
          if [ $? -eq 0 ]; then
            dialog --msgbox "$choice formatted as $fstype." 6 50
          else
            err=$(cat /tmp/format_err)
            dialog --msgbox "Format failed:\n$err" 8 60
          fi
        fi
        ;;
      4)
        info=$(lsblk -f "$choice"; echo ""; sudo blkid "$choice")
        echo "$info" > /tmp/drive_info.txt
        dialog --textbox /tmp/drive_info.txt 20 60
        ;;
      5) break ;;
      *) break ;;
    esac
  done
done

clear
