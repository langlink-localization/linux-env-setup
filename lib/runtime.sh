#!/bin/bash

# Runtime helpers shared across scripts.

config_home_dir() {
    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        getent passwd "$SUDO_USER" | cut -d: -f6
        return 0
    fi

    printf '%s\n' "$HOME"
}

default_config_file_path() {
    if [[ -n "${LINUX_ENV_SETUP_CONFIG:-}" ]]; then
        printf '%s\n' "$LINUX_ENV_SETUP_CONFIG"
        return 0
    fi

    printf '%s\n' "$(config_home_dir)/.linux-env-setup.yaml"
}

legacy_config_file_path() {
    printf '%s\n' "$(config_home_dir)/.env-config.yaml"
}

resolve_config_file_path() {
    if [[ -n "${LINUX_ENV_SETUP_CONFIG:-}" ]]; then
        printf '%s\n' "$LINUX_ENV_SETUP_CONFIG"
        return 0
    fi

    local default_config
    local legacy_config

    default_config="$(default_config_file_path)"
    legacy_config="$(legacy_config_file_path)"

    if [[ -f "$default_config" ]]; then
        printf '%s\n' "$default_config"
    elif [[ -f "$legacy_config" ]]; then
        printf '%s\n' "$legacy_config"
    else
        printf '%s\n' "$default_config"
    fi
}
