import os, osproc, macros, parseutils, sequtils, streams, strutils

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
  >>? (s & " >& /dev/null")
  
proc `>>`*(s: string) =
  discard >>? s

proc `>>>`*(s: string) =
  discard >>>? s

proc `>>!`*(s: string) =
  let code = >>? s
  if code != 0:
    writeln(stdmsg, "Error code ", code, " executing: ", s)

proc `>>>!`*(s: string) =
  >>! (s & " >& /dev/null")

template DIRNAME*: expr =
  parentDir(instantiationInfo(0, true).filename)

type
  Cmd* = distinct Process

proc cmd*(c: string): Cmd = 
  startProcess(c, "", [], nil, {poEvalCommand}).Cmd

proc stdout*(c: Cmd): Stream =
  Process(c).outputStream

proc `$`*(c: Cmd): string =
  let s = c.stdout
  result = ""
  while not s.atEnd:
    result.add(s.readLine.string & "\n")

proc `$$`*(c: Cmd): string =
  let s = c.stdout
  var res: seq[string] = @[]
  while not s.atEnd:
    res.add(s.readLine.string)
  result = res.join(" ")
  
when isMainModule:
  let x = $$cmd"docker ps --no-trunc -aq"
  echo i"docker rm $x"
