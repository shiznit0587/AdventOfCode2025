# Day 9

Part 2 of this day was definitely the weeding-out puzzle. I tried some computational geometry algorithms from "Introduction to Algorithms: Second Edition" for finding whether edges intersect via a direction calculated from cross products. With all edges being strictly vertical or horizontal and the values being whole integers, the standard algorithms just broke down on me. I probably forgot to do some type-casting. There was also the issue that "intersects" in the traditional sense includes the case of an endpoint from one edge being along the other edge, but that's allowed here as long as the edge doesn't extend into the rect's region. I spent three days on this solution, and I still think it's not 100% correct. I think that the rect formed by the points `2,5` and `9,7` in the example would also pass my checks, but it is entirely _outside_ the region formed by the edges. It happens to have the same area as the proper solution though, so my testing didn't catch it.

# Day 8

Not much to say this day, just that I hit an issue again with modifying a copy instead of the contents within a list.

# Day 7

That felt trivial compared to the other days so far, and for the first time, the language didn't really get in my way.

# Day 6

I tried to save processing time by implementing a version of `utils.readLines` that takes a lambda, and writing one for parsing the lines out into operands for equations. zig is extremely limited in what a "lambda" can do. First off, it must be a member of a type. Second, it can't access any state. Third, there's no way to bind arguments to a function.

I also got tripped up at one point about sometimes getting a reference to an item in a data container, or getting a copy. There's seemingly no consistency in the API, and there's no syntactic difference between the two as far as I can tell.

The constraints of this language, its instability, and the things it decides to or not to be opinionated about, are really starting to wear on me.

# Day 5

I kept having an issue where after my code to merge ranges, it looked as though no changes had been made to them. I needed to take a pointer to the ranges in the list, otherwise I was modifying a copy. Beginner mistake.

# Day 4

I'm really over zig's incessant safety. Any time I want to use a for loop with negative numbers, or with an increment of anything other than a usize, I have to jump through hoops. I can't just use an i32 as an indexer, it must be a usize. It takes two builtin functions for every cast. It's just extra code the compiler could already deduce.

I went back and attempted multiple algorithm changes to optimize this day. It was taking 48ms. I reworked it to edit the lines in place, and that brought it down to 40ms. I tried changing it to tracking a queue of coords to process, removing all full scans of the grid. I tried implementing my own linked list. I tried converting from [][]u8 to [][]bool. I tried pre-caching all the adjacent coords with rolls per starting roll. I tried keeping lists of adjacent rolls in a map. That last one took longer just to build the data structure. Then I ported a double-buffered solution I'd seen elsewhere, reducing heap alloc calls to just two. That was ~200ms. I can not for the life of me figure out a way to make this solution faster.

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
