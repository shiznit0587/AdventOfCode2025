const std = @import("std");
const util = @import("../util.zig");

const Range = struct { start: usize, end: usize, alive: bool = true };

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day5/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 5 - Part 1\n", .{});

    var ranges = std.ArrayList(Range).empty;
    var ids = std.ArrayList(usize).empty;

    var parsingRanges = true;
    for (lines.lines) |line| {
        if (line.len == 0) {
            parsingRanges = false;
        } else if (parsingRanges) {
            var iter = std.mem.splitScalar(u8, line, '-');
            const start = try std.fmt.parseInt(usize, iter.next().?, 10);
            const end = try std.fmt.parseInt(usize, iter.next().?, 10);
            try ranges.append(gpa, Range{ .start = start, .end = end });
        } else {
            try ids.append(gpa, try std.fmt.parseInt(usize, line, 10));
        }
    }

    var count: usize = 0;
    for (ids.items) |id| {
        for (ranges.items) |range| {
            if (range.start <= id and id <= range.end) {
                count += 1;
                break;
            }
        }
    }

    std.debug.print("    Fresh Count = {}\n", .{count});
    std.debug.print("  Day 5 - Part 2\n", .{});

    std.mem.sortUnstable(Range, ranges.items[0..], {}, rangeLess);

    // Merge overlapping ranges.
    for (0..ranges.items.len - 1) |i| {
        var ri = &ranges.items[i];
        if (!ri.alive) continue;
        for (i + 1..ranges.items.len) |j| {
            var rj = &ranges.items[j];
            if (rj.alive and ri.end >= rj.start) {
                ri.end = @max(ri.end, rj.end);
                rj.alive = false;
            }
        }
    }

    count = 0;
    for (ranges.items) |range| {
        if (range.alive) count += range.end - range.start + 1;
    }

    std.debug.print("    Fresh Count = {}\n", .{count});
}

fn rangeLess(_: void, a: Range, b: Range) bool {
    return a.start < b.start;
}
