# setStdIoUnbuffered() # doesn't affect readBuffer and slows down read
{.deadCodeElim: on.} # the binary got huge, so adding this just to be safe

import posix
import posix/termios
import terminal
import strutils
import docopt
import osproc
import sequtils

setControlCHook(proc(){.noconv.} = discard)


# proc c_setvbuf(f: File, buf: pointer, mode: cint, size: csize): cint {.
#   importc: "setvbuf", header: "<stdio.h>", tags: [].}
# var myIONBF {.importc: "_IONBF", nodecl.}: cint
# discard c_setvbuf(stdout, nil, myIONBF, 0)

type cssize* {.importc: "ssize_t", nodecl.} = int # size_t is supposed to be uint but it isn't!

var TIOCSWINSZ* {.importc, header: "<sys/ioctl.h>".}: cuint

# Ripped from sysio:
# when not declared(sysFatal):
#   {.push profiler: off.}
#   when hostOS == "standalone":
#     proc sysFatal(exceptn: typedesc, message: string) {.inline.} =
#       panic(message)

#     proc sysFatal(exceptn: typedesc, message, arg: string) {.inline.} =
#       rawoutput(message)
#       panic(arg)
#   else:
#     proc sysFatal(exceptn: typedesc, message: string) {.inline, noReturn.} =
#       var e: ref exceptn
#       new(e)
#       e.msg = message
#       raise e

#     proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noReturn.} =
#       var e: ref exceptn
#       new(e)
#       e.msg = message & arg
#       raise e
#   {.pop.}

# include system
# include system/sysio # to get checkErr

{.push stackTrace:off, profiler:off.}
proc c_read(filedes: cint, buf: pointer, n: csize_t): cssize {.
  importc: "read", header: "<stdio.h>", tags: [ReadIOEffect].}
proc c_ferror(f: File): cint {.
  importc: "ferror", header: "<stdio.h>", tags: [].}
proc c_clearerr(f: File) {.
  importc: "clearerr", header: "<stdio.h>".}
proc raiseEIO(msg: string) {.noinline, noreturn.} =
  var e: ref IOError
  e.msg = msg
  raise e
  # sysFatal(IOError, msg)
proc checkErr(f: File) =
  if c_ferror(f) != 0:
    c_clearerr(f)
    raiseEIO("Unknown IO Error")

proc read(f: File, buffer: pointer, len: Natural): int =
  result = c_read(f.getFileHandle, buffer, csize_t(len))
  if result != len: checkErr(f)
{.pop.}

const doc = """
Prefix CLI program output lines with a string.

Usage:
  prefixcli [--eval] [--sep=SEP] [<prefix>]
  prefixcli [options]

Arguments:
  <prefix>    The string to prefix each terminal line with. (default: ">")

Options:
  --sep=SEP   The separator to use after the prefix. (default: " ")
  --eval      Evaluate the prefix as a shell command
  -h --help   Show this screen
  --version   Show version

Examples:
  tcpdump -i any 'tcp port 443' | prefixcli --eval 'date +%s'
"""

let args = docopt(doc, version = "Prefix CLI 0.1")
# echo args

var separator:string

if args["--sep"].kind == ValueKind.vkStr:
  separator = $args["--sep"]
else:
  separator = " "

var prefix:string
if args["<prefix>"]:
  prefix = $args["<prefix>"]
else:
  prefix = ">"

prefix.add(separator)

let eval = args["--eval"].to_bool
var lastEvalLength = 0

proc setTerminalSize(width: int, height: int):int =
  var winSize = IOctl_WinSize(ws_row: height.cushort, ws_col: width.cushort)
  result = ioctl(stdout.getFileHandle, TIOCSWINSZ, addr winsize)


var originalTerminalWidth:int
var finalTerminalWidth:int
var lastTerminalWidth:int
var currentTerminalWidth:int
var lastTerminalHeight:int

let inTty = any(@[stdin, stdout, stderr], proc(x:File):bool = x.isatty)
if inTty:
  lastTerminalHeight = terminalHeight()
  originalTerminalWidth = terminalWidth()
  finalTerminalWidth = originalTerminalWidth
  system.addQuitProc(proc(){.noconv.} =
    discard setTerminalSize(finalTerminalWidth, lastTerminalHeight)
    resetAttributes())

  if eval:
    prefix = ""
    lastEvalLength = prefix.len

  discard setTerminalSize(originalTerminalWidth - prefix.len, lastTerminalHeight)
  lastTerminalWidth = terminalWidth()

# import os
# var prefix:string
# if paramCount() > 0:
#   prefix = paramStr(1)
# else:
#   prefix = ">"

# let prefix = ">"

const bufferSize = 8192 # works with c_read but not c_fread or readBuffer!
# const bufferSize = 1 # works with c_fread and readBuffer but slow!
var buffer = newString(bufferSize)
var lastByteWasLf = true
var bytesRead: int
# nim can't handle while (bytesRead = stdin.read(..)) != 0
bytesRead = stdin.read(buffer[0].addr, bufferSize)
# while not stdin.endOfFile: # does not work with read()
while bytesRead != 0:
  if eval:
    prefix = execProcess("sh", args=["-c", $args["<prefix>"]], options={
      poUsePath, poStdErrToStdOut
    })
    prefix.removeSuffix('\l')
    prefix.add(separator)

  if inTty:
    currentTerminalWidth = terminalWidth()
    lastTerminalHeight = terminalHeight()
    let evalLengthChanged = lastEvalLength != prefix.len
    let windowResized = currentTerminalWidth != lastTerminalWidth
    if windowResized or evalLengthChanged:
      if windowResized:
        # assume window resized and the width is accurate
        finalTerminalWidth = currentTerminalWidth
      discard setTerminalSize(currentTerminalWidth + lastEvalLength - prefix.len, lastTerminalHeight)
      currentTerminalWidth = terminalWidth()
      lastTerminalWidth = currentTerminalWidth
      lastEvalLength = prefix.len

  # echo "reading stdin"
  # let bytesRead = stdin.read(buffer[0].addr, bufferSize)
  # let bytesRead = stdin.readBuffer(buffer[0].addr, bufferSize)

  var start = 0
  if lastByteWasLf:
    stdout.write(prefix)
  for i in 0..<bytesRead:
    # skip last \l because there might not be text on the new line to prefix
    if (i != bytesRead - 1 and buffer[i] == '\l') or (buffer[i] == '\r'):
      let length = i - start + 1
      discard stdout.writeBuffer(buffer[start].addr, length)
      start = i + 1
      stdout.write(prefix)
  if start < bytesRead:
    let length = bytesRead - start
    discard stdout.writeBuffer(buffer[start].addr, length)
  stdout.flushFile()
  # echo bytesRead
  if bytesRead > 0:
    lastByteWasLf = buffer[bytesRead - 1] == '\l'
  bytesRead = stdin.read(buffer[0].addr, bufferSize)
