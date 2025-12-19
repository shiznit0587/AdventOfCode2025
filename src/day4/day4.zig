const std = @import("std");
const util = @import("../util.zig");

const Coord = struct { x: usize, y: usize };

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var result = try util.readLinesMutable(gpa, "src/day4/input.txt");
    defer result.deinit(gpa);

    std.debug.print("  Day 4 - Part 1\n", .{});

    var grid: Grid = .{
        .grid = result.lines,
        .width = result.lines[0].len,
        .height = result.lines.len,
    };
    var count: usize = grid.tick();

    std.debug.print("    Accessible Rolls = {}\n", .{count});
    std.debug.print("  Day 4 - Part 2\n", .{});

    var evalCount: usize = count;
    while (evalCount > 0) {
        evalCount = grid.tick();
        count += evalCount;
    }

    std.debug.print("    Rolls Removed = {}\n", .{count});
}

const Grid = struct {
    grid: [][]u8,
    width: usize,
    height: usize,

    fn tick(self: *Grid) usize {
        var count: usize = 0;

        for (0..self.height) |y| {
            const row = self.grid[y];
            for (0..self.width) |x| {
                if (row[x] != '@') {
                    continue;
                }

                var adjacentRolls: i32 = 0;

                var dy: i32 = -1;
                while (dy <= 1) : (dy += 1) {
                    var dx: i32 = -1;
                    while (dx <= 1) : (dx += 1) {
                        if (dx == 0 and dy == 0) continue;

                        const x2_i: i32 = @as(i32, @intCast(x)) + dx;
                        const y2_i: i32 = @as(i32, @intCast(y)) + dy;

                        if (0 <= x2_i and x2_i < @as(i32, @intCast(self.width)) and
                            0 <= y2_i and y2_i < @as(i32, @intCast(self.height)))
                        {
                            const x2: usize = @intCast(x2_i);
                            const y2: usize = @intCast(y2_i);

                            if (self.grid[y2][x2] == '@' or self.grid[y2][x2] == 'a') {
                                adjacentRolls += 1;
                            }
                        }
                    }
                }

                if (adjacentRolls < 4) {
                    self.grid[y][x] = 'a';
                    count += 1;
                }
            }
        }

        for (0..self.height) |y| {
            const row = self.grid[y];
            for (0..self.width) |x| {
                if (row[x] == 'a') row[x] = '.';
            }
        }

        return count;
    }
};
