# Dotfiles

Personal dotfiles for Fedora workstation with Hyprland desktop environment.

## What's inside

- **Hyprland** -- tiling Wayland compositor config (hyprland, hypridle, hyprlock)
- **AGS (Aylur's GTK Shell)** -- custom desktop shell (bar, notifications, OSD, overview)
- **Waybar** -- status bar config
- **Neovim** -- Lua-based config with plugins
- **Alacritty** -- terminal emulator
- **tmux** -- terminal multiplexer
- **Fish** -- shell config + functions
- **Bash** -- aliases, variables, custom scripts
- **Rofi** -- application launcher
- **Git** -- global ignore patterns
- **Various scripts** in `.local/bin/`

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/) for symlink management
- [just](https://github.com/casey/just) command runner (optional)
- Fedora 40+ (configs reference Fedora-specific paths)

## Installation

```bash
git clone https://github.com/nikromen/dotfiles ~/.dotfiles
cd ~/.dotfiles
stow -R . --target=$HOME
```

Or using just:

```bash
cd ~/.dotfiles
just stow
```

## Dry run

Preview what stow will do without making changes:

```bash
just stow-dry-run
```

## Uninstall

```bash
just unstow
```

## Notes

- Wallpapers are stored in Git LFS (install `git-lfs` before cloning)
- Configs are designed for my personal setup -- review before using
- Some scripts have hardcoded paths specific to my environment
