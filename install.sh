#!/bin/bash
set -euo pipefail

get_partition_name() {
  local disk=$1
  local part_num=$2
  if [[ "$disk" =~ nvme ]]; then
      echo "${disk}p${part_num}"
  else
      echo "${disk}${part_num}"
  fi
}

read -p "Enter the target DISK (/dev/nvme0n1): " DISK
read -p "Enter hostname for the machine (asd): " HOSTNAME
read -p "Enter username (cliff): " USERNAME
read -sp "Enter password for $USERNAME: " USER_PASSWORD
read -p "Enter timezone (Asia/Jakarta): " TIMEZONE
read -p "Enter your microcode package? (intel-ucode/amd-ucode): " MICROCODE_PKG
read -p "EFI size (1024 MiB): " EFI_SIZE
read -p "SWAP size (8192 MiB): " SWAP_SIZE

umount -R /mnt 2>/dev/null || true
if [[ -n "${DISK:-}" && -b "$DISK" ]]; then
    SWAP_PART=$(get_partition_name "$DISK" 2)
    swapoff "$SWAP_PART" 2>/dev/null || true
fi

parted --script "$DISK" \
  mklabel gpt \
  mkpart ESP fat32 1MiB "$((EFI_SIZE + 1))MiB" \
  set 1 boot on \
  mkpart primary linux-swap "$((EFI_SIZE + 1))MiB" "$((EFI_SIZE + SWAP_SIZE + 1))MiB" \
  mkpart primary ext4 "$((EFI_SIZE + SWAP_SIZE + 1))MiB" 100%

mkfs.fat -F 32 "$(get_partition_name "$DISK" 1)"
mkswap "$(get_partition_name "$DISK" 2)"
mkfs.ext4 "$(get_partition_name "$DISK" 3)"

mount "$(get_partition_name "$DISK" 3)" /mnt
mount --mkdir "$(get_partition_name "$DISK" 1)" /mnt/boot
swapon "$(get_partition_name "$DISK" 2)"

pacstrap -K /mnt base linux linux-firmware "$MICROCODE_PKG" networkmanager sudo neovim

genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "LANG=en_US.UTF-8" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

echo "$HOSTNAME" > /etc/hostname
cat <<EOL > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOL

passwd -l root

systemctl enable NetworkManager

pacman -Syu --noconfirm

pacman -S --noconfirm base-devel xorg xorg-xinit i3 i3status dmenu \
    kitty qutebrowser alsa-utils ufw git github-cli tmux \
    noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra fontconfig

systemctl enable ufw
ufw default deny incoming
ufw default allow outgoing

useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
echo "$USERNAME:$USER_PASSWORD" | chpasswd

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

sudo -u "$USERNAME" bash <<'EOC'
echo 'exec i3' > ~/.xinitrc
EOC

EOF

echo "Installation complete!"
