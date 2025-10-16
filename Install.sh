#!/bin/bash
set -euo pipefail

# Check internet first
if ! ping -c1 archlinux.org &>/dev/null; then
    echo "No internet connection!" >&2
    exit 1
fi

# Must be root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Must be UEFI booted
if [[ ! -d /sys/firmware/efi ]]; then
    echo "System not booted in UEFI mode!" >&2
    exit 1
fi

get_partition_name() {
  local disk=$1
  local part_num=$2
  if [[ "$disk" =~ nvme ]]; then
      echo "${disk}p${part_num}"
  else
      echo "${disk}${part_num}"
  fi
}

cleanup() {
    echo "Cleaning up..."
    umount -R /mnt 2>/dev/null || true
    if [[ -n "${DISK:-}" && -b "$DISK" ]]; then
        SWAP_PART=$(get_partition_name "$DISK" 2)
        swapoff "$SWAP_PART" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# --- User input ---
lsblk -d -o NAME,SIZE,MODEL
while true; do
  read -p "Enter the target disk (e.g., /dev/nvme0n1 or /dev/sda): " DISK
  [[ -b "$DISK" ]] && break
  echo "Disk $DISK not found."
done

echo "You are about to wipe all data on $DISK"
read -p "Type YES in all caps to continue: " CONFIRM
if [[ "$CONFIRM" != "YES" ]]; then
    echo "Aborting. (You must type YES in all caps)"
    exit 1
fi

read -p "Enter hostname for the machine: " HOSTNAME
read -p "Enter username: " USERNAME

# Root password
while true; do
  read -s -p "Enter password for root user: " ROOT_PASSWORD
  echo
  read -s -p "Confirm password: " ROOT_PASSWORD_CONFIRM
  echo
  [[ "$ROOT_PASSWORD" == "$ROOT_PASSWORD_CONFIRM" ]] && break
  echo "Passwords do not match. Try again."
done

# Regular user password
while true; do
  read -s -p "Enter password for $USERNAME: " USER_PASSWORD
  echo
  read -s -p "Confirm password: " USER_PASSWORD_CONFIRM
  echo
  [[ "$USER_PASSWORD" == "$USER_PASSWORD_CONFIRM" ]] && break
  echo "Passwords do not match. Try again."
done

# Timezone
while true; do
  read -p "Enter timezone (e.g., Asia/Jakarta): " TIMEZONE
  [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] && break
  echo "Invalid timezone."
done

# CPU vendor
CPU_VENDOR=""
while true; do
  read -p "Is your CPU Intel or AMD? (intel/amd): " CPU_VENDOR
  CPU_VENDOR=${CPU_VENDOR,,}
  [[ "$CPU_VENDOR" == "intel" || "$CPU_VENDOR" == "amd" ]] && break
  echo "Enter 'intel' or 'amd'."
done

# Disk info
lsblk -d -o NAME,SIZE,MODEL "$DISK"
DISK_SIZE=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_GB=$((DISK_SIZE / 1024 / 1024 / 1024))
echo "Disk size: ${DISK_SIZE_GB} GB"

# Partition sizes
while true; do
  read -p "EFI size (MiB): " EFI_SIZE
  read -p "SWAP size (MiB): " SWAP_SIZE
  TOTAL_REQUESTED=$((EFI_SIZE + SWAP_SIZE))
  AVAILABLE=$((DISK_SIZE_GB * 1024))
  [[ $TOTAL_REQUESTED -lt $AVAILABLE ]] && break
  echo "Partitions exceed disk size ($AVAILABLE MiB)."
done

read -p "Proceed to partition $DISK with these values? [y/N]: " confirm
[[ "$confirm" == [yY] ]] || { echo "Aborting."; exit 1; }

# --- Partition, format, mount ---
umount -R /mnt 2>/dev/null || true
SWAP_PART=$(get_partition_name "$DISK" 2)
swapoff "$SWAP_PART" 2>/dev/null || true

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

# --- Install base system ---
MICROCODE_PKG=$([[ "$CPU_VENDOR" == "intel" ]] && echo "intel-ucode" || echo "amd-ucode")
pacstrap -K /mnt base linux linux-firmware "$MICROCODE_PKG" networkmanager sudo neovim

genfstab -U /mnt > /mnt/etc/fstab

# --- Chroot setup ---
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

echo "root:$ROOT_PASSWORD" | chpasswd

systemctl enable NetworkManager

pacman -Syu --noconfirm
pacman -S --noconfirm base-devel xorg xorg-xinit libx11 libxft libxinerama alsa-utils firefox git

useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
echo "$USERNAME:$USER_PASSWORD" | chpasswd

sudo -u "$USERNAME" mkdir -p /home/$USERNAME/.local/bin
if ! sudo -u "$USERNAME" grep -q '.local/bin' /home/$USERNAME/.bashrc 2>/dev/null; then
    echo 'export PATH="\$HOME/.local/bin:\$PATH"' >> /home/$USERNAME/.bashrc
fi

sudo -u "$USERNAME" bash <<'EOSU'
mkdir -p /home/$USERNAME/suckless
cd /home/$USERNAME/suckless

for repo in dwm st dmenu slstatus; do
    rm -rf "\$repo"
    git clone --depth 1 "https://git.suckless.org/\$repo"
    cd "\$repo"
    make
    case "\$repo" in
        dmenu)
            cp dmenu dmenu_run dmenu_path stest /home/$USERNAME/.local/bin/
            ;;
        *)
            cp "\$repo" /home/$USERNAME/.local/bin/
            ;;
    esac
    cd ..
done

if [[ ! -f /home/$USERNAME/.xinitrc ]]; then
    echo "slstatus &" >> /home/$USERNAME/.xinitrc
    echo "exec dwm" >> /home/$USERNAME/.xinitrc
fi
EOSU

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo "Installation complete. Login as $USERNAME and run: startx"
echo "⚠️  IMPORTANT: Firewall was NOT installed."
echo "    After logging in, you can enable ufw manually with:"
echo "    sudo pacman -S ufw && sudo systemctl enable --now ufw"
