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

sync_agents_md() {
  local target="$1"
  mkdir -p "$(dirname "$target")"
  grep -v '^@' ~/dotfiles/.codex/AGENTS.md > "$target"
  log_info "synced ~/dotfiles/.codex/AGENTS.md -> $target (@ includes stripped)"
}

setup_devin() {
  fmt_title_underline "Devin (~/.config/devin/)"
  sync_agents_md ~/.config/devin/AGENTS.md
}

setup_droid() {
  fmt_title_underline "Factory Droid (~/.factory/)"
  sync_agents_md ~/.factory/AGENTS.md
}

setup_opencode() {
  fmt_title_underline "OpenCode (~/.config/opencode/)"
  sync_agents_md ~/.config/opencode/AGENTS.md
}

install_skill_pkg() {
  local src="$1"
  shift
  if (cd ~ && npx -y skills add "$src" "$@" -y); then
    log_info "installed skills from $src"
  else
    log_warning "skills add $src failed"
  fi
}

setup_skills() {
  fmt_title_underline "Skills (~/.agents/skills/)"
  mkdir -p ~/.agents/skills

  for parent in ~/.claude ~/.codex ~/.cursor ~/.factory ~/.gemini ~/.config/devin ~/.config/opencode; do
    [ -d "$parent" ] || continue
    if [ -d "$parent/skills" ] && [ ! -L "$parent/skills" ]; then
      for item in "$parent/skills"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        [ -e ~/.agents/skills/"$name" ] || mv "$item" ~/.agents/skills/
      done
      rm -rf "$parent/skills"
    fi
    ln -sfn ~/.agents/skills "$parent/skills"
    log_info "$parent/skills -> ~/.agents/skills"
  done

  if ! command -v npx >/dev/null 2>&1; then
    log_warning "npx not found; skipped skills install"
    return
  fi

  install_skill_pkg antfu/skills -s antfu -s antfu-create-pr -s nitro -s nuxt -s pinia -s pnpm -s unocss -s vite -s vitepress -s vitest -s vue
  install_skill_pkg slidevjs/slidev -s slidev
  install_skill_pkg rolldown/tsdown -s tsdown -s tsdown-migrate
  install_skill_pkg vercel/turborepo -s turborepo
  install_skill_pkg vueuse/vueuse -s vueuse-functions
  install_skill_pkg vercel-labs/agent-skills -s web-design-guidelines
  install_skill_pkg git@github.com:posva/vue-rulekit.git -s pinia-colada
  install_skill_pkg zeke/faster-gh-cli-skill -s faster-gh-cli-skill
  install_skill_pkg ast-grep/agent-skill -s ast-grep-outline
  install_skill_pkg vercel-labs/agent-browser -s agent-browser
  install_skill_pkg vuejs-ai/skills -s vue-router-best-practices -s vue-testing-best-practices -s vue-debug-guides -s vue-pinia-best-practices
  install_skill_pkg cursor/plugins -s deslop
  install_skill_pkg yusukebe/ax -s ax
  rm -f ~/skills-lock.json
}

setup_claude
setup_codex
setup_devin
setup_droid
setup_opencode
setup_skills
