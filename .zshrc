# ============================================================================
# PATH CONFIGURATION
# ============================================================================

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# OpenCode
export PATH="$HOME/.opencode/bin:$PATH"

# OpenJDK
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# ============================================================================
# ZSH PLUGINS
# ============================================================================

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Autocomplete (Ghost text)
source ~/.zsh-autosuggestions/zsh-autosuggestions.zsh

# Note: This MUST be sourced after autosuggestions
source ~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Syntax Highlighting Colors (blacklotus theme)
ZSH_HIGHLIGHT_STYLES[command]='fg=#d500f9,bold'           # green
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#c2185b'          # red
ZSH_HIGHLIGHT_STYLES[alias]='fg=#c4a1ff'                  # fg_dim (light purple)
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ff4081,bold'           # hotpink
ZSH_HIGHLIGHT_STYLES[path]='fg=#9c27b0'                   # purple
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#d500f9'               # violet_glow
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#D48BFF' # string purple-pink
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#D48BFF' # string purple-pink
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#D48BFF' # string purple-pink
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#BD00FF'       # purple
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#BD00FF'            # purple
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#ff1744,bold'              # green
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#ff1744,bold'    
# ============================================================================
# SHELL INITIALIZATION
# ============================================================================

export EXA_COLORS="\
di=38;2;196;161;255:\
ex=38;2;255;23;68:\
*.md=38;2;189;0;255:\
*.lua=38;2;189;0;255:\
*.ts=38;2;189;0;255:\
*.tsx=38;2;189;0;255:\
*.sql=38;2;189;0;255:\
*.json=38;2;189;0;255:\
*.js=38;2;189;0;255:\
*.jsx=38;2;189;0;255:\
*.vue=38;2;189;0;255:\
*.java=38;2;189;0;255:\
fi=37"
# ============================================================================
# SHELL INITIALIZATION
# ============================================================================

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ============================================================================
# ALIASES
# ============================================================================

# File listing (eza)
alias ls='eza --icons --group-directories-first'
alias ll='eza -1 --icons --group-directories-first'
alias la='eza -la'
alias ld='eza -1 --sort=modified'
alias lt='eza --tree'

# Other tools
alias cat='bat'
alias reload='source ~/.zshrc'

# Neovim
alias lazyvim="NVIM_APPNAME=lazyvim nvim"

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

# Start development servers in tmux
start() {
  local cmd=""
  local win_name=""
  local current_dir=$(pwd)
  local sub_arg=$1

  # Logic for Java/Maven
  if [[ -f "pom.xml" ]]; then
    cmd="mvn spring-boot:run"
    win_name="spring"

  # Logic for Node/NPM/PNPM
  elif [[ -f "package.json" ]]; then
    win_name="pnpm"
    if [[ "$sub_arg" == "dev" ]]; then
      cmd="pnpm run dev"
    else
      cmd="pnpm start"
    fi
  else
    echo "❌ No pom.xml or package.json found in $current_dir"
    return 1
  fi

  # Dispatch to the Kitty 'server' session
  if /opt/homebrew/bin/tmux has-session -t server 2>/dev/null; then
    /opt/homebrew/bin/tmux new-window -t server -c "$current_dir" -n "$win_name" "$cmd; zsh"
    echo "🚀 Sent to Kitty: $cmd (Window: $win_name)"
  else
    echo "⚠️ Session 'server' not found. Ensure Kitty is open."
    echo "Running locally: $cmd"
    eval "$cmd"
  fi
}

# Install packages in new Ghostty window
pi() {
  local dir_escaped=$(printf '%q' "$PWD")
  local pkg_cmd="install"
  
  if [ $# -gt 0 ]; then
    pkg_cmd="add $*"
  fi

  local inner_cmd='
    cd '"$dir_escaped"' &&
    echo "📦 Running pnpm '"$pkg_cmd"' ..." &&
    /opt/homebrew/bin/pnpm '"$pkg_cmd"' &&
    echo "\n🏁 Finished. Press ENTER to close." &&
    read -r
  '

  open -na Ghostty --args \
    window-width=90 \
    window-height=24 \
    -e /bin/zsh -c "$inner_cmd"
}

# Quick config file editor
conf() {
  local editor="${EDITOR:-nvim}"
  local key="$1"
  
  typeset -A files
  files=(
    ghostty      "$HOME/.config/ghostty/config"
    gitconfig    "$HOME/.gitconfig"
    kitty        "$HOME/.config/kitty/kitty.conf"
    nvim         "$HOME/.config/nvim/init.lua"
    sketchybar   "$HOME/.config/sketchybar/sketchybarrc"
    skhd         "$HOME/.config/skhd/skhdrc"
    starship     "$HOME/.config/starship.toml"
    tmux         "$HOME/.tmux.conf"
    yabai        "$HOME/.config/yabai/yabairc"
    zshrc        "$HOME/.zshrc"
  )

  if [[ -z "$key" || "$key" == "help" || "$key" == "-h" ]]; then
    echo "available configs:"
    for k in ${(k)files}; do
      printf "  %s\n" "$k"
    done | sort
    return 0
  fi

  if [[ -z "${files[$key]}" ]]; then
    echo "unknown config: $key"
    echo "run: config help"
    return 1
  fi

  "$editor" "${files[$key]}"
}

alias ccreader="/Users/manfad/dev/cc-reader/cc-reader"
