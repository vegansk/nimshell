# Package

version       = "0.1.0"
author        = "Anatoly Galiulin"
description   = "Download and install script for nim language"
license       = "MIT"
bin           = @["nimbootstrap"]
binDir        = "bin"

# Deps

requires "nim >= 0.10.2", "nimshell"
