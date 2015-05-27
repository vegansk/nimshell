import os, macros, parseutils, sequtils

macro i*(text: string{lit}): expr =
  var nodes: seq[NimNode] = @[]
  # Parse string literal into "stuff".
  for k, v in text.strVal.interpolatedFragments:
    if k == ikStr or k == ikDollar:
      nodes.add(newLit(v))
    else:
      nodes.add(parseExpr("$(" & v & ")"))
  # Fold individual nodes into a statement list.
  result = newNimNode(nnkStmtList).add(
    foldr(nodes, a.infix("&", b)))

proc `>>?`*(s: string): int =
  execShellCmd s

proc `>>>?`*(s: string): int =
  >>? (s & " > /dev/null")
  
proc `>>`*(s: string) =
  discard >>? s

proc `>>>`*(s: string) =
  discard >>>? s

proc `>>!`*(s: string) =
  let code = >>? s
  if code != 0:
    writeln(stdmsg, "Error code ", code, " executing: ", s)

proc `>>>!`*(s: string) =
  >>! (s & " > /dev/null")

template DIRNAME*: expr =
  parentDir(instantiationInfo(0, true).filename)
