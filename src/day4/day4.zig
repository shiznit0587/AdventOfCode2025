const std = @import("std");
const util = @import("../util.zig");

const Coord = struct { x: usize, y: usize };
const QueueCoord = struct { x: usize, y: usize, n: ?*QueueCoord = null };

const Queue = struct {
    h: ?*QueueCoord = null,

    fn push(q: *Queue, n: *QueueCoord) void {
        n.n = q.h;
        q.h = n;
    }

    fn pop(q: *Queue) ?*QueueCoord {
        const h = q.h orelse return null;
        q.h = h.n;
        return h;
    }
};

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var result = try util.readLines(gpa, "src/day4/input.txt");
    // var grid = Grid{
    //     .grid = result.lines,
    //     .width = result.lines[0].len,
    //     .height = result.lines.len,
    // };
    defer result.deinit(gpa);
    var grid = try Grid.fromLines(result.lines, gpa);
    defer grid.deinit(gpa);

    std.debug.print("  Day 4 - Part 1\n", .{});

    //std.PriorityDequeue(Coord, {}, {});
    // std.ArrayDeque(Coord).init();

    // std.Treap(comptime Key: type, comptime compareFn: anytype)

    // const width = lines[0].len;
    // const height = lines.len;

    // var coords = AccessibleCoords.fromLines(lines);
    // coords.eval(lines);

    // I think I should just use a different character to mean "accessible roll".
    // Then I can do all the work in place on the single lines array.
    //defer gpa.free(accessibleRollCoords);

    // var count: usize = grid.tick();

    // std.debug.print("    Accessible Rolls = {}\n", .{count});
    std.debug.print("  Day 4 - Part 2\n", .{});

    // For part 2, I actually don't care about the count per run, just the total.
    // Which means, I can assume all "ready to remove" have been removed.
    // That might reduce the number of full passes, as things cascade.
    // Oh! I wonder if there's a way to reduce the area I'm checking each pass
    // to only affected coordinates!
    // I think then, instead of doing passes, I keep a queue of coordinates to check.
    // I first populate it with every coordinate.
    // Then, as I remove rolls, I add each adjacent coord to the queue.

    // I can do one of two things for the count:
    // - I can increment a counter every time I remove one, or
    // - I can count them all at the start, then count them all at the end, and subtract.

    var queueMap = std.AutoHashMap(Coord, void).init(gpa);
    defer queueMap.deinit();

    var queue: Queue = .{};

    var adjMap = std.AutoHashMap(Coord, Adjacent).init(gpa);
    defer adjMap.deinit();

    for (0..grid.height) |y| {
        for (0..grid.width) |x| {
            // if (grid.grid[y][x] == '@') {
            const c = Coord{ .x = x, .y = y };
            // for (grid3.iterator()) |c| {
            if (grid.hasRoll(c)) {
                const qc = try gpa.create(QueueCoord);
                // defer gpa.destroy(qc);
                qc.x = c.x;
                qc.y = c.y;
                // qc.* = .{ .x = c.x, .y = c.y };
                // list.prepend(&user1.node);

                // queue.prepend(&qc.n);
                queue.push(qc);
                try queueMap.put(c, {});
                try adjMap.put(c, _adjCoords(c, grid));
            }
        }
    }

    var count: usize = 0;
    while (queue.pop()) |n| {
        // const qc_ptr: *QueueCoord = @fieldParentPtr("n", n);
        // const c = qc_ptr.c;
        const c: Coord = .{ .x = n.x, .y = n.y };
        // queue.
        // for (queue.keys()) |c| {
        // std.debug.print("- {d}\n", .{key});
        // }
        // Dereference the pointer to get the key slice
        // const key_slice = key_ptr.*;
        // std.debug.print("- {s}\n", .{key_slice});
        // }

        // const c = queue.pop().?.key;
        // const c = key_ptr.*;
        // _ = queue.swapRemove(c);
        const adjCoords = adjMap.get(c).?;

        var adjRolls: usize = 0;
        for (0..adjCoords.len) |i| {
            const adjC = adjCoords.coords[i];
            // if (grid.grid[adjC.y][adjC.x] == '@') {
            if (grid.hasRoll(adjC)) {
                adjRolls += 1;
            }
        }

        if (adjRolls < 4) {
            // try coords.append(gpa, Coord{ .x = x, .y = y });
            // carry it off.
            count += 1;
            // grid.grid[c.y][c.x] = '.';
            grid.clearRoll(c);
            // queue neighbors.
            // for (adjCoords.coords) |adjC| {
            for (0..adjCoords.len) |i| {
                const adjC = adjCoords.coords[i];
                // if (!queueMap.contains(adjC) and grid.grid[adjC.y][adjC.x] == '@') {
                if (!queueMap.contains(adjC) and grid.hasRoll(adjC)) {

                    // Need to allocate a heap item, can't use the stack one.
                    const qc = try gpa.create(QueueCoord);
                    // defer gpa.destroy(qc);
                    // qc.* = .{ .x = adjC.x, .y = adjC.y };
                    qc.x = adjC.x;
                    qc.y = adjC.y;
                    // queue.prepend(&qc.n);
                    queue.push(qc);
                }
                // _ = try queue.getOrPut(adjC);
            }
            // I should build an adjacency matrix once, to save computation, right?
        }

        // defer gpa.destroy(n);

        // only one iteration of for loop - I can't find a good way to get any key from the map.
        // Maybe a map is the wrong type. Set, maybe?

        // _ = queue.swapRemove(c);
        // break;
    }
    // }

    // start by populating the queue with every

    // var evalCount: usize = count;
    // while (evalCount > 0) {
    // evalCount = grid.tick();
    // count += evalCount;
    // }

    std.debug.print("    Rolls Removed = {}\n", .{count});
}

const Grid = struct {
    // grid: [][]u8,
    grid: [][]bool,
    width: usize,
    height: usize,

    fn fromLines(lines: []const []const u8, gpa: std.mem.Allocator) !Grid {
        const w = lines[0].len;
        const h = lines.len;

        const g = try gpa.alloc([]bool, h);

        for (0..h) |y| {
            const row = try gpa.alloc(bool, w);
            g[y] = row;
            for (0..w) |x| {
                if (lines[y][x] == '@') {
                    row[x] = true;
                }
            }
        }

        return .{ .grid = g, .width = w, .height = h };
    }

    fn deinit(self: *Grid, gpa: std.mem.Allocator) void {
        for (0..self.height) |y| {
            gpa.free(self.grid[y]);
        }
        gpa.free(self.grid);
    }

    fn hasRoll(self: *Grid, c: Coord) bool {
        return self.grid[c.y][c.x];
    }

    fn clearRoll(self: *Grid, c: Coord) void {
        self.grid[c.y][c.x] = false;
    }

    // fn tick(self: *Grid) usize {
    //     var count: usize = 0;

    //     for (0..self.height) |y| {
    //         const row = self.grid[y];
    //         for (0..self.width) |x| {
    //             if (row[x] != '@') {
    //                 continue;
    //             }

    //             var adjacentRolls: i32 = 0;

    //             var dy: i32 = -1;
    //             while (dy <= 1) : (dy += 1) {
    //                 var dx: i32 = -1;
    //                 while (dx <= 1) : (dx += 1) {
    //                     if (dx == 0 and dy == 0) {
    //                         continue;
    //                     }

    //                     const x2_i: i32 = @as(i32, @intCast(x)) + dx;
    //                     const y2_i: i32 = @as(i32, @intCast(y)) + dy;

    //                     if (0 <= x2_i and x2_i < @as(i32, @intCast(self.width)) and
    //                         0 <= y2_i and y2_i < @as(i32, @intCast(self.height)))
    //                     {
    //                         const x2: usize = @intCast(x2_i);
    //                         const y2: usize = @intCast(y2_i);

    //                         if (self.grid[y2][x2] == '@' or self.grid[y2][x2] == 'a') {
    //                             adjacentRolls += 1;
    //                         }
    //                     }
    //                 }
    //             }

    //             if (adjacentRolls < 4) {
    //                 self.grid[y][x] = 'a';
    //                 count += 1;
    //             }
    //         }
    //     }

    //     for (0..self.height) |y| {
    //         const row = self.grid[y];
    //         for (0..self.width) |x| {
    //             if (row[x] == 'a') row[x] = '.';
    //         }
    //     }

    //     return count;
    // }
};

const Adjacent = struct {
    coords: [8]Coord,
    len: usize,
};

fn _adjCoords(c: Coord, grid: Grid) Adjacent {
    return _adjacentCoords(c.x, c.y, grid.width, grid.height);
}

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
