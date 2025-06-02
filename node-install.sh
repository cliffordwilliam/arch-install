#!/bin/bash

set -e  # Exit on error

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Installing NVM...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Define NVM env line
NVM_LINES='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'

# Append to all relevant shell init files
echo -e "${GREEN}Adding NVM to shell profiles...${NC}"
for FILE in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
  if [ -f "$FILE" ]; then
    if ! grep -q 'nvm.sh' "$FILE"; then
      echo -e "\n# NVM configuration" >> "$FILE"
      echo "$NVM_LINES" >> "$FILE"
      echo "→ Updated $FILE"
    else
      echo "✓ NVM already configured in $FILE"
    fi
  fi
done

# Load NVM for this session
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"

echo -e "${GREEN}Installing latest LTS Node.js...${NC}"
nvm install --lts
nvm alias default 'lts/*'

echo -e "${GREEN}Installation complete.${NC}"
echo "Restart your terminal or run 'source ~/.bashrc' or 'source ~/.zshrc' to start using Node."
