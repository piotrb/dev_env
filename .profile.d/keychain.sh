# vim: ts=2:et:sw=2
if [[ -e `which keychain` ]]; then
  if [ $TMUX ]; then
    echo "Loading Keychain ..."
    eval `keychain id_rsa -q --eval`
  fi
fi
