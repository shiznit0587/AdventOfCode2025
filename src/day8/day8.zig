const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day8/input.txt");
    defer rlr.deinit(gpa);

    const numBoxes = rlr.lines.len;
    var boxes = try std.ArrayList(JunctionBox).initCapacity(gpa, numBoxes);
    var circuits = try std.ArrayList(Circuit).initCapacity(gpa, numBoxes);

    for (0..numBoxes) |i| {
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
            .boxes = try std.ArrayList(usize).initCapacity(gpa, numBoxes),
        });
        circuits.items[i].boxes.appendAssumeCapacity(i);
    }

    var distances = try std.ArrayList(Distance).initCapacity(gpa, numBoxes * numBoxes / 2);

    for (0..numBoxes - 1) |i| {
        for (i + 1..numBoxes) |j| {
            distances.appendAssumeCapacity(.{
                .boxAId = i,
                .boxBId = j,
                .distance = _squareDistance(boxes.items[i].pos, boxes.items[j].pos),
            });
        }
    }

    std.mem.sortUnstable(Distance, distances.items[0..], {}, _distanceAsc);

    var dIdx: usize = 0;
    var largestCircuitSize: usize = 1;
    while (largestCircuitSize < numBoxes) : (dIdx += 1) {
        const d = distances.items[dIdx];
        const boxA = boxes.items[d.boxAId];
        const boxB = boxes.items[d.boxBId];

        if (boxA.circuitId != boxB.circuitId) {
            var circuitA = &circuits.items[boxA.circuitId];
            var circuitB = &circuits.items[boxB.circuitId];

            circuitA.boxes.appendSliceAssumeCapacity(circuitB.boxes.items[0..]);
            for (circuitB.boxes.items) |b| {
                boxes.items[b].circuitId = circuitA.id;
            }
            circuitB.boxes.clearAndFree(gpa);

            largestCircuitSize = @max(largestCircuitSize, circuitA.boxes.items.len);
        }

        if (dIdx == 999) {
            std.mem.sortUnstable(Circuit, circuits.items[0..], {}, _circuitsBySizeDesc);
            var result: usize = 1;
            for (circuits.items[0..3]) |c| {
                result *= c.boxes.items.len;
            }
            std.mem.sortUnstable(Circuit, circuits.items[0..], {}, _circuitsById);

            std.debug.print("  Day 8 - Part 1\n", .{});
            std.debug.print("    product = {}\n", .{result});
        }

        if (largestCircuitSize == numBoxes) {
            const result = boxes.items[d.boxAId].pos.x * boxes.items[d.boxBId].pos.x;

            std.debug.print("  Day 8 - Part 2\n", .{});
            std.debug.print("    product = {}\n", .{result});
        }
    }
}

fn _squareDistance(a: Vector, b: Vector) i64 {
    return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z);
}

fn _distanceAsc(_: void, a: Distance, b: Distance) bool {
    return a.distance < b.distance;
}

fn _circuitsBySizeDesc(_: void, a: Circuit, b: Circuit) bool {
    return a.boxes.items.len > b.boxes.items.len;
}

fn _circuitsById(_: void, a: Circuit, b: Circuit) bool {
    return a.id < b.id;
}

const Vector = struct { x: i64, y: i64, z: i64 };
const JunctionBox = struct { id: usize, pos: Vector, circuitId: usize };
const Circuit = struct { id: usize, boxes: std.ArrayList(usize) };
const Distance = struct { boxAId: usize, boxBId: usize, distance: i64 };
