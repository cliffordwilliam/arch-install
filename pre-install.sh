#!/bin/bash
set -euo pipefail

# --- Assumptions ---
DISK="/dev/nvme0n1"
read -p "Enter name for root: " HOSTNAME
read -s -p "Enter password for root $HOSTNAME: " ROOT_PASSWORD
echo
TIMEZONE="Asia/Jakarta"

echo "=== Partitioning $DISK ==="
parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB 1025MiB \
  set 1 boot on \
  mkpart primary linux-swap 1025MiB 5121MiB \
  mkpart primary ext4 5121MiB 100%

echo "=== Formatting partitions ==="
mkfs.fat -F 32 "${DISK}p1"
mkswap "${DISK}p2"
mkfs.ext4 "${DISK}p3"

echo "=== Mounting partitions ==="
mount "${DISK}p3" /mnt
mount --mkdir "${DISK}p1" /mnt/boot
swapon "${DISK}p2"

echo "=== Installing base system ==="
pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager

echo "=== Generating fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

echo "=== Chrooting and configuring ==="
arch-chroot /mnt /bin/bash <<EOF
# Timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
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
