#!/bin/bash

# Uninstall Script
# Removes the Linux environment setup

set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/config_parser.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Linux Environment Setup Uninstaller${NC}"
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

confirm_uninstall() {
    echo -e "${YELLOW}⚠️  WARNING: This will remove all users, department structure, and configurations!${NC}"
    echo
    
    if [[ -n "$DEPARTMENT_NAME" ]]; then
        echo "This will remove:"
        echo "• Department directory: /opt/$DEPARTMENT_NAME"
        echo "• Department group: $DEPARTMENT_NAME-team"
        echo "• Users: ${USERS[*]}"
        echo "• All user data and configurations"
        echo
    fi
    
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    if [[ "$confirm" != "yes" ]]; then
        print_error "Uninstall cancelled"
        exit 1
    fi
    
    echo
    read -p "Last chance! Type 'DELETE EVERYTHING' to proceed: " final_confirm
    if [[ "$final_confirm" != "DELETE EVERYTHING" ]]; then
        print_error "Uninstall cancelled"
        exit 1
    fi
    
    echo
}

remove_users() {
    echo -e "${BLUE}👥 Removing users...${NC}"
    
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            # Kill any running processes for the user
            sudo pkill -u "$user" 2>/dev/null || true
            
            # Remove user and home directory
            sudo userdel -r "$user" 2>/dev/null || true
            
            print_success "Removed user: $user"
        else
            print_warning "User $user not found"
        fi
    done
}

remove_department() {
    echo -e "${BLUE}🏢 Removing department structure...${NC}"
    
    if [[ -n "$DEPARTMENT_NAME" ]]; then
        # Remove department directory
        if [[ -d "/opt/$DEPARTMENT_NAME" ]]; then
            sudo rm -rf "/opt/$DEPARTMENT_NAME"
            print_success "Removed department directory: /opt/$DEPARTMENT_NAME"
        else
            print_warning "Department directory not found"
        fi
        
        # Remove department group
        if getent group "$DEPARTMENT_NAME-team" >/dev/null 2>&1; then
            sudo groupdel "$DEPARTMENT_NAME-team"
            print_success "Removed department group: $DEPARTMENT_NAME-team"
        else
            print_warning "Department group not found"
        fi
    fi
}

remove_docker() {
    echo -e "${BLUE}🐳 Removing Docker (optional)...${NC}"
    
    if [[ "$INSTALL_DOCKER" == "true" ]]; then
        read -p "Do you want to remove Docker? (y/N): " remove_docker_choice
        case $remove_docker_choice in
            [Yy]|[Yy][Ee][Ss])
                if command -v docker >/dev/null 2>&1; then
                    # Stop Docker service
                    sudo systemctl stop docker 2>/dev/null || true
                    sudo systemctl disable docker 2>/dev/null || true
                    
                    # Remove Docker packages
                    if [[ -f /etc/os-release ]]; then
                        . /etc/os-release
                        OS=$ID
                        
                        case $OS in
                            ubuntu|debian)
                                sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                                sudo apt autoremove -y
                                ;;
                            centos|rhel|rocky|almalinux)
                                sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                                ;;
                            fedora)
                                sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                                ;;
                        esac
                    fi
                    
                    # Remove Docker group
                    if getent group docker >/dev/null 2>&1; then
                        sudo groupdel docker 2>/dev/null || true
                    fi
                    
                    print_success "Docker removed"
                else
                    print_warning "Docker not found"
                fi
                ;;
            *)
                print_warning "Docker removal skipped"
                ;;
        esac
    fi
}

remove_config() {
    echo -e "${BLUE}📋 Removing configuration files...${NC}"
    
    # Remove configuration file
    if [[ -f "$HOME/.env-config.yaml" ]]; then
        rm "$HOME/.env-config.yaml"
        print_success "Removed configuration file"
    else
        print_warning "Configuration file not found"
    fi
}

clean_home_directories() {
    echo -e "${BLUE}🧹 Cleaning development tools from current user...${NC}"
    
    # Ask about cleaning current user's development tools
    read -p "Do you want to remove NVM, pyenv, and related tools from your home directory? (y/N): " clean_choice
    case $clean_choice in
        [Yy]|[Yy][Ee][Ss])
            # Remove NVM
            if [[ -d "$HOME/.nvm" ]]; then
                rm -rf "$HOME/.nvm"
                print_success "Removed NVM"
            fi
            
            # Remove pyenv
            if [[ -d "$HOME/.pyenv" ]]; then
                rm -rf "$HOME/.pyenv"
                print_success "Removed pyenv"
            fi
            
            # Remove from shell profiles
            for profile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                if [[ -f "$profile" ]]; then
                    # Remove NVM lines
                    sed -i '/NVM_DIR/d' "$profile"
                    sed -i '/nvm\.sh/d' "$profile"
                    sed -i '/bash_completion/d' "$profile"
                    
                    # Remove pyenv lines
                    sed -i '/PYENV_ROOT/d' "$profile"
                    sed -i '/pyenv init/d' "$profile"
                fi
            done
            
            print_success "Cleaned shell profiles"
            ;;
        *)
            print_warning "Home directory cleaning skipped"
            ;;
    esac
}

main() {
    print_header
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        exit 1
    fi
    
    # Load configuration
    if [[ -f "$HOME/.env-config.yaml" ]]; then
        parse_config "$HOME/.env-config.yaml"
    else
        print_warning "Configuration file not found. Limited uninstall available."
    fi
    
    confirm_uninstall
    
    remove_users
    remove_department
    remove_docker
    remove_config
    clean_home_directories
    
    echo
    print_success "Uninstall completed"
    echo
    echo -e "${YELLOW}Note: You may need to restart your terminal or log out and back in.${NC}"
    echo -e "${YELLOW}Some system packages and fonts may still be installed.${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi