import nimshell, os, future, osproc, sequtils, strutils, tables

type Settings = Table[string,string]
proc initSettings(): Settings = initTable[string,string]()

proc parseSettingsLine(s: string): Settings =
  result = initSettings()
  let kv = s.split "="
  if kv.len == 2:
    result[kv[0].strip] = kv[1].strip

proc readScriptSettings(): Settings =
  result = initSettings()
  let f = system.open paramStr(1)
  defer: f.close
  while not f.endOfFile:
    let line = f.readLine.strip
    if not line.startsWith "##:": continue
    for k, v in line[3..^0].parseSettingsLine:
             result[k] = v

let ss = readScriptSettings()
  
# First try compilers which are known to be fast(er than GCC)
var COMPILER = ""
let exeName = exe"executable"

if not ?(which "nim"): quit("Nim is not found on your system")
  
if ss.hasKey "cc":
  COMPILER = "--cc:" & ss["cc"]
elif ?(which "tcc"):
  COMPILER = "--cc:tcc"
elif ?(which "clang"):
  COMPILER = "--cc:clang"

block:
  let tmp = mktemp()
  defer: removeDir(tmp)

  >>! cmd"""nim c --verbosity:0 --hints:off --warnings:off $COMPILER --out:"${tmp / exeName}" --nimcache:"$tmp" "${paramStr(1)}""""

  quit (>>? cmd"""${tmp / exeName} ${lc[paramStr(i) | (i <- 2..paramCount()), string].mapIt(string, quoteShell(it)).join(" ")}""")

