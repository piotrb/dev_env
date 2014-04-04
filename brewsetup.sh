#!/bin/bash

ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"

brew tap phinze/cask
brew install brew-cask

brew tap jimbojsb/launchrocket
brew cask install launchrocket

brew install mysql ctags rbenv ruby-build vim git rbenv-gem-rehash scala wget postgresql rbenv-gemset the_silver_searcher memcached tmux
