## Quick context — what this repo is

- Language: Zig
- Purpose: Advent of Code puzzle runner (each day under `src/dayN`) that exposes a small CLI. The library root is `src/root.zig`, CLI entrypoint is `src/main.zig`.

## Big picture (useful scaffolding knowledge)

- Public module name: `AdventOfCode2025` — defined in `build.zig` with `root.zig` as the library root. Top-level executable is `src/main.zig`.
- Day-specific code is organized under `src/day{N}/day{N}.zig`. Each day module is expected to expose a `pub fn run()` that takes no args and performs both part 1 and part 2 outputs. Example: `src/day1/day1.zig` and its `src/day1/input.txt`.
- `src/root.zig` imports per-day modules and calls `runDay(day, &dayX.run)` — add new days here by importing the file and registering a call to `runDay`.
 - `src/root.zig` now also re-exports helpers (see `pub const util = @import("util.zig")`). Use `@import("AdventOfCode2025").util` from day modules instead of fragile relative imports.

## Build / run / test (exact commands to use)

- Build the project (default target = native):
  - `zig build`
- Run the app (from the repo root):
  - `zig build run --` (args after `--` are forwarded to the program)
- Run tests (the build script defines test steps for both library and executable):
  - `zig build test`
- Installed binary location (default prefix): `zig-out/bin/AdventOfCode2025` after `zig build`.

## Project-specific patterns & tips for making edits

- When adding a new day:
  1. Create `src/dayN/dayN.zig` with `pub fn run() void` (or `!void` if the code uses `try`).
  2. Put the puzzle input at `src/dayN/input.txt` and open it via `std.fs.cwd().openFile("src/dayN/input.txt", .{})`
  3. In `src/root.zig` import `@import("dayN/dayN.zig")` and call `try runDay(N, &dayN.run);`

- I/O & error handling: many day files will use `try`; prefer `pub fn run() !void` if the body calls `try` — otherwise compilation errors occur (e.g., `try` inside a `void` function will fail to compile).
 - Helpers exported on the library root: use `const util = @import("AdventOfCode2025").util;` in day files for consistent imports.

- Timing/logging: the runner uses `std.time.Timer` and `std.debug.print` to show timings for each day and the total run.

## Testing guidance

- The build script already provides `zig build test` which runs all `test` blocks. If you add test blocks inside a day module or the root module, they will be discovered by Zig's test runner.

## Files to reference while editing

- `build.zig` — build targets, test/run steps and install locations
- `src/root.zig` — the overall runner and how days are registered + timing
- `src/main.zig` — entrypoint for the executable
- `src/day*/` — per-day implementation and `input.txt` location

## Example tasks an AI agent should be able to perform immediately

- Add a new day module for day 2 and wire it into `src/root.zig`.
- Fix a compilation error caused by a `try` inside a `pub fn run() void` by converting it to `pub fn run() !void` and updating callers.
- Add unit tests using Zig `test` blocks inside a day module and run `zig build test`.

If any part of this repo's structure is unclear, tell me where you want more detail and I'll expand these instructions.
