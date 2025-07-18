#!/bin/bash

# Bootstrap script for new servers (run as root)
# This script creates an admin user and prepares the system for setup

set -e

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
    
    echo -e "${BLUE}👤 Creating admin user: $username...${NC}"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        print_warning "User $username already exists"
        read -p "Do you want to continue with existing user? (y/N): " continue_choice
        case $continue_choice in
            [Yy]|[Yy][Ee][Ss]) 
                echo "Continuing with existing user..."
                ;;
            *) 
                print_error "Please choose a different username or remove the existing user."
                exit 1
                ;;
        esac
    else
        # Create user
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd
        print_success "User $username created"
    fi
    
    # Add to sudo group
    if command -v usermod >/dev/null 2>&1; then
        usermod -aG sudo "$username" 2>/dev/null || usermod -aG wheel "$username" 2>/dev/null || true
    fi
    
    # Ensure sudo access
    if [[ ! -f "/etc/sudoers.d/$username" ]]; then
        echo "$username ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$username"
        chmod 440 "/etc/sudoers.d/$username"
    fi
    
    print_success "Admin user configured with sudo access"
    
    # Show password if generated
    if [[ -z "$2" ]]; then
        echo -e "${YELLOW}Generated password for $username: $password${NC}"
        echo -e "${YELLOW}Please save this password securely!${NC}"
    fi
    
    echo "$username:$password"
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
    
    echo -e "${BLUE}📥 Downloading project...${NC}"
    
    # Remove existing directory if present
    if [[ -d "$project_dir" ]]; then
        rm -rf "$project_dir"
    fi
    
    # Download project
    su - "$username" -c "cd && git clone https://github.com/langlink-localization/linux-env-setup.git"
    
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
    local password="$2"
    
    print_header
    
    check_root
    install_base_packages
    
    # Create admin user and capture credentials
    user_credentials=$(create_admin_user "$username" "$password")
    username=$(echo "$user_credentials" | cut -d: -f1)
    
    setup_ssh_access "$username"
    download_project "$username"
    display_completion_message "$username"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi