# 🧪 Automated Arch Linux Installer

Just run the script and it does everything for you.

## ⚠️ Warning

Check the script and edit the content before running it as needed.

---

## 🚀 How to Use

1. Boot from the official [Arch ISO](https://archlinux.org/download/).
2. Connect to the internet.
3. Run preinstall in live env, run postinstall after logging in:

```bash
curl -LO https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/preinstall.sh
curl -LO https://raw.githubusercontent.com/cliffordwilliam/arch-install/main/postinstall.sh
chmod +x preinstall.sh
bash -x preinstall.sh
```

## Connect to internet in live env

run

```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect "WIFI NAME"
exit
```

## Connect to internet in after logging in

run

```bash
nmtui
```

1. pick "Activate a connection"
2. pick "Quit"

## After postinstall

```bash
login as user
startx to start ui
```

## After postinstall push ssh key to remote github using github cli

```bash
[cliff@cliff repos]$ gh auth logout
✓ Logged out of github.com account cliffordwilliam
[cliff@cliff repos]$ gh auth login
? Where do you use GitHub? GitHub.com
? What is your preferred protocol for Git operations on this host? SSH
? Upload your SSH public key to your GitHub account? /home/cliff/.ssh/id_ed25519.pub
? Title for your SSH key: cliff-bla-bla-computer-linux
? How would you like to authenticate GitHub CLI? Login with a web browser

! First copy your one-time code: 1231-1231
Press Enter to open https://github.com/login/device in your browser...
! Failed opening a web browser at https://github.com/login/device
  exec: "xdg-open,x-www-browser,www-browser,wslview": executable file not found in $PATH
  Please try entering the URL in your browser manually


✓ Authentication complete.
- gh config set -h github.com git_protocol ssh
✓ Configured git protocol
! Authentication credentials saved in plain text
✓ Uploaded the SSH key to your GitHub account: /home/cliff/.ssh/id_ed25519.pub
✓ Logged in as cliffordwilliam
[cliff@cliff repos]$ ssh -T git@github.com
```

## Working is as simple as
1. git init
2. git add and git commit
3. gh repo create coffee-shop --public --source=. --remote=origin --push

The 3rd one creates the remote repo and push the local there
