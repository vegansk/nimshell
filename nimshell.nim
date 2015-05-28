import os, osproc, macros, parseutils, sequtils, streams, strutils, monad/maybe, private/utils

type
  Command* = ref object
    value: string
    process: Maybe[Process]
    stdout: Maybe[Stream]

proc newCommand*(cmd: string): Command =
  new(result)
  result.value = cmd
  result.process = nothing[Process]()
  result.stdout = nothing[Stream]()

# Maybe.unbox causes compile error. https://github.com/superfunc/monad/issues/1
proc unbox[T](v: Maybe[T]): T = v.value

proc close*(cmd: Command) =
  if ?cmd.process:
    cmd.process.unbox().close()

macro cmd*(text: string{lit}): expr =
  var nodes: seq[NimNode] = @[]
  for k, v in text.strVal.interpolatedFragments:
    if k == ikStr or k == ikDollar:
      nodes.add(newLit(v))
    else:
      nodes.add(parseExpr("$(" & v & ")"))
  var str = newNimNode(nnkStmtList).add(
    foldr(nodes, a.infix("&", b)))
  result = newCall(bindSym"newCommand", str)

when not defined(shellNoImplicits):
  converter stringToCommand(s: string): Command = newCommand(s)

proc `&>`(c: Command, s: Stream): Command =
  assert true != ?c.process
  c.stdout = just(s)
  result = c
  
proc execCommand*(c: Command, options: set[ProcessOption] = {}) =
  assert true != ?c.process
  var opt = options
  if not ?c.stdout:
    opt = opt + {poParentStreams}
  c.process = just(startProcess(c.value, "", [], nil, opt + {poEvalCommand}))
  if ?c.stdout:
    c.process.unbox().outputStream().copyStream(c.stdout.unbox())

proc exitCode(c: Command): int =
  result = waitForExit(c.process.unbox())

proc `>>?`*(c: Command): int =
  execCommand(c)
  result = c.exitCode()

proc `>>`*(c: Command) =
  discard >>? c

proc `>>!`*(c: Command) =
  let res = >>? c
  if res != 0:
    write(stderr, "Error code " & $res & " while executing command: " & c.value)
    quit(res)

template SCRIPTDIR*: expr =
  parentDir(instantiationInfo(0, true).filename)

proc `$`*(c: Command): string =
  let sout = newStringStream()
  >> (c &> sout)
  result = sout.data.strip

proc `$$`*(c: Command): seq[string] = ($c).splitLines()

when isMainModule:
  var v = cmd"""ls ${($$"ls /").mapIt(string, "/" & it).join(" ")}"""
  >> v
  assert true == ?v.process

  assert 0 != >>? ("execInvalidCommand" &> newDevNullStream())

  assert "Hello, world!" == $cmd"echo Hello, world!"
  for v in $$"ls -lah /":
    echo "\"" & v & "\""
