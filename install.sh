#!/bin/bash

# Nelson Loop Framework Installer
# Installs Nelson commands to your system

set -e

INSTALL_DIR="$HOME/.nelson"
REPO_URL="git@github.com:jusgou/nelson.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║                                                          ║"
echo "║   ██╗  ██╗ █████╗       ██╗  ██╗ █████╗     ██╗        ║"
echo "║   ██║  ██║██╔══██╗      ██║  ██║██╔══██╗    ██║        ║"
echo "║   ███████║███████║█████╗███████║███████║    ██║        ║"
echo "║   ██╔══██║██╔══██║╚════╝██╔══██║██╔══██║    ╚═╝        ║"
echo "║   ██║  ██║██║  ██║      ██║  ██║██║  ██║    ██╗        ║"
echo "║   ╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝        ║"
echo "║                                                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Nelson Loop Framework Installer"
echo ""

# Check if directory exists
if [ -d "$INSTALL_DIR" ]; then
    print_info "Nelson template directory already exists at $INSTALL_DIR"
    read -p "Update existing installation? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
    print_info "Updating existing installation..."
    cd "$INSTALL_DIR"
    git pull
else
    print_info "Cloning Nelson template to $INSTALL_DIR..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

print_success "Nelson template installed to $INSTALL_DIR"

# Check if already in PATH
if [[ ":$PATH:" == *":$INSTALL_DIR/bin:"* ]]; then
    print_success "Nelson commands are already in your PATH"
else
    echo ""
    print_info "Add Nelson commands to your PATH:"
    echo ""
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "    export PATH=\"\$HOME/.nelson/bin:\$PATH\""
    echo ""
    echo "Then run:"
    echo "    source ~/.bashrc  # or source ~/.zshrc"
    echo ""
fi

# Make all commands executable
chmod +x "$INSTALL_DIR"/bin/nelson-*

print_success "Installation complete!"
echo ""
echo "Available commands:"
echo "  → nelson-scaffold        - Scaffold new Nelson projects"
echo "  → nelson-prd-generator   - Generate PRD for Toro mode"
echo "  → nelson-specs-generator - Generate specs for Plan/Build mode"
echo "  → nelson-status          - Monitor Nelson progress"
echo "  → nelson-punch-ralph     - Run quality review"
echo ""
echo "Now go throw punches. 🥊"
