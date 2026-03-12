# Linux Environment Setup

`linux-env-setup` bootstraps a shared Linux development workspace on a dedicated machine. It creates a team workspace under `/opt/<workspace-name>`, provisions user accounts, and optionally installs Docker, Tailscale, Zsh, Node.js, and Python through an interactive shell-based workflow.

It is designed for small teams, lab machines, and fresh Linux hosts where you want one repeatable setup flow without introducing a heavier configuration-management stack.

## Features

- Interactive setup for workspace name, users, shells, and optional services
- Shared workspace layout under `/opt/<workspace-name>`
- User creation with per-user shell preferences and Docker group membership
- Optional Docker and Tailscale installation
- Optional Node.js and Python toolchains for the operator account running `./install.sh`
- Zsh setup with Oh My Zsh, Powerlevel10k, and common aliases
- Root-only storage for generated initial credentials
- Manifest-based uninstall guardrails for managed users and workspace resources

## Scope

This project is a good fit when you want to prepare:

- a new Linux development server
- a shared team workstation
- a sandbox or lab machine with multiple named users

It is not a full replacement for Ansible, Puppet, or host fleet management.

## Quick Start

### Recommended: clone, review, then run

```bash
git clone https://github.com/langlink-localization/linux-env-setup.git
cd linux-env-setup

./setup.sh
./install.sh
```

### New server bootstrap

Use bootstrap when you start from a fresh host and have root access. It creates an admin user, enables SSH, and clones the repository for that user.

```bash
curl -fsSL https://raw.githubusercontent.com/langlink-localization/linux-env-setup/master/bootstrap.sh | sudo bash
```

With a custom username:

```bash
curl -fsSL https://raw.githubusercontent.com/langlink-localization/linux-env-setup/master/bootstrap.sh | sudo bash -s -- devadmin
```

To bootstrap from a fork or another mirror, override the clone URL:

```bash
curl -fsSL https://raw.githubusercontent.com/langlink-localization/linux-env-setup/master/bootstrap.sh | \
  sudo env LINUX_ENV_SETUP_REPO_URL=https://github.com/<owner>/<repo>.git bash
```

## Configuration

The preferred config file is:

```text
~/.linux-env-setup.yaml
```

Legacy configs at `~/.env-config.yaml` are still read for backward compatibility. You can also override the path explicitly:

```bash
LINUX_ENV_SETUP_CONFIG=/path/to/custom-config.yaml ./install.sh
```

Example config:

```yaml
workspace_name: "eng-team"
users:
  - name: "alice"
    zsh: true
    docker: true
  - name: "bob"
    zsh: false
    docker: false
system:
  install_node: true
  install_python: true
  install_docker: true
  install_tailscale: false
```

## What Gets Installed

### Shared machine setup

- base packages such as `curl`, `wget`, `git`, `vim`, and build tools
- Docker, if selected
- Tailscale, if selected
- a shared workspace under `/opt/<workspace-name>`

### Managed user setup

- user accounts
- optional Zsh configuration
- optional Docker group membership
- `~/workspace` symlink to the shared workspace

### Operator account setup

The user running `./install.sh` can also install optional personal toolchains:

- Node.js via `nvm`
- Python via `pyenv`
- Hack Nerd Font in `~/.local/share/fonts`

These are user-scoped installs, not machine-wide package-manager installs.

## Workspace Layout

```text
/opt/<workspace-name>/
├── projects/
├── shared/
├── docs/
├── scripts/
├── archives/
├── workspace-info.txt
└── user-passwords.txt
```

## Commands

```bash
./setup.sh
./install.sh
./status.sh
sudo ./show-passwords.sh
./uninstall.sh

make setup
make install
make status
make passwords
make uninstall
make test
```

## Security Notes

- Bootstrap adds the created admin user to `sudo` or `wheel`; it does not grant passwordless sudo by default.
- Generated user credentials are stored in `/opt/<workspace-name>/user-passwords.txt` with root-only permissions.
- Newly created users are forced to change their password on first login when `chage` is available.
- `show-passwords.sh` is intended to be run with `sudo` so the credentials file does not need to be group-readable.
- Bootstrap will ask before replacing an existing `~/linux-env-setup` checkout.

## Tailscale

If Tailscale is installed, authenticate after installation:

```bash
sudo tailscale up
```

Useful aliases added for managed users:

```bash
ts
tsstatus
tsip
tsping <device>
tsup
tsdown
```

## Uninstall Behavior

`./uninstall.sh` only removes resources recorded in the install manifest when available:

- users created by this tool
- workspace directory created by this tool
- team group created by this tool
- local config files
- optional operator-local `nvm` and `pyenv` directories

Machine-wide packages such as Docker are left in place for manual review.

## Validation

Run the local smoke checks before publishing changes:

```bash
make test
```

This currently covers:

- `bash -n` syntax checks for project shell scripts
- config path resolution
- parser compatibility for both `workspace_name` and legacy `department_name`

## License

MIT
