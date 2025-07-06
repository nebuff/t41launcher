#!/bin/bash

MOUNT_BASE="$HOME/mnt"
mkdir -p "$MOUNT_BASE"

# Get root device and its parent disk
ROOT_PART=$(findmnt / -o SOURCE -n)
ROOT_DISK=$(lsblk -no PKNAME "$ROOT_PART" | sed 's|^|/dev/|')

# Build blocklist
PROTECTED_DEVICES=("$ROOT_PART")
[ -n "$ROOT_DISK" ] && PROTECTED_DEVICES+=("$ROOT_DISK")

is_protected() {
  local dev="$1"
  for protected in "${PROTECTED_DEVICES[@]}"; do
    [ "$dev" = "$protected" ] && return 0
  done
  return 1
}

while true; do
  drives=()
  mapfile -t drives < <(lsblk -lnpo NAME,SIZE,TYPE,MOUNTPOINT | grep 'part' | awk '{print $1}')

  menu_items=()
  for dev in "${drives[@]}"; do
    size=$(lsblk -ndo SIZE "$dev")
    mp=$(lsblk -ndo MOUNTPOINT "$dev")
    label="$dev ($size)"
    if is_protected "$dev"; then
      label+=" [System - Protected]"
    elif [ -n "$mp" ]; then
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

  if is_protected "$choice"; then
    dialog --msgbox "$choice is part of the root system and is protected from all actions." 7 50
    continue
  fi

  while true; do
    mpath=$(lsblk -ndo MOUNTPOINT "$choice")
    size=$(lsblk -ndo SIZE "$choice")
    status="${mpath:-Unmounted}"

    options=(1 "Mount / Unmount")
    [ -n "$mpath" ] && options+=(2 "Browse")
    options+=(3 "Format Drive" 4 "Other Options" 5 "Drive Check (First Aid)" 6 "Back")

    action=$(dialog --backtitle "T41 Drive Manager" --title "Drive: $choice ($size)" \
      --menu "Status: $status\nSelect action:" 20 60 10 "${options[@]}" 3>&1 1>&2 2>&3)

    case $action in
      1)
        if [ -z "$mpath" ]; then
          default_mp="$MOUNT_BASE/$(basename "$choice")"
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
        fstype=$(dialog --menu "Select filesystem type:" 10 40 4 \
          ext4 "Linux ext4" \
          vfat "FAT32 (USB/Windows)" \
          ntfs "Windows NTFS" \
          exfat "exFAT (large USBs)" \
          3>&1 1>&2 2>&3)
        [ -z "$fstype" ] && continue
        dialog --yesno "Are you sure you want to format $choice as $fstype?\nAll data will be lost!" 8 60
        if [ $? -eq 0 ]; then
          sudo mkfs.$fstype "$choice" 2>/tmp/format_err
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
      5)
        if [ -z "$mpath" ]; then
          dialog --msgbox "Drive must be mounted to perform check." 6 50
          continue
        fi
        dialog --infobox "Checking drive $choice for errors..." 5 50
        sudo fsck -n "$choice" > /tmp/fsck_output 2>&1
        if grep -q "clean" /tmp/fsck_output; then
          dialog --msgbox "No errors found on $choice." 6 50
        else
          dialog --textbox /tmp/fsck_output 20 70
          dialog --yesno "Errors detected.\nAttempt repairs?" 7 50
          if [ $? -eq 0 ]; then
            sudo fsck -y "$choice" | tee /tmp/fsck_repair
            dialog --textbox /tmp/fsck_repair 20 70
          fi
        fi
        ;;
      6) break ;;
      *) break ;;
    esac
  done
done

clear
