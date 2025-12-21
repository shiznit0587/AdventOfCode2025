//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const day1 = @import("day1/day1.zig");
const day2 = @import("day2/day2.zig");
const day3 = @import("day3/day3.zig");
const day4 = @import("day4/day4.zig");
const day5 = @import("day5/day5.zig");
const day6 = @import("day6/day6.zig");
const day7 = @import("day7/day7.zig");
const day8 = @import("day8/day8.zig");
const day9 = @import("day9/day9.zig");

pub fn run() !void {
    std.debug.print("\n🎅🎅🎅🎅🎅 ADVENT OF CODE 2025 🎅🎅🎅🎅🎅\n\n", .{});

    var timer = try std.time.Timer.start();

    try runDay(1, day1.run);
    try runDay(2, day2.run);
    try runDay(3, day3.run);
    try runDay(4, day4.run);
    try runDay(5, day5.run);
    try runDay(6, day6.run);
    try runDay(7, day7.run);
    try runDay(8, day8.run);
    try runDay(9, day9.run);

    std.debug.print("Total Time = {d:.3} ms\n", .{@as(f64, @floatFromInt(timer.read())) / std.time.ns_per_ms});
    std.debug.print("\n", .{});
}

fn runDay(day: usize, runFn: fn () anyerror!void) !void {
    std.debug.print("Running Day {}...\n", .{day});

    var timer = try std.time.Timer.start();
    try runFn();
    std.debug.print("Day {} Time = {d:.3} ms\n\n", .{ day, @as(f64, @floatFromInt(timer.read())) / std.time.ns_per_ms });
}
