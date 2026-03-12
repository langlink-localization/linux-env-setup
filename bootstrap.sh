#!/bin/bash

# Bootstrap script for new servers (run as root)
# This script creates an admin user and prepares the system for setup

set -eo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}    Linux Environment Setup Bootstrap${NC}"
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

repo_url_from_script_source() {
    local script_source="${1:-}"
    local script_dir

    if [[ -z "$script_source" || "$script_source" != */* || ! -f "$script_source" ]]; then
        return 1
    fi

    script_dir="$(cd "$(dirname "$script_source")" && pwd)"

    git -C "$script_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
    git -C "$script_dir" config --get remote.origin.url >/dev/null 2>&1 || return 1
    git -C "$script_dir" config --get remote.origin.url
}

resolve_repo_url() {
    local repo_url

    if [[ -n "${LINUX_ENV_SETUP_REPO_URL:-}" ]]; then
        printf '%s\n' "$LINUX_ENV_SETUP_REPO_URL"
    elif repo_url="$(repo_url_from_script_source "${BASH_SOURCE[0]:-}")"; then
        printf '%s\n' "$repo_url"
    else
        printf '%s\n' "https://github.com/langlink-localization/linux-env-setup.git"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This bootstrap script must be run as root."
        echo "Usage: sudo ./bootstrap.sh [username] [password]"
        exit 1
    fi
}

install_base_packages() {
    echo -e "${BLUE}📦 Installing base packages...${NC}"
    
    # Detect OS
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y curl wget git sudo vim openssh-server
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y curl wget git sudo vim openssh-server
            ;;
        fedora)
            dnf install -y curl wget git sudo vim openssh-server
            ;;
        *)
            print_warning "Unsupported OS: $OS. Continuing anyway..."
            ;;
    esac
    
    print_success "Base packages installed"
}

create_admin_user() {
    local username="${1:-devuser}"
    local password="${2:-$(openssl rand -base64 12)}"
    local password_set=false
    
    echo -e "${BLUE}👤 Creating admin user: $username...${NC}" >&2
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo -e "${YELLOW}⚠️  User $username already exists${NC}" >&2
        read -p "Do you want to continue with existing user? (y/N): " continue_choice
        case $continue_choice in
            [Yy]|[Yy][Ee][Ss]) 
                echo "Continuing with existing user..." >&2
                ;;
            *) 
                echo -e "${RED}❌ Please choose a different username or remove the existing user.${NC}" >&2
                exit 1
                ;;
        esac
    else
        # Create user
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        password_set=true
        echo -e "${GREEN}✅ User $username created${NC}" >&2
    fi
    
    # Add to an administrative group, but do not create passwordless sudo defaults.
    if command -v usermod >/dev/null 2>&1; then
        if getent group sudo >/dev/null 2>&1; then
            usermod -aG sudo "$username"
        elif getent group wheel >/dev/null 2>&1; then
            usermod -aG wheel "$username"
        else
            print_warning "No sudo or wheel group found. Verify administrative access manually." >&2
        fi
    fi
    
    echo -e "${GREEN}✅ Admin user added to an administrative group${NC}" >&2
    
    # Show password only when a new password was actually set.
    if [[ "$password_set" == true && -z "${2:-}" ]]; then
        echo -e "${YELLOW}Generated password for $username: $password${NC}" >&2
        echo -e "${YELLOW}Please save this password securely!${NC}" >&2
    fi
    
    # Output only the username to stdout for capture.
    echo "$username"
}

setup_ssh_access() {
    local username="$1"
    local admin_home="/home/$username"
    
    echo -e "${BLUE}🔐 Setting up SSH access...${NC}"
    
    # Enable SSH service
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Create SSH directory for admin user
    mkdir -p "$admin_home/.ssh"
    chmod 700 "$admin_home/.ssh"
    chown "$username:$username" "$admin_home/.ssh"
    
    print_success "SSH access configured"
}

download_project() {
    local username="$1"
    local admin_home="/home/$username"
    local project_dir="$admin_home/linux-env-setup"
    local repo_url
    local quoted_repo_url
    
    echo -e "${BLUE}📥 Downloading project...${NC}"

    repo_url="$(resolve_repo_url)"
    printf -v quoted_repo_url '%q' "$repo_url"
    
    # Confirm before replacing an existing checkout.
    if [[ -d "$project_dir" ]]; then
        print_warning "Existing project directory found at $project_dir"
        read -p "Replace it with a fresh clone? (y/N): " replace_choice
        case $replace_choice in
            [Yy]|[Yy][Ee][Ss])
                rm -rf "$project_dir"
                ;;
            *)
                print_warning "Keeping existing project directory"
                return 0
                ;;
        esac
    fi
    
    # Download project
    su - "$username" -c "cd && git clone $quoted_repo_url"
    
    # Make scripts executable
    chmod +x "$project_dir"/*.sh
    chmod +x "$project_dir/modules"/*.sh
    
    print_success "Project downloaded and prepared"
}

display_completion_message() {
    local username="$1"
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Bootstrap completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Switch to the admin user:"
    echo "   su - $username"
    echo
    echo "2. Go to the project directory:"
    echo "   cd ~/linux-env-setup"
    echo
    echo "3. Run the interactive setup:"
    echo "   ./setup.sh"
    echo
    echo "4. Install the environment:"
    echo "   ./install.sh"
    echo
    echo -e "${BLUE}Or run everything in one command:${NC}"
    echo "   su - $username -c 'cd ~/linux-env-setup && ./setup.sh && ./install.sh'"
    echo
}

main() {
    local username="${1:-devuser}"
    local password="${2:-}"

    print_header

    check_root
    install_base_packages

    # Create admin user and capture the resulting username.
    username=$(create_admin_user "$username" "$password")
    
    setup_ssh_access "$username"
    download_project "$username"
    display_completion_message "$username"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
