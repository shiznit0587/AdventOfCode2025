const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const allocator = std.heap.page_allocator;

    var lines = try util.readLines(allocator, "src/day1/input.txt");
    defer lines.deinit(allocator);

    std.debug.print("  Day 1 - Part 1\n", .{});

    var dial: i32 = 50;
    var password1: u32 = 0;
    var password2: u32 = 0;

    for (lines.lines) |line| {
        const step = try std.fmt.parseInt(i32, line[1..], 10);

        dial = switch (line[0]) {
            'L' => (dial - step),
            'R' => (dial + step),
            else => dial,
        };

        while (dial < 0) {
            dial += 100;
            password2 += 1;
        }

        while (dial >= 100) {
            dial -= 100;
            password2 += 1;
        }

        if (dial == 0) {
            password1 += 1;
        }
    }

    std.debug.print("    Password: {d}\n", .{password1});
    std.debug.print("  Day 1 - Part 2\n", .{});
    std.debug.print("    Password: {d}\n", .{password2});
}
