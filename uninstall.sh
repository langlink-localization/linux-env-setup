#!/bin/bash

# Uninstall Script
# Removes the Linux environment setup

set -eo pipefail

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

declare -a CREATED_USERS=()
WORKSPACE_DIRECTORY_CREATED=false
TEAM_GROUP_CREATED=false
CONFIG_FILE=""
MANIFEST_FILE=""

manifest_path() {
    if [[ -z "$DEPARTMENT_NAME" ]]; then
        return 0
    fi

    printf '/opt/%s/.linux-env-setup-manifest\n' "$DEPARTMENT_NAME"
}

load_install_state() {
    CONFIG_FILE="$(resolve_config_file_path)"

    if [[ -f "$CONFIG_FILE" ]]; then
        parse_config "$CONFIG_FILE"
    else
        print_warning "Configuration file not found. Limited uninstall available."
    fi

    MANIFEST_FILE="$(manifest_path)"
    if [[ -n "$MANIFEST_FILE" && -f "$MANIFEST_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$MANIFEST_FILE"
    fi
}

confirm_uninstall() {
    echo -e "${YELLOW}⚠️  WARNING: This will remove the managed workspace resources recorded by this tool.${NC}"
    echo
    
    if [[ -f "$MANIFEST_FILE" ]]; then
        echo "This will remove:"
        if [[ "$WORKSPACE_DIRECTORY_CREATED" == "true" ]]; then
            echo "• Workspace directory: /opt/$DEPARTMENT_NAME"
        fi
        if [[ "$TEAM_GROUP_CREATED" == "true" ]]; then
            echo "• Team group: $DEPARTMENT_NAME-team"
        fi
        if [[ ${#CREATED_USERS[@]} -gt 0 ]]; then
            echo "• Managed users: ${CREATED_USERS[*]}"
        fi
        echo "• Saved configuration files"
        echo "• Operator-local NVM/pyenv tools (optional)"
        echo
    else
        echo "No install manifest was found."
        echo "This run will only remove configuration files and optional operator-local toolchains."
        echo "User accounts, shared groups, and workspace directories will be left untouched."
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

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_warning "Install manifest not found; skipping user removal"
        return 0
    fi

    if [[ ${#CREATED_USERS[@]} -eq 0 ]]; then
        print_warning "No managed users recorded in manifest"
        return 0
    fi

    for user in "${CREATED_USERS[@]}"; do
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
    echo -e "${BLUE}🏢 Removing workspace structure...${NC}"

    if [[ ! -f "$MANIFEST_FILE" ]]; then
        print_warning "Install manifest not found; skipping workspace removal"
        return 0
    fi

    if [[ -n "$DEPARTMENT_NAME" ]]; then
        # Remove workspace directory only if this tool created it
        if [[ "$WORKSPACE_DIRECTORY_CREATED" == "true" && -d "/opt/$DEPARTMENT_NAME" ]]; then
            sudo rm -rf "/opt/$DEPARTMENT_NAME"
            print_success "Removed workspace directory: /opt/$DEPARTMENT_NAME"
        else
            print_warning "Workspace directory retained"
        fi
        
        # Remove team group only if this tool created it
        if [[ "$TEAM_GROUP_CREATED" == "true" ]] && getent group "$DEPARTMENT_NAME-team" >/dev/null 2>&1; then
            sudo groupdel "$DEPARTMENT_NAME-team"
            print_success "Removed team group: $DEPARTMENT_NAME-team"
        else
            print_warning "Team group retained"
        fi
    fi
}

remove_manifest() {
    if [[ -n "$MANIFEST_FILE" && -f "$MANIFEST_FILE" ]]; then
        sudo rm -f "$MANIFEST_FILE"
        print_success "Removed install manifest: $MANIFEST_FILE"
    fi
}

remove_docker() {
    echo -e "${BLUE}🐳 Shared system packages${NC}"
    echo "Docker and other machine-wide packages are not removed automatically."
    echo "Review them manually if this machine is dedicated to this workspace."
}

remove_config() {
    echo -e "${BLUE}📋 Removing configuration files...${NC}"

    if [[ -n "${LINUX_ENV_SETUP_CONFIG:-}" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            rm "$CONFIG_FILE"
            print_success "Removed configuration file: $CONFIG_FILE"
        else
            print_warning "Configuration file not found"
        fi
        return 0
    fi

    local default_config
    local legacy_config

    default_config="$(default_config_file_path)"
    legacy_config="$(legacy_config_file_path)"

    if [[ -f "$default_config" ]]; then
        rm "$default_config"
        print_success "Removed configuration file: $default_config"
    fi

    if [[ -f "$legacy_config" ]]; then
        rm "$legacy_config"
        print_success "Removed legacy configuration file: $legacy_config"
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
    
    load_install_state
    
    confirm_uninstall
    
    remove_users
    remove_department
    remove_manifest
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
