ZSH_CONFIG_DIR="${${:-$HOME/.zshrc}:A:h}/zsh"

for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
  source "$config_file"
done
unset config_file
