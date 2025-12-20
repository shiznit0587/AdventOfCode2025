const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day8/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 8 - Part 1\n", .{});

    // I don't understand how to do this efficiently. I need to get the distances from every
    // junction to every junction, sort those distances ASC, then for the 1000 shortest,
    // connect them, merging their circuits.
    // That means I also need to track which junction boxes are in which circuits.
    // Each time I join two junction boxes, I could be joining large circuits.

    var boxes = try std.ArrayList(JunctionBox).initCapacity(gpa, rlr.lines.len);
    var circuits = try std.ArrayList(Circuit).initCapacity(gpa, rlr.lines.len);

    for (0..rlr.lines.len) |i| {
        var iter = std.mem.splitScalar(u8, rlr.lines[i], ',');
        boxes.appendAssumeCapacity(.{
            .id = i,
            .pos = .{
                .x = try std.fmt.parseInt(i32, iter.next().?, 10),
                .y = try std.fmt.parseInt(i32, iter.next().?, 10),
                .z = try std.fmt.parseInt(i32, iter.next().?, 10),
            },
            .circuitId = i,
        });
        circuits.appendAssumeCapacity(.{
            .id = i,
            .boxes = try std.ArrayList(usize).initCapacity(gpa, 1),
        });
        circuits.items[i].boxes.appendAssumeCapacity(i);
    }

    var distances = try std.ArrayList(Distance).initCapacity(gpa, boxes.items.len * boxes.items.len / 2);

    for (0..boxes.items.len - 1) |i| {
        for (i + 1..boxes.items.len) |j| {
            distances.appendAssumeCapacity(.{
                .boxAId = i,
                .boxBId = j,
                .distance = _squareDistance(boxes.items[i].pos, boxes.items[j].pos),
            });

            // std.debug.print("      distance from {} to {} = {}\n", .{ i, j, distances.getLast().distance });
        }
    }

    std.mem.sortUnstable(Distance, distances.items[0..], {}, _distanceAsc);

    for (0..1000) |dIdx| {
        const d = distances.items[dIdx];
        const boxA = boxes.items[d.boxAId];
        const boxB = boxes.items[d.boxBId];

        // std.debug.print("      merging from {} to {} : distance = {}\n", .{ boxA.id, boxB.id, d.distance });

        if (boxA.circuitId == boxB.circuitId) continue;

        var circuitA = &circuits.items[boxA.circuitId];
        var circuitB = &circuits.items[boxB.circuitId];

        try circuitA.boxes.appendSlice(gpa, circuitB.boxes.items[0..]);

        for (circuitB.boxes.items) |b| {
            boxes.items[b].circuitId = circuitA.id;
        }

        circuitB.boxes.clearAndFree(gpa);
    }

    std.mem.sortUnstable(Circuit, circuits.items[0..], {}, _circuitsBySizeDesc);

    var result: usize = 1;
    for (circuits.items[0..3]) |c| {
        result *= c.boxes.items.len;
    }

    std.debug.print("    product = {}\n", .{result});

    std.debug.print("  Day 8 - Part 2\n", .{});
}

fn _squareDistance(a: Vector, b: Vector) i64 {
    return (a.x - b.x) * (a.x - b.x) +
        (a.y - b.y) * (a.y - b.y) +
        (a.z - b.z) * (a.z - b.z);
}

fn _distanceAsc(_: void, a: Distance, b: Distance) bool {
    return a.distance < b.distance;
}

fn _circuitsBySizeDesc(_: void, a: Circuit, b: Circuit) bool {
    return a.boxes.items.len > b.boxes.items.len;
}

const Vector = struct {
    x: i64,
    y: i64,
    z: i64,
};

const JunctionBox = struct {
    id: usize,
    pos: Vector,
    circuitId: usize,
};

const Circuit = struct {
    id: usize,
    boxes: std.ArrayList(usize),
};

const Distance = struct {
    boxAId: usize,
    boxBId: usize,
    distance: i64,
};
