#!/usr/bin/env nimrunner
import nimshell, os

if paramCount() != 1: quit "Usage: nimboostrap PATH"
if not ?(which "git"): quit "Git must be installed!"

let DIR = paramStr(1)

createDir DIR

>>! cmd"git clone -b master --depth 1 git://github.com/Araq/Nim.git $DIR"
setCurrentDir DIR
>>! cmd"git clone -b master --depth 1 git://github.com/nim-lang/csources"
setCurrentDir "csources"
when defined(windows):
  >>! "build.bat"
  setCurrentDir ".."
  >>! "bin/nim.exe c koch.nim"
  >>! "./koch.exe boot -d:release"
else:
  >>! "./build.sh"
  setCurrentDir ".."
  >>! "bin/nim c koch.nim"
  >>! "./koch boot -d:release"
