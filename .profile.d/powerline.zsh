module_path=($module_path /usr/local/lib/zpython)

export PATH=$HOME/Library/Python/2.7/bin:$PATH
export PATH=$HOME/.python/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

function powerline_precmd() {
    PS1="$(powerline-shell --shell zsh $?)"
}

function install_powerline_precmd() {
  for s in "${precmd_functions[@]}"; do
    if [ "$s" = "powerline_precmd" ]; then
      return
    fi
  done
  precmd_functions+=(powerline_precmd)
}

if [ `command -v powerline-shell` ]; then
  install_powerline_precmd
fi
