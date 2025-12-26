const std = @import("std");
const util = @import("../util.zig");
const Regex = @import("regex").Regex;

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day10/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 10 - Part 1\n", .{});

    var regex = try Regex.compile(gpa, "\\[([\\.#]+)\\] (\\(.*\\)) \\{(.*)\\}");
    defer regex.deinit();

    var machines = try std.ArrayList(Machine).initCapacity(gpa, rlr.lines.len);
    for (rlr.lines) |line| {
        var machine: Machine = .{};

        if (try regex.find(line)) |match| {
            const lightsStr = match.captures[0];
            const buttonsStr = match.captures[1];
            const joltagesStr = match.captures[2];

            for (0..lightsStr.len) |i| {
                if (lightsStr[i] == '#') {
                    machine.lights.set(i);
                }
            }

            var btnsIter = std.mem.splitScalar(u8, buttonsStr, ' ');
            while (btnsIter.next()) |btnStr| {
                var btn: Button = Button.initEmpty();

                var btnIter = std.mem.splitScalar(u8, btnStr[1 .. btnStr.len - 1], ',');
                while (btnIter.next()) |lightIdStr| {
                    const lightId = try std.fmt.parseInt(u64, lightIdStr, 10);
                    btn.set(lightId);
                }

                try machine.buttons.append(gpa, btn);
            }

            var joltageIter = std.mem.splitScalar(u8, joltagesStr, ',');
            while (joltageIter.next()) |joltageStr| {
                const joltage = try std.fmt.parseInt(u64, joltageStr, 10);
                try machine.joltages.append(gpa, joltage);
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
