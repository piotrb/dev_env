#!/bin/bash - 
set -x -o nounset
git show $1 -- "$2" | git apply

