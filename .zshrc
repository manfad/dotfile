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

# Load Autocomplete (Ghost text)
source ~/.zsh-autosuggestions/zsh-autosuggestions.zsh

# Note: This MUST be sourced after autosuggestions
source ~/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# What you type. Unknown text stays the terminal white; a real command turns green.
# Defaults paint unknown tokens ANSI red, which is the brown line under the path.
ZSH_HIGHLIGHT_STYLES[default]='none'
ZSH_HIGHLIGHT_STYLES[unknown-token]='none'
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[path]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=8'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument-delimiter]='fg=yellow'

# ============================================================================
# SHELL INITIALIZATION
# ============================================================================

# Zoxide (smart cd)
eval "$(zoxide init zsh)"

# Starship prompt
# Select independent Herdr tools before initializing Starship.
source "$HOME/.config/herdr-app/shell-profile.zsh"
eval "$(starship init zsh)"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ============================================================================
# ALIASES
# ============================================================================
# File listing (eza)
alias ls='eza -la --icons --group-directories-first'  # all files, full detail
alias ll='eza -a -1 --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'

# File finding (fd)
alias fdf='fd -t f'
alias cpd="printf %s \$(pwd) | pbcopy"
alias ip='ipconfig getifaddr en0 || ipconfig getifaddr en1'
alias i='ip'

# Navigation
alias d='cd ..'
# Other tools
alias cat='bat'
alias reload='source ~/.zshrc'
alias r='reload'

# Neovim
# Open nvim with a single path argument by first cd-ing into its folder
# (the file's parent, or the directory itself). This roots the file explorer
# there, and leaves the terminal in that folder after you quit.
# Plain `nvim` is always the default profile; `lazyvim` remains opt-in.
# NVIM_APPNAME is selected by the terminal profile above.
nvim() {
  if [[ $# -eq 1 && "$1" != -* ]]; then
    if [[ -d "$1" ]]; then
      cd "$1" && command nvim .
      return
    fi
    if [[ -d "${1:h}" ]]; then
      cd "${1:h}" && command nvim "${1:t}"
      return
    fi
  fi
  command nvim "$@"
}

alias lazyvim="NVIM_APPNAME=lazyvim nvim"

codex() {
  if [[ "$1" == "yolo" ]]; then
    shift
    command codex --dangerously-bypass-approvals-and-sandbox "$@"
    return
  fi

  command codex "$@"
}

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

# Quick config file editor
conf() {
  local editor="${EDITOR:-nvim}"
  local key="$1"
  
  typeset -A files
  files=(
    claude       "$HOME/.claude/settings.json"
    codex        "$HOME/.codex/config.toml"
    ghostty      "$HOME/.config/ghostty/config"
    gitconfig    "$HOME/.gitconfig"
    herdr        "$HOME/.config/herdr/config.toml"
    hunk         "$HOME/.config/hunk/config.toml"
    nvim         "$HOME/.config/nvim/init.lua"
    ssh          "$HOME/.ssh/config"
    starship     "$HOME/.config/starship.toml"
    zsh          "$HOME/.zshrc"
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
    echo "run: conf help"
    return 1
  fi

  command "$editor" "${files[$key]}"
}

export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/postgresql@16/lib"
export CPPFLAGS="-I/opt/homebrew/opt/postgresql@16/include"

# Prefer Homebrew shims over Vite+ shims for tools like codex/npm/node.
if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# >>> cursor wrapper >>>
# bare `cursor` → Cursor Agent CLI; otherwise open the desktop app / pass through flags
cursor() {
  if (( $# == 0 )); then
    command cursor agent
  else
    command cursor "$@"
  fi
}
# <<< cursor wrapper <<<

alias p=ports
alias pk='ports kill'


# nota            → bring Nota forward
# nota .          → open every regular file in this directory (top level, non-hidden)
# nota FILE...    → open those files in Nota
nota() {
  local -a files
  if (( $# == 0 )); then
    open -a Nota
    return
  fi
  local arg
  for arg in "$@"; do
    if [[ -d $arg ]]; then
      files+=("$arg"/*(.N))
    else
      files+=("$arg")
    fi
  done
  (( ${#files} )) || { print -u2 "nota: nothing to open"; return 1; }
  open -a Nota -- "${files[@]}"
}

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# office NAS: if ~/nas is connected, cd into it; otherwise (re)mount first
nas() {
  if perl -e 'alarm 3; exec @ARGV' ls ~/nas >/dev/null 2>&1 && mount | grep -q " on $HOME/nas "; then
    cd ~/nas
  else
    umount -f ~/nas 2>/dev/null
    local pw
    pw=$(security find-generic-password -a manfad -s nas-smb -w 2>/dev/null) || {
      echo "nas: no password in Keychain. Run: security add-generic-password -a manfad -s nas-smb -w" >&2
      return 1
    }
    mkdir -p ~/nas
    mount_smbfs "//manfad:${pw}@192.168.2.223/Office" ~/nas && cd ~/nas
  fi
}

# >>> dup >>>
source "/Users/manfad/talk/dup/dup.zsh"
# <<< dup <<<

# Vault Phosphor: keep history/completion popups in dark mode.
export DUP_THEME=dark
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6B9F70"

source "$HOME/.config/herdr-app/shell-colors.zsh"
