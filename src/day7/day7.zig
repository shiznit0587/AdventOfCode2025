const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day7/input.txt");
    defer rlr.deinit(gpa);
    const width = rlr.lines[0].len;

    std.debug.print("  Day 7 - Part 1\n", .{});

    var beams: std.ArrayList(u64) = try std.ArrayList(u64).initCapacity(gpa, width);
    defer beams.deinit(gpa);

    for (0..width) |x| {
        beams.appendAssumeCapacity(if (rlr.lines[0][x] == 'S') 1 else 0);
    }

    var splits: usize = 0;
    var y: usize = 2;
    while (y < rlr.lines.len) : (y += 2) {
        for (0..width) |x| {
            if (beams.items[x] > 0 and rlr.lines[y][x] == '^') {
                beams.items[x - 1] += beams.items[x];
                beams.items[x + 1] += beams.items[x];
                beams.items[x] = 0;
                splits += 1;
            }
        }
    }

    var sum: u64 = 0;
    for (0..width) |x| {
        sum += beams.items[x];
    }

    std.debug.print("    beams splits = {}\n", .{splits});
    std.debug.print("  Day 7 - Part 2\n", .{});
    std.debug.print("    timelines = {}\n", .{sum});
}
