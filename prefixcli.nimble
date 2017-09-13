# Package

version       = "0.1.0"
author        = "d10n"
description   = "Prepend CLI output with a string"
license       = "MIT"

bin = @["prefixcli"]
srcDir = "src"
binDir = "bin"

# Dependencies

requires "nim >= 0.17.0"
requires "docopt >= 0.6.5"

task package, "Prepare for release":
    exec "nimble build"
    if hostOS == "macosx":
        exec "strip bin/prefixcli"
    else:
        exec "strip -s bin/prefixcli"
    exec "upx --best bin/prefixcli"
