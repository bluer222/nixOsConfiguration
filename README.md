# NixOS Configuration

This is a modular NixOS configuration organized for easy expansion and maintenance.

## What's New

✅ **Fully modularized** - No duplication in configuration.nix
✅ **All networking settings** in `modules/networking/core.nix`
✅ **Shell, audio, desktop** moved to separate focused modules
✅ **Duplicate packages removed** (e.g., cups no longer in utilities.nix)
✅ **Old files cleaned up** - apps.nix, boot.nix, home.nix, etc. deleted


## Directory Structure

```
nixos/
├── config/                    # Application configuration files (dotfiles)
│
├── modules/                   # System-level NixOS modules
│   ├── boot.nix              # Bootloader and kernel configuration
│   ├── gpu.nix               # GPU drivers (NVIDIA, Intel)
│   ├── hardware/
│   │   ├── power.nix         # Power management (TLP)
│   │   └── virtualisation.nix # QEMU, Docker, Waydroid
│   ├── system/
│   │   ├── core.nix          # Core system settings (Nix, security, locales, etc.)
│   │   ├── shell.nix         # Zsh shell configuration
│   │   ├── audio.nix         # PipeWire audio configuration
│   │   ├── desktop.nix       # KDE Plasma + Bluetooth + KDE Connect + Howdy
│   │   └── systemd.nix       # Systemd services and configuration
│   ├── networking/
│   │   ├── core.nix          # NetworkManager, firewall, TCP settings, hostname
│   │   ├── avahi.nix         # mDNS service discovery
│   │   └── nginx.nix         # Nginx web server
│   └── services/
│       ├── printing.nix      # CUPS printer services
│       └── vr.nix            # WiVRn VR streaming service
│
├── home/                      # Home Manager configuration
│   ├── home.nix              # Home Manager entry point
│   └── modules/
│       ├── user.nix          # User account and groups
│       ├── base.nix          # Base system packages and utilities
│       └── apps/             # Application-specific configurations
│           ├── gaming.nix      # Steam, Lutris, Godot, etc.
│           ├── multimedia.nix  # OBS, Audacity, GIMP, etc.
│           ├── development.nix # VSCode, Git, Java, etc.
│           ├── utilities.nix   # General utilities and tools
│           ├── security.nix    # Security tools (burpsuite, nmap, etc.)
│           └── desktops/
│               └── kde.nix    # KDE Plasma specific packages
│                              # (Ready to add hyprland.nix, gnome.nix, etc.)
│
├── configuration.nix         # Main system configuration (imports modules only)
├── flake.nix                # Flake configuration
├── hardware-configuration.nix # Hardware-specific config (auto-generated)
├── mcontrolcenter.nix       # Custom package build
└── README.md                # This file
```

## How to Add New Modules

### Adding a New System Service/Module

Create a new file in the appropriate `modules/` subdirectory:

```bash
# Example: Adding Nextcloud
cat > /etc/nixos/modules/services/nextcloud.nix << 'EOF'
{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    # ... configuration ...
  };
}
EOF
```

Then add the import to `configuration.nix`:
```nix
imports = [
  # ... existing imports ...
  ./modules/services/nextcloud.nix
];
```

### Adding a New Desktop Environment

Create a new file in `home/modules/apps/desktops/`:

```bash
# Example: Adding Hyprland support
cat > /etc/nixos/home/modules/apps/desktops/hyprland.nix << 'EOF'
{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    # ... configuration ...
  };
  
  home.packages = with pkgs; [
    waybar          # Status bar for Hyprland
    dunst           # Notifications
    # ... other Hyprland tools ...
  ];
}
EOF
```

Then add to `configuration.nix`:
```nix
imports = [
  # ... existing imports ...
  ./home/modules/apps/desktops/hyprland.nix
];
```

### Adding Application Packages

If you have a lot of custom packages for a specific domain, create a new file in `home/modules/apps/`:

```bash
# Example: Adding CAD tools
cat > /etc/nixos/home/modules/apps/cad.nix << 'EOF'
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    freecad
    kicad
    blender
    # ... other CAD tools ...
  ];
}
EOF
```

## Customizing Modules

All modules use standard NixOS module syntax and can be customized by:

1. **Editing the module directly** - Most modules are self-contained
2. **Environment variables** - Some packages respect environment variables
3. **Dotfiles in config/** - For application-specific configuration files

## Rebuilding

After making changes:

```bash
# Rebuild system
sudo nixos-rebuild switch --flake /etc/nixos#samm-desktop

# Or with nom for better output
sudo nixos-rebuild switch --flake /etc/nixos#samm-desktop | nom
```

## Key Organization Principles

- **Boot & Hardware**: All boot, kernel, GPU, and power management in `modules/`
- **Networking**: Network services and protocols grouped in `modules/networking/`
- **User Applications**: All user-facing apps organized in `home/modules/apps/`
- **Desktops**: Desktop environments as separate, independent modules
- **Services**: System services organized in `modules/services/`
- **Easy Addition**: New modules follow the same pattern, making it simple to add Hyprland, additional DEs, or more services

