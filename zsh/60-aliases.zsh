# IDE
alias code="open $1 -a \"Cursor\""
alias cursor="open $1 -a \"Cursor\""

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
alias cc="claude"
alias ccc="claude -c"
alias ccr="claude -r"

# eza — brew install eza
alias ll="eza -l -g --icons"
alias lla="ll -a"

# Git
alias grt='cd "$(git rev-parse --show-toplevel)"'

alias gs='git status'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpft='git push --follow-tags'
alias gpl='git pull --rebase'
alias gcl='git clone'
alias gst='git stash'
alias grm='git rm'
alias gmv='git mv'

alias main='git checkout --force main'

alias gco='git checkout'
alias gcob='git checkout -b'

alias gb='git branch'
alias gbd='git branch -d'

alias grb='git rebase'
alias grbom='git rebase origin/main'
alias grbc='git rebase --continue'
alias grbu='git reset --hard ORIG_HEAD'

alias gl='git log'
alias glo='git log --oneline --graph'
alias glf='git log --first-parent'

alias grh='git reset HEAD'
alias grh1='git reset HEAD~1'
alias gundo='git reset --soft HEAD~1'

alias ga='git add'
alias gA='git add -A'

alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcam='git add -A && git commit -m'
alias gfp='git fetch --all --prune'
alias gfrb='git fetch origin && git rebase origin/master'

alias gxn='git clean -dn'
alias gx='git clean -df'

alias gsha='git rev-parse HEAD | pbcopy'

alias ghci='gh run list -L 1'
alias gct='git branch --all | fzf --preview "git log --oneline -10 {1}" | sed "s/remotes\/origin\///" | xargs git checkout'

# Homebrew
alias homeupdate="brew update && brew upgrade && brew cleanup"
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
