# coreutils4win

GNU coreutils reimplemented in Zig, targeting Windows (x86_64).

## Utilities

`basename` `cat` `cp` `dirname` `echo` `false` `head` `ls` `mkdir` `mv` `pwd` `rm` `rmdir` `tail` `touch` `true` `uname` `whoami`

## Build

Requires Zig 0.15+. Produces Windows PE executables regardless of host OS.

```
zig build
```

Binaries are placed in `zig-out/bin/`.

## Test

```
zig build test
```

## License

Apache License 2.0. Copyright (C) 2026 AnmiTaliDev.
