echo "Disabling git gui ..."

git()
{
  if [ "$1" = "gui" ]; then
    echo "git gui is disdabled"
    false
  else
    command git $*
  fi
}

alias tigs='tig status'
