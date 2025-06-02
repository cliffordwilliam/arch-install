#!/bin/bash

set -e  # Exit on error

# Colors for clarity
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing NVM...${NC}"

# Download and install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM into the current session
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo -e "${GREEN}Installing latest LTS Node.js...${NC}"
nvm install --lts

echo -e "${GREEN}Setting default Node.js version to LTS...${NC}"
nvm alias default 'lts/*'

echo -e "${GREEN}Done!${NC} To start using Node, restart your terminal or run:"
echo "source ~/.nvm/nvm.sh"
