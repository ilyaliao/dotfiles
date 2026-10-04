#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

fmt_title_underline() {
  echo -e "${BLUE}${1}${NC}"
  echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
}

setup_cursor() {
  fmt_title_underline "Cursor (~/.cursor/ and app)"
  mkdir -p ~/.cursor
  ln -sfn ~/dotfiles/cursor/statusline.sh ~/.cursor/statusline.sh
  log_info "~/.cursor/statusline.sh -> ~/dotfiles/cursor/statusline.sh"

  local cursor_user="$HOME/Library/Application Support/Cursor/User"
  mkdir -p "$cursor_user"
  ln -sfn ~/dotfiles/.vscode/settings.json "$cursor_user/settings.json"
  log_info "Cursor/User/settings.json -> ~/dotfiles/.vscode/settings.json"
  ln -sfn ~/dotfiles/.vscode/keybindings.json "$cursor_user/keybindings.json"
  log_info "Cursor/User/keybindings.json -> ~/dotfiles/.vscode/keybindings.json"
}

setup_ni() {
  fmt_title_underline "ni (~/.nirc)"
  ln -sfn ~/dotfiles/nirc ~/.nirc
  log_info "~/.nirc -> ~/dotfiles/nirc"
}

setup_starship() {
  fmt_title_underline "Starship (~/.config/starship.toml)"
  mkdir -p ~/.config
  ln -sfn ~/dotfiles/starship/starship.toml ~/.config/starship.toml
  log_info "~/.config/starship.toml -> ~/dotfiles/starship/starship.toml"
}

setup_symlinks() {
  setup_cursor
  setup_ni
  setup_starship
}

setup_symlinks
