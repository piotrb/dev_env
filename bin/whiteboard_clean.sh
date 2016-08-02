#!/bin/bash - 
#===============================================================================
#
#          FILE: whiteboard_clean.sh
# 
#         USAGE: ./whiteboard_clean.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: YOUR NAME (), 
#  ORGANIZATION: 
#       CREATED: 09/25/2015 09:42
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
convert "$1" -morphology Convolve DoG:15,100,0 -negate -normalize -blur 0x1 -channel RBG -level 60%,91%,0.1 "$2"
