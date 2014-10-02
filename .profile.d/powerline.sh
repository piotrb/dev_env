if [ -e ~/.python/lib/Python2.7 ]; then

  export PATH=~/.python/bin:$PATH
  POWERLINE_BASE=~/.python/lib/Python2.7/site-packages/powerline

  if [ -e $POWERLINE_BASE ]; then
    . $POWERLINE_BASE/bindings/zsh/powerline.zsh
  fi

fi  
