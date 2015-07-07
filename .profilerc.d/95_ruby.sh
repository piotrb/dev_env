alias cucumber="spring_wrapper cucumber"
alias rspec="spring_wrapper rspec"
alias ph="bundle exec ph"
alias cap="bundle exec cap"
alias yard="bundle exec yard"
alias yardoc="bundle exec yardoc"
alias rake="spring_wrapper rake"
alias rails="spring_wrapper rails"
alias rdbm="rake db:migrate db:test:prepare"

alias teaspoon="spring_wrapper teaspoon -d phantomjs -q --format=tap_y | tapout progress"

export SPEC_OPTS=--color

export PATH=~/.rbenv/bin:$PATH

if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
