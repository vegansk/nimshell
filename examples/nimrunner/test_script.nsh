#!/usr/bin/env nimrunner
##: cc=gcc
import os

echo "Hello, world!"

echo "Params:", paramCount()
echo "Args:"
for i in 1..paramCount():
  echo "arg" & $i & " = " & paramStr(i)