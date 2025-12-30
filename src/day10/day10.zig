const std = @import("std");
const util = @import("../util.zig");

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day10/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 10 - Part 1\n", .{});

    var machines = try std.ArrayList(Machine).initCapacity(gpa, rlr.lines.len);
    for (rlr.lines) |line| {
        var machine: Machine = .{};

        var parsingJoltages = false;
        var lightId: usize = 0;
        var num: usize = 0;
        var button: Button = Button.initEmpty();
        for (line) |c| {
            if (c == '{') {
                parsingJoltages = true;
            } else if (c == '}') {
                try machine.joltages.append(gpa, num);
            } else if (c == '.') {
                lightId += 1;
            } else if (c == '#') {
                machine.lights.set(lightId);
                lightId += 1;
            } else if (c == '(') {
                button = Button.initEmpty();
            } else if (c == ')') {
                button.set(num);
                num = 0;
                try machine.buttons.append(gpa, button);
            } else if ('0' <= c and c <= '9') {
                num = num * 10 + c - '0';
            } else if (c == ',') {
                if (!parsingJoltages) {
                    button.set(num);
                    num = 0;
                } else {
                    try machine.joltages.append(gpa, num);
                    num = 0;
                }
            }
        }

        machines.appendAssumeCapacity(machine);
    }

    var sumMinPresses: usize = 0;
    for (machines.items) |machine| {
        const numButtons = machine.buttons.items.len;

        // Seed the queue.
        var queue: std.DoublyLinkedList = .{};
        for (0..numButtons) |i| {
            var item = try gpa.create(QueueItem);
            item.* = .{};
            item.nextButtonId = i;
            queue.append(&item.node);
        }

        var minPresses: usize = 0;
        while (queue.popFirst()) |node| {
            const item: *QueueItem = @fieldParentPtr("node", node);
            item.lights = item.lights.xorWith(machine.buttons.items[item.nextButtonId]);
            item.pressedButtons.set(item.nextButtonId);

            if (item.lights == machine.lights) {
                minPresses = item.pressedButtons.count();
                break;
            }

            // Don't queue any previous button - those combinations have already been processed.
            for (item.nextButtonId + 1..numButtons) |i| {
                var newItem = try gpa.create(QueueItem);
                newItem.lights = item.lights;
                newItem.pressedButtons = item.pressedButtons;
                newItem.nextButtonId = i;
                queue.append(&newItem.node);
            }
        }

        sumMinPresses += minPresses;
    }

    std.debug.print("    Button Presses = {}\n", .{sumMinPresses});

    std.debug.print("  Day 10 - Part 2\n", .{});
}

// I checked my input - there's at most 10 lights and 13 buttons in any machine.
const Lights = std.StaticBitSet(10);
const Button = std.StaticBitSet(10);
const Buttons = std.StaticBitSet(13);

const Machine = struct {
    lights: Lights = Lights.initEmpty(),
    buttons: std.ArrayList(Button) = .{},
    joltages: std.ArrayList(usize) = .{},
};

const QueueItem = struct {
    lights: Lights = Lights.initEmpty(),
    pressedButtons: Buttons = Buttons.initEmpty(),
    nextButtonId: usize = 0,
    node: std.DoublyLinkedList.Node = .{},
};
