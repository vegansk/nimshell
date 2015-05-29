import streams

type
  DevNullStreamObj = object of StreamObj
  DevNullStream* = ref DevNullStreamObj

when defined(windows):
  const
    IO_BUFF_SIZE = 1
else:
  const
    IO_BUFF_SIZE = 4096


proc nullClose(s: Stream)  = discard
proc nullAtEnd(s: Stream): bool  = true
proc nullSetPosition(s: Stream; pos: int)  = discard
proc nullGetPosition(s: Stream): int  = -1
proc nullReadData(s: Stream; buffer: pointer; bufLen: int): int = 0
proc nullWriteData(s: Stream; buffer: pointer; bufLen: int) = discard
proc nullFlush(s: Stream) = discard

proc newDevNullStream*(): DevNullStream =
  new(result)
  result.closeImpl = nullClose
  result.atEndImpl = nullAtEnd
  result.setPositionImpl = nullSetPosition
  result.getPositionImpl = nullGetPosition
  result.readDataImpl = nullReadData
  result.writeDataImpl = nullWriteData
  result.flushImpl = nullFlush

proc copyStream*(sin: Stream, sout: Stream) =
  var arr: array[0..IO_BUFF_SIZE-1, uint8]
  while not sin.atEnd:
    let len = sin.readData(addr(arr), arr.len)
    if len > 0:
      sout.writeData(addr(arr), len)

when isMainModule:
  let
    sin = newStringStream("Hello, world!")
    sout = newStringStream()

  sin.copyStream(sout)

  echo sout.data
  
