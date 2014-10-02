if [[ -e `which keychain` ]]; then
  if [ $TMUX ]; then
    eval `keychain --eval`
  fi
fi
