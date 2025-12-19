const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var result = try util.readLines(gpa, "src/day4/input.txt");
    defer result.deinit(gpa);
    var grid = try Grid.init(result.lines, gpa);
    defer grid.deinit(gpa);

    std.debug.print("  Day 4 - Part 1\n", .{});
    std.debug.print("  Day 4 - Part 2\n", .{});
}

const Coord = struct { x: i32, y: i32 };

const RollList = std.ArrayList(Coord);
const RollMap = std.AutoHashMap(Coord, RollList);

const Grid = struct {
    width: usize,
    height: usize,
    rolls: RollMap,

    fn deinit(self: *Grid, gpa: std.mem.Allocator) void {
        var iter = self.rolls.valueIterator();
        while (iter.next()) |r| {
            r.deinit(gpa);
        }
        self.rolls.deinit();
    }

    fn init(lines: []const []const u8, gpa: std.mem.Allocator) !Grid {
        const w = lines[0].len;
        const h = lines.len;
        var rolls = RollMap.init(gpa);

        for (0..h) |y| {
            for (0..w) |x| {
                if (lines[y][x] == '@') {
                    try rolls.put(.{ .x = @intCast(x), .y = @intCast(y) }, RollList.empty);
                }
            }
        }

        var iter = rolls.keyIterator();
        while (iter.next()) |c_ptr| {
            const x = c_ptr.x;
            const y = c_ptr.y;

            var dx: i32 = -1;
            var dy: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                while (dy <= 1) : (dy += 1) {
                    if (dx == 0 and dy == 0) continue;
                    const x2 = x + dx;
                    const y2 = y + dy;
                    if (0 <= x2 and x2 < w and
                        0 <= y2 and y2 < h)
                    {
                        if (rolls.getEntry(.{ .x = x2, .y = y2 })) |e| {
                            try e.value_ptr.append(gpa, c_ptr.*);
                        }
                    }
                }
            }
        }

        return .{
            .width = w,
            .height = h,
            .rolls = rolls,
        };
    }
};
