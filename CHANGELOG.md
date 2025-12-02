# Day 1

I got the basics in place. There's a function that takes a lambda to run each day while timing it.

I decided to use the Raptor Mini AI coding agent with this project, to help me hit the ground running in zig. I've never used an AI in Agent mode before, I'd only used in Ask mode. It's quite a different experience, allowing the AI to run commands, edit files, etc. It's been somewhat helpful. It gave me multiple approaches to reading in the lines of a file and explaining how memory ownership is managed. However, it took a lot of iteration on its own to get results that compiled, and the end results were unneccesarily convoluted. It never used a file reader or buffered reader, ArrayList or Spliterator; it just did the raw reads, buffer management, overflow management, and container resizing manually. So far, I would not hire this AI for a job.

It didn't help that zig had an overhaul of its I/O library recently (dubbed "writergate"), which has rendered forum posts, blog posts, stack overflow posts, documentation, and trained AI models obsolete. And the new library was having issues internally as well, so that was fun.

Once I finished the `util.readLines` method, the actual puzzle only took ten minutes.

# Project Setup

> `brew install zig`

## VS Code Plugins
- [Zig Language](https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig)
- [LLDB DAP](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.lldb-dap)

## VS Code Settings
```json
"zig.zls.enabled": "on",
"lldb-dap.executable-path": "/Applications/Xcode.app/Contents/Developer/usr/bin/lldb-dap",
"lldb-dap.serverMode": true
```

## `launch.json`
```json
"configurations": [
    {
        "type": "lldb-dap",
        "request": "launch",
        "name": "Debug",
        "program": "${workspaceRoot}/zig-out/bin/AdventOfCode2025",
        "args": [],
        "env": [],
        "cwd": "${workspaceRoot}",
        "preLaunchTask": "zig build"
    }
]
```

## `tasks.json`
```json
"tasks": [
    {
        "label": "zig build",
        "type": "shell",
        "command": "zig",
        "args": [
            "build"
        ],
        "group": {
            "kind": "build",
            "isDefault": true
        }
    }
]
```

# References

- https://ziglang.org/
- https://ziglang.org/documentation/master/
- https://ziglang.org/documentation/master/std/
- https://zigistry.dev/
- https://ziggit.dev/
- https://zigistry.dev/programs/github/zig-utils/zig-regex/
- https://ziggit.dev/t/debugging-zig-with-a-debugger/7160/
