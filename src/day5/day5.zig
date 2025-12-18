const std = @import("std");
const util = @import("../util.zig");

const Range = struct { start: usize, end: usize };

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day5/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 5 - Part 1\n", .{});

    var ranges = std.ArrayList(Range).empty;
    var ids = std.ArrayList(usize).empty;

    var inRanges = true;
    for (lines.lines) |line| {
        if (line.len == 0) {
            inRanges = false;
        } else if (inRanges) {
            var iter = std.mem.splitScalar(u8, line, '-');
            const start = try std.fmt.parseInt(usize, iter.next().?, 10);
            const end = try std.fmt.parseInt(usize, iter.next().?, 10);
            try ranges.append(gpa, Range{ .start = start, .end = end });
        } else {
            try ids.append(gpa, try std.fmt.parseInt(usize, line, 10));
        }
    }

    var freshCount: usize = 0;

    for (ids.items) |id| {
        for (ranges.items) |range| {
            if (range.start <= id and id <= range.end) {
                freshCount += 1;
                break;
            }
        }
    }

    std.debug.print("    Fresh Count = {}\n", .{freshCount});

    std.debug.print("  Day 5 - Part 2\n", .{});
}
