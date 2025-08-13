#!/bin/bash

# Claude ChatGPT MCP Server Runner Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Claude ChatGPT MCP Server${NC}"
echo "================================"

# Check if Bun is installed
if ! command -v bun &> /dev/null; then
    echo -e "${RED}❌ Bun is not installed. Please install Bun first:${NC}"
    echo "   curl -fsSL https://bun.sh/install | bash"
    exit 1
fi

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This MCP server only works on macOS${NC}"
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    bun install
fi

# Make the script executable
chmod +x index.ts

# Check if ChatGPT app is installed
if [ ! -d "/Applications/ChatGPT.app" ]; then
    echo -e "${YELLOW}⚠️  ChatGPT app not found in /Applications/ChatGPT.app${NC}"
    echo "   Please make sure ChatGPT desktop app is installed."
    echo "   Download from: https://chatgpt.com/download"
fi

# Display configuration information
echo -e "${GREEN}📋 Configuration Info:${NC}"
echo "   Current user: $(whoami)"
echo "   Bun path: $(which bun)"
echo "   Project path: $(pwd)"
echo ""
echo -e "${YELLOW}📝 Claude Desktop Config:${NC}"
echo "   File: ~/Library/Application Support/Claude/claude_desktop_config.json"
echo ""
echo "   Add this configuration:"
echo "   {"
echo "     \"mcpServers\": {"
echo "       \"chatgpt-mcp\": {"
echo "         \"command\": \"$(which bun)\","
echo "         \"args\": [\"run\", \"$(pwd)/index.ts\"]"
echo "       }"
echo "     }"
echo "   }"
echo ""

# Run the server
echo -e "${GREEN}🎯 Starting MCP Server...${NC}"
echo "   Press Ctrl+C to stop"
echo ""

bun run index.ts