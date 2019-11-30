#!/bin/bash

# Install Homebrew itself
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Deps for tools
brew install libgit2 go

# Ruby
brew install rbenv ruby-build rbenv-gemset

# Terminal Tools
brew install the_platinum_searcher neovim wget tmux avn tig git reattach-to-user-namespace ctags direnv

# AWS CLI
brew install awscli

# Node
brew tap ouchxp/nodenv
brew install node nodenv nodenv-nvmrc

# Some additional languages and tools
#brew install mysql scala postgresql memcached

# Puma Dev
# brew install puma-dev

# Foreman-like process manager
brew install overmind
