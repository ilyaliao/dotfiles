# mise must activate before OMZ fzf/starship so binaries resolve via shims
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

export NI_AUTO_INSTALL=true
export PATH="$HOME/.local/bin:$PATH"

export LAUNCH_EDITOR="cursor"

# fzf + fd
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || cat {} 2> /dev/null | head -500'
export FZF_DEFAULT_OPTS='--bind ctrl-e:down,ctrl-u:up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || cat {} 2> /dev/null | head -500"'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX_HEIGHT='80%'
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="--preview 'ls -la {}'"
