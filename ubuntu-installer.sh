#/!/bin/bash

echo "Architecture (default: amd64):"
echo "1. amd64"
echo "2. arm64"
read -p "Choose by typing number (press enter for amd64): " ARCH_CHOICE

case $ARCH_CHOICE in
    2)
        UBUNTU_ARCH="arm64"
        ;;
    *)
        UBUNTU_ARCH="amd64"
        ;;
esac


read -p "Hostname: " HOSTNAME
read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo
read -s -p "Confirm password: " PASSWORD_CONFIRM
echo

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo "Given passwords are not the same"
    exit 1
fi

# latest lts version of ubuntu
UBUNTU_VERSION=$(curl -s http://changelogs.ubuntu.com/meta-release-lts | grep "Version:" | tail -1 | cut -d' ' -f2)
ISO_NAME="ubuntu-${UBUNTU_VERSION}-live-server-${UBUNTU_ARCH}.iso"
ISO_URL="https://releases.ubuntu.com/${UBUNTU_VERSION}/${ISO_NAME}"
if ! wget -c "$ISO_URL"; then
    echo "Downloading ubuntu image failed"
    exit 1
fi

cat > "user-data" << EOF
#cloud-config
hostname: $HOSTNAME
users:
  - name: $USERNAME
    lock_passwd: false
    passwd: $(openssl passwd -6 $PASSWORD)
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
EOF
