#!/bin/bash
set -euo pipefail

# --- This script is for NVMe only ---
DISK="/dev/nvme0n1"
read -p "Enter hostname for the machine: " HOSTNAME
read -s -p "Enter password for root user: " ROOT_PASSWORD
echo

# Prompt for timezone
while true; do
  read -p "Enter timezone (e.g., Asia/Jakarta): " TIMEZONE
  if [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    break
  else
    echo "Invalid timezone. Please enter a valid timezone from /usr/share/zoneinfo."
  fi
done

# Prompt for CPU vendor
CPU_VENDOR=""
while true; do
  read -p "Is your CPU Intel or AMD? (intel/amd): " CPU_VENDOR
  CPU_VENDOR=${CPU_VENDOR,,}  # convert to lowercase
  if [[ "$CPU_VENDOR" == "intel" || "$CPU_VENDOR" == "amd" ]]; then
    break
  else
    echo "Please enter 'intel' or 'amd'."
  fi
done

# Show disk size using lsblk
echo "=== Detected disk info ==="
lsblk -d -o NAME,SIZE,MODEL "$DISK"

DISK_SIZE=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
echo "Total disk size: ${DISK_SIZE_GB} GB"

# Prompt for partition sizes
echo "Now enter partition sizes in MiB (e.g., 1024 = 1GiB)"
read -p "Enter EFI partition size (e.g., 1024): " EFI_SIZE
read -p "Enter SWAP partition size (e.g., 4096): " SWAP_SIZE

# Calculate start and end positions
ROOT_START=$((EFI_SIZE + SWAP_SIZE + 1))
echo "Root partition will start at ${ROOT_START}MiB and take the remaining space."

# Confirm
read -p "Proceed to partition $DISK with these values? [y/N]: " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborting."
  exit 1
fi

echo "=== Cleaning up any previous mounts ==="
umount -R /mnt 2>/dev/null || true
if swapon --show=NAME --noheadings | grep -q "^${DISK}p2$"; then
  echo "Disabling swap on ${DISK}p2"
  swapoff "${DISK}p2"
fi

echo "=== Partitioning $DISK ==="
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB "$((EFI_SIZE + 1))MiB" \
  set 1 boot on \
  mkpart primary linux-swap "$((EFI_SIZE + 1))MiB" "$((EFI_SIZE + SWAP_SIZE + 1))MiB" \
  mkpart primary ext4 "$((EFI_SIZE + SWAP_SIZE + 1))MiB" 100%

echo "=== Formatting partitions ==="
mkfs.fat -F 32 "${DISK}p1"
mkswap "${DISK}p2"
mkfs.ext4 "${DISK}p3"

echo "=== Mounting partitions ==="
mount "${DISK}p3" /mnt
mount --mkdir "${DISK}p1" /mnt/boot
swapon "${DISK}p2"

echo "=== Installing base system ==="
# CPU vendor microcode package assignment
if [[ "$CPU_VENDOR" == "intel" ]]; then
  MICROCODE_PKG="intel-ucode"
else
  MICROCODE_PKG="amd-ucode"
fi
pacstrap -K /mnt base linux linux-firmware "$MICROCODE_PKG" networkmanager

echo "=== Generating fstab ==="
genfstab -U /mnt > /mnt/etc/fstab

echo "=== Chrooting and configuring ==="
arch-chroot /mnt /bin/bash <<EOF
# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat <<EOL > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

# Root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Enable networking
systemctl enable NetworkManager

# Install and configure GRUB
pacman -Sy --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "✅ Arch installation complete! You can now reboot."
