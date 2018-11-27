#!/bin/bash

# Install Homebrew itself
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Deps for tools
brew install libgit2 go

# Ruby
brew install rbenv ruby-build rbenv-gemset

# Terminal Tools
brew install the_platinum_searcher vim wget tmux avn tig git reattach-to-user-namespace ctags direnv terraform_landscape

# AWS CLI
brew install awscli

# N Node Manager
brew install n

# Some additional languages and tools
#brew install mysql scala postgresql memcached

# Puma Dev
# brew install puma-dev