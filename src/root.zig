//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

const day1 = @import("day1/day1.zig");

pub fn run() !void {
    std.debug.print("\n🎅🎅🎅🎅🎅 ADVENT OF CODE 2025 🎅🎅🎅🎅🎅\n\n", .{});

    var timer = try std.time.Timer.start();

    try runDay(1, day1.run);

    std.debug.print("Total Time = {d:.3} ms\n", .{@as(f64, @floatFromInt(timer.read())) / std.time.ns_per_ms});
    std.debug.print("\n", .{});
}

fn runDay(day: usize, runFn: fn () anyerror!void) !void {
    std.debug.print("Running Day {}...\n", .{day});

    var timer = try std.time.Timer.start();
    try runFn();
    std.debug.print("Day {} Time = {d:.3} ms\n\n", .{ day, @as(f64, @floatFromInt(timer.read())) / std.time.ns_per_ms });
}
