# Installation

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

The installer supports Termux and common Linux package managers.

## Termux

```bash
pkg update
pkg install curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## Debian / Ubuntu

```bash
sudo apt update
sudo apt install curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

`bat` may be exposed as `batcat`; Terminal Explorer supports this automatically.

## Fedora / RHEL

```bash
sudo dnf install curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## Arch / Manjaro

```bash
sudo pacman -S curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## openSUSE

```bash
sudo zypper install curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## Alpine

```bash
sudo apk add bash curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## Void Linux

```bash
sudo xbps-install -S bash curl git
curl -fsSL https://raw.githubusercontent.com/baska-pro/terminal-explorer/main/install.sh | bash
```

## Clone

```bash
git clone https://github.com/baska-pro/terminal-explorer.git
cd terminal-explorer
./install.sh
```

## Verify

```bash
terminal-explorer --version
terminal-explorer --doctor
```

## PATH

Linux installs commands under:

```text
~/.local/bin
```

If it is not in PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
