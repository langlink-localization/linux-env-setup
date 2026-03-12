#!/bin/bash

# Package Installation Module
# Installs base packages and development tools

set -eo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/config_parser.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
}

# Install base packages
install_base_packages() {
    echo -e "${BLUE}📦 Installing base packages for $OS...${NC}"
    
    case $OS in
        ubuntu|debian)
            sudo apt update
            sudo apt install -y \
                curl \
                wget \
                git \
                vim \
                zsh \
                build-essential \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                unzip \
                fontconfig \
                python3-pip \
                python3-yaml
            ;;
        centos|rhel|rocky|almalinux)
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y \
                curl \
                wget \
                git \
                vim \
                zsh \
                epel-release \
                fontconfig \
                python3-pip \
                python3-pyyaml
            ;;
        fedora)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y \
                curl \
                wget \
                git \
                vim \
                zsh \
                fontconfig \
                python3-pip \
                python3-pyyaml
            ;;
        *)
            print_warning "Unsupported OS: $OS. Continuing with manual installation..."
            ;;
    esac
    
    print_success "Base packages installed"
}

# Install Hack Nerd Font
install_hack_font() {
    echo -e "${BLUE}📦 Installing Hack Nerd Font...${NC}"
    
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    
    if [[ ! -f "$FONT_DIR/Hack Regular Nerd Font Complete.ttf" ]]; then
        wget -O /tmp/Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
        unzip -o /tmp/Hack.zip -d "$FONT_DIR"
        fc-cache -fv
        rm /tmp/Hack.zip
        print_success "Hack Nerd Font installed"
    else
        print_warning "Hack Nerd Font already installed"
    fi
}

# Install Node.js via NVM
install_nodejs() {
    if [[ "$INSTALL_NODE" == "true" ]]; then
        local installer

        echo -e "${BLUE}📦 Installing Node.js for the current operator account...${NC}"
        
        if [[ ! -d "$HOME/.nvm" ]]; then
            installer="$(mktemp)"
            curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh -o "$installer"
            bash "$installer"
            rm -f "$installer"
            
            # Load NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            # Install latest LTS Node.js
            nvm install --lts
            nvm use --lts
            nvm alias default lts/*
            
            print_success "Node.js installed"
        else
            print_warning "NVM already installed"
        fi
    else
        echo -e "${BLUE}⏭️  Skipping Node.js installation${NC}"
    fi
}

# Install Python via pyenv
install_python() {
    if [[ "$INSTALL_PYTHON" == "true" ]]; then
        local installer

        echo -e "${BLUE}📦 Installing Python for the current operator account...${NC}"
        
        if [[ ! -d "$HOME/.pyenv" ]]; then
            installer="$(mktemp)"
            curl -fsSL https://pyenv.run -o "$installer"
            bash "$installer"
            rm -f "$installer"
            
            # Add to PATH temporarily
            export PYENV_ROOT="$HOME/.pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            eval "$(pyenv init -)"
            
            # Install latest Python
            PYTHON_VERSION=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
            pyenv install "$PYTHON_VERSION"
            pyenv global "$PYTHON_VERSION"
            
            print_success "Python $PYTHON_VERSION installed"
        else
            print_warning "pyenv already installed"
        fi
    else
        echo -e "${BLUE}⏭️  Skipping Python installation${NC}"
    fi
}

main() {
    # Parse configuration
    parse_config "$(resolve_config_file_path)"
    
    detect_os
    install_base_packages
    install_hack_font
    install_nodejs
    install_python
    
    print_success "Package installation completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
