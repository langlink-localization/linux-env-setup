#!/bin/bash

# Linux Environment Installation Script
# This script installs the environment based on the configuration

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="$HOME/.env-config.yaml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Linux Environment Installer${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to parse YAML configuration
parse_yaml() {
    local file="$1"
    local prefix="$2"
    
    # Simple YAML parser for our specific format
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]// /}"
            value="${BASH_REMATCH[2]}"
            value="${value//\"/}"  # Remove quotes
            
            # Create environment variable
            declare -g "${prefix}${key}"="$value"
        fi
    done < "$file"
}

# Function to load configuration
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        echo "Please run ./setup.sh first."
        exit 1
    fi
    
    echo -e "${BLUE}📖 Loading configuration...${NC}"
    
    # Load configuration into variables
    source "$SCRIPT_DIR/lib/config_parser.sh"
    parse_config "$CONFIG_FILE"
    
    print_success "Configuration loaded"
}

check_requirements() {
    echo -e "${BLUE}🔍 Checking requirements...${NC}"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        echo "For new servers, please run: sudo ./bootstrap.sh"
        echo "Then switch to the created user and run this script."
        exit 1
    fi
    
    # Check for required tools
    local missing_tools=()
    
    for tool in curl wget git; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo "Please install them first or run the bootstrap script."
        exit 1
    fi
    
    print_success "Requirements check passed"
}

run_installation() {
    echo -e "${BLUE}🚀 Starting installation...${NC}"
    
    # Run installation modules in order
    local modules=(
        "packages"
        "department"
        "docker"
        "zsh"
    )
    
    for module in "${modules[@]}"; do
        echo -e "${BLUE}📦 Installing $module...${NC}"
        
        if [[ -f "$SCRIPT_DIR/modules/install-$module.sh" ]]; then
            chmod +x "$SCRIPT_DIR/modules/install-$module.sh"
            # Run module in a clean environment with proper working directory
            (cd "$SCRIPT_DIR" && "$SCRIPT_DIR/modules/install-$module.sh")
        else
            print_warning "Module $module not found, skipping"
        fi
    done
    
    print_success "Installation completed successfully!"
}

display_completion_message() {
    echo
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
    echo "What was installed:"
    echo "• Department directory structure"
    echo "• User accounts with configured shells"
    echo "• Development tools (Node.js, Python, Docker)"
    echo "• Zsh with Oh My Zsh and Powerlevel10k"
    echo "• Useful aliases and functions"
    echo
    echo -e "${YELLOW}Important next steps:${NC}"
    echo "1. Log out and log back in (or restart your terminal)"
    echo "2. Configure your Git settings:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
    echo "3. Users should change their default passwords"
    echo "4. Run 'p10k configure' to set up Powerlevel10k theme"
    echo
    echo -e "${BLUE}Quick commands to try:${NC}"
    echo "• workspace    - Go to department workspace"
    echo "• projects     - Go to projects directory"
    echo "• newproject <name> - Create a new project"
    echo "• gs           - Git status"
    echo "• dps          - Docker ps"
    echo
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${BLUE}Configuration file:${NC} $CONFIG_FILE"
    fi
}

main() {
    print_header
    
    check_requirements
    load_config
    run_installation
    display_completion_message
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi