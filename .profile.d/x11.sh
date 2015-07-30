export DISPLAY=:0

function withx {
  {
    xinit &
    xpid=$!
    sleep 0.1 
  } 2>/dev/null >/dev/null

  trap "echo 'waiting for child to die ...'" SIGHUP SIGINT SIGTERM
  eval $*
  kill $xpid
  trap - SIGHUP SIGINT SIGTERM
}
