const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day2/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 2 - Part 1\n", .{});

    var ranges = std.ArrayList([]usize).empty;

    // I need to handle seeing the same number more than once.
    // Example: 222222 is 2 repeated, 22 repeated, and 222 repeated.
    var addedNumbers = std.ArrayList(usize).empty;

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
        const start = range[0];
        const end = range[1];
        const numLen = digitCount(start);
        const maxDoodooLength = @divFloor(numLen, 2);

        for (1..maxDoodooLength + 1) |doodooLength| {
            if (numLen % doodooLength != 0) {
                continue;
            }

            const topDoodooFactor = powInt(10, numLen - doodooLength);
            const minDoodoo = @divFloor(start, topDoodooFactor);
            const maxDoodoo = @divFloor(end, topDoodooFactor);

            const doodooFactor = powInt(10, doodooLength);

            // mahna-mahna
            for (minDoodoo..maxDoodoo + 1) |doodoo| {
                // calculate FULL DOODOO : TODO: make this a helper function
                var fullDoodoo = doodoo;
                var fullDoodooLength = doodooLength;
                while (fullDoodooLength < numLen) {
                    fullDoodoo = fullDoodoo * doodooFactor + doodoo;
                    fullDoodooLength += doodooLength;
                }

                if (start <= fullDoodoo and fullDoodoo <= end and !has(&addedNumbers, fullDoodoo)) {
                    try addedNumbers.append(gpa, fullDoodoo);

                    if (doodooLength == maxDoodooLength and numLen % 2 == 0) {
                        sumPart1 += fullDoodoo;
                    }

                    sumPart2 += fullDoodoo;
                }
            }
        }
    }

    std.debug.print("    Invalid ID sum: {d}\n", .{sumPart1});
    std.debug.print("  Day 2 - Part 2\n", .{});
    std.debug.print("    Invalid ID sum: {d}\n", .{sumPart2});
}

/// Add ranges split based on the number of digits, ensuring the minx/max of all ranges are the same length.
fn checkAndAddRange(ranges: *std.ArrayList([]usize), gpa: std.mem.Allocator, start: usize, end: usize) !void {
    const startDigits = digitCount(start);
    const endDigits = digitCount(end);

    if (startDigits == endDigits) {
        // TODO: See if there's a less-verbose way to allocate this array and add it to the list
        // or if there's tuple support
        var range = try gpa.alloc(usize, 2);
        range[0] = start;
        range[1] = end;
        try ranges.append(gpa, range);
    } else {
        const newStart = powInt(10, startDigits);
        const newEnd = newStart - 1;

        var range = try gpa.alloc(usize, 2);
        range[0] = start;
        range[1] = newEnd;

        try ranges.append(gpa, range);
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

// TODO: See if there's a std version of this
fn powInt(base: usize, power: usize) usize {
    return switch (power) {
        0 => 1,
        1 => base,
        else => base * powInt(base, power - 1),
    };
}

// TODO: See if there's a std version of this (or a Set type)
fn has(list: *std.ArrayList(usize), val: usize) bool {
    for (list.items) |item| {
        if (item == val) {
            return true;
        }
    }
    return false;
}
