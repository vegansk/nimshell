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
>>! cmd"git clone -b master --depth 1 git://github.com/Araq/Nim.git $NIM_DIR"
setCurrentDir NIM_DIR
>>! cmd"git clone -b master --depth 1 git://github.com/nim-lang/csources"
setCurrentDir "csources"
>>! sh("." / "build")
setCurrentDir ParDir
>>! ("bin" / exe"nim" & " c koch.nim")
>>! ("." / exe"koch" & " boot -d:release")

echo "Don't forget to add " & (NIM_DIR / "bin") & " to your PATH"

if NIMBLE_DIR == "":
  quit()

# Modify path to install nimble
putEnv("PATH", getEnv("PATH") & $PathSep & (NIM_DIR / "bin"))
  
# Then install nimble
createDir NIMBLE_DIR
>>! cmd"git clone https://github.com/nim-lang/nimble.git $NIMBLE_DIR"
setCurrentDir NIMBLE_DIR
when defined(windows):
  >>! cmd"nim c ${ "src" / "nimble" }"
  moveFile "src" / exe"nimble", "src" / exe"nimble1"
  >>! "src" / exe"nimble1" & " -y install"
else:
  >>! "nim c -r src/nimble -y install"

# Modify path to use nimble
putEnv("PATH", getEnv("PATH") & $PathSep & (getHomeDir() / ".nimble" / "bin"))

# Install nimrunner
let NIMRUNNER_DIR = mktemp()
block:
  defer: removeDir NIMRUNNER_DIR
  >>! cmd"git clone https://github.com/vegansk/nimshell $NIMRUNNER_DIR"
  setCurrentDir NIMRUNNER_DIR
  >>! cmd"nimble -y install"
  setCurrentDir NIMRUNNER_DIR / "examples" / "nimrunner"
  >>! cmd"nimble -y install"

echo "Don't forget to add " & (getHomeDir() / ".nimble" / "bin") & " to your PATH"
