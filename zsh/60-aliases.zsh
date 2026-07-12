# IDE
alias code="open $1 -a \"Cursor\""
alias cursor="open $1 -a \"Cursor\""

# Claude Code
alias cc="claude"
alias ccc="claude -c"
alias ccr="claude -r"
alias ccd="claude --dangerously-skip-permissions"

# Cursor Agent
alias ca="agent"
alias cac="agent --continue"
alias car="agent --resume"

# Node Package Manager — https://github.com/antfu/ni
alias nio="ni --prefer-offline"
alias s="nr start"
alias d="nr dev"
alias b="nr build"
alias bw="nr build --watch"
alias t="nr test"
alias tu="nr test -u"
alias tw="nr test --watch"
alias w="nr watch"
alias p="nr play"
alias c="nr typecheck"
alias up="nr up"
alias lint="nr lint"
alias lintf="nr lint --fix"
alias release="nr release"
alias re="nr release"

# eza — mise install eza
alias ll="eza -l -g --icons"
alias lla="ll -a"

# Git
alias grt='cd "$(git rev-parse --show-toplevel)"'
alias gpf='git push --force-with-lease'

alias main='git checkout --force main'

alias gundo='git reset --soft HEAD~1'
alias gsha='git rev-parse HEAD | pbcopy'

alias prs='gh pr list'
alias prd='gh pr diff'
alias prv='gh pr view'
alias prc='gh pr checkout'

alias ghci='gh run list -L 1'
alias gct='git branch --all | fzf --preview "git log --oneline -10 {1}" | sed "s/remotes\/origin\///" | xargs git checkout'

# Homebrew
alias homeupdate="brew update && brew upgrade -y && brew cleanup"
homeuninstall() {
  local name
  for name in "$@"; do
    if brew list --cask "$name" &>/dev/null; then
      brew uninstall --cask --force --zap "$name"
    elif brew list --formula "$name" &>/dev/null; then
      brew uninstall --force "$name"
    else
      echo "homeuninstall: '$name' 未安裝" >&2
    fi
  done
}
