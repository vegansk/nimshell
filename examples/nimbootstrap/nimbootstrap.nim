#!/usr/bin/env nimrunner
import nimshell, os

let usageHelp = """
Nim bootstrap script

Usage:
  nimboostrap <NIM_DIR> [<NIMBLE_DIR>]

Options:
  <NIM_DIR>       Nim installation path
  <NIMBLE_DIR>    Nimble installation path
"""

if(paramCount() < 1 or paramCount() > 3):
  quit usageHelp

if not ?(which "git"): quit "Git must be installed!"

let NIM_DIR = paramStr(1)
let NIMBLE_DIR = if paramCount() > 1: paramStr(2) else: ""

# First install nim
createDir NIM_DIR
>>! cmd"git clone -b devel --depth 1 git://github.com/vegansk/Nim.git $NIM_DIR"
setCurrentDir NIM_DIR
>>! cmd"git clone -b devel --depth 1 git://github.com/nim-lang/csources"
setCurrentDir "csources"
>>! sh("." / "build")
setCurrentDir ParDir
>>! ("bin" / exe"nim" & " c koch.nim")
>>! ("." / exe"koch" & " boot -d:release")

echo "Don't forget to add " & (NIM_DIR / "bin") & " to your PATH"

if NIMBLE_DIR == "":
  quit()

# Modify path to install nimble
putEnv("PATH", (NIM_DIR / "bin") & $PathSep & getEnv("PATH"))
  
# Then install nimble
createDir NIMBLE_DIR
setCurrentDir NIMBLE_DIR
when defined(windows):
  >>! cmd"git clone --depth 1 https://github.com/nim-lang/nimble.git $NIMBLE_DIR"
  >>! "nim c -r src/nimble -y install"

# Modify path to use nimble
putEnv("PATH", (getHomeDir() / ".nimble" / "bin") & $PathSep & getEnv("PATH"))

# Install nimrunner
let NIMRUNNER_DIR = mktemp()
block:
  defer:
    try:
      removeDir NIMRUNNER_DIR
    except: discard
  >>! cmd"git clone https://github.com/vegansk/nimshell $NIMRUNNER_DIR"
  setCurrentDir NIMRUNNER_DIR
  >>! cmd"nimble -y install"
  setCurrentDir NIMRUNNER_DIR / "examples" / "nimrunner"
  >>! cmd"nimble -y install"

echo "Don't forget to add " & (getHomeDir() / ".nimble" / "bin") & " to your PATH"
