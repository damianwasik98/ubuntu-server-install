#!/bin/bash
set -euo pipefail

# This script creates bootable USB drive with given Ubuntu ISO image

OS="$(uname -s)"
IS_MACOS=false && [[ "$OS" == "Darwin" ]] && IS_MACOS=true

list_devices() {
  if $IS_MACOS; then
    diskutil list external physical | grep -E "^/dev/"
  else
    lsblk -d -o NAME,SIZE,MODEL | grep "sd"
  fi
}

prepare_device() {
  local device="$1"
  if [ "$IS_MACOS" == true ]; then
    diskutil unmountDisk "$device"
  fi
}

write_iso_to_usb() {
  local iso="$1"
  local device="$2"

  if $IS_MACOS; then
    dd if="$iso" of="/dev/r${device#/dev/}" bs=1m
  else
    dd if="$iso" of="$device" bs=4M status=progress
  fi
}

devices=$(list_devices)

USB_DEVICE=$(echo "$devices" | fzf --prompt="Select USB device: " | awk '{print $1}')
if [[ -z "$USB_DEVICE" ]]; then
  echo "No device selected. Exiting."
  exit 1
fi

ISO_FILE=$(find ./ubuntu-images -maxdepth 1 -type f -name "*.iso" | fzf --prompt="Select ISO file: ")
if [[ -z "$ISO_FILE" ]]; then
  echo "No ISO file selected. Exiting."
  exit 1
fi

USER_CONFIG="user-data.yaml"
if [[ ! -f "$USER_CONFIG" ]]; then
  echo "Warning: No $USER_CONFIG found. Continuing without cloud-init config."
fi

echo
printf "Are you sure you want to create a bootable USB on device:\n%s\nand write:\n%s?\n(y/n) " "$USB_DEVICE" "$ISO_FILE"
read CONFIRMATION
if [[ "$CONFIRMATION" != "y" ]]; then
  echo "Operation canceled."
  exit 1
fi

echo "Preparing USB device..."
prepare_device "$USB_DEVICE"

echo "Writing ISO to USB..."
write_iso_to_usb "$ISO_FILE" "$USB_DEVICE"

echo "Bootable USB created successfully!"
