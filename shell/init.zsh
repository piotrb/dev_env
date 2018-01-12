# load global rc scripts
if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.(zsh|sh); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# load rc scripts
if [ -d $HOME/.profilerc.d ]; then
  for i in $HOME/.profilerc.d/*.(zsh|sh); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi

# load profile scripts
if [ -d $HOME/.profile.d ]; then
  for i in $HOME/.profile.d/*.(zsh|sh); do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi