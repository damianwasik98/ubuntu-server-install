#!/bin/bash

set -e
set -u
set -o pipefail

echo "Starting the creation of Ubuntu bootable USB drive"

echo "Do you want to generate fresh user-data.yaml file? (y/n)"
read -r generate_data

if [[ "$generate_data" =~ ^[Yy]$ ]]; then
  echo "Generating user data..."
  ./bin/generate-user-data.sh
  echo "User data generation complete."
fi

echo "Do you want to download new Ubuntu image? (y/n)"
read -r download_iso

if [[ "$download_iso" =~ ^[Yy]$ ]]; then
  echo "Downloading Ubuntu ISO..."
  ./bin/download-ubuntu-iso.sh
  echo "Ubuntu ISO downloaded successfully."
fi

echo "Writing ISO to USB..."
./bin/write-iso-to-usb.sh
echo "ISO has been written to USB successfully."

echo "Script completed successfully!"
