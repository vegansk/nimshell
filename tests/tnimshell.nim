import options, sequtils, strutils, unittest

# Include since we test private APIs
include ./nimshell

suite "nimshell":
  when defined(windows):
    test "Windows tests":
      var v = cmd"""dir ${($$"dir /b /ad c:\\").mapIt(string, "\"c:\\" & it & "\"").join(" ")}"""
      >> v
      check: true == ?v.process

      for v in $$"dir /b c:\\":
        echo "\"" & v & "\""

  elif defined(posix):
    test "POSIX tests":
      var v = cmd"""ls ${($$"ls /").mapIt(string, "/" & it).join(" ")}"""
      >> v
      check: isSome(v.process)

      for v in $$"ls -lah /":
        echo "\"" & v & "\""

  test "common tests":
    check: 0 != >>? ("execInvalidCommand" &> devNull())
    check: "Hello, world!" == $cmd"echo Hello, world!"

    check: true == (cmd"exit 0" and cmd"exit 0")
    check: false == (cmd"exit 0" and cmd"exit 123")
    check: `$?`() == 123

    check: true == (cmd"exit 1" or cmd"exit 0")
    check: false == (cmd"exit 1" or cmd"exit 3")
    check: `$?`() == 3

    echo(which "sh")
