# Day 5

I kept having an issue where after my code to merge ranges, it looked as though no changes had been made to them. I needed to take a pointer to the ranges in the list, otherwise I was modifying a copy. Beginner mistake.

# Day 4

I'm really over zig's incessant safety. Any time I want to use a for loop with negative numbers, or with an increment of anything other than a usize, I have to jump through hoops. I can't just use an i32 as an indexer, it must be a usize. It takes two builtin functions for every cast. It's just extra code the compiler could already deduce.

# Day 3

I didn't find Day 3 at all challenging. By using character subtraction, I never needed to perform any full string -> number conversion, and indexing into the line for single digits was super quick.

# Day 2

The AI coding agent was terrible for this day. It kept trying to generate invalid reverse-iterating for loops, using wrong number types for variables, etc. It was just getting it my way.

For the puzzle itself, I had two ideas for a solution:
1. Convert each number between the range bounds to a string and compare the two halves.
2. Convert each number between the range bounds to a list of digits and compare the two halves.

I went with option 2. I'm kind of regretting it, as the solution takes >8s to run.

For part 2, I came up with a completely different approach. For each range, for each length of repeated digits, I iterate between the min and max for the repeated section, expand it out to the correct number of digits, then check if the generated number is still in the range. Then I had to add tracking for seen values, as 222222 was being counted three times - as 2 repeated, 22 repeated, and 222 repeated. The final solution for Day 2 runs in .7 ms!

I'm beginning to dislike this language, at least for these puzzles. The compiler makes it a point to require the programmer to be tediously explicit; with valuetype casts, with integer division, with const correctness; it doesn't let any ambiguity through. There's also the fact that every single allocation must be "tried". I'm sure for systems programming it's important to be able to recover or repair gracefully when system resources are low, but it's unneccessary for this type of project.

# Day 1

I got the basics in place. There's a function that takes a lambda to run each day while timing it.

I decided to use the Raptor Mini AI coding agent with this project, to help me hit the ground running in zig. I've never used an AI in Agent mode before, I'd only used in Ask mode. It's quite a different experience, allowing the AI to run commands, edit files, etc. It's been somewhat helpful. It gave me multiple approaches to reading in the lines of a file and explaining how memory ownership is managed. However, it took a lot of iteration on its own to get results that compiled, and the end results were unneccesarily convoluted. It never used a file reader or buffered reader, ArrayList or Spliterator; it just did the raw reads, buffer management, overflow management, and container resizing manually. So far, I would not hire this AI for a job.

It didn't help that zig had an overhaul of its I/O library recently (dubbed "writergate"), which has rendered forum posts, blog posts, stack overflow posts, documentation, and trained AI models obsolete. And the new library was having issues internally as well, so that was fun.

Once I finished the `util.readLines` method, the actual puzzle only took ten minutes and runs in .5 ms.

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
