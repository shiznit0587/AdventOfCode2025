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
    const paths = try _dfs("you", "out", deviceMap, &visited, 0);

    std.debug.print("    Num paths = {}\n", .{paths});

    std.debug.print("  Day 11 - Part 2\n", .{});
}

fn _dfs(node: String, dest: String, graph: std.StringHashMap(std.ArrayList(String)), visited: *std.StringHashMap(void), count: usize) !usize {
    if (std.mem.eql(u8, node, dest)) {
        return count + 1;
    }

    var result = count;
    try visited.put(node, {});

    for (graph.getPtr(node).?.items) |next| {
        if (!visited.contains(next)) {
            result += try _dfs(next, dest, graph, visited, count);
        }
    }

    _ = visited.remove(node);
    return result;
}

const String = []const u8;
