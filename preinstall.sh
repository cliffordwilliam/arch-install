#!/usr/bin/env bash
set -euo pipefail

DISK="/dev/nvme0n1"
EFI="${DISK}p1"
ROOT="${DISK}p2"
HOSTNAME="cliff-arch"
TIMEZONE="Asia/Jakarta"
LOCALE="en_US.UTF-8"
ROOT_PASSWORD="rootpassword"  # change this!
USERNAME="cliff"
USER_PASSWORD="userpassword"  # change this!

echo "[+] Setting timezone to $TIMEZONE..."
timedatectl set-timezone "$TIMEZONE"

echo "[+] Wiping and formatting disk..."
mkfs.fat -F32 "$EFI"
mkfs.ext4 "$ROOT"

echo "[+] Mounting partitions..."
mount "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI" /mnt/boot/efi

echo "[+] Creating swap file..."
fallocate -l 4G /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
# swapon will be done inside chroot

echo "[+] Installing reflector and updating mirrorlist..."
pacman -Sy --noconfirm reflector
reflector --country "Indonesia" --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "[+] Installing base system..."
pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager sudo vim grub efibootmgr

echo "[+] Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[+] Creating in-chroot script..."
cat > /mnt/root/in-chroot.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="$1"
TIMEZONE="$2"
LOCALE="$3"
USERNAME="$4"
USER_PASSWORD="$5"
ROOT_PASSWORD="$6"

echo "[+] Setting timezone..."
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

echo "[+] Generating locale..."
sed -i "s/^#\?$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo "[+] Setting hostname..."
echo "$HOSTNAME" > /etc/hostname

echo "[+] Enabling services..."
systemctl enable NetworkManager
systemctl enable systemd-timesyncd

echo "[+] Enabling swap..."
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

echo "[+] Tuning swappiness..."
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

echo "[+] Setting root password..."
echo "root:$ROOT_PASSWORD" | chpasswd

echo "[+] Installing and configuring GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "[+] Creating user '$USERNAME'..."
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[+] Enabling postinstall to run on first login..."
mkdir -p /home/$USERNAME/.config/autostart
cat << 'EOS' > /home/$USERNAME/.bash_profile
if [ -z "\$DISPLAY" ] && [ "\$XDG_VTNR" -eq 1 ]; then
  bash ~/postinstall.sh
fi
EOS
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/postinstall.sh
chmod +x /home/$USERNAME/postinstall.sh

echo "[+] Done in chroot."
EOF

chmod +x /mnt/root/in-chroot.sh

echo "[+] Chrooting and continuing setup..."
arch-chroot /mnt /root/in-chroot.sh "$HOSTNAME" "$TIMEZONE" "$LOCALE" "$USERNAME" "$USER_PASSWORD" "$ROOT_PASSWORD"

echo "[+] Cleaning up..."
rm /mnt/root/in-chroot.sh

echo "[+] Unmounting and rebooting..."
umount -R /mnt
reboot
