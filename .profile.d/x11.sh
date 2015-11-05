#!/bin/bash - 
if [[ `uname` = 'Linux' ]]; then
  echo "Setting X Display to :1 ..."
  export DISPLAY=:1
fi
