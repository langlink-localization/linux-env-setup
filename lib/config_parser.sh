#!/bin/bash

# Configuration Parser Library
# Simple YAML parser for the configuration file

# Global variables to store configuration
declare -g DEPARTMENT_NAME=""
declare -g INSTALL_NODE=false
declare -g INSTALL_PYTHON=false
declare -g INSTALL_DOCKER=false
declare -g -a USERS=()
declare -g -A USER_ZSH=()
declare -g -A USER_DOCKER=()

parse_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found: $config_file"
        return 1
    fi
    
    # Reset arrays and variables
    unset USERS USER_ZSH USER_DOCKER
    declare -g -a USERS=()
    declare -g -A USER_ZSH=()
    declare -g -A USER_DOCKER=()
    declare -g DEPARTMENT_NAME=""
    declare -g INSTALL_NODE=false
    declare -g INSTALL_PYTHON=false
    declare -g INSTALL_DOCKER=false
    
    local in_users_section=false
    local in_system_section=false
    local current_user=""
    
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Check for main sections
        if [[ "$line" == "users:" ]]; then
            in_users_section=true
            in_system_section=false
            continue
        elif [[ "$line" == "system:" ]]; then
            in_users_section=false
            in_system_section=true
            continue
        fi
        
        # Parse department name
        if [[ "$line" =~ ^department_name:[[:space:]]*\"?([^\"]+)\"? ]]; then
            DEPARTMENT_NAME="${BASH_REMATCH[1]}"
            continue
        fi
        
        # Parse users section
        if [[ "$in_users_section" == true ]]; then
            if [[ "$line" =~ ^-[[:space:]]*name:[[:space:]]*\"?([^\"]+)\"? ]]; then
                current_user="${BASH_REMATCH[1]}"
                USERS+=("$current_user")
                USER_ZSH["$current_user"]=false
                USER_DOCKER["$current_user"]=false
            elif [[ "$line" =~ ^zsh:[[:space:]]*([a-zA-Z]+) ]] && [[ -n "$current_user" ]]; then
                USER_ZSH["$current_user"]="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^docker:[[:space:]]*([a-zA-Z]+) ]] && [[ -n "$current_user" ]]; then
                USER_DOCKER["$current_user"]="${BASH_REMATCH[1]}"
            fi
        fi
        
        # Parse system section
        if [[ "$in_system_section" == true ]]; then
            if [[ "$line" =~ ^install_node:[[:space:]]*([a-zA-Z]+) ]]; then
                INSTALL_NODE="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^install_python:[[:space:]]*([a-zA-Z]+) ]]; then
                INSTALL_PYTHON="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^install_docker:[[:space:]]*([a-zA-Z]+) ]]; then
                INSTALL_DOCKER="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$config_file"
}

# Function to get user list
get_users() {
    printf '%s\n' "${USERS[@]}"
}

# Function to check if user should have zsh
user_has_zsh() {
    local user="$1"
    [[ "${USER_ZSH[$user]}" == "true" ]]
}

# Function to check if user should have docker
user_has_docker() {
    local user="$1"
    [[ "${USER_DOCKER[$user]}" == "true" ]]
}

# Function to print configuration for debugging
print_config() {
    echo "Department: $DEPARTMENT_NAME"
    echo "Install Node: $INSTALL_NODE"
    echo "Install Python: $INSTALL_PYTHON"
    echo "Install Docker: $INSTALL_DOCKER"
    echo "Users:"
    for user in "${USERS[@]}"; do
        echo "  - $user (zsh: ${USER_ZSH[$user]}, docker: ${USER_DOCKER[$user]})"
    done
}