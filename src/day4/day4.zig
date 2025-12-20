const std = @import("std");
const util = @import("../util.zig");

const Adjacent = struct {
    coords: [8]Point,
    len: usize,
};

const Point = struct {
    x: i32,
    y: i32,

    fn getAdjacent(self: *Point) Adjacent {
        var res: Adjacent = undefined;
        res.len = 0;

        var dy: i32 = -1;
        while (dy <= 1) : (dy += 1) {
            var dx: i32 = -1;
            while (dx <= 1) : (dx += 1) {
                if (dx == 0 and dy == 0) {
                    continue;
                }

                res.coords[res.len] = Point{
                    .x = self.x + dx,
                    .y = self.y + dy,
                };
                res.len += 1;
            }
        }

        return res;
    }
};

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var result = try util.readLines(gpa, "src/day4/input.txt");
    defer result.deinit(gpa);

    std.debug.print("  Day 4 - Part 1\n", .{});

    var grid = try Grid.initFromLines(result.lines, gpa);
    defer grid.deinit();

    const rollCount = grid.rolls.count();

    var nextGrid = try Grid.initWithCapacity(@intCast(rollCount), gpa);
    defer nextGrid.deinit();

    var grid_ptr = &grid;
    var nextGrid_ptr = &nextGrid;

    grid_ptr.tick(nextGrid_ptr);

    std.debug.print("    Rolls Removed = {}\n", .{rollCount - nextGrid_ptr.rolls.count()});

    std.debug.print("  Day 4 - Part 2\n", .{});

    while (grid.rolls.count() != nextGrid.rolls.count()) {
        const temp = nextGrid_ptr;
        nextGrid_ptr = grid_ptr;
        grid_ptr = temp;

        grid_ptr.tick(nextGrid_ptr);
    }

    std.debug.print("    Rolls Removed = {}\n", .{rollCount - nextGrid_ptr.rolls.count()});
}

const Grid = struct {
    rolls: std.AutoHashMap(Point, void),

    fn initFromLines(lines: []const []const u8, gpa: std.mem.Allocator) !Grid {
        const w = lines[0].len;
        const h = lines.len;

        var rolls = std.AutoHashMap(Point, void).init(gpa);
        try rolls.ensureTotalCapacity(@intCast(w * h));

        for (0..lines.len) |y| {
            const line = lines[y];
            for (0..line.len) |x| {
                if (line[x] == '@') {
                    rolls.putAssumeCapacity(.{ .x = @intCast(x), .y = @intCast(y) }, {});
                }
            }
        }

        return .{ .rolls = rolls };
    }

    fn initWithCapacity(capacity: u32, gpa: std.mem.Allocator) !Grid {
        var rolls = std.AutoHashMap(Point, void).init(gpa);
        try rolls.ensureTotalCapacity(capacity);
        return .{ .rolls = rolls };
    }

    fn deinit(self: *Grid) void {
        self.rolls.deinit();
    }

    fn tick(self: *Grid, next: *Grid) void {
        next.rolls.clearRetainingCapacity();
        var iter = self.rolls.keyIterator();
        while (iter.next()) |c| {
            const adjPoints = c.getAdjacent();
            var adjacentRolls: i32 = 0;
            for (0..adjPoints.len) |i| {
                if (self.rolls.contains(adjPoints.coords[i])) {
                    adjacentRolls += 1;
                    if (adjacentRolls >= 4) {
                        next.rolls.putAssumeCapacity(c.*, {});
                        break;
                    }
                }
            }
        }
    }
};
