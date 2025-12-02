const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const allocator = std.heap.page_allocator;

    var lines = try util.readLines(allocator, "src/day1/input.txt");
    defer lines.deinit(allocator);

    std.debug.print("  Day 1 - Part 1\n", .{});

    // Example: iterate owned lines
    var idx: usize = 0;
    for (lines.lines) |line| {
        std.debug.print("    pushed line {}: {s}\n", .{ idx, line });
        idx += 1;
    }

    std.debug.print("  Day 1 - Part 2\n", .{});
}
