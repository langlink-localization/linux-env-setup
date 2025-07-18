# Linux Environment Setup

A modern, script-based Linux development environment setup tool that allows you to customize department structures, user accounts, and system configurations through an interactive interface.

## 🌟 Features

- **Interactive Setup**: Configure everything through a user-friendly Q&A interface
- **Script-Based**: Pure shell scripts without complex templating engines
- **Custom Department Structure**: Create your own department name and directory structure
- **Flexible User Management**: Add multiple users with individual configurations
- **Shell Selection**: Choose which users get Zsh with Oh My Zsh and Powerlevel10k
- **Docker Integration**: Selectively add users to Docker group
- **Tailscale VPN**: Optional zero-config VPN for secure remote access
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
- **Tailscale**: Zero-config VPN (if selected)

### For Zsh Users
- **Oh My Zsh**: Popular Zsh framework
- **Powerlevel10k**: Beautiful and fast prompt
- **Plugins**: autosuggestions, syntax highlighting, completions
- **Aliases**: Git, Docker, Tailscale, and system shortcuts
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
  install_tailscale: true
```

## 🛠️ Available Commands

```bash
# Main commands
./setup.sh         # Run interactive setup
./install.sh       # Install environment
./status.sh        # Check installation status
./show-passwords.sh # Show user passwords
./uninstall.sh     # Remove installation

# Or use make commands
make setup         # Run interactive setup
make install       # Install environment
make status        # Check installation status
make passwords     # Show user passwords
make uninstall     # Remove installation

# User shortcuts (after installation)
workspace          # Go to department workspace
projects           # Go to projects directory
newproject <name>  # Create new project
gs                 # Git status
dps                # Docker ps
ts                 # Tailscale command (if installed)
tsstatus           # Tailscale status (if installed)
```

## 🔒 Security Features

- **Secure Password Generation**: Random 16-character passwords
- **Proper Permissions**: Restricted access to sensitive files
- **Group-based Access**: Department team groups
- **Password Storage**: Secure location with limited access

## 🔑 Password Management

### Viewing User Passwords

After installation, user passwords are stored securely in:
```
/opt/your-department-name/user-passwords.txt
```

**Method 1: Using the script**
```bash
./show-passwords.sh
# or
make passwords
```

**Method 2: Direct file access**
```bash
sudo cat /opt/your-department-name/user-passwords.txt
```

### Changing Passwords

**Change your own password:**
```bash
passwd
```

**Change another user's password (requires sudo):**
```bash
sudo passwd username
```

### Security Recommendations

1. **Change default passwords immediately** after first login
2. Use strong, unique passwords for each account
3. Consider using SSH keys instead of passwords
4. Remove or secure the password file after initial setup:
   ```bash
   sudo rm /opt/your-department-name/user-passwords.txt
   ```

## 🔗 Tailscale VPN Integration

### What is Tailscale?
Tailscale is a zero-config VPN that creates a secure network between your devices using WireGuard technology. It's perfect for:
- Remote access to your servers
- Secure team collaboration
- Accessing development environments from anywhere

### Setup After Installation

**1. Connect to your Tailscale network:**
```bash
sudo tailscale up
```

**2. (Optional) Enable SSH access via Tailscale:**
```bash
sudo tailscale up --ssh
```

**3. (Optional) Enable subnet routes:**
```bash
sudo tailscale up --advertise-routes=192.168.1.0/24
```

### Useful Tailscale Commands

The installation adds convenient aliases for all users:

```bash
ts              # Tailscale command (sudo tailscale)
tsstatus        # Check Tailscale status
tsip            # Get your Tailscale IP
tsping <device> # Ping another device on your network
tsup            # Connect to Tailscale
tsdown          # Disconnect from Tailscale
```

### Getting Started with Tailscale

1. **Create a Tailscale account** at https://tailscale.com/
2. **Run the connection command**: `sudo tailscale up`
3. **Authenticate in your browser** when prompted
4. **Check your status**: `tsstatus`
5. **Get your IP**: `tsip`

### Benefits for Development Teams

- **Secure access** to development servers from anywhere
- **No port forwarding** or complex firewall rules needed
- **Access control** through the Tailscale admin panel
- **Automatic encryption** of all traffic
- **Works across different networks** (home, office, mobile)

## 📄 License

MIT License