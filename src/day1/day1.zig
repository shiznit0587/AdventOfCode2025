const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const allocator = std.heap.page_allocator;

    // Read all lines as owned copies (each line allocated separately)
    // Read lines using single-pass push-style API (one allocation per line)
    var pushed = try util.readLinesPush(allocator, "src/day1/input.txt");
    defer pushed.deinit(allocator);

    std.debug.print("  Day 1 - Part 1\n", .{});
    // Example: iterate owned lines
    var idx: usize = 0;
    for (pushed.lines) |line| {
        std.debug.print("    pushed line {}: {s}\n", .{ idx, line });
        idx += 1;
    }

    std.debug.print("  Day 1 - Part 2\n", .{});
}
