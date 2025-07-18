#!/bin/bash

# Interactive Linux Environment Configuration Setup
# This script allows users to configure department name, users, and system settings

set -e

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file path
CONFIG_FILE="$HOME/.env-config.yaml"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Linux Environment Setup Configuration${NC}"
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

# Function to validate input
validate_username() {
    local username="$1"
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        return 1
    fi
    return 0
}

# Function to collect department information
collect_department_info() {
    echo -e "${BLUE}🏢 Department Configuration${NC}"
    echo "=========================================="
    
    while true; do
        read -p "Enter department name (e.g., tech-department, dev-team): " DEPARTMENT_NAME
        if [[ -n "$DEPARTMENT_NAME" && "$DEPARTMENT_NAME" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            break
        else
            print_error "Invalid department name. Use lowercase letters, numbers, hyphens, and underscores only."
        fi
    done
    
    while true; do
        read -p "Enter number of users to create (1-10): " USER_COUNT
        if [[ "$USER_COUNT" =~ ^[1-9]|10$ ]]; then
            break
        else
            print_error "Please enter a number between 1 and 10."
        fi
    done
    
    echo
}

# Function to collect user information
collect_user_info() {
    echo -e "${BLUE}👥 User Configuration${NC}"
    echo "=========================================="
    
    USERNAMES=()
    ZSH_USERS=()
    DOCKER_USERS=()
    
    for ((i=1; i<=USER_COUNT; i++)); do
        echo -e "${YELLOW}User $i:${NC}"
        
        while true; do
            read -p "  Username: " username
            if validate_username "$username"; then
                # Check if username already exists
                if [[ " ${USERNAMES[@]} " =~ " ${username} " ]]; then
                    print_error "Username '$username' already exists. Please choose a different name."
                else
                    USERNAMES+=("$username")
                    break
                fi
            else
                print_error "Invalid username. Use lowercase letters, numbers, hyphens, and underscores only."
            fi
        done
        
        while true; do
            read -p "  Configure Zsh for this user? (y/N): " zsh_choice
            case $zsh_choice in
                [Yy]|[Yy][Ee][Ss]) 
                    ZSH_USERS+=("$username")
                    break
                    ;;
                [Nn]|[Nn][Oo]|"") 
                    break
                    ;;
                *) 
                    print_error "Please answer y or n."
                    ;;
            esac
        done
        
        while true; do
            read -p "  Add to Docker group? (y/N): " docker_choice
            case $docker_choice in
                [Yy]|[Yy][Ee][Ss]) 
                    DOCKER_USERS+=("$username")
                    break
                    ;;
                [Nn]|[Nn][Oo]|"") 
                    break
                    ;;
                *) 
                    print_error "Please answer y or n."
                    ;;
            esac
        done
        
        echo
    done
}

# Function to collect system configuration
collect_system_config() {
    echo -e "${BLUE}🔧 System Configuration${NC}"
    echo "=========================================="
    
    while true; do
        read -p "Install Node.js globally? (Y/n): " node_choice
        case $node_choice in
            [Yy]|[Yy][Ee][Ss]|"") 
                INSTALL_NODE=true
                break
                ;;
            [Nn]|[Nn][Oo]) 
                INSTALL_NODE=false
                break
                ;;
            *) 
                print_error "Please answer y or n."
                ;;
        esac
    done
    
    while true; do
        read -p "Install Python globally? (Y/n): " python_choice
        case $python_choice in
            [Yy]|[Yy][Ee][Ss]|"") 
                INSTALL_PYTHON=true
                break
                ;;
            [Nn]|[Nn][Oo]) 
                INSTALL_PYTHON=false
                break
                ;;
            *) 
                print_error "Please answer y or n."
                ;;
        esac
    done
    
    while true; do
        read -p "Install Docker? (Y/n): " docker_choice
        case $docker_choice in
            [Yy]|[Yy][Ee][Ss]|"") 
                INSTALL_DOCKER=true
                break
                ;;
            [Nn]|[Nn][Oo]) 
                INSTALL_DOCKER=false
                break
                ;;
            *) 
                print_error "Please answer y or n."
                ;;
        esac
    done
    
    echo
}

# Function to display configuration summary
display_summary() {
    echo -e "${BLUE}📋 Configuration Summary${NC}"
    echo "=========================================="
    echo "Department: $DEPARTMENT_NAME"
    echo "Users: ${USERNAMES[*]}"
    echo "Zsh users: ${ZSH_USERS[*]:-None}"
    echo "Docker users: ${DOCKER_USERS[*]:-None}"
    echo "Install Node.js: $INSTALL_NODE"
    echo "Install Python: $INSTALL_PYTHON"
    echo "Install Docker: $INSTALL_DOCKER"
    echo
}

# Function to save configuration
save_config() {
    cat > "$CONFIG_FILE" << EOF
# Linux Environment Setup Configuration
# Generated on $(date)

department_name: "$DEPARTMENT_NAME"
users:
EOF

    for username in "${USERNAMES[@]}"; do
        echo "  - name: \"$username\"" >> "$CONFIG_FILE"
        
        # Check if user needs zsh
        if [[ " ${ZSH_USERS[@]} " =~ " ${username} " ]]; then
            echo "    zsh: true" >> "$CONFIG_FILE"
        else
            echo "    zsh: false" >> "$CONFIG_FILE"
        fi
        
        # Check if user needs docker
        if [[ " ${DOCKER_USERS[@]} " =~ " ${username} " ]]; then
            echo "    docker: true" >> "$CONFIG_FILE"
        else
            echo "    docker: false" >> "$CONFIG_FILE"
        fi
    done
    
    cat >> "$CONFIG_FILE" << EOF

system:
  install_node: $INSTALL_NODE
  install_python: $INSTALL_PYTHON
  install_docker: $INSTALL_DOCKER
EOF

    print_success "Configuration saved to $CONFIG_FILE"
}

# Main function
main() {
    print_header
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root."
        echo "For new servers, please run: sudo ./bootstrap.sh"
        echo "Then switch to the created user and run this script."
        exit 1
    fi
    
    # Check if configuration already exists
    if [[ -f "$CONFIG_FILE" ]]; then
        print_warning "Configuration file already exists at $CONFIG_FILE"
        read -p "Do you want to overwrite it? (y/N): " overwrite
        case $overwrite in
            [Yy]|[Yy][Ee][Ss]) 
                rm "$CONFIG_FILE"
                ;;
            *) 
                print_error "Setup cancelled."
                exit 1
                ;;
        esac
    fi
    
    # Collect configuration
    collect_department_info
    collect_user_info
    collect_system_config
    
    # Display summary and confirm
    display_summary
    
    while true; do
        read -p "Proceed with this configuration? (Y/n): " confirm
        case $confirm in
            [Yy]|[Yy][Ee][Ss]|"") 
                break
                ;;
            [Nn]|[Nn][Oo]) 
                print_error "Setup cancelled."
                exit 1
                ;;
            *) 
                print_error "Please answer y or n."
                ;;
        esac
    done
    
    # Save configuration
    save_config
    
    print_success "Setup completed successfully!"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run ./install.sh to install the environment"
    echo "2. Log out and back in for all changes to take effect"
    echo "3. Configure your Git settings if needed"
    echo
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi