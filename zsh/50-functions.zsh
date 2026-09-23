function glp() {
  git --no-pager log -$1
}

# I put
# `~/i` for my projects
# `~/f` for forks
# `~/r` for reproductions
# `~/w` for work

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

function .claude() {
  cd ~/.claude
}

function dotfiles() {
  cd ~/dotfiles
}

function dir() {
  mkdir $1 && cd $1
}

function clone() {
  if [[ -z $2 ]] then
    git clone "$@" && cd "$(basename "$1" .git)"
  else
    git clone "$@" && cd "$2"
  fi
}

function clonei() {
  local back="$PWD"
  i && clone "$@" && code . && cd "$back"
}

function cloner() {
  local back="$PWD"
  repros && clone "$@" && code . && cd "$back"
}

function clonef() {
  local back="$PWD"
  forks && clone "$@" && code . && cd "$back"
}

function clonew () {
  local back="$PWD"
  works && clone "$@" && code . && cd "$back"
}

function codei() {
  i && code "$@" && cd -
}
