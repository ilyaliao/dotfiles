# mise must activate before OMZ fzf/starship so binaries resolve via shims
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

export NI_AUTO_INSTALL=true
export PATH="$HOME/.local/bin:$PATH"

export LAUNCH_EDITOR="cursor"

# fzf + fd
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_CTRL_T_COMMAND=''
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'ls -la {}'"
