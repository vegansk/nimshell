import nimshell, os, future, osproc, sequtils, strutils

# First try compilers which are known to be fast(er than GCC)
var COMPILER = ""
let exeName = exe"executable"

if not ?(which "nim"): quit("Nim is not found on your system")
  
if ?(which "tcc"):
  COMPILER = "--cc:tcc"
elif ?(which "clang"):
  COMPILER = "--cc:clang"

block:
  let tmp = mktemp()
  defer: removeDir(tmp)

  >>! cmd"""nim c --verbosity:0 --hints:off $COMPILER --out:"${tmp / exeName}" --nimcache:"$tmp" "${paramStr(1)}""""

  quit (>>? cmd"""${tmp / exeName} ${lc[paramStr(i) | (i <- 2..paramCount()), string].mapIt(string, quoteShell(it)).join(" ")}""")

