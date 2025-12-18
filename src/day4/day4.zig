const std = @import("std");
const util = @import("../util.zig");

const Coord = struct { x: usize, y: usize };

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var result = try util.readLinesMutable(gpa, "src/day4/input.txt");
    const lines = result.lines;
    defer result.deinit(gpa);

    std.debug.print("  Day 4 - Part 1\n", .{});

    const accessibleRollCoords = try _getAccessibleRollCoords(gpa, lines);
    defer gpa.free(accessibleRollCoords);

    std.debug.print("    Accessible Rolls = {}\n", .{accessibleRollCoords.len});

    std.debug.print("  Day 4 - Part 2\n", .{});

    var rollsRemoved: usize = 0;
    while (true) {
        const coords = try _getAccessibleRollCoords(gpa, lines);
        defer gpa.free(coords);

        if (coords.len == 0) {
            break;
        }

        rollsRemoved += coords.len;

        for (coords) |coord| {
            lines[coord.y][coord.x] = '.';
        }
    }

    std.debug.print("    Rolls Removed = {}\n", .{rollsRemoved});
}

fn _getAccessibleRollCoords(gpa: std.mem.Allocator, lines: [][]u8) ![]Coord {
    var coords = std.ArrayList(Coord).empty;

    for (0..lines.len) |y| {
        const line = lines[y];
        for (0..line.len) |x| {
            if (line[x] != '@') {
                continue;
            }

            var adjacentRolls: i32 = 0;
            const adj = _adjacentCoords(x, y, lines[0].len, lines.len);
            for (0..adj.len) |i| {
                const c = adj.coords[i];
                if (lines[c.y][c.x] == '@') {
                    adjacentRolls += 1;
                }
            }

            if (adjacentRolls < 4) {
                try coords.append(gpa, Coord{ .x = x, .y = y });
            }
        }
    }

    return coords.toOwnedSlice(gpa);
}

const Adjacent = struct {
    coords: [8]Coord,
    len: usize,
};

fn _adjacentCoords(x: usize, y: usize, width: usize, height: usize) Adjacent {
    var res: Adjacent = undefined;
    res.len = 0;

    var dy: i32 = -1;
    while (dy <= 1) : (dy += 1) {
        var dx: i32 = -1;
        while (dx <= 1) : (dx += 1) {
            if (dx == 0 and dy == 0) {
                continue;
            }

            const x2_i: i32 = @as(i32, @intCast(x)) + dx;
            const y2_i: i32 = @as(i32, @intCast(y)) + dy;

            if (0 <= x2_i and x2_i < @as(i32, @intCast(width)) and
                0 <= y2_i and y2_i < @as(i32, @intCast(height)))
            {
                res.coords[res.len] = Coord{
                    .x = @intCast(x2_i),
                    .y = @intCast(y2_i),
                };
                res.len += 1;
            }
        }
    }

    return res;
}
