module_path=($module_path /usr/local/lib/zpython)

if [ -e ~/.python/lib/Python2.7/site-packages/powerline ]; then
  export POWERLINE_BASE=$HOME/.python/lib/Python2.7/site-packages/powerline
  export PATH=$HOME/.python/bin:$PATH
fi

# linux
if [ -e ~/.local/lib/python2.7/site-packages/powerline ]; then
  export POWERLINE_BASE=$HOME/.local/lib/python2.7/site-packages/powerline
  export PATH=$HOME/.local/bin:$PATH
fi

# linux shared
if [ -e /usr/local/lib/python2.7/dist-packages/powerline ]; then
  export POWERLINE_BASE=/usr/local/lib/python2.7/dist-packages/powerline
fi

if [ -e $POWERLINE_BASE ]; then
  . $POWERLINE_BASE/bindings/zsh/powerline.zsh
  powerline-daemon -q
fi
