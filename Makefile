# Linux Environment Setup Makefile

.PHONY: help setup install status uninstall clean test

# Default target
help:
	@echo "Linux Environment Setup - Available Commands:"
	@echo ""
	@echo "  make setup      - Run interactive configuration setup"
	@echo "  make install    - Install the environment based on configuration"
	@echo "  make status     - Check installation status"
	@echo "  make uninstall  - Remove the installation"
	@echo "  make clean      - Remove configuration files"
	@echo "  make test       - Run basic tests"
	@echo "  make all        - Setup and install in one command"
	@echo ""
	@echo "Bootstrap commands (run as root):"
	@echo "  sudo make bootstrap                    - Bootstrap with default user"
	@echo "  sudo make bootstrap USER=myuser        - Bootstrap with custom user"
	@echo "  sudo make bootstrap USER=myuser PASS=mypass - Bootstrap with custom user and password"
	@echo ""

# Setup configuration
setup:
	@echo "Running interactive setup..."
	@chmod +x setup.sh
	@./setup.sh

# Install environment
install:
	@echo "Installing environment..."
	@chmod +x install.sh
	@./install.sh

# Check status
status:
	@echo "Checking installation status..."
	@chmod +x status.sh
	@./status.sh

# Uninstall
uninstall:
	@echo "Uninstalling environment..."
	@chmod +x uninstall.sh
	@./uninstall.sh

# Clean configuration
clean:
	@echo "Cleaning configuration files..."
	@rm -f ~/.env-config.yaml
	@echo "Configuration files removed"

# Test installation
test:
	@echo "Running basic tests..."
	@chmod +x lib/config_parser.sh
	@chmod +x modules/*.sh
	@echo "Scripts are executable"
	@if [ -f ~/.env-config.yaml ]; then \
		echo "✅ Configuration file exists"; \
	else \
		echo "❌ Configuration file missing - run 'make setup' first"; \
	fi

# Setup and install in one command
all: setup install

# Bootstrap for new servers (requires root)
bootstrap:
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "Error: Bootstrap must be run as root"; \
		echo "Usage: sudo make bootstrap [USER=username] [PASS=password]"; \
		exit 1; \
	fi
	@chmod +x bootstrap.sh
	@./bootstrap.sh $(USER) $(PASS)

# Make all scripts executable
executable:
	@echo "Making all scripts executable..."
	@chmod +x *.sh
	@chmod +x lib/*.sh
	@chmod +x modules/*.sh
	@echo "All scripts are now executable"