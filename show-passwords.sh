#!/bin/bash

# Show User Passwords Script
# Displays the passwords for created users

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config_parser.sh"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    User Passwords Information${NC}"
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

main() {
    print_header
    
    # Load configuration
    CONFIG_FILE="$HOME/.env-config.yaml"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        echo "Please run ./setup.sh first to create the configuration."
        exit 1
    fi
    
    parse_config "$CONFIG_FILE"
    
    if [[ -z "$DEPARTMENT_NAME" ]]; then
        print_error "Department name not found in configuration"
        exit 1
    fi
    
    local password_file="/opt/$DEPARTMENT_NAME/user-passwords.txt"
    
    if [[ ! -f "$password_file" ]]; then
        print_error "Password file not found: $password_file"
        echo "This usually means the installation hasn't been completed yet."
        echo "Please run ./install.sh first."
        exit 1
    fi
    
    echo -e "${BLUE}Department:${NC} $DEPARTMENT_NAME"
    echo -e "${BLUE}Password file:${NC} $password_file"
    echo
    
    if [[ ! -r "$password_file" ]]; then
        print_warning "Cannot read password file directly (requires sudo)"
        echo "To view passwords, run:"
        echo "  sudo cat $password_file"
        echo
        echo "Or to view with this script:"
        echo "  sudo $0"
        exit 1
    fi
    
    echo -e "${YELLOW}Created User Passwords:${NC}"
    echo "----------------------------------------"
    
    while IFS=':' read -r username password; do
        if [[ -n "$username" && -n "$password" ]]; then
            echo -e "${GREEN}User:${NC} $username"
            echo -e "${BLUE}Password:${NC} $password"
            echo
        fi
    done < "$password_file"
    
    echo "----------------------------------------"
    echo -e "${RED}⚠️  IMPORTANT SECURITY NOTES:${NC}"
    echo "1. Change these default passwords immediately after first login"
    echo "2. Use strong, unique passwords for each account"
    echo "3. Consider using SSH keys instead of passwords"
    echo "4. Remove or secure this password file after initial setup"
    echo
    echo -e "${BLUE}Commands to change password:${NC}"
    echo "  passwd              # Change your own password"
    echo "  sudo passwd <user>  # Change another user's password"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi