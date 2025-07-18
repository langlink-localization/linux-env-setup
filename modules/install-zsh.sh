#!/bin/bash

# Zsh Configuration Module
# Installs and configures Zsh with Oh My Zsh and Powerlevel10k

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

# Configure Zsh for a specific user
configure_zsh_for_user() {
    local user="$1"
    local user_home="/home/$user"
    
    echo -e "${BLUE}🐚 Configuring Zsh for $user...${NC}"
    
    # Check if user exists
    if ! id "$user" &>/dev/null; then
        print_warning "User $user does not exist, skipping"
        return 0
    fi
    
    # Install Oh My Zsh for the user
    if [[ ! -d "$user_home/.oh-my-zsh" ]]; then
        sudo -u "$user" bash -c "cd '$user_home' && sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"
        print_success "Oh My Zsh installed for $user"
    else
        print_warning "Oh My Zsh already installed for $user"
    fi
    
    # Install Powerlevel10k theme
    if [[ ! -d "$user_home/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        sudo -u "$user" bash -c "cd '$user_home' && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git '$user_home/.oh-my-zsh/custom/themes/powerlevel10k'"
        print_success "Powerlevel10k installed for $user"
    else
        print_warning "Powerlevel10k already installed for $user"
    fi
    
    # Install zsh plugins
    local plugins_dir="$user_home/.oh-my-zsh/custom/plugins"
    
    if [[ ! -d "$plugins_dir/zsh-autosuggestions" ]]; then
        sudo -u "$user" bash -c "cd '$user_home' && git clone https://github.com/zsh-users/zsh-autosuggestions '$plugins_dir/zsh-autosuggestions'"
        print_success "zsh-autosuggestions installed for $user"
    fi
    
    if [[ ! -d "$plugins_dir/zsh-syntax-highlighting" ]]; then
        sudo -u "$user" bash -c "cd '$user_home' && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git '$plugins_dir/zsh-syntax-highlighting'"
        print_success "zsh-syntax-highlighting installed for $user"
    fi
    
    # Create .zshrc for the user
    create_zshrc_for_user "$user"
    
    print_success "Zsh configuration completed for $user"
}

# Create .zshrc configuration file
create_zshrc_for_user() {
    local user="$1"
    local user_home="/home/$user"
    
    sudo -u "$user" tee "$user_home/.zshrc" > /dev/null << EOF
# Enable Powerlevel10k instant prompt
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

# Oh My Zsh configuration
export ZSH="\$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
    docker
    docker-compose
    npm
    node
    python
    pip
    sudo
    history
)

source \$ZSH/oh-my-zsh.sh

# Environment variables
export EDITOR='vim'
export LANG=en_US.UTF-8

# NVM configuration
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

# pyenv configuration
export PYENV_ROOT="\$HOME/.pyenv"
export PATH="\$PYENV_ROOT/bin:\$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "\$(pyenv init -)"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'

# Docker aliases
alias dps='docker ps'
alias dimg='docker images'
alias dcp='docker compose'
alias dcup='docker compose up'
alias dcdown='docker compose down'
alias dcbuild='docker compose build'

# Department workspace aliases
alias workspace='cd ~/workspace 2>/dev/null || echo "Workspace not found"'
alias projects='cd ~/workspace/projects 2>/dev/null || echo "Projects directory not found"'

# Work functions
newproject() {
    if [[ -z "\$1" ]]; then
        echo "Usage: newproject <project_name>"
        return 1
    fi
    
    local project_dir="\$HOME/workspace/projects/\$1"
    mkdir -p "\$project_dir"
    cd "\$project_dir"
    echo "Project directory created: \$project_dir"
}

# Powerlevel10k configuration
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
    
    # Set proper ownership
    sudo chown "$user:$user" "$user_home/.zshrc"
    
    print_success ".zshrc created for $user"
}

main() {
    # Parse configuration
    parse_config "$HOME/.env-config.yaml"
    
    echo -e "${BLUE}🐚 Configuring Zsh for users...${NC}"
    
    local zsh_users_count=0
    
    for user in "${USERS[@]}"; do
        if user_has_zsh "$user"; then
            configure_zsh_for_user "$user"
            ((zsh_users_count++))
        fi
    done
    
    if [[ $zsh_users_count -eq 0 ]]; then
        echo -e "${BLUE}⏭️  No users configured for Zsh${NC}"
    else
        print_success "Zsh configuration completed for $zsh_users_count users"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi