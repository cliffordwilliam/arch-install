#!/bin/bash

echo "=== GitHub Account Setup Script ==="

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

# Generate SSH key
if [ -f "$ssh_key" ]; then
  echo "SSH key already exists: $ssh_key"
else
  ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key"
  echo "SSH key generated at: $ssh_key"
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)"
ssh-add "$ssh_key"

# Append SSH config
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

# Create Git config for this account
cat > "$gitconfig_account" <<EOF
[user]
  name = $git_name
  email = $git_email
EOF
echo "Git identity config saved to $gitconfig_account"

# Add includeIf rule to ~/.gitconfig if missing
if ! grep -q "includeIf \"gitdir:~/dev/$account/\"" ~/.gitconfig 2>/dev/null; then
  echo "
[includeIf \"gitdir:~/dev/$account/\"]
  path = $gitconfig_account
" >> ~/.gitconfig
  echo "Linked $gitconfig_account to ~/dev/$account/ in ~/.gitconfig"
else
  echo "includeIf already exists for ~/dev/$account/"
fi

# Show the public key
echo
echo "=== Public Key (copy this into GitHub SSH keys UI) ==="
cat "$ssh_key.pub"
echo
echo "Add it at: https://github.com/settings/ssh/new"
echo "When cloning, use:"
echo "  git@${ssh_alias}:<username>/<repo>.git"
