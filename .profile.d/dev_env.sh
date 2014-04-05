export EDITOR="vim"
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export PATH="$HOME/bin:/usr/local/bin:/usr/local/sbin:$PATH"

export MYSQL_UNIX_PORT=/tmp/mysql.sock

alias cucumber="spring_wrapper cucumber"
alias rspec="spring_wrapper rspec"
alias ph="bundle exec ph"
alias cap="bundle exec cap"
alias rake="spring_wrapper rake"
alias rails="spring_wrapper rails"

export RBENV_GEMSETS="global"

export SPEC_OPTS=--color

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

export PATH=$PATH:~/Library/Python/2.7/bin
export PYTHONPATH=/usr/local/lib/python2.6/site-packages

ulimit -n 2048

function dev_gemfile() {
  export BUNDLER_GEMFILE=Gemfile.dev
  ln -s ~/.Gemfile.dev Gemfile.dev
}

function reg_gemfile() {
  export BUNDLER_GEMFILE=Gemfile
}

