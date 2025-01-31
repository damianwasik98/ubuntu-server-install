#!/bin/bash
set -euo pipefail

# This script downloads Ubuntu Server ISO image from Ubuntu releases page into ubuntu-images directory.

echo -e "Select architecture:\n1. amd64 (default)\n2. arm64"
read -p "Choice (Enter for amd64): " ARCH_CHOICE
UBUNTU_ARCH=$([[ "$ARCH_CHOICE" == "2" ]] && echo "arm64" || echo "amd64")

UBUNTU_VERSION=$(curl -s http://changelogs.ubuntu.com/meta-release-lts | grep "Version:" | tail -1 | cut -d' ' -f2)

read -p "Enter Ubuntu Server version (default: $UBUNTU_VERSION): " CUSTOM_VERSION
[[ -n "$CUSTOM_VERSION" ]] && UBUNTU_VERSION="$CUSTOM_VERSION"

if [[ -z "$UBUNTU_VERSION" ]]; then
  echo "Failed to fetch the latest Ubuntu Server version."
  exit 1
fi

echo "Selected Ubuntu Server $UBUNTU_VERSION for $UBUNTU_ARCH"

ISO_NAME="ubuntu-${UBUNTU_VERSION}-live-server-${UBUNTU_ARCH}.iso"
ISO_URL="https://releases.ubuntu.com/${UBUNTU_VERSION}/${ISO_NAME}"
UBUNTU_IMAGES_DIR="./ubuntu-images"

echo "Downloading Ubuntu ISO..."
wget -P "$UBUNTU_IMAGES_DIR" -c "$ISO_URL" || {
  echo "Failed to download Ubuntu ISO"
  exit 1
}

echo "ISO downloaded successfully: $ISO_NAME"
