const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day9/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 9 - Part 1\n", .{});

    const numTiles = rlr.lines.len;
    var tiles = try std.ArrayList(Point).initCapacity(gpa, numTiles);

    for (rlr.lines) |line| {
        var iter = std.mem.splitScalar(u8, line, ',');
        tiles.appendAssumeCapacity(.{
            .x = try std.fmt.parseInt(i64, iter.next().?, 10),
            .y = try std.fmt.parseInt(i64, iter.next().?, 10),
        });
    }

    var rects = try std.ArrayList(Rectangle).initCapacity(gpa, numTiles * numTiles / 2);

    for (0..numTiles - 1) |i| {
        for (i + 1..numTiles) |j| {
            const a = tiles.items[i];
            const b = tiles.items[j];
            const area = (@abs(a.x - b.x) + 1) * (@abs(a.y - b.y) + 1);

            rects.appendAssumeCapacity(.{ .a = a, .b = b, .area = area });
        }
    }

    std.mem.sortUnstable(Rectangle, rects.items[0..], {}, _rectsByAreaDesc);

    std.debug.print("    largest area = {}\n", .{rects.items[0].area});
    std.debug.print("  Day 9 - Part 2\n", .{});

    var edges = try std.ArrayList(Edge).initCapacity(gpa, numTiles);

    for (0..numTiles) |i| {
        // When constructing edges, order the points from "smallest" to "largest",
        // so we can assume later that all edges go from the top-left toward the bottom-right.
        const ta = tiles.items[i];
        const tb = tiles.items[(i + 1) % numTiles];
        const wa = ta.x + ta.y;
        const wb = tb.x + tb.y;

        edges.appendAssumeCapacity(.{
            .start = if (wa < wb) ta else tb,
            .end = if (wa < wb) tb else ta,
        });
    }

    for (rects.items) |rect| {
        const rectEdges: [4]RectEdge = _getRectEdges(rect);

        var intersects = false;
        for (edges.items) |edge| {
            if (_edgeIntersectsRectEdge(edge, rectEdges[0]) or
                _edgeIntersectsRectEdge(edge, rectEdges[1]) or
                _edgeIntersectsRectEdge(edge, rectEdges[2]) or
                _edgeIntersectsRectEdge(edge, rectEdges[3]))
            {
                intersects = true;
            }

            if (intersects) break;
        }

        if (!intersects) {
            std.debug.print("    largest area = {}\n", .{rect.area});
            break;
        }
    }
}

const Point = struct { x: i64, y: i64 };
const Edge = struct { start: Point, end: Point };
const Side = enum { Left, Top, Right, Bottom };
const Rectangle = struct { a: Point, b: Point, area: u64 };
const RectEdge = struct { start: Point, end: Point, side: Side };

fn _rectsByAreaDesc(_: void, a: Rectangle, b: Rectangle) bool {
    return a.area > b.area;
}

// Calculate the rect's edges, also with points from "smallest" to "largest".
fn _getRectEdges(rect: Rectangle) [4]RectEdge {
    const c: Point = .{ .x = rect.a.x, .y = rect.b.y };
    const d: Point = .{ .x = rect.b.x, .y = rect.a.y };

    const l = @min(rect.a.x, rect.b.x, c.x, d.x);
    const r = @max(rect.a.x, rect.b.x, c.x, d.x);
    const t = @min(rect.a.y, rect.b.y, c.y, d.y);
    const b = @max(rect.a.y, rect.b.y, c.y, d.y);

    return [_](RectEdge){
        .{ .start = .{ .x = l, .y = t }, .end = .{ .x = r, .y = t }, .side = Side.Top },
        .{ .start = .{ .x = r, .y = t }, .end = .{ .x = r, .y = b }, .side = Side.Right },
        .{ .start = .{ .x = l, .y = b }, .end = .{ .x = r, .y = b }, .side = Side.Bottom },
        .{ .start = .{ .x = l, .y = t }, .end = .{ .x = l, .y = b }, .side = Side.Left },
    };
}

fn _edgeIntersectsRectEdge(e: Edge, re: RectEdge) bool {
    const horizontal = (re.side == Side.Top or re.side == Side.Bottom);
    if (horizontal == (e.start.y == e.end.y)) {
        return false;
    }

    if (horizontal) {
        if (re.start.x < e.start.x and e.start.x < re.end.x) {
            // Check for full intersect.
            if (e.start.y < re.start.y and re.start.y < e.end.y) return true;
            // Check for an endpoint along the rect edge and cutting into the rect's area.
            if (e.start.y == re.start.y) return re.side == Side.Top;
            if (e.end.y == re.start.y) return re.side == Side.Bottom;
        }
    } else {
        if (re.start.y < e.start.y and e.start.y < re.end.y) {
            // Check for full intersect.
            if (e.start.x < re.start.x and re.start.x < e.end.x) return true;
            // Check for an endpoint along the rect edge and cutting into the rect's area.
            if (e.start.x == re.start.x) return re.side == Side.Left;
            if (e.end.x == re.start.x) return re.side == Side.Right;
        }
    }

    return false;
}
