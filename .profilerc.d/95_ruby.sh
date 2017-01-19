alias cucumber="spring_wrapper cucumber"
alias rspec="spring_wrapper rspec"
alias ph="bundle_wrapper ph"
alias cap="bundle_wrapper cap"
alias yard="bundle_wrapper yard"
alias yardoc="bundle_wrapper yardoc"
alias rake="spring_wrapper rake"
alias rails="spring_wrapper rails"
alias guard="bundle_wrapper guard"
alias rdbm="rake db:migrate"
alias be="bundle_wrapper"

alias pry-remote="bundle_wrapper pry-remote"
alias pry="bundle_wrapper pry"

alias teaspoon="spring_wrapper teaspoon -d phantomjs -q --format=tap_y | tapout progress"

export SPEC_OPTS=--color

export PATH=~/.rbenv/bin:$PATH

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
