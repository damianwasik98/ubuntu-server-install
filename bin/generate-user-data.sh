#!/bin/bash
set -euo pipefail

# This script generates user-data.yaml file

read -p "Enter hostname for the new system: " HOSTNAME
read -p "Enter username: " USERNAME

while true; do
  read -s -p "Enter password: " PASSWORD
  echo
  read -s -p "Confirm password: " PASSWORD_CONFIRM
  echo
  [[ "$PASSWORD" == "$PASSWORD_CONFIRM" ]] && break || echo "Passwords do not match, try again."
done

cat >"user-data.yaml" <<EOF
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: $HOSTNAME
    username: $USERNAME
    password: $(openssl passwd -6 "$PASSWORD")
  user-data:
    users:
      - name: $USERNAME
        lock_passwd: false
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
EOF

echo "Cloud-Init configuration created successfully: user-data.yaml"
