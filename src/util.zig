const std = @import("std");

pub const ReadLinesResult = struct {
    /// The buffer holding the raw file contents. Slices in `lines` reference this.
    data: []u8,

    /// A slice array containing slices (views) into `data` for each line.
    /// Allocated with the provided allocator and freed by `deinit`.
    lines: []const []const u8,

    pub fn deinit(self: *ReadLinesResult, allocator: std.mem.Allocator) void {
        // free the array of slices first, then the underlying data buffer
        allocator.free(self.lines);
        allocator.free(self.data);
    }
};

/// Read the text file at `path` into a single allocated buffer and return an
/// owned `ReadLinesResult` containing the raw buffer and an ArrayList of line
/// slices (`[]const u8`) that reference that buffer. Lines are split on LF '\n'
/// and any trailing CR '\r' is trimmed from each line.
pub fn readLines(allocator: std.mem.Allocator, path: []const u8) !ReadLinesResult {
    var fs = std.fs.cwd();

    const file = try fs.openFile(path, .{});
    defer file.close();

    // Read the whole file into an allocated buffer. Start with a small cap.
    const data = try file.readToEndAlloc(allocator, 4096);

    // Two-pass approach: first count lines, then allocate an array and fill it.
    var count: usize = 0;
    if (data.len == 0) {
        count = 0;
    } else {
        var i: usize = 0;
        while (i < data.len) {
            if (data[i] == '\n') count += 1;
            i += 1;
        }
        if (data.len > 0 and data[data.len - 1] != '\n') count += 1;
    }

    // Allocate an array to hold the slices. The slices will reference `data`.
    var lines = try allocator.alloc([]const u8, count);

    // Fill the allocated array with trimmed slices.
    var idx: usize = 0;
    var start: usize = 0;
    var j: usize = 0;
    while (j < data.len) {
        if (data[j] == '\n') {
            var end = j;
            // Trim CR before newline if present
            if (end > start and data[end - 1] == '\r') end -= 1;
            lines[idx] = data[start..end];
            idx += 1;
            start = j + 1;
        }
        j += 1;
    }
    // final partial line if the file doesn't end with a newline
    if (start < data.len) {
        var end = data.len;
        if (end > start and data[end - 1] == '\r') end -= 1;
        lines[idx] = data[start..end];
    }

    return ReadLinesResult{ .data = data, .lines = lines };
}

pub const ReadLinesOwnedResult = struct {
    /// Owned copies of each line. Each inner slice is an owned allocation and
    /// must be freed individually by `deinit`.
    lines: [][]u8,

    pub fn deinit(self: *ReadLinesOwnedResult, allocator: std.mem.Allocator) void {
        // Free each allocated line
        for (self.lines) |line| {
            allocator.free(line);
        }
        // Free the array of slices
        allocator.free(self.lines);
    }
};

/// Read into owned per-line allocations. This returns an array of owned
/// `[]u8` slices where each slice has been allocated with the provided
/// allocator and contains a copy of a line (CR trimmed). This is simpler to
/// use when callers don't want to keep a single large buffer alive.
pub fn readLinesOwned(allocator: std.mem.Allocator, path: []const u8) !ReadLinesOwnedResult {
    // Use readLines to parse the file into slices pointing to a single buffer,
    // then copy each slice into its own allocation, freeing the original buffer.
    var temp = try readLines(allocator, path);
    // Ensure we free temp when we're done copying
    defer temp.deinit(allocator);

    const count = temp.lines.len;
    var out = try allocator.alloc([]u8, count);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const s = temp.lines[i];
        // allocate copy for this line
        const dest = try allocator.alloc(u8, s.len);
        // copy bytes
        @memcpy(dest, s);
        out[i] = dest[0..s.len];
    }

    return ReadLinesOwnedResult{ .lines = out };
}

pub const ReadLinesPushResult = struct {
    /// Owned copies of each line as a slice array (`[][]u8`). The outer slice
    /// is allocated with the provided allocator and must be freed by `deinit`.
    lines: [][]u8,

    pub fn deinit(self: *ReadLinesPushResult, allocator: std.mem.Allocator) void {
        // Free each owned line buffer, then free the container slice.
        for (self.lines) |line| {
            allocator.free(line);
        }
        allocator.free(self.lines);
    }
};

/// Read a file in a single pass using two growing ArrayLists:
/// - `cur` collects bytes for the current line as `ArrayList(u8)`
/// - when a newline is seen `cur.toOwnedSlice()` produces a new owned []u8 which
///   is appended to `lines` (ArrayList([]u8)).
/// This avoids the two-pass counting approach and performs one allocation per
/// line (owned copy) and amortized growth for the lists.
pub fn readLinesPush(allocator: std.mem.Allocator, path: []const u8) !ReadLinesPushResult {
    const fs = std.fs.cwd();

    const file = try fs.openFile(path, .{});
    defer file.close();

    var capacity: usize = 8;
    var lines = try allocator.alloc([]u8, capacity);
    var len: usize = 0;
    // Temporary expanding buffer for the current line (bytes)
    var cur_capacity: usize = 256;
    var cur_buf = try allocator.alloc(u8, cur_capacity);
    var cur_len: usize = 0;
    defer allocator.free(cur_buf);

    var buf: [4096]u8 = undefined;
    while (true) {
        const n = try file.read(buf[0..]);
        if (n == 0) break;

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const b = buf[i];
            if (b == '\n') {
                // Convert current buffer to an owned slice and append to lines
                const owned = try allocator.alloc(u8, cur_len);
                @memcpy(owned, cur_buf[0..cur_len]);
                // Trim trailing CR if present
                var end = cur_len;
                if (end > 0 and owned[end - 1] == '\r') end -= 1;
                const final = owned[0..end];
                if (len >= capacity) {
                    const new_capacity = if (capacity == 0) 8 else capacity * 2;
                    lines = try allocator.realloc(lines, new_capacity);
                    capacity = new_capacity;
                }
                lines[len] = final;
                len += 1;
                // reset current buffer
                cur_len = 0;
            } else {
                if (cur_len >= cur_capacity) {
                    const new_cap = cur_capacity * 2;
                    cur_buf = try allocator.realloc(cur_buf, new_cap);
                    cur_capacity = new_cap;
                }
                cur_buf[cur_len] = b;
                cur_len += 1;
            }
        }
    }

    // Flush final partial line if any bytes remain
    if (cur_len > 0) {
        const owned = try allocator.alloc(u8, cur_len);
        @memcpy(owned, cur_buf[0..cur_len]);
        var end = cur_len;
        if (end > 0 and owned[end - 1] == '\r') end -= 1;
        const final = owned[0..end];
        if (len >= capacity) {
            const new_capacity = if (capacity == 0) 8 else capacity * 2;
            lines = try allocator.realloc(lines, new_capacity);
            capacity = new_capacity;
        }
        lines[len] = final;
        len += 1;
    }

    // Resize the outer array to the exact number of items and return.
    lines = try allocator.realloc(lines, len);
    return ReadLinesPushResult{ .lines = lines };
}

test "readLinesPush single-pass copies lines" {
    const allocator = std.testing.allocator;

    const example = "x\ny\r\nz";
    const file_path = "/tmp/test_lines_push.txt";

    const wf = try std.fs.cwd().createFile(file_path, .{});
    defer std.fs.cwd().removeFile(file_path) catch {};
    defer wf.close();
    try wf.writeAll(example);

    var r = try readLinesPush(allocator, file_path);
    defer r.deinit(allocator);

    try std.testing.expectEqualStrings("x", r.lines[0]);
    try std.testing.expectEqualStrings("y", r.lines[1]);
    try std.testing.expectEqualStrings("z", r.lines[2]);
}

test "readLinesOwned returns owned line copies" {
    const allocator = std.testing.allocator;

    const example = "a\nb\r\nc\n";
    const file_path = "/tmp/test_lines_owned.txt";

    const wf = try std.fs.cwd().createFile(file_path, .{});
    defer std.fs.cwd().removeFile(file_path) catch {};
    defer wf.close();
    try wf.writeAll(example);

    var r = try readLinesOwned(allocator, file_path);
    defer r.deinit(allocator);

    try std.testing.expectEqualStrings("a", r.lines[0]);
    try std.testing.expectEqualStrings("b", r.lines[1]);
    try std.testing.expectEqualStrings("c", r.lines[2]);
}

test "readLines returns expected slices for LF & CRLF" {
    const allocator = std.testing.allocator;

    const example = "one\ntwo\r\nthree\n"; // contains both LF and CRLF
    const file_path = "/tmp/test_lines.txt";

    const wf = try std.fs.cwd().createFile(file_path, .{});
    defer std.fs.cwd().removeFile(file_path) catch {};
    defer wf.close();
    try wf.writeAll(example);

    var result = try readLines(allocator, file_path);
    defer result.deinit(allocator);

    try std.testing.expectEqualStrings("one", result.lines[0]);
    try std.testing.expectEqualStrings("two", result.lines[1]);
    try std.testing.expectEqualStrings("three", result.lines[2]);
}
