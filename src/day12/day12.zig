const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day12/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 12 - Part 1\n", .{});

    // I want to see what Part 2 is, so here's what I'm going to do.
    // So, I'm going to simply count how many regions have a size large enough to hold
    // the presents, based only on the number of spaces each takes up.
    // Then I'll keep guessing via binary search.

    const spaces = [_](usize){ 7, 7, 5, 7, 6, 7 };

    var count: usize = 0;
    for (30..rlr.lines.len) |i| {
        const line = rlr.lines[i];
        const width = try std.fmt.parseInt(usize, line[0..2], 10);
        const height = try std.fmt.parseInt(usize, line[3..5], 10);

        const counts = [_](usize){
            try std.fmt.parseInt(usize, line[7..9], 10),
            try std.fmt.parseInt(usize, line[10..12], 10),
            try std.fmt.parseInt(usize, line[13..15], 10),
            try std.fmt.parseInt(usize, line[16..18], 10),
            try std.fmt.parseInt(usize, line[19..21], 10),
            try std.fmt.parseInt(usize, line[22..24], 10),
        };

        const sizeSums = counts[0] * spaces[0] +
            counts[1] * spaces[1] +
            counts[2] * spaces[2] +
            counts[3] * spaces[3] +
            counts[4] * spaces[4] +
            counts[5] * spaces[5];

        if (sizeSums <= width * height) {
            count += 1;
        }
    }

    std.debug.print("    Count = {}\n", .{count});

    // THAT WAS THE RIGHT ANSWER!?!?

    std.debug.print("  Day 12 - Part 2\n", .{});

    // Part 2 is locked until completing all other parts.
}
