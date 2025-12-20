const std = @import("std");
const util = @import("../util.zig");

const Operation = enum { Add, Multiply };

const Equation = struct {
    operands: std.ArrayList(usize) = std.ArrayList(usize).empty,
    op: Operation = Operation.Add,

    fn solve(self: *const Equation) usize {
        return switch (self.op) {
            Operation.Add => self.add(),
            Operation.Multiply => self.mult(),
        };
    }

    fn add(self: *const Equation) usize {
        var result: usize = 0;
        for (self.operands.items) |operand| {
            result += operand;
        }
        return result;
    }

    fn mult(self: *const Equation) usize {
        var result: usize = 1;
        for (self.operands.items) |operand| {
            result *= operand;
        }
        return result;
    }
};

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var equations = std.ArrayList(Equation).empty;
    defer equations.deinit(gpa);

    var lines = try util.readLines(gpa, "src/day6/input.txt");
    defer lines.deinit(gpa);

    std.debug.print("  Day 6 - Part 1\n", .{});

    for (lines.lines) |line| {
        var idx: usize = 0;

        var splitIterator = std.mem.tokenizeScalar(u8, line, ' ');
        while (splitIterator.next()) |token| {
            if (equations.items.len <= idx) {
                try equations.append(gpa, .{});
            }

            switch (token[0]) {
                '+' => equations.items[idx].op = Operation.Add,
                '*' => equations.items[idx].op = Operation.Multiply,
                else => try equations.items[idx].operands.append(gpa, try std.fmt.parseInt(usize, token, 10)),
            }

            idx += 1;
        }
    }

    var result: usize = 0;
    for (equations.items) |equation| {
        result += equation.solve();
    }

    std.debug.print("    result = {}\n", .{result});
    std.debug.print("  Day 6 - Part 2\n", .{});

    result = 0;
    var eq: Equation = .{};
    for (0..lines.lines[0].len) |idx| {
        var operand: usize = 0;
        for (lines.lines) |line| {
            switch (line[idx]) {
                '+' => eq.op = Operation.Add,
                '*' => eq.op = Operation.Multiply,
                ' ' => {},
                else => operand = (operand * 10) + (line[idx] - '0'),
            }
        }

        if (operand != 0) {
            try eq.operands.append(gpa, operand);
        } else {
            result += eq.solve();
            eq = .{};
        }
    }

    result += eq.solve();
    std.debug.print("    result = {}\n", .{result});
}
