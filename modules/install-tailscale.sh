#!/bin/bash

# Tailscale Installation Module
# Installs Tailscale VPN for secure networking

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

download_to_root_file() {
    local url="$1"
    local destination="$2"
    local mode="${3:-0644}"
    local temp_file

    temp_file="$(mktemp)"
    curl -fsSL "$url" -o "$temp_file"
    sudo install -D -m "$mode" "$temp_file" "$destination"
    rm -f "$temp_file"
}

tailscale_apt_repo_family() {
    local os_id="$1"

    case "$os_id" in
        ubuntu|debian)
            printf '%s\n' "$os_id"
            ;;
        *)
            return 1
            ;;
    esac
}

tailscale_apt_repo_url() {
    local family="$1"
    local codename="$2"
    local artifact="$3"

    printf 'https://pkgs.tailscale.com/stable/%s/%s.%s\n' "$family" "$codename" "$artifact"
}

tailscale_rpm_repo_url() {
    local os_id="$1"

    case "$os_id" in
        centos|rhel|rocky|almalinux)
            printf '%s\n' 'https://pkgs.tailscale.com/stable/centos/7/tailscale.repo'
            ;;
        fedora)
            printf '%s\n' 'https://pkgs.tailscale.com/stable/fedora/tailscale.repo'
            ;;
        *)
            return 1
            ;;
    esac
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

# Install Tailscale
install_tailscale() {
    if [[ "$INSTALL_TAILSCALE" != "true" ]]; then
        echo -e "${BLUE}⏭️  Skipping Tailscale installation${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🔗 Installing Tailscale...${NC}"
    
    # Check if Tailscale is already installed
    if command -v tailscale >/dev/null 2>&1; then
        print_warning "Tailscale already installed"
        return 0
    fi
    
    case $OS in
        ubuntu|debian)
            local family
            local codename

            family="$(tailscale_apt_repo_family "$OS")"
            codename="$(lsb_release -cs)"

            sudo mkdir -p --mode=0755 /usr/share/keyrings
            download_to_root_file \
                "$(tailscale_apt_repo_url "$family" "$codename" "noarmor.gpg")" \
                "/usr/share/keyrings/tailscale-archive-keyring.gpg"
            download_to_root_file \
                "$(tailscale_apt_repo_url "$family" "$codename" "tailscale-keyring.list")" \
                "/etc/apt/sources.list.d/tailscale.list"

            sudo apt-get update
            sudo apt-get install -y tailscale
            ;;
        centos|rhel|rocky|almalinux)
            download_to_root_file \
                "$(tailscale_rpm_repo_url "$OS")" \
                "/etc/yum.repos.d/tailscale.repo"
            sudo yum install -y tailscale
            ;;
        fedora)
            download_to_root_file \
                "$(tailscale_rpm_repo_url "$OS")" \
                "/etc/yum.repos.d/tailscale.repo"
            sudo dnf install -y tailscale
            ;;
        *)
            print_error "Unsupported OS for Tailscale installation: $OS"
            echo "Please visit https://tailscale.com/download for manual installation instructions"
            return 1
            ;;
    esac
    
    # Enable and start Tailscale service
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
    
    print_success "Tailscale installed and service started"
}

# Configure Tailscale
configure_tailscale() {
    if [[ "$INSTALL_TAILSCALE" != "true" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}⚙️  Configuring Tailscale...${NC}"
    
    # Check if already connected
    if sudo tailscale status >/dev/null 2>&1; then
        print_warning "Tailscale is already configured"
        echo "Current status:"
        sudo tailscale status
        return 0
    fi
    
    print_success "Tailscale is ready for authentication"
    
    echo
    echo -e "${BLUE}🔗 Next Steps for Tailscale Setup:${NC}"
    echo "1. Connect this device to your Tailscale network:"
    echo "   sudo tailscale up"
    echo
    echo "2. (Optional) Enable SSH access via Tailscale:"
    echo "   sudo tailscale up --ssh"
    echo
    echo "3. (Optional) Enable subnet routes if needed:"
    echo "   sudo tailscale up --advertise-routes=192.168.1.0/24"
    echo
    echo "4. Check status:"
    echo "   sudo tailscale status"
    echo
    echo "5. Get your device's Tailscale IP:"
    echo "   sudo tailscale ip"
    echo
    echo -e "${YELLOW}📝 Note: You'll need to authenticate with your Tailscale account${NC}"
    echo -e "${YELLOW}Visit https://tailscale.com/ to create an account if you don't have one${NC}"
}

# Add Tailscale configuration to user shells
add_tailscale_aliases() {
    if [[ "$INSTALL_TAILSCALE" != "true" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}🔧 Adding Tailscale aliases to user shells...${NC}"
    
    # Define aliases
    local aliases='
# Tailscale aliases
alias ts="sudo tailscale"
alias tsstatus="sudo tailscale status"
alias tsip="sudo tailscale ip"
alias tsping="sudo tailscale ping"
alias tsup="sudo tailscale up"
alias tsdown="sudo tailscale down"
'
    
    for user in "${USERS[@]}"; do
        local user_home="/home/$user"
        
        # Add to .bashrc for non-Zsh users or users keeping a custom .zshrc.
        if [[ -f "$user_home/.bashrc" ]]; then
            if ! grep -q "# Tailscale aliases" "$user_home/.bashrc"; then
                echo "$aliases" | sudo tee -a "$user_home/.bashrc" >/dev/null
                print_success "Added Tailscale aliases to $user's .bashrc"
            fi
        fi
    done
}

# Test Tailscale installation
test_tailscale() {
    if [[ "$INSTALL_TAILSCALE" != "true" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}🧪 Testing Tailscale installation...${NC}"
    
    if command -v tailscale >/dev/null 2>&1; then
        print_success "Tailscale command is available"
        echo "Tailscale version: $(tailscale version)"
    else
        print_error "Tailscale command not found"
        return 1
    fi
    
    if systemctl is-active --quiet tailscaled; then
        print_success "Tailscale service is running"
    else
        print_warning "Tailscale service is not running"
    fi
}

main() {
    # Parse configuration
    parse_config "$(resolve_config_file_path)"
    
    detect_os
    install_tailscale
    configure_tailscale
    add_tailscale_aliases
    test_tailscale
    
    if [[ "$INSTALL_TAILSCALE" == "true" ]]; then
        print_success "Tailscale installation completed"
        echo -e "${YELLOW}Don't forget to run 'sudo tailscale up' to connect to your network!${NC}"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
