export EDITOR="vim"
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

export PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH"

ulimit -n 2048

alias fixtty="stty sane"
alias ag="echo use pt instead"
alias kraken="open -a GitKraken"
