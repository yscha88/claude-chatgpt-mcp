#!/bin/bash

# Claude ChatGPT MCP Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Claude ChatGPT MCP Setup${NC}"
echo "============================="

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This setup script only works on macOS${NC}"
    exit 1
fi

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${YELLOW}📦 Installing Bun...${NC}"
    curl -fsSL https://bun.sh/install | bash
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
bun install

# Make scripts executable
chmod +x index.ts
chmod +x run.sh

# Claude Desktop config path
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

# Create Claude config directory if it doesn't exist
if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "${YELLOW}📁 Creating Claude config directory...${NC}"
    mkdir -p "$CLAUDE_CONFIG_DIR"
fi

# Current project path
PROJECT_PATH=$(pwd)
BUN_PATH=$(which bun)

# Generate the MCP server configuration
MCP_CONFIG="{
  \"mcpServers\": {
    \"chatgpt-mcp\": {
      \"command\": \"$BUN_PATH\",
      \"args\": [\"run\", \"$PROJECT_PATH/index.ts\"]
    }
  }
}"

# Check if config file exists
if [ -f "$CLAUDE_CONFIG_FILE" ]; then
    echo -e "${BLUE}📋 Existing Claude config found${NC}"
    echo "   Backing up to: ${CLAUDE_CONFIG_FILE}.backup"
    cp "$CLAUDE_CONFIG_FILE" "${CLAUDE_CONFIG_FILE}.backup"
    
    # Check if the file already has mcpServers
    if grep -q "mcpServers" "$CLAUDE_CONFIG_FILE"; then
        echo -e "${YELLOW}⚠️  mcpServers section already exists in config${NC}"
        echo "   Please manually add the chatgpt-mcp configuration:"
        echo ""
        echo "   \"chatgpt-mcp\": {"
        echo "     \"command\": \"$BUN_PATH\","
        echo "     \"args\": [\"run\", \"$PROJECT_PATH/index.ts\"]"
        echo "   }"
        echo ""
    else
        # Try to merge with existing config
        echo -e "${GREEN}🔧 Merging with existing config...${NC}"
        # This is a simple merge - in production you might want to use jq
        python3 -c "
import json
import sys

try:
    with open('$CLAUDE_CONFIG_FILE', 'r') as f:
        config = json.load(f)
except:
    config = {}

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['chatgpt-mcp'] = {
    'command': '$BUN_PATH',
    'args': ['run', '$PROJECT_PATH/index.ts']
}

with open('$CLAUDE_CONFIG_FILE', 'w') as f:
    json.dump(config, f, indent=2)
" 2>/dev/null || {
            echo -e "${YELLOW}⚠️  Could not automatically merge config. Please add manually.${NC}"
        }
    fi
else
    echo -e "${GREEN}📝 Creating new Claude config...${NC}"
    echo "$MCP_CONFIG" > "$CLAUDE_CONFIG_FILE"
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"
echo "   1. Restart Claude Desktop app"
echo "   2. Grant accessibility permissions when prompted:"
echo "      System Preferences > Privacy & Security > Privacy > Accessibility"
echo "   3. Make sure ChatGPT desktop app is installed and running"
echo ""
echo -e "${BLUE}🎯 Usage examples:${NC}"
echo "   • \"Ask ChatGPT what is the weather like?\""
echo "   • \"Show me my recent ChatGPT conversations\""
echo "   • \"Send this to ChatGPT: Explain quantum computing\""
echo ""
echo -e "${GREEN}🚀 To test the server manually, run:${NC}"
echo "   ./run.sh"