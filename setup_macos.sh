#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
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

setup_macos() {
  fmt_title_underline "Configuring macOS"

  if [[ "$(uname)" != "Darwin" ]]; then
    log_error "Cannot run this command on non-macOS system. Exiting."
    exit 1
  fi

  log_info "Finder: show all filename extensions"
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  log_info "show hidden files by default"
  defaults write com.apple.Finder AppleShowAllFiles -bool false

  log_info "only use UTF-8 in Terminal.app"
  defaults write com.apple.terminal StringEncodings -array 4

  log_info "expand save dialog by default"
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

  log_info "show the ~/Library folder in Finder"
  chflags nohidden ~/Library

  log_info "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  log_info "Enable subpixel font rendering on non-Apple LCDs"
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  log_info "Use current directory as default search scope in Finder"
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  log_info "Show Path bar in Finder"
  defaults write com.apple.finder ShowPathbar -bool true

  log_info "Show Status bar in Finder"
  defaults write com.apple.finder ShowStatusBar -bool true

  log_info "Press Ctrl+Cmd to drag windows from anywhere"
  defaults write -g NSWindowShouldDragOnGesture -bool true

  log_info "Disable press-and-hold for keys in favor of key repeat"
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  log_info "Disable press-and-hold for keys in VS Code (for vim key repeat)"
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
  defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false
  defaults write com.vscodium ApplePressAndHoldEnabled -bool false
  defaults write com.microsoft.VSCodeExploration ApplePressAndHoldEnabled -bool false

  log_info "Set a blazingly fast keyboard repeat rate"
  defaults write NSGlobalDomain KeyRepeat -int 1

  log_info "Set a shorter Delay until key repeat"
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  log_info "Enable tap to click (Trackpad)"
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  log_info "Set Caps Lock delay to 0 (instant)"
  hidutil property --set '{"CapsLockDelayOverride":0}'

  log_info "Killing affected applications"
  for app in Safari Finder Dock Mail SystemUIServer; do killall "$app" >/dev/null 2>&1; done
  
  echo
  log_info "macOS configuration completed!"
  log_warning "Some changes may require a logout/restart to take effect."
}

# Run the setup function
setup_macos
