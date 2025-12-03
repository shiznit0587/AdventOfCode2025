const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var lines = try util.readLines(gpa, "src/day2/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 2 - Part 1\n", .{});

    var sum: usize = 0;
    var splitIterator = std.mem.splitScalar(u8, lines.lines[0], ',');
    while (splitIterator.next()) |range| {
        var iter = std.mem.splitScalar(u8, range, '-');

        const start: usize = try std.fmt.parseInt(usize, iter.next().?, 10);
        const end: usize = try std.fmt.parseInt(usize, iter.next().?, 10);

        for (start..end + 1) |num| {
            const digits = try getDigits(num, gpa);
            defer gpa.free(digits);

            if (digits.len % 2 != 0) {
                continue;
            }

            if (std.mem.eql(usize, digits[0..@divFloor(digits.len, 2)], digits[@divFloor(digits.len, 2)..])) {
                sum += num;
            }
        }
    }

    // This solution is quite slow. I wonder if there's a way to determine prefix values, and then check if the duplicate version of each exists in the range?
    // I'm going to have to do something, since this takes several seconds to run, and part 2 is going to be even worse.

    std.debug.print("    Invalid ID sum: {d}\n", .{sum});
    std.debug.print("  Day 2 - Part 2\n", .{});
}

fn digitCount(num: usize) usize {
    var count: usize = 0;
    var n = num;
    while (n != 0) : (n /= 10) {
        count += 1;
    }
    return count;
}

fn getDigits(num: usize, gpa: std.mem.Allocator) ![]usize {
    const count = digitCount(num);
    var digits = try gpa.alloc(usize, count);

    var n = num;
    for (0..digits.len) |i| {
        digits[digits.len - 1 - i] = n % 10;
        n /= 10;
    }

    return digits;
}
