#!/bin/bash - 
find t-p-l.com/cmd -type d -d 1 | xargs -n1 go get -v
find t-p-l.com/cmd -type d -d 1 | xargs -n1 go install -v

