# ============================================================================
# OS DETECTION
# ============================================================================
case "$OSTYPE" in
  darwin*) export OS="mac" ;;
  linux*)
    if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
      export OS="wsl"
    else
      export OS="linux"
    fi
    ;;
esac

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

export PATH="$HOME/.local/bin:$PATH"

# Homebrew (mac uses /opt/homebrew, linuxbrew uses /home/linuxbrew)
if [[ "$OS" == "mac" && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ ("$OS" == "linux" || "$OS" == "wsl") && -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# pnpm (install path differs per OS)
if [[ "$OS" == "mac" ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
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

[[ -f ~/.zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source ~/.zsh-autosuggestions/zsh-autosuggestions.zsh

# Note: This MUST be sourced after autosuggestions
[[ -f ~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source ~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Syntax Highlighting Colors (blacklotus theme)
ZSH_HIGHLIGHT_STYLES[command]='fg=#d500f9,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#c2185b'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#c4a1ff'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ff4081,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=#9c27b0'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#d500f9'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#D48BFF'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#D48BFF'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#D48BFF'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#BD00FF'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#BD00FF'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#ff1744,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#ff1744,bold'

# eza colors
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
*.xml=38;2;189;0;255:\
*.jsx=38;2;189;0;255:\
*.vue=38;2;189;0;255:\
*.java=38;2;189;0;255:\
fi=37"

# ============================================================================
# SHELL INITIALIZATION
# ============================================================================

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ============================================================================
# ALIASES
# ============================================================================

# File listing (eza)
alias ls='eza -a --icons --group-directories-first'
alias ll='eza -a -1 --icons --group-directories-first'
alias la='eza -la'
alias ld='eza -1 --sort=modified'
alias lt='eza --tree'

# File finding (fd)
alias lf='fd -t f'

# Other tools
alias cat='bat'
alias reload='source ~/.zshrc'

# Copy current working directory to clipboard
case "$OS" in
  mac) alias cpwd='printf %s "$(pwd)" | pbcopy' ;;
  wsl) alias cpwd='printf %s "$(pwd)" | clip.exe' ;;
  linux)
    if command -v wl-copy >/dev/null 2>&1; then
      alias cpwd='printf %s "$(pwd)" | wl-copy'
    elif command -v xclip >/dev/null 2>&1; then
      alias cpwd='printf %s "$(pwd)" | xclip -selection clipboard'
    fi
    ;;
esac

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

# Local IP — no args returns this machine's IP; with args, passes through to
# the real `ip` (iproute2) command on Linux.
ip() {
  if [[ $# -eq 0 ]]; then
    case "$OS" in
      mac) ipconfig getifaddr en0 || ipconfig getifaddr en1 ;;
      linux|wsl) hostname -I | awk '{print $1}' ;;
      *) echo "ip: unsupported OS" >&2; return 1 ;;
    esac
  else
    if [[ "$OS" == "linux" || "$OS" == "wsl" ]] && command -v /usr/sbin/ip >/dev/null 2>&1; then
      /usr/sbin/ip "$@"
    elif [[ "$OS" == "linux" || "$OS" == "wsl" ]] && command -v /sbin/ip >/dev/null 2>&1; then
      /sbin/ip "$@"
    else
      command ip "$@"
    fi
  fi
}

# Quick config file editor
conf() {
  local editor="${EDITOR:-nvim}"
  local key="$1"

  typeset -A files
  files=(
    ghostty      "$HOME/.config/ghostty/config"
    gitconfig    "$HOME/.gitconfig"
    nvim         "$HOME/.config/nvim/init.lua"
    starship     "$HOME/.config/starship.toml"
    tmux         "$HOME/.tmux.conf"
    zshrc        "$HOME/.zshrc"
  )

  # Mac-only configs
  if [[ "$OS" == "mac" ]]; then
    files[sketchybar]="$HOME/.config/sketchybar/sketchybarrc"
  fi

  if [[ -z "$key" || "$key" == "help" || "$key" == "-h" ]]; then
    echo "available configs:"
    for k in ${(k)files}; do
      printf "  %s\n" "$k"
    done | sort
    return 0
  fi

  if [[ -z "${files[$key]}" ]]; then
    echo "unknown config: $key"
    echo "run: conf help"
    return 1
  fi

  "$editor" "${files[$key]}"
}
