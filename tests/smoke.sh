#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_eq() {
    local actual="$1"
    local expected="$2"
    local message="$3"

    if [[ "$actual" != "$expected" ]]; then
        echo "Assertion failed: $message"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        exit 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Assertion failed: $message"
        echo "Expected to find: $needle"
        exit 1
    fi
}

run_syntax_checks() {
    local file
    local -a shell_files=()

    mapfile -t shell_files < <(find "$PROJECT_DIR" -path "$PROJECT_DIR/.git" -prune -o -type f -name '*.sh' -print | sort)

    for file in "${shell_files[@]}"; do
        bash -n "$file"
    done
}

run_config_smoke_tests() {
    local temp_root
    local legacy_config
    local default_config
    local override_config

    temp_root="$(mktemp -d)"
    export HOME="$temp_root/home"
    mkdir -p "$HOME"
    unset LINUX_ENV_SETUP_CONFIG

    source "$PROJECT_DIR/lib/config_parser.sh"

    default_config="$HOME/.linux-env-setup.yaml"
    legacy_config="$HOME/.env-config.yaml"
    override_config="$temp_root/custom-config.yaml"

    assert_eq "$(default_config_file_path)" "$default_config" "default config path should be repo-specific"
    assert_eq "$(resolve_config_file_path)" "$default_config" "new config path should be preferred when nothing exists"

    cat > "$legacy_config" <<'EOF'
department_name: "legacy-workspace"
users:
  - name: "alice"
    zsh: true
    docker: false

system:
  install_node: true
  install_python: false
  install_docker: true
  install_tailscale: false
EOF

    assert_eq "$(resolve_config_file_path)" "$legacy_config" "legacy config should still be detected"
    parse_config "$legacy_config"
    assert_eq "$WORKSPACE_NAME" "legacy-workspace" "legacy department_name should map to workspace name"
    assert_eq "$DEPARTMENT_NAME" "legacy-workspace" "legacy department_name should preserve compatibility"
    assert_eq "${USERS[0]}" "alice" "legacy config should parse users"
    assert_eq "${USER_ZSH[alice]}" "true" "legacy config should parse zsh preference"
    assert_eq "${USER_DOCKER[alice]}" "false" "legacy config should parse docker preference"

    cat > "$default_config" <<'EOF'
workspace_name: "modern-workspace"
users:
  - name: "bob"
    zsh: false
    docker: true

system:
  install_node: false
  install_python: true
  install_docker: false
  install_tailscale: true
EOF

    assert_eq "$(resolve_config_file_path)" "$default_config" "new config should win when both files exist"
    parse_config "$default_config"
    assert_eq "$WORKSPACE_NAME" "modern-workspace" "new workspace_name should parse"
    assert_eq "$DEPARTMENT_NAME" "modern-workspace" "new workspace_name should keep compatibility alias"
    assert_eq "${USERS[0]}" "bob" "new config should parse users"
    assert_eq "${USER_ZSH[bob]}" "false" "new config should parse zsh preference"
    assert_eq "${USER_DOCKER[bob]}" "true" "new config should parse docker preference"

    cat > "$override_config" <<'EOF'
workspace_name: "override-workspace"
users:
  - name: "carol"
    zsh: true
    docker: true

system:
  install_node: true
  install_python: true
  install_docker: false
  install_tailscale: false
EOF

    export LINUX_ENV_SETUP_CONFIG="$override_config"
    assert_eq "$(default_config_file_path)" "$override_config" "env override should become the default config path"
    assert_eq "$(resolve_config_file_path)" "$override_config" "env override should win over discovered configs"
    parse_config "$override_config"
    assert_eq "$WORKSPACE_NAME" "override-workspace" "override config should parse workspace name"
    assert_eq "${USERS[0]}" "carol" "override config should parse users"

    unset LINUX_ENV_SETUP_CONFIG
    rm -rf "$temp_root"
}

run_tailscale_helper_tests() {
    source "$PROJECT_DIR/modules/install-tailscale.sh"

    assert_eq "$(tailscale_apt_repo_family ubuntu)" "ubuntu" "Ubuntu should map to the Ubuntu repo family"
    assert_eq "$(tailscale_apt_repo_family debian)" "debian" "Debian should map to the Debian repo family"
    assert_eq "$(tailscale_apt_repo_url debian bookworm tailscale-keyring.list)" "https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list" "Debian repo URL should use the Debian path"
    assert_eq "$(tailscale_apt_repo_url ubuntu noble noarmor.gpg)" "https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg" "Ubuntu repo URL should use the Ubuntu path"
    assert_eq "$(tailscale_rpm_repo_url fedora)" "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" "Fedora should keep the Fedora repo URL"
}

run_zsh_helper_tests() {
    local temp_root
    local managed_file
    local legacy_file
    local custom_file
    local rendered

    temp_root="$(mktemp -d)"
    managed_file="$temp_root/managed.zshrc"
    legacy_file="$temp_root/legacy.zshrc"
    custom_file="$temp_root/custom.zshrc"

    source "$PROJECT_DIR/modules/install-zsh.sh"

    INSTALL_TAILSCALE=true
    rendered="$(render_managed_zshrc)"
    assert_contains "$rendered" "$MANAGED_ZSHRC_MARKER" "Managed renderer should include the managed marker"
    assert_contains "$rendered" 'alias ts="sudo tailscale"' "Managed renderer should include Tailscale aliases when enabled"

    INSTALL_TAILSCALE=false
    rendered="$(render_managed_zshrc)"
    assert_contains "$rendered" "alias workspace='cd ~/workspace" "Managed renderer should include workspace aliases"

    printf '%s\n' "$rendered" > "$managed_file"
    cat > "$legacy_file" <<'EOF'
# Enable Powerlevel10k instant prompt
# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
# Git aliases
alias gs='git status'
alias workspace='cd ~/workspace 2>/dev/null || echo "Workspace not found"'
newproject() {
    echo "legacy"
}
EOF
    cat > "$custom_file" <<'EOF'
# my custom zshrc
export PATH="$HOME/bin:$PATH"
EOF

    is_managed_zshrc "$managed_file"
    is_legacy_generated_zshrc "$legacy_file"
    if is_managed_zshrc "$custom_file"; then
        echo "Assertion failed: custom zshrc should not be treated as managed"
        exit 1
    fi
    if is_legacy_generated_zshrc "$custom_file"; then
        echo "Assertion failed: custom zshrc should not be treated as legacy tool-generated"
        exit 1
    fi

    rm -rf "$temp_root"
}

main() {
    run_syntax_checks
    run_config_smoke_tests
    run_tailscale_helper_tests
    run_zsh_helper_tests
    echo "Smoke tests passed"
}

main "$@"
