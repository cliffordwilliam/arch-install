#!/bin/bash

# -----------------------------
# Step 1: Prompt for Account Information
# -----------------------------

# Prompt for user information (Name and Email)
read -p "Enter the name for this account: " NAME
read -p "Enter the email address for this account: " EMAIL

# Define filename for the SSH keys
SSH_KEY="$HOME/.ssh/id_ed25519_$NAME"

# -----------------------------
# Step 2: Generate SSH Keys for New Account
# -----------------------------

echo "Generating SSH key for account ($EMAIL)..."
# Generate SSH keys for the account
ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N "" # -N "" sets an empty passphrase

# -----------------------------
# Step 3: Authenticate with GitHub (GH CLI)
# -----------------------------

# Check if GitHub CLI is installed and authenticate
if command -v gh &> /dev/null
then
    echo "Logging into GitHub..."
    gh auth login
else
    echo "GitHub CLI (gh) is not installed. Please install it to proceed with GitHub authentication."
    exit 1
fi

# -----------------------------
# Step 4: Set up SSH config for multiple GitHub accounts
# -----------------------------

echo "Configuring SSH settings for GitHub account $EMAIL..."

# Add SSH config for the account
cat <<EOL >> "$HOME/.ssh/config"
Host github.com-$NAME  
  HostName github.com
  User git
  IdentityFile $SSH_KEY
EOL

# -----------------------------
# Step 5: Organize Project Directory Structure
# -----------------------------

echo "Creating directory structure for dev projects..."

# Create the directories for the repositories
mkdir -p "$HOME/dev/$NAME"

# -----------------------------
# Step 6: Create and Configure .gitconfig for Multiple Accounts
# -----------------------------

echo "Creating .gitconfig for account..."

# Create a new gitconfig specific to this account
cat <<EOL > "$HOME/.gitconfig-$NAME"
[user]
  name = $NAME
  email = $EMAIL
EOL

# Main .gitconfig: Add include for the new account
echo "Configuring main .gitconfig..."
cat <<EOL >> "$HOME/.gitconfig"
[includeIf "gitdir:$HOME/dev/$NAME/"]
  path = $HOME/.gitconfig-$NAME  
EOL

echo "Setup complete for account $NAME!"
