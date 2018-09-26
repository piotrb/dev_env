#!/bin/bash

# Install Homebrew itself
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# brew tap phinze/cask
# brew install brew-cask

# launchrocket no longer works on Mojave, so its out
# brew tap jimbojsb/launchrocket
# brew cask install launchrocket

# Deps for tools
brew install libgit2 go

# Ruby
brew install rbenv ruby-build rbenv-gemset

# Terminal Tools
brew install the_platinum_searcher vim wget tmux avn tig git reattach-to-user-namespace ctags

# Some additional languages and tools
#brew install mysql scala postgresql memcached
