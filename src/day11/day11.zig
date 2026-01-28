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

    const paths = try _dfs("you", "out", deviceMap, gpa);

    std.debug.print("    Num paths = {}\n", .{paths});

    std.debug.print("  Day 11 - Part 2\n", .{});

    // We happen to know there's no cycles in the input data, so:
    // - there's no need to track visited nodes, and as such,
    // - we can cache the count of paths between nodes without worrying about visitation conflicts.

    const path1_a = try _dfs("svr", "dac", deviceMap, gpa);
    const path1_b = try _dfs("dac", "fft", deviceMap, gpa);
    const path1_c = try _dfs("fft", "out", deviceMap, gpa);
    const paths1 = path1_a * path1_b * path1_c;

    const path2_a = try _dfs("svr", "fft", deviceMap, gpa);
    const path2_b = try _dfs("fft", "dac", deviceMap, gpa);
    const path2_c = try _dfs("dac", "out", deviceMap, gpa);
    const paths2 = path2_a * path2_b * path2_c;

    std.debug.print("    Num paths = {}\n", .{paths1 + paths2});
}

fn _dfs(node: String, target: String, graph: std.StringHashMap(std.ArrayList(String)), gpa: std.mem.Allocator) !usize {
    var cache = std.StringHashMap(usize).init(gpa);
    defer cache.deinit();
    return try _dfs_recursive(node, target, graph, &cache, 0);
}

fn _dfs_recursive(node: String, target: String, graph: std.StringHashMap(std.ArrayList(String)), cache: *std.StringHashMap(usize), count: usize) !usize {
    if (std.mem.eql(u8, node, target)) {
        return count + 1;
    }

    var result = count;

    const neighbors = graph.getPtr(node);
    if (neighbors) |n| {
        for (n.items) |next| {
            if (cache.contains(next)) {
                result += cache.get(next).?;
            } else {
                result += try _dfs_recursive(next, target, graph, cache, count);
            }
        }
    }

    try cache.put(node, result);
    return result;
}

const String = []const u8;
