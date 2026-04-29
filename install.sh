#!/bin/bash

# Dotfiles installer
# Creates symlinks from dotfiles to home directory

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect OS
case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)
        if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
            OS="wsl"
        else
            OS="linux"
        fi
        ;;
    *) OS="unknown" ;;
esac

echo "Installing dotfiles from $DOTFILES_DIR (detected OS: $OS)"

# Backup existing configs
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -e "$src" ]; then
        echo "Skip: source $src not found"
        return
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Backing up existing $dest"
        mv "$dest" "$backup_dir/"
    fi

    echo "Linking $src -> $dest"
    ln -sf "$src" "$dest"
}

# Link root dotfiles (cross-platform)
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Link .config files (cross-platform)
mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

# macOS-only status bar + keyboard remapper
if [ "$OS" = "mac" ]; then
    link_file "$DOTFILES_DIR/.config/sketchybar" "$HOME/.config/sketchybar"
    mkdir -p "$HOME/.config/karabiner"
    link_file "$DOTFILES_DIR/.config/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
fi

echo ""
echo "Done! Backups saved to: $backup_dir"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Open nvim and run :Lazy to install plugins"
