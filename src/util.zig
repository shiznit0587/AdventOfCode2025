const std = @import("std");

pub const ReadLinesResult = struct {
    /// The buffer holding the raw file contents. Slices in `lines` reference this.
    data: []u8,

    /// A slice array containing slices (views) into `data` for each line.
    /// Allocated with the provided allocator and freed by `deinit`.
    lines: []const []const u8,

    pub fn deinit(self: *ReadLinesResult, allocator: std.mem.Allocator) void {
        allocator.free(self.lines);
        allocator.free(self.data);
    }
};

pub fn readLines(gpa: std.mem.Allocator, path: []const u8) !ReadLinesResult {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const data = try file.readToEndAlloc(gpa, std.math.maxInt(usize));

    var lines = std.ArrayList([]const u8).empty;

    var splitIterator = std.mem.splitScalar(u8, data, '\n');
    while (splitIterator.next()) |line| {
        try lines.append(gpa, line);
    }

    return .{ .lines = try lines.toOwnedSlice(gpa), .data = data };
}

pub const MutableLinesResult = struct {
    lines: [][]u8,

    pub fn deinit(self: *MutableLinesResult, gpa: std.mem.Allocator) void {
        for (self.lines) |line| {
            gpa.free(line);
        }
        gpa.free(self.lines);
    }
};

pub fn readLinesMutable(gpa: std.mem.Allocator, path: []const u8) !MutableLinesResult {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const data = try file.readToEndAlloc(gpa, std.math.maxInt(usize));
    defer gpa.free(data);

    var lines = std.ArrayList([]u8).empty;

    var splitIterator = std.mem.splitScalar(u8, data, '\n');
    while (splitIterator.next()) |line| {
        const mut_line = try gpa.alloc(u8, line.len);
        @memcpy(mut_line, line);
        try lines.append(gpa, mut_line);
    }

    return .{ .lines = try lines.toOwnedSlice(gpa) };
}
