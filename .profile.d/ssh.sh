check-ssh-add() {
  if ! ssh-add -l >/dev/null; then
    ssh-add
  fi
}

check-ssh-add
