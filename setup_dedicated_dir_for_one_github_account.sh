#!/bin/bash

echo "=== Create dedicated dir for 1 account ==="

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config

# Ask for account namespace
read -p "Enter an account label (e.g. personal, work): " account
account_dir="$HOME/dev/$account"
ssh_key="$HOME/.ssh/id_ed25519_$account"
ssh_alias="github.com-$account"
gitconfig_account="$HOME/.gitconfig-$account"

# Ask for Git identity
read -p "Enter the Git user name for this account: " git_name
read -p "Enter the Git email for this account: " git_email

# Create dev folder if not exists
mkdir -p "$account_dir"
echo "Created or found directory: $account_dir"

# Generate SSH key if not exists
if [ -f "$ssh_key" ]; then
  echo "SSH key already exists: $ssh_key"
else
  ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
  echo "SSH key generated at: $ssh_key (no passphrase)"
fi

# Append SSH config if missing, add namespace
if ! grep -q "Host $ssh_alias" ~/.ssh/config 2>/dev/null; then
  echo "
# $account GitHub account
Host $ssh_alias
  HostName github.com
  User git
  IdentityFile $ssh_key
  IdentitiesOnly yes
" >> ~/.ssh/config
  echo "SSH config added for $ssh_alias"
else
  echo "SSH config already exists for $ssh_alias"
fi

# Create Git config for this account, each dir should have this
cat > "$gitconfig_account" <<EOF
[user]
  name = $git_name
  email = $git_email
EOF
echo "Git identity config saved to $gitconfig_account"

# Add includeIf rule to ~/.gitconfig if missing, this tells git to see this dir config to be dynamic
if ! grep -q "includeIf \"gitdir:~/dev/$account/\"" ~/.gitconfig 2>/dev/null; then
  echo "
[includeIf \"gitdir:~/dev/$account/\"]
  path = $gitconfig_account
" >> ~/.gitconfig
  echo "Linked $gitconfig_account to ~/dev/$account/ in ~/.gitconfig"
else
  echo "includeIf already exists for ~/dev/$account/"
fi

# Show the public key, so you can add it to github FE
echo
echo "=== Public Key (copy this into GitHub SSH keys UI) ==="
cat "$ssh_key.pub"
echo
echo "Add it at: https://github.com/settings/ssh/new"
echo "When cloning, use:"
echo "  git@${ssh_alias}:<username>/<repo>.git"

echo "When pushing existing for first time, add remote like this git@github.com-ALIAS-NAMESPACE-HERE:roundpork/test-repo.git"
