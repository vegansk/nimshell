import nimshell, os, oids, future, osproc, sequtils, strutils

# First try compilers which are known to be fast(er than GCC)
var COMPILER = ""
when defined(posix):
  let which = "which"
  let exeName = "executable"
elif defined(windows):
  let which = "where"
  let exeName = "executable.exe"
else:
  {.error "Your OS is not supported".}

proc mktemp(): string =
  result = getTempDir() / $genOid()
  createDir(result)

if not (cmd"$which nim" &> devNull()): quit("Nim is not found on your system")
  
if (cmd"$which tcc" &> devNull()):
  COMPILER = "--cc:tcc"
elif ("$which clang" &> devNull()):
  COMPILER = "--cc:clang"

block:
  let tmp = mktemp()
  defer: removeDir(tmp)

  >>! cmd"""nim c --verbosity:0 --hints:off $COMPILER --out:"${tmp / exeName}" --nimcache:"$tmp" "${paramStr(1)}""""

  quit (>>? cmd"""${tmp / exeName} ${lc[paramStr(i) | (i <- 2..paramCount()), string].mapIt(string, quoteShell(it)).join(" ")}""")

  