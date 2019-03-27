import unittest, streams
import ./nimshell/private/utils

suite "copyStream":
  test "correctly copies data":
    let
      input = "Hello, world!"
      sin = newStringStream("Hello, world!")
      sout = newStringStream()

    sin.copyStream(sout)

    let output = sout.data
    check: output == input
