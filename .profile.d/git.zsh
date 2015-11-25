echo -n "[git]"

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
