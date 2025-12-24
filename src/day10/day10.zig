const std = @import("std");
const util = @import("../util.zig");
const Regex = @import("regex").Regex;

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day10/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 10 - Part 1\n", .{});

    const regex = try Regex.compile(gpa, "\\[([\\.#]+)\\] (\\(.*\\)) \\{(.*)\\}");
    // defer regex.deinit(); // error: expected type '*regex.Regex', found '*const regex.Regex'

    for (rlr.lines) |line| {
        if (try regex.find(line)) |match| {
            std.debug.print("Found: {s}\n", .{match.slice});

            for (match.captures) |capture| {
                std.debug.print("Capture: {s}\n", .{capture});
            }
        }
    }

    std.debug.print("  Day 10 - Part 2\n", .{});
}

fn _toggleLights(lights: Lights, btn: Button) Lights {
    return lights ^ btn;
}

// Instead of []bool and []usize for lights and buttons, we just use bits and XOR them
const Button = usize;
const Lights = usize;
const PressCount = usize;

const MachineDef = struct {
    lights: usize,
    buttons: []Button,
    joltages: []usize,
};
