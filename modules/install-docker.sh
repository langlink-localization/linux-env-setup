#!/bin/bash

# Docker Installation Module
# Installs Docker and adds users to docker group

set -e

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

# Install Docker
install_docker() {
    if [[ "$INSTALL_DOCKER" != "true" ]]; then
        echo -e "${BLUE}⏭️  Skipping Docker installation${NC}"
        return 0
    fi
    
    echo -e "${BLUE}🐳 Installing Docker...${NC}"
    
    # Check if Docker is already installed
    if command -v docker >/dev/null 2>&1; then
        print_warning "Docker already installed"
        return 0
    fi
    
    case $OS in
        ubuntu|debian)
            # Add Docker's official GPG key
            curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            
            # Add Docker repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Install Docker
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|rocky|almalinux)
            # Install Docker repository
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # Install Docker
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        fedora)
            # Install Docker repository
            sudo dnf install -y dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            
            # Install Docker
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            print_error "Unsupported OS for Docker installation: $OS"
            return 1
            ;;
    esac
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_success "Docker installed and started"
}

# Add users to Docker group
add_users_to_docker_group() {
    if [[ "$INSTALL_DOCKER" != "true" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}👥 Adding users to Docker group...${NC}"
    
    # Check if docker group exists
    if ! getent group docker > /dev/null 2>&1; then
        print_warning "Docker group not found, creating it"
        sudo groupadd docker
    fi
    
    for user in "${USERS[@]}"; do
        if user_has_docker "$user"; then
            # Check if user exists
            if id "$user" &>/dev/null; then
                sudo usermod -aG docker "$user"
                print_success "Added $user to docker group"
            else
                print_warning "User $user does not exist, skipping"
            fi
        fi
    done
}

# Test Docker installation
test_docker() {
    if [[ "$INSTALL_DOCKER" != "true" ]]; then
        return 0
    fi
    
    echo -e "${BLUE}🧪 Testing Docker installation...${NC}"
    
    if sudo docker run --rm hello-world >/dev/null 2>&1; then
        print_success "Docker test passed"
    else
        print_warning "Docker test failed, but installation may still be working"
    fi
}

main() {
    # Parse configuration
    parse_config "$HOME/.env-config.yaml"
    
    detect_os
    install_docker
    add_users_to_docker_group
    test_docker
    
    if [[ "$INSTALL_DOCKER" == "true" ]]; then
        print_success "Docker installation completed"
        echo -e "${YELLOW}Note: Users need to log out and back in for Docker group membership to take effect${NC}"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi