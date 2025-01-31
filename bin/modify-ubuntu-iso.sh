#!/bin/bash
set -e
# This script modifies Ubuntu Server ISOs for automated installation
# Compatible with Ubuntu versions 20.04, 22.04, and 24.04

usage() {
  echo "Usage: $0 <input-iso> <user-data-file> <output-iso>"
  echo "Example: $0 ubuntu-22.04-server.iso user-data.yaml ubuntu-22.04-autoinstall.iso"
  exit 1
}

if [ "$#" -ne 3 ]; then
  usage
fi

INPUT_ISO="$1"
USER_DATA="$2"
OUTPUT_ISO="$3"

detect_ubuntu_version() {
  local iso_name="$1"
  if [[ $iso_name =~ ubuntu-([0-9]{2})\.([0-9]{2}) ]]; then
    echo "${BASH_REMATCH[1]}${BASH_REMATCH[2]}" # Returns version as YYMM (e.g., 2004, 2204)
  else
    echo "Error: Unable to detect Ubuntu version from filename"
    exit 1
  fi
}

UBUNTU_VERSION=$(detect_ubuntu_version "$INPUT_ISO")
echo "Detected Ubuntu version: ${UBUNTU_VERSION:0:2}.${UBUNTU_VERSION:2:2}"

MOUNT_DIR=$(mktemp -d)
NEW_ISO_DIR=$(mktemp -d)

cleanup() {
	echo "Cleaning up temporary directories..."
	if mountpoint -q "$MOUNT_DIR"; then
		umount "$MOUNT_DIR"
	fi
	rm -rf "$MOUNT_DIR" "$NEW_ISO_DIR"
}

trap cleanup EXIT

echo "Mounting ISO image..."
mount -o loop "$INPUT_ISO" "$MOUNT_DIR"

echo "Copying ISO contents..."
cp -r "$MOUNT_DIR"/* "$NEW_ISO_DIR/"
cp -r "$MOUNT_DIR"/.disk "$NEW_ISO_DIR/" 2>/dev/null || true

echo "Setting up cloud-init configuration..."
mkdir -p "$NEW_ISO_DIR/nocloud/"

cp "$USER_DATA" "$NEW_ISO_DIR/nocloud/user-data"
touch "$NEW_ISO_DIR/nocloud/meta-data"

echo "Modifying boot configuration..."
if [ "$UBUNTU_VERSION" -ge 2204 ]; then
  # For 22.04 and newer, modify both UEFI and BIOS boot configurations
  echo "Applying 22.04+ boot modifications..."

  # Modify GRUB configuration
  sed -i 's/---/autoinstall ds=nocloud\\\;s=\/cdrom\/nocloud\/ ---/' "$NEW_ISO_DIR/boot/grub/grub.cfg"

  # Modify UEFI configuration
  if [ -f "$NEW_ISO_DIR/boot/grub/grub.cfg" ]; then
    sed -i 's/timeout=30/timeout=1/' "$NEW_ISO_DIR/boot/grub/grub.cfg"
  fi
else
  # For 20.04, use the older autoinstall configuration method
  echo "Applying 20.04 boot modifications..."

  # Modify GRUB configuration for 20.04
  sed -i 's/---/autoinstall ds=nocloud-net\\\;s=\/cdrom\/nocloud\/ ---/' "$NEW_ISO_DIR/boot/grub/grub.cfg"

  # Additional modifications needed for 20.04
  if [ -f "$NEW_ISO_DIR/isolinux/txt.cfg" ]; then
    sed -i 's/^default live/default live-nocloud/' "$NEW_ISO_DIR/isolinux/txt.cfg"
  fi
fi

echo "Creating new ISO..."
# Create the modified ISO with appropriate options based on version
xorriso -as mkisofs -r \
  -V "Ubuntu Server AutoInstall" \
  -o "$OUTPUT_ISO" \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  "$NEW_ISO_DIR"

echo "Modified ISO created successfully at: $OUTPUT_ISO"
