const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day4/input.txt");
    defer lines.deinit(gpa);

    // for every character, check the nearby characters for being a roll.

    std.debug.print("  Day 4 - Part 1\n", .{});

    var accessibleRolls: i32 = 0;
    for (0..lines.lines.len) |y| {
        const line = lines.lines[y];
        for (0..line.len) |x| {
            if (line[x] != '@') {
                continue;
            }

            var adjacentRolls: i32 = 0;

            // check the adjacent 8 and count how many are crates.
            var dy: i32 = -1;
            while (dy <= 1) : (dy += 1) {
                var dx: i32 = -1;
                while (dx <= 1) : (dx += 1) {
                    if (dx == 0 and dy == 0) {
                        continue;
                    }
                    const x2: i32 = @as(i32, @intCast(x)) + dx;
                    const y2: i32 = @as(i32, @intCast(y)) + dy;
                    if (0 <= x2 and x2 < line.len and
                        0 <= y2 and y2 < lines.lines.len and
                        lines.lines[@as(usize, @intCast(y2))][@as(usize, @intCast(x2))] == '@')
                    {
                        adjacentRolls += 1;
                    }
                }
            }

            if (adjacentRolls < 4) {
                accessibleRolls += 1;
            }
        }
    }

    std.debug.print("    Accessible Rolls = {}\n", .{accessibleRolls});

    std.debug.print("  Day 4 - Part 2\n", .{});
}
