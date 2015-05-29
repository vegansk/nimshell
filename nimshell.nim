{.push warnings:off hints:off.}
import os, osproc, macros, parseutils, sequtils, streams, strutils, monad/maybe, private/utils
{.pop.}

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

var
  lastExitCode {.threadvar.}: int

proc `>>?`*(c: Command): int

proc exitCode*(c: Command): int =
  if not ?c.process:
    lastExitCode = >>? c
  else:
    lastExitCode = waitForExit(c.process.unbox())
  result = lastExitCode

proc `$?`*(): int = lastExitCode

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
  converter stringToCommand*(s: string): Command = newCommand(s)
  converter commandToBool*(c: Command): bool = c.exitCode() == 0

proc `&>`*(c: Command, s: Stream): Command =
  assert true != ?c.process
  c.stdout = just(s)
  result = c

proc execCommand*(c: Command, options: set[ProcessOption] = {}) =
  assert true != ?c.process
  var opt = options
  var line = c.value
  if not ?c.stdout:
    opt = opt + {poParentStreams}
  when defined(windows):
    line = "cmd /q /d /c " & line
  c.process = just(startProcess(line, "", [], nil, opt + {poEvalCommand, poUsePath, poStdErrToStdOut}))
  if ?c.stdout:
    c.process.unbox().outputStream().copyStream(c.stdout.unbox())

proc `>>?`*(c: Command): int =
  if not ?c.process:
    execCommand(c)
  result = c.exitCode()

proc `>>`*(c: Command) =
  discard >>? c

proc `>>!`*(c: Command) =
  let res = >>? c
  if res != 0:
    write(stderr, "Error code " & $res & " while executing command: " & c.value & "\n")
    quit(res)

proc devNull*(): Stream {.inline.} = newDevNullStream()

template SCRIPTDIR*: expr =
  parentDir(instantiationInfo(0, true).filename)

proc `$`*(c: Command): string =
  let sout = newStringStream()
  >> (c &> sout)
  result = sout.data.strip

proc `$$`*(c: Command): seq[string] =
  result = ($c).splitLines()
  if result[0] == "":
    result = @[]

####################################################################################################
# Helpers

proc which*(name: string): string =
  if existsFile name:
    return name
  for p in getEnv("PATH").split(PathSep):
    if existsFile(p / name):
      return (p / name)
  return ""

proc `?`*(s: string): bool = not (s.strip == "")

####################################################################################################
# Some tests
when isMainModule:
  when defined(windows):
    var v = cmd"""dir ${($$"dir /b /ad c:\\").mapIt(string, "\"c:\\" & it & "\"").join(" ")}"""
    >> v
    assert true == ?v.process

    assert 0 != >>? ("execInvalidCommand" &> devNull())
  
    assert "Hello, world!" == $cmd"echo Hello, world!"

    for v in $$"dir /b c:\\":
      echo "\"" & v & "\""


  elif defined(posix):
    var v = cmd"""ls ${($$"ls /").mapIt(string, "/" & it).join(" ")}"""
    >> v
    assert true == ?v.process
  
    assert 0 != >>? ("execInvalidCommand" &> devNull())
  
    assert "Hello, world!" == $cmd"echo Hello, world!"

    for v in $$"ls -lah /":
      echo "\"" & v & "\""
  
  assert true == (cmd"exit 0" and cmd"exit 0")
  assert false == (cmd"exit 0" and cmd"exit 123")
  assert `$?`() == 123
  
  assert true == (cmd"exit 1" or cmd"exit 0")
  assert false == (cmd"exit 1" or cmd"exit 3")
  assert `$?`() == 3
        
  echo (which "sh")
