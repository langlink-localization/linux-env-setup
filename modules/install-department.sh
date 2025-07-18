#!/bin/bash

# Department Setup Module
# Creates department structure and user accounts

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

# Generate secure password
generate_password() {
    openssl rand -base64 16
}

# Create department directory structure
create_department_structure() {
    echo -e "${BLUE}🏢 Creating department structure...${NC}"
    
    sudo mkdir -p "/opt/$DEPARTMENT_NAME"/{projects,shared,docs,scripts,archives}
    sudo groupadd -f "$DEPARTMENT_NAME-team"
    
    print_success "Department structure created at /opt/$DEPARTMENT_NAME"
}

# Create user accounts
create_users() {
    echo -e "${BLUE}👥 Creating user accounts...${NC}"
    
    local password_file="/opt/$DEPARTMENT_NAME/user-passwords.txt"
    
    # Create password file with secure permissions
    sudo touch "$password_file"
    sudo chmod 600 "$password_file"
    
    for user in "${USERS[@]}"; do
        if ! id "$user" &>/dev/null; then
            # Generate secure password
            user_pass=$(generate_password)
            
            # Determine shell
            if user_has_zsh "$user"; then
                shell="/bin/zsh"
            else
                shell="/bin/bash"
            fi
            
            # Create user
            sudo useradd -m -s "$shell" -G "$DEPARTMENT_NAME-team" "$user"
            echo "$user:$user_pass" | sudo chpasswd
            
            # Save password to secure location
            echo "$user:$user_pass" | sudo tee -a "$password_file" > /dev/null
            
            print_success "Created user: $user"
        else
            print_warning "User $user already exists"
        fi
        
        # Create workspace link
        sudo ln -sf "/opt/$DEPARTMENT_NAME" "/home/$user/workspace" 2>/dev/null || true
    done
}

# Set directory permissions
set_permissions() {
    echo -e "${BLUE}🔐 Setting directory permissions...${NC}"
    
    # Set department directory permissions
    sudo chown -R "root:$DEPARTMENT_NAME-team" "/opt/$DEPARTMENT_NAME"
    sudo chmod -R 775 "/opt/$DEPARTMENT_NAME"
    
    # Secure the password file
    local password_file="/opt/$DEPARTMENT_NAME/user-passwords.txt"
    if [[ -f "$password_file" ]]; then
        sudo chown "root:$DEPARTMENT_NAME-team" "$password_file"
        sudo chmod 640 "$password_file"
    fi
    
    print_success "Directory permissions set"
}

# Create department info file
create_department_info() {
    echo -e "${BLUE}📄 Creating department information file...${NC}"
    
    local info_file="/opt/$DEPARTMENT_NAME/department-info.txt"
    
    cat > /tmp/department-info.txt << EOF
${DEPARTMENT_NAME^} Department Setup - $(date)
================================================

Department Directory: /opt/$DEPARTMENT_NAME
Team Group: $DEPARTMENT_NAME-team

Users Created:
EOF

    for user in "${USERS[@]}"; do
        echo "- $user" >> /tmp/department-info.txt
        if user_has_zsh "$user"; then
            echo "  - Shell: Zsh (with Oh My Zsh)" >> /tmp/department-info.txt
        else
            echo "  - Shell: Bash" >> /tmp/department-info.txt
        fi
        if user_has_docker "$user"; then
            echo "  - Docker: Yes" >> /tmp/department-info.txt
        else
            echo "  - Docker: No" >> /tmp/department-info.txt
        fi
    done
    
    cat >> /tmp/department-info.txt << EOF

Important Notes:
1. Please change default passwords immediately
2. Workspace directory: /opt/$DEPARTMENT_NAME
3. User workspace shortcut: ~/workspace
4. Passwords stored in: /opt/$DEPARTMENT_NAME/user-passwords.txt
EOF

    if [[ "$INSTALL_DOCKER" == "true" ]]; then
        echo "5. Users need to log out and back in for Docker permissions to take effect" >> /tmp/department-info.txt
    fi
    
    sudo mv /tmp/department-info.txt "$info_file"
    sudo chown "root:$DEPARTMENT_NAME-team" "$info_file"
    sudo chmod 644 "$info_file"
    
    print_success "Department info saved to: $info_file"
}

main() {
    # Parse configuration
    parse_config "$HOME/.env-config.yaml"
    
    create_department_structure
    create_users
    set_permissions
    create_department_info
    
    print_success "Department setup completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi