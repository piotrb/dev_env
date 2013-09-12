#!/bin/bash

# load profile scripts
if [ -d $HOME/.profile.d ]; then
  for i in $HOME/.profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

. ~/Library/Python/2.7/lib/python/site-packages/powerline/bindings/bash/powerline.sh
