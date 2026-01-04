const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day11/input.txt");
    defer rlr.deinit(gpa);

    var deviceMap: std.StringHashMap(std.ArrayList(String)) = std.StringHashMap(std.ArrayList(String)).init(gpa);
    defer deviceMap.deinit();

    for (rlr.lines) |line| {
        const name = line[0..3];
        try deviceMap.put(name, std.ArrayList(String).empty);

        var iter = std.mem.splitScalar(u8, line[5..], ' ');
        while (iter.next()) |d| {
            try deviceMap.getPtr(name).?.append(gpa, d);
        }
    }

    std.debug.print("  Day 11 - Part 1\n", .{});

    var visited = std.StringHashMap(void).init(gpa);

    var path = std.ArrayList(String).empty;
    try path.append(gpa, "out");
    const paths = try _dfs("you", path.items, deviceMap, &visited, 0);

    std.debug.print("    Num paths = {}\n", .{paths});

    std.debug.print("  Day 11 - Part 2\n", .{});

    path.clearRetainingCapacity();
    try path.appendSlice(gpa, &[_](String){ "dac", "fft", "out" });
    const paths1 = try _dfs("svr", path.items, deviceMap, &visited, 0);

    path.clearRetainingCapacity();
    try path.appendSlice(gpa, &[_](String){ "fft", "dac", "out" });
    const paths2 = try _dfs("svr", path.items, deviceMap, &visited, 0);

    std.debug.print("    Num paths = {}\n", .{paths1 + paths2});
}

fn _dfs(node: String, path: []String, graph: std.StringHashMap(std.ArrayList(String)), visited: *std.StringHashMap(void), count: usize) !usize {
    if (std.mem.eql(u8, node, path[0])) {
        if (path.len == 1) {
            return count + 1;
        }
        return _dfs(node, path[1..], graph, visited, count);
    }

    var result = count;
    try visited.put(node, {});

    const neighbors = graph.getPtr(node);
    if (neighbors) |n| {
        for (n.items) |next| {
            if (!visited.contains(next)) {
                result += try _dfs(next, path, graph, visited, count);
            }
        }
    }

    _ = visited.remove(node);
    return result;
}

const String = []const u8;
