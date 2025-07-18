#!/bin/bash

# Status Check Script
# Checks the installation status of the Linux environment

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
    echo -e "${BLUE}    Linux Environment Setup Status${NC}"
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

check_config() {
    echo -e "${BLUE}📋 Configuration Status${NC}"
    echo "----------------------------------------"
    
    if [[ -f "$HOME/.env-config.yaml" ]]; then
        print_success "Configuration file exists"
        parse_config "$HOME/.env-config.yaml"
        echo "Department: $DEPARTMENT_NAME"
        echo "Users: ${USERS[*]}"
        echo "Install Node.js: $INSTALL_NODE"
        echo "Install Python: $INSTALL_PYTHON"
        echo "Install Docker: $INSTALL_DOCKER"
    else
        print_error "Configuration file not found"
        echo "Run ./setup.sh to create configuration"
    fi
    echo
}

check_department() {
    echo -e "${BLUE}🏢 Department Status${NC}"
    echo "----------------------------------------"
    
    if [[ -n "$DEPARTMENT_NAME" ]]; then
        local dept_dir="/opt/$DEPARTMENT_NAME"
        
        if [[ -d "$dept_dir" ]]; then
            print_success "Department directory exists: $dept_dir"
            
            # Check subdirectories
            for subdir in projects shared docs scripts archives; do
                if [[ -d "$dept_dir/$subdir" ]]; then
                    echo "  ✓ $subdir/"
                else
                    echo "  ✗ $subdir/"
                fi
            done
            
            # Check info file
            if [[ -f "$dept_dir/department-info.txt" ]]; then
                print_success "Department info file exists"
            else
                print_warning "Department info file missing"
            fi
        else
            print_error "Department directory not found"
        fi
        
        # Check group
        if getent group "$DEPARTMENT_NAME-team" >/dev/null 2>&1; then
            print_success "Department group exists: $DEPARTMENT_NAME-team"
        else
            print_error "Department group not found"
        fi
    else
        print_warning "No department configured"
    fi
    echo
}

check_users() {
    echo -e "${BLUE}👥 User Status${NC}"
    echo "----------------------------------------"
    
    if [[ ${#USERS[@]} -eq 0 ]]; then
        print_warning "No users configured"
        return
    fi
    
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            print_success "User $user exists"
            
            # Check shell
            user_shell=$(getent passwd "$user" | cut -d: -f7)
            if user_has_zsh "$user"; then
                if [[ "$user_shell" == "/bin/zsh" ]]; then
                    echo "  ✓ Shell: zsh"
                else
                    echo "  ✗ Shell: $user_shell (expected zsh)"
                fi
            else
                echo "  ✓ Shell: $user_shell"
            fi
            
            # Check groups
            user_groups=$(groups "$user" 2>/dev/null || echo "")
            if [[ "$user_groups" == *"$DEPARTMENT_NAME-team"* ]]; then
                echo "  ✓ Department group membership"
            else
                echo "  ✗ Not in department group"
            fi
            
            if user_has_docker "$user"; then
                if [[ "$user_groups" == *"docker"* ]]; then
                    echo "  ✓ Docker group membership"
                else
                    echo "  ✗ Not in docker group"
                fi
            fi
            
            # Check workspace link
            if [[ -L "/home/$user/workspace" ]]; then
                echo "  ✓ Workspace link exists"
            else
                echo "  ✗ Workspace link missing"
            fi
        else
            print_error "User $user not found"
        fi
    done
    echo
}

check_zsh_config() {
    echo -e "${BLUE}🐚 Zsh Configuration Status${NC}"
    echo "----------------------------------------"
    
    local zsh_users_found=false
    
    for user in "${USERS[@]}"; do
        if user_has_zsh "$user"; then
            zsh_users_found=true
            echo "User: $user"
            
            local user_home="/home/$user"
            
            # Check Oh My Zsh
            if [[ -d "$user_home/.oh-my-zsh" ]]; then
                echo "  ✓ Oh My Zsh installed"
            else
                echo "  ✗ Oh My Zsh not installed"
            fi
            
            # Check Powerlevel10k
            if [[ -d "$user_home/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
                echo "  ✓ Powerlevel10k installed"
            else
                echo "  ✗ Powerlevel10k not installed"
            fi
            
            # Check plugins
            local plugins_dir="$user_home/.oh-my-zsh/custom/plugins"
            if [[ -d "$plugins_dir/zsh-autosuggestions" ]]; then
                echo "  ✓ zsh-autosuggestions installed"
            else
                echo "  ✗ zsh-autosuggestions not installed"
            fi
            
            if [[ -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
                echo "  ✓ zsh-syntax-highlighting installed"
            else
                echo "  ✗ zsh-syntax-highlighting not installed"
            fi
            
            # Check .zshrc
            if [[ -f "$user_home/.zshrc" ]]; then
                echo "  ✓ .zshrc exists"
            else
                echo "  ✗ .zshrc missing"
            fi
        fi
    done
    
    if [[ "$zsh_users_found" == false ]]; then
        print_warning "No users configured for Zsh"
    fi
    echo
}

check_development_tools() {
    echo -e "${BLUE}🛠️  Development Tools Status${NC}"
    echo "----------------------------------------"
    
    # Check Node.js
    if [[ "$INSTALL_NODE" == "true" ]]; then
        if [[ -d "$HOME/.nvm" ]]; then
            print_success "NVM installed"
            if command -v node >/dev/null 2>&1; then
                echo "  ✓ Node.js: $(node --version)"
            else
                echo "  ✗ Node.js not available in PATH"
            fi
        else
            print_error "NVM not installed"
        fi
    else
        echo "Node.js installation: Skipped"
    fi
    
    # Check Python
    if [[ "$INSTALL_PYTHON" == "true" ]]; then
        if [[ -d "$HOME/.pyenv" ]]; then
            print_success "pyenv installed"
            if command -v python >/dev/null 2>&1; then
                echo "  ✓ Python: $(python --version)"
            else
                echo "  ✗ Python not available in PATH"
            fi
        else
            print_error "pyenv not installed"
        fi
    else
        echo "Python installation: Skipped"
    fi
    
    # Check Docker
    if [[ "$INSTALL_DOCKER" == "true" ]]; then
        if command -v docker >/dev/null 2>&1; then
            print_success "Docker installed"
            echo "  ✓ Docker: $(docker --version)"
            
            # Check Docker service
            if systemctl is-active --quiet docker; then
                echo "  ✓ Docker service running"
            else
                echo "  ✗ Docker service not running"
            fi
        else
            print_error "Docker not installed"
        fi
    else
        echo "Docker installation: Skipped"
    fi
    echo
}

main() {
    print_header
    
    check_config
    check_department
    check_users
    check_zsh_config
    check_development_tools
    
    echo -e "${BLUE}Status check completed${NC}"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi