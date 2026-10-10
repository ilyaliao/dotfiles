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

setup_claude() {
  fmt_title_underline "Claude Code (~/.claude/)"
  mkdir -p ~/.claude
  ln -sfn ~/dotfiles/.claude/CLAUDE.md ~/.claude/CLAUDE.md
  log_info "~/.claude/CLAUDE.md -> ~/dotfiles/.claude/CLAUDE.md"
  mkdir -p ~/dotfiles/.claude/rules
  ln -sfn ~/dotfiles/.claude/rules ~/.claude/rules
  log_info "~/.claude/rules -> ~/dotfiles/.claude/rules"
  ln -sfn ~/dotfiles/.claude/keybindings.json ~/.claude/keybindings.json
  log_info "~/.claude/keybindings.json -> ~/dotfiles/.claude/keybindings.json"
  ln -sfn ~/dotfiles/.claude/settings.json ~/.claude/settings.json
  log_info "~/.claude/settings.json -> ~/dotfiles/.claude/settings.json"
  ln -sfn ~/dotfiles/.claude/statusline-command.sh ~/.claude/statusline-command.sh
  log_info "~/.claude/statusline-command.sh -> ~/dotfiles/.claude/statusline-command.sh"
  ln -sfn ~/dotfiles/.claude/bin ~/.claude/bin
  log_info "~/.claude/bin -> ~/dotfiles/.claude/bin"
}

setup_codex() {
  fmt_title_underline "Codex (~/.codex/)"
  mkdir -p ~/.codex
  ln -sfn ~/dotfiles/.codex/AGENTS.md ~/.codex/AGENTS.md
  log_info "~/.codex/AGENTS.md -> ~/dotfiles/.codex/AGENTS.md"
  ln -sfn ~/dotfiles/.codex/hooks.json ~/.codex/hooks.json
  log_info "~/.codex/hooks.json -> ~/dotfiles/.codex/hooks.json"
  if [[ -e ~/.codex/config.toml && ! -L ~/.codex/config.toml ]]; then
    log_info "~/.codex/config.toml is a local file, left in place"
  else
    rm -f ~/.codex/config.toml
    cp ~/dotfiles/.codex/config.toml ~/.codex/config.toml
    log_info "copied ~/dotfiles/.codex/config.toml -> ~/.codex/config.toml"
  fi
}

setup_other_agents() {
  fmt_title_underline "Other agents (AGENTS.md copies)"
  for target in ~/.config/devin/AGENTS.md ~/.factory/AGENTS.md ~/.config/opencode/AGENTS.md; do
    mkdir -p "$(dirname "$target")"
    grep -v '^@' ~/dotfiles/.codex/AGENTS.md > "$target"
    log_info "synced ~/dotfiles/.codex/AGENTS.md -> $target (@ includes stripped)"
  done
}

setup_claude
setup_codex
setup_other_agents
