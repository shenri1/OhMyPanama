# OhMyPanama

**A modern, opinionated Fedora Linux setup automation tool for developers**

OhMyPanama is a system configuration and package management automation tool designed to transform a fresh Fedora installation into a fully-configured development environment with your favorite tools, themes, and settings.

---

## ✨ Features

- 🚀 **One-command installation** - Get your perfect setup in minutes
- 📦 **Multi-source package management** - DNF, Flatpak, COPR, Curl installers
- 🎨 **Custom theming** - Beautiful, consistent terminal theme (btop, alacritty, eza)
- 🛠️ **Developer-focused** - Pre-configured development tools and languages
- 🔒 **Security hardened** - UFW firewall, secure defaults
- 🎯 **Modular design** - Easy to customize and extend

---

## 🚦 Quick Start

### Prerequisites

- Fresh Fedora installation (tested on Fedora 42+)
- Regular user account with sudo privileges
- Internet connection

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/OhMyPanama.git
cd OhMyPanama

# Make scripts executable
chmod +x install.sh

# Run the installer
./install.sh
```

The script will:
1. Verify your system (Fedora check)
2. Add RPM Fusion repositories
3. Install and configure packages
4. Set up your shell environment (zsh + oh-my-zsh)
5. Apply security configurations
6. Install themes and fonts

### Post-Installation

**Reboot your system to apply all changes:**
```bash
sudo reboot
```

---

## 🗂️ Project Structure

```
OhMyPanama/
├── install.sh                      # Main installation script
├── ohmypanama.sh                   # Configuration orchestrator
├── config/                         # Configuration files
│   ├── btop/btop.conf             # System monitor config
│   └── opencode/opencode.json     # OpenCode config
├── install/
│   ├── packages/
│   │   ├── packages.sh            # Package installation logic
│   │   └── lists/
│   │       ├── dnf.list          # DNF packages
│   │       ├── flatpak.list      # Flatpak apps
│   │       ├── copr.list         # COPR repositories
│   │       ├── curl.list         # Curl installers
│   │       └── rpm.list          # Direct RPM downloads
│   ├── config/
│   │   ├── system.sh             # System-wide configurations
│   │   └── kde.sh                # KDE-specific settings
│   └── finalization/
│       └── cleanup.sh            # Post-install cleanup
├── themes/
│   └── ohmypanama/               # Custom theme files
│       ├── alacritty.toml
│       ├── btop.theme
│       └── eza.yml
├── LICENSE                        # MIT License
└── README.md                      # This file
```

---

## 🎨 Customization

### Adding Packages

Edit the appropriate list file in `install/packages/lists/`:

**DNF packages** (`dnf.list`):
```bash
package-name
another-package
```

**Flatpak apps** (`flatpak.list`):
```bash
com.example.App
```

**COPR repositories** (`copr.list`):
```bash
repo-owner/repo-name | package1 package2
```

**Curl installers** (`curl.list`):
```bash
# Format: Name | Check Command | URL | Install Command
Name | command -v name | https://example.com/install.sh | sh
```

---

## 🔧 Advanced Options

### Skip Uninstall Prompt
```bash
./install.sh --no-uninstall
```

### Run Individual Modules
```bash
# Only install packages
source install/packages/packages.sh

# Only configure system
source install/config/system.sh
```

---

## 🛡️ Security Features

- UFW firewall enabled with secure defaults
- SSH access allowed (configurable)
- Replaces firewalld with UFW
- System hardening through package selection

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request**

### Areas for Contribution
- [ ] Create uninstall script
- [ ] Add update mechanism
- [ ] More theme options
- [ ] Better error handling and logging

---

## 📋 TODO

- [ ] Complete KDE configuration module
- [ ] Add package removal/bloatware cleanup
- [ ] Implement update checker
- [ ] Add logging system
- [ ] Create system restore point before installation
- [ ] Add interactive mode for package selection
- [ ] Multi-language support

---

## 🙏 Acknowledgments

Inspired by:
- [ohmydebn](https://github.com/dougburks/ohmydebn) - Debian automation
- [omarchy](https://github.com/basecamp/omarchy) - Arch Linux setup

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/yourusername/OhMyPanama/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/OhMyPanama/discussions)

---

## ⚠️ Disclaimer

This script makes significant changes to your system. While tested, **always backup your important data** before running system automation scripts. Use at your own risk.

---

<p align="center">Made with ❤️ by Silas Henrique</p>
<p align="center">🇧🇷 Brazil</p>
