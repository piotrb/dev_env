ssh-add -K 2> /dev/null

function sshx() {
  # $1 = bastion
  # #2 = host
  ssh-keygen -R "$2"
  ssh -J "$1" "$2" "${*:3}"
}
