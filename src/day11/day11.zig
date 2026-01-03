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

    const svrToDac = try _dfs("svr", "dac", deviceMap, &visited, 0);
    const dacToFft = try _dfs("dac", "fft", deviceMap, &visited, 0);
    const fftToOut = try _dfs("fft", "out", deviceMap, &visited, 0);
    const paths1 = svrToDac * dacToFft * fftToOut;

    const svrToFft = try _dfs("svr", "fft", deviceMap, &visited, 0);
    const fftToDac = try _dfs("fft", "dac", deviceMap, &visited, 0);
    const dacToOut = try _dfs("dac", "out", deviceMap, &visited, 0);
    const paths2 = svrToFft * fftToDac * dacToOut;

    std.debug.print("    Num paths = {}\n", .{paths1 + paths2});
}

fn _dfs(node: String, dest: String, graph: std.StringHashMap(std.ArrayList(String)), visited: *std.StringHashMap(void), count: usize) !usize {
    if (std.mem.eql(u8, node, dest)) {
        return count + 1;
    }

    var result = count;
    try visited.put(node, {});

    const neighbors = graph.getPtr(node);
    if (neighbors) |n| {
        for (n.items) |next| {
            if (!visited.contains(next)) {
                result += try _dfs(next, dest, graph, visited, count);
            }
        }
    }

    _ = visited.remove(node);
    return result;
}

const String = []const u8;
