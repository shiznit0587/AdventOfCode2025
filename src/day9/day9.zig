const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day9/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 9 - Part 1\n", .{});

    var tiles = try std.ArrayList(Point).initCapacity(gpa, rlr.lines.len);

    for (rlr.lines) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');
        tiles.appendAssumeCapacity(.{
            .x = try std.fmt.parseInt(i64, iter.next().?, 10),
            .y = try std.fmt.parseInt(i64, iter.next().?, 10),
        });
    }

    var largest: u64 = 0;
    for (0..tiles.items.len - 1) |i| {
        for (i + 1..tiles.items.len) |j| {
            const a = tiles.items[i];
            const b = tiles.items[j];
            const area = (@abs(a.x - b.x) + 1) * (@abs(a.y - b.y) + 1);
            largest = @max(largest, area);
        }
    }

    std.debug.print("    largest area = {}\n", .{largest});
    std.debug.print("  Day 9 - Part 2\n", .{});
}

const Point = struct { x: i64, y: i64 };
