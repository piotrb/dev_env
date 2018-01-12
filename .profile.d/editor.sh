export EDITOR=vim
export GIT_EDITOR=vim

function code() {
  # reference to the original `code` command
  _code=$(which vscode)
  # if incoming stdin via a pipe...
  if [[ -p /dev/stdin ]] ; then
    tmpFile=$(mktemp -t stdin)
    tee "$tmpFile" > /dev/null
    $_code -w "$tmpFile" &
  else
    # otherwise, pass along any arguments to the original `code`
    $_code "$@"
  fi
}
