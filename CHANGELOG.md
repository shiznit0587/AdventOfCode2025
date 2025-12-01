# Day 1

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
