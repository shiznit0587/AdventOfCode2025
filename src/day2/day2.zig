const std = @import("std");
const util = @import("../util.zig");

const Range = struct { start: usize, end: usize };

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day2/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 2 - Part 1\n", .{});

    var ranges = std.ArrayList(Range).empty;

    // I need to handle seeing the same number more than once.
    // Example: 222222 is 2 repeated, 22 repeated, and 222 repeated.
    var addedNumbers = std.AutoHashMap(usize, void).init(gpa);
    defer addedNumbers.deinit();

    var splitIterator = std.mem.splitScalar(u8, lines.lines[0], ',');
    while (splitIterator.next()) |range| {
        var iter = std.mem.splitScalar(u8, range, '-');

        const start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const end = try std.fmt.parseInt(usize, iter.next().?, 10);

        try checkAndAddRange(&ranges, gpa, start, end);
    }

    var sumPart1: usize = 0;
    var sumPart2: usize = 0;
    for (ranges.items) |range| {
        const numLen = digitCount(range.start);
        const maxRepeatedLen = @divFloor(numLen, 2);

        for (1..maxRepeatedLen + 1) |repeatedLen| {
            if (numLen % repeatedLen != 0) {
                continue;
            }

            const highDigitsDivisor = try std.math.powi(usize, 10, numLen - repeatedLen);
            const minRepeated = @divFloor(range.start, highDigitsDivisor);
            const maxRepeated = @divFloor(range.end, highDigitsDivisor);

            const repeatMultiplier = try std.math.powi(usize, 10, repeatedLen);

            for (minRepeated..maxRepeated + 1) |repeated| {
                // Flood repeated segment into lower digits of candidate until it reaches the full length.
                var candidate = repeated;
                var candidateLength = repeatedLen;
                while (candidateLength < numLen) {
                    candidate = candidate * repeatMultiplier + repeated;
                    candidateLength += repeatedLen;
                }

                if (range.start <= candidate and candidate <= range.end and !addedNumbers.contains(candidate)) {
                    try addedNumbers.put(candidate, {});

                    if (repeatedLen == maxRepeatedLen and numLen % 2 == 0) {
                        sumPart1 += candidate;
                    }

                    sumPart2 += candidate;
                }
            }
        }
    }

    std.debug.print("    Invalid ID sum: {d}\n", .{sumPart1});
    std.debug.print("  Day 2 - Part 2\n", .{});
    std.debug.print("    Invalid ID sum: {d}\n", .{sumPart2});
}

/// Add ranges split based on the number of digits, ensuring the minx/max of all ranges are the same length.
fn checkAndAddRange(ranges: *std.ArrayList(Range), gpa: std.mem.Allocator, start: usize, end: usize) !void {
    const startDigits = digitCount(start);
    const endDigits = digitCount(end);

    if (startDigits == endDigits) {
        try ranges.append(gpa, Range{ .start = start, .end = end });
    } else {
        const newStart = try std.math.powi(usize, 10, startDigits);
        const newEnd = newStart - 1;

        try ranges.append(gpa, Range{ .start = start, .end = newEnd });
        try checkAndAddRange(ranges, gpa, newStart, end);
    }
}

fn digitCount(num: usize) usize {
    var count: usize = 0;
    var n = num;
    while (n != 0) : (n /= 10) {
        count += 1;
    }
    return count;
}
