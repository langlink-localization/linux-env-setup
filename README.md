# Linux Environment Setup

A modern, script-based Linux development environment setup tool that allows you to customize department structures, user accounts, and system configurations through an interactive interface.

## 🌟 Features

- **Interactive Setup**: Configure everything through a user-friendly Q&A interface
- **Script-Based**: Pure shell scripts without complex templating engines
- **Custom Department Structure**: Create your own department name and directory structure
- **Flexible User Management**: Add multiple users with individual configurations
- **Shell Selection**: Choose which users get Zsh with Oh My Zsh and Powerlevel10k
- **Docker Integration**: Selectively add users to Docker group
- **Global Tools**: Install Node.js and Python globally for all users
- **Secure Setup**: Generate secure passwords and proper permissions
- **Cross-Platform**: Supports Ubuntu, Debian, CentOS, RHEL, Fedora, and derivatives

## 🚀 Quick Start

### Method 1: New Server (Root Access) - Recommended

```bash
# One-click deployment with default settings
curl -fsSL https://raw.githubusercontent.com/langlink-localization/linux-env-setup/master/bootstrap.sh | bash

# With custom username and password
curl -fsSL https://raw.githubusercontent.com/langlink-localization/linux-env-setup/master/bootstrap.sh | bash -s -- myuser mypassword
```

### Method 2: Existing User Setup

```bash
# Clone the repository
git clone https://github.com/langlink-localization/linux-env-setup.git
cd linux-env-setup

# Run interactive setup
./setup.sh

# Install the environment
./install.sh
```

### Method 3: Manual Steps

```bash
# 1. Clone repository
git clone https://github.com/langlink-localization/linux-env-setup.git
cd linux-env-setup

# 2. Run setup
chmod +x setup.sh
./setup.sh

# 3. Install environment
chmod +x install.sh
./install.sh
```

## 📖 What Gets Installed

### For All Users
- **Base Tools**: curl, wget, git, vim, build tools
- **Fonts**: Hack Nerd Font for terminal icons
- **Node.js**: Latest LTS version (if selected)
- **Python**: Latest stable version (if selected)
- **Docker**: Latest stable version (if selected)

### For Zsh Users
- **Oh My Zsh**: Popular Zsh framework
- **Powerlevel10k**: Beautiful and fast prompt
- **Plugins**: autosuggestions, syntax highlighting, completions
- **Aliases**: Git, Docker, and system shortcuts
- **Functions**: Project management utilities

### Directory Structure
```
/opt/your-department-name/
├── projects/          # Development projects
├── shared/           # Shared resources
├── docs/             # Documentation
├── scripts/          # Utility scripts
├── archives/         # Archive storage
├── department-info.txt    # Setup information
└── user-passwords.txt     # Initial passwords (secure)
```

## 🔧 Configuration

The setup creates a YAML configuration file that drives all installations:

```yaml
department_name: "tech-department"
users:
  - name: "alice"
    zsh: true
    docker: true
  - name: "bob"
    zsh: false
    docker: true
system:
  install_node: true
  install_python: true
  install_docker: true
```

## 🛠️ Available Commands

```bash
# Main commands
./setup.sh         # Run interactive setup
./install.sh       # Install environment
./status.sh        # Check installation status
./uninstall.sh     # Remove installation

# User shortcuts (after installation)
workspace          # Go to department workspace
projects           # Go to projects directory
newproject <name>  # Create new project
gs                 # Git status
dps                # Docker ps
```

## 🔒 Security Features

- **Secure Password Generation**: Random 16-character passwords
- **Proper Permissions**: Restricted access to sensitive files
- **Group-based Access**: Department team groups
- **Password Storage**: Secure location with limited access

## 📄 License

MIT License