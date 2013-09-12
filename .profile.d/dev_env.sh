#export EDITOR="$HOME/bin/mate_editor"
export EDITOR="vim"
export LC_CTYPE=en_US.UTF-8

export PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH"

#export CC=/usr/bin/gcc-4.2 # needed for Lion only

export MYSQL_UNIX_PORT=/tmp/mysqld.sock

alias cucumber="bundle exec cucumber"

alias rspec="bundle exec rspec"

alias r="rspec"

alias dl="~/Work/dev_launcher/run.sh"

export SPEC_OPTS=--color

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

function load_rvm() {
  # This loads RVM into a shell session.
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
  # Add RVM to PATH for scripting
  export PATH="$PATH:$HOME/.rvm/bin"
}

export PATH=$PATH:~/Library/Python/2.7/bin

ulimit -n 2048



