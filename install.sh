#!/bin/bash

# Dotfiles installer
# Creates symlinks from dotfiles to home directory

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Backup existing configs
backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "Backing up existing $dest"
        mv "$dest" "$backup_dir/"
    fi

    echo "Linking $src -> $dest"
    ln -sf "$src" "$dest"
}

# Link root dotfiles
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Link .config files
mkdir -p "$HOME/.config"
link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
link_file "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
link_file "$DOTFILES_DIR/.config/yabai" "$HOME/.config/yabai"
link_file "$DOTFILES_DIR/.config/skhd" "$HOME/.config/skhd"
link_file "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

echo ""
echo "Done! Backups saved to: $backup_dir"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Open nvim and run :Lazy to install plugins"
echo "  3. Restart yabai/skhd if needed: yabai --restart-service && skhd --restart-service"
