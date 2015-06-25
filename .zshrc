# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="agnoster"
#ZSH_THEME="geoffgarside"
#ZSH_THEME="tonotdo"
#ZSH_THEME="tjkirch"
#ZSH_THEME="wedisagree"
#ZSH_THEME="ys"
#ZSH_THEME="piotr"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

#ZSH_TMUX_ITERM2=true
#ZSH_TMUX_AUTOSTART=true

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git rails ruby brew gem heroku rake pow git-hubflow)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...

if [ -d $HOME/.profile.d ]; then
  for i in $HOME/.profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  for i in $HOME/.profile.d/*.zsh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

#if [ ! $TMUX ]; then
#  tmux has-session -t shell 2>/dev/null && tmux attach-session -t shell || tmux new-session -s shell
#fi

export TERM="xterm-256color"
