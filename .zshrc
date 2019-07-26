zmodload zsh/zprof
source ~/.zsh/antigen.zsh

export NVM_LAZY_LOAD=true
#export NVM_NO_USE=true

export RBENV_ROOT=~/.rbenv

antigen init "$HOME/.antigenrc"

source ~/Work/dev_env/shell/init.zsh

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
