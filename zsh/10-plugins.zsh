ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"

zinit wait lucid for \
  OMZL::completion.zsh \
  OMZL::git.zsh \
  OMZP::git \
  OMZP::brew \
  OMZP::fzf \
  OMZP::ssh \
  OMZP::npm

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

zinit wait lucid for \
  atinit"zicompinit; zicdreplay; \
    compdef _i_complete i; compdef _repros_complete repros; \
    compdef _forks_complete forks; compdef _works_complete works" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  zsh-users/zsh-completions \
  atload"bindkey '^[[A' history-substring-search-up; bindkey '^[[B' history-substring-search-down" \
    zsh-users/zsh-history-substring-search \
  MichaelAquilina/zsh-you-should-use
