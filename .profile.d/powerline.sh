if [ -e ~/.python/lib/Python2.7/site-packages/powerline ]; then
  POWERLINE_BASE=~/.python/lib/Python2.7/site-packages/powerline
  export PATH=~/.python/bin:$PATH
fi

if [ -e ~/.local/lib/python2.7/site-packages/powerline ]; then
  POWERLINE_BASE=~/.local/lib/python2.7/site-packages/powerline
  export PATH=~/.local/bin:$PATH
fi

if [ -e $POWERLINE_BASE ]; then
  . $POWERLINE_BASE/bindings/zsh/powerline.zsh
fi  
