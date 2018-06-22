#!/bin/bash

# Install Homebrew itself
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew tap phinze/cask
brew install brew-cask

brew tap jimbojsb/launchrocket
brew cask install launchrocket

brew install the_platinum_searcher libgit2 go ctags rbenv ruby-build vim git wget rbenv-gemset tmux

# Some additional languages and tools
#brew install mysql scala postgresql memcached
