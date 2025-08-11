source ~/.bash_profile

# git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1
# ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
ZSH_THEME="spaceship"

# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
# git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-nvm
  brew
  you-should-use
)

export NVM_AUTO_USE=true
export NVM_LAZY_LOAD=true
export NVM_COMPLETION=true
export LAUNCH_EDITOR="cursor-nightly"

# https://ohmyz.sh/
source $ZSH/oh-my-zsh.sh

# -------------------------------- #
# IDE
# -------------------------------- #

alias code="open $1 -a \"Cursor Nightly\""
alias cursor="open $1 -a \"Cursor Nightly\""
alias vscode="open $1 -a \"Visual Studio Code\""

# -------------------------------- #
# Node Package Manager
# -------------------------------- #
# https://github.com/antfu/ni

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

# -------------------------------- #
# Best LS Command Replacement
# -------------------------------- #
# brew install eza

alias ll="eza -l -g --icons"
alias lla="ll -a"

# -------------------------------- #
# Git
# -------------------------------- #

# Use github/hub
alias git=hub

# Go to project root
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

function glp() {
  git --no-pager log -$1
}

function gd() {
  if [[ -z $1 ]] then
    git diff --color | diff-so-fancy
  else
    git diff --color $1 | diff-so-fancy
  fi
}

function gdc() {
  if [[ -z $1 ]] then
    git diff --color --cached | diff-so-fancy
  else
    git diff --color --cached $1 | diff-so-fancy
  fi
}

# -------------------------------- #
# Directories
#
# I put
# `~/i` for my projects
# `~/f` for forks
# `~/r` for reproductions
# -------------------------------- #

function i() {
  cd ~/i/$1
}

function repros() {
  cd ~/r/$1
}

function forks() {
  cd ~/f/$1
}

function works() {
  cd ~/w/$1
}

function pr() {
  if [ $1 = "ls" ]; then
    gh pr list
  else
    gh pr checkout $1
  fi
}

function dir() {
  mkdir $1 && cd $1
}

function clone() {
  if [[ -z $2 ]] then
    hub clone "$@" && cd "$(basename "$1" .git)"
  else
    hub clone "$@" && cd "$2"
  fi
}

function cleanpr() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not in a git repository."
    return 1
  fi

  local current_branch
  current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "__DETACHED__")

  local remotes_to_remove=()
  while IFS= read -r remote; do
    if [[ "$remote" != "origin" && "$remote" != "upstream" ]]; then
      remotes_to_remove+=("$remote")
    fi
  done < <(git remote)

  local removed_branches=0
  local removed_remotes=0

  for remote in "${remotes_to_remove[@]}"; do
    while IFS=' ' read -r branch upstream; do
      if [[ "$upstream" == "$remote/"* && "$branch" != "$current_branch" ]]; then
        if git branch -D "$branch" >/dev/null 2>&1; then
          ((removed_branches++))
          # local  remote  branch
          echo "local  $remote  $branch"
        fi
      fi
    done < <(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads 2>/dev/null | grep " $remote/")
    if git remote remove "$remote" >/dev/null 2>&1; then
      ((removed_remotes++))
    fi
  done

  git fetch --all --prune --quiet >/dev/null 2>&1

  local pr_branches_removed=0
  while IFS=' ' read -r branch upstream; do
    if [[ "$branch" != "$current_branch" && "$upstream" == "origin/pr/"* ]]; then
      if git branch -D "$branch" >/dev/null 2>&1; then
        ((pr_branches_removed++))
        # local  author  name
        # branch like pr/ArthurDarkstone/4841
        local pr_author pr_name
        pr_author=$(echo "$upstream" | cut -d'/' -f3)
        pr_name=$(echo "$upstream" | cut -d'/' -f4-)
        echo "local  $pr_author  $pr_name"
      fi
    fi
  done < <(git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads 2>/dev/null | grep " origin/pr/")

  local pr_refs_removed=0
  while IFS= read -r r_branch; do
    local trimmed_branch=$(echo "$r_branch" | xargs)
    if [[ -n "$trimmed_branch" ]]; then
      if git branch -rd "$trimmed_branch" >/dev/null 2>&1; then
        ((pr_refs_removed++))
        # remote  author  name
        # trimmed_branch like origin/pr/ArthurDarkstone/4841
        local pr_author pr_name
        pr_author=$(echo "$trimmed_branch" | cut -d'/' -f3)
        pr_name=$(echo "$trimmed_branch" | cut -d'/' -f4-)
        echo "remote  $pr_author  $pr_name"
      fi
    fi
  done < <(git branch -r 2>/dev/null | grep 'origin/pr/')

  echo "Cleaned: $removed_remotes remotes, $((removed_branches + pr_branches_removed)) local branches, $pr_refs_removed remote refs"
}

# Clone to ~/i and cd to it
function clonei() {
  i && clone "$@" && cursor-nightly . && cd ~2
}

function cloner() {
  repros && clone "$@" && cursor-nightly . && cd ~2
}

function clonef() {
  forks && clone "$@" && cursor-nightly . && cd ~2
}

function clonew () {
  works && clone "$@" && cursor-nightly . && cd ~2
}

function codei() {
  i && cursor-nightly "$@" && cd -
}

function serve() {
  if [[ -z $1 ]] then
    live-server dist
  else
    live-server $1
  fi
}

# -------------------------------- #
# Custom
# -------------------------------- #

function browser() {
  if [[ -z $1 ]] then
    npx broz localhost:4000
  else
    npx broz "localhost:$(basename "$1")"
  fi
}

function treeL() {
  if [[ -z $1 ]] then
    tree -a -I '.git|node_modules|dist|build|coverage|logs|tmp|vendor'
  else
    tree -a -I '.git|node_modules|dist|build|coverage|logs|tmp|vendor' -L $1
  fi
}

function checkCircle() {
  if [[ -z $1 ]] then
    madge --circular --extensions ts,js src/
  else
    madge --circular --extensions ts,js $1
  fi
}

alias bt='npx @agentdeskai/browser-tools-server@1.2.0'
