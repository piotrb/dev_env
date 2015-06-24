check-ssh-add() {
  if ! ssh-add -l >/dev/null; then
    ssh-add -t 5h
  fi
}

check-ssh-add
