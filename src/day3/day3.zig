const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day3/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 3 - Part 1\n", .{});

    var sum1: usize = 0;
    var sum2: usize = 0;
    for (lines.lines) |line| {
        sum1 += try _findJoltage(line, 2, 0);
        sum2 += try _findJoltage(line, 12, 0);
    }

    std.debug.print("    Sum = {}\n", .{sum1});
    std.debug.print("  Day 3 - Part 2\n", .{});
    std.debug.print("    Sum = {}\n", .{sum2});
}

fn _findJoltage(line: []const u8, digits: usize, start: usize) !usize {
    var digit: u8 = '0';
    var idx: usize = 0;
    for (start..line.len - digits + 1) |i| {
        if (line[i] > digit) {
            digit = line[i];
            idx = i;
        }
    }

    return switch (digits) {
        1 => (digit - '0'),
        else => (digit - '0') * try std.math.powi(usize, 10, digits - 1) + try _findJoltage(line, digits - 1, idx + 1),
    };
}
