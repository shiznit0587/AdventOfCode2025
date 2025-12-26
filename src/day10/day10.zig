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

            // `lightsStr` is a character sequence of `.` and `#` with each representing the start state of each light.
            machine.lights.len = lightsStr.len;
            // for (lightsStr) |char| {
            for (0..machine.lights.len) |i| {
                if (lightsStr[i] == '#') {
                    // machine.lights.lights = (machine.lights.lights << 1) | (if (char == '#') @as(usize, 1) else @as(usize, 0));
                    machine.lights.lights |= (@as(usize, 1) << (@as(u6, @intCast(i))));
                }
            }

            // I think I want to rework this to not use a regex.
            // I think I want to split on space, then split on ,
            // var btnRegex = try Regex.compile(gpa, "\\([\\d,]+\\)");
            // defer btnRegex.deinit();

            var btnsIter = std.mem.splitScalar(u8, buttonsStr, ' ');

            // for (try btnRegex.findAll(gpa, buttonsStr)) |btnMatch| {
            var btnIdx: usize = 0;
            while (btnsIter.next()) |btnStr| {
                var modifier: usize = 0;

                var btnIter = std.mem.splitScalar(u8, btnStr[1 .. btnStr.len - 1], ',');
                while (btnIter.next()) |lightIdxStr| {
                    const lightIdx = try std.fmt.parseInt(u64, lightIdxStr, 10);
                    modifier |= (@as(usize, 1) << @as(u6, @intCast(lightIdx)));
                }

                const btn: Button = .{ .id = btnIdx, .modifier = modifier };

                try machine.buttons.append(gpa, btn);
                btnIdx += 1;
            }

            // std.debug.print("machine buttons = [ ", .{});
            // for (machine.buttons.items) |b| {
            //     b.print();
            //     std.debug.print(" ", .{});
            // }
            // std.debug.print("]\n", .{});

            var joltageIter = std.mem.splitScalar(u8, joltagesStr, ',');
            while (joltageIter.next()) |joltageStr| {
                const joltage = try std.fmt.parseInt(u64, joltageStr, 10);
                try machine.joltages.append(gpa, joltage);
            }
        }

        machines.appendAssumeCapacity(machine);
    }

    // Now, I need to solve each machine.
    // For each machine, I need to do a BFS of all possible sequences of button presses.
    // It's a BFS because I'm looking for the minimum number to get to the result.

    // For BFS, I build out a queue starting with each button being pressed once,
    // then for each button press I run it, check the state, and queue each next possible button press.

    var sumMinPresses: usize = 0;

    for (machines.items) |machine| {
        // std.debug.print("Machine: Target lights=", .{});
        // machine.lights.print();
        // std.debug.print("\n", .{});

        const numButtons = machine.buttons.items.len;

        // Seed the queue.
        var queue: std.DoublyLinkedList = .{};

        // Try getting the original item array out of scope, and see what happens.
        {
            // const items = try gpa.alloc(QueueItem, numButtons);

            for (0..numButtons) |i| {
                // items[i] = .{ .button = i };
                // queue.append(&items[i].node);
                var item = try gpa.create(QueueItem);
                item.* = .{};
                item.lights.len = machine.lights.len;
                item.nextButton = machine.buttons.items[i];
                queue.append(&item.node);
            }
        }

        var minPresses: usize = 0;

        // var iters: usize = 0;

        // The whole idea of a queue is moot too.
        // The order doesn't matter!
        // I think when queueing another button, I need to compare IDs as well.
        // This way I don't test duplicates.

        // Process the queue.
        while (queue.popFirst()) |node| {
            const item: *QueueItem = @fieldParentPtr("node", node);

            // const btn = machine.buttons.items[item.nextButton];
            // std.debug.print("        testing queue item: buttonId={}, button=", .{item.nextButton.id});
            // item.nextButton.print();
            // std.debug.print(", lights=", .{});
            // item.lights.print();
            // std.debug.print(", presses={}\n", .{item.pressedButtons.items.len});

            // apply the button.
            // item.lights ^= btn;
            // item.presses += 1;

            // item.pressedButtons |= (@as(usize, 1) << @as(u6, @intCast(item.nextButton)));

            try item.apply(gpa);

            // std.debug.print("          after press: buttonId={}, lights=", .{item.nextButton.id});
            // item.lights.print();
            // std.debug.print(", goal=", .{});
            // machine.lights.print();
            // std.debug.print("\n", .{});

            // For every item in the queue, what I really want to print is the buttons pressed and the lights.
            // I'll print the goal once at the top of the run for this machine.

            // std.debug.print("      Buttons = {}:[ ", .{item.pressedButtons.items.len});
            // item.printPressedButtons();
            // std.debug.print(" ], lights = ", .{});
            // item.lights.print();
            // std.debug.print("\n", .{});

            // check the result
            if (item.lights.lights == machine.lights.lights) {
                // Solution found!
                minPresses = item.pressedButtons.items.len;

                // print out all the buttons that were pressed.
                // std.debug.print("Buttons = {}:[ ", .{item.pressedButtons.items.len});
                // item.printPressedButtons();
                // std.debug.print(" ]\n", .{});

                gpa.destroy(item);
                break;
            }

            // if (item.pressedButtons.items.len >= 4) {
            // The sample input should not reach here.
            // gpa.destroy(item);
            // break;
            // }

            // if it's not solved, queue another for each button.
            // const newItems = try gpa.alloc(QueueItem, numButtons - 1);
            var queuedMore = false;
            for (item.nextButton.id + 1..numButtons) |i| {
                // Don't queue any pressed button again.
                // if (item.pressedButtons & (@as(usize, 1) << @as(u6, @intCast(i))) == 1) {
                if (item.hasPressedButton(i)) {
                    continue;
                }

                // Don't queue just turning the same lights off again.
                // if (i == item.button) {
                //     continue;
                // }
                // const idx = if (i < item.button) i else i - 1;
                // var newItem = try gpa.create(QueueItem);
                // var btn = machine.buttons.items[i];
                var newItem = try item.createNext(machine.buttons.items[i], gpa);

                // newItem.* = .{
                //     .lights = item.lights,
                //     .presses = item.presses,
                //     .pressedButtons = item.pressedButtons,
                //     .nextButton = i,
                // };
                // queue.append(&newItems[idx].node);
                queue.append(&newItem.node);

                queuedMore = true;
            }

            if (!queuedMore) {
                // std.debug.print("no more to queue from this button?\n", .{});
            }
            // std.debug.print("          queued all other buttons: lights={}, presses={}\n", .{ item.lights, item.presses });

            // iters += 1;
            // if (iters >= 100) {
            //     break;
            // }

            // destroy this one.
            // item.node.next = null;
            // item.node.prev = null;
            gpa.destroy(item);
        }

        while (queue.popFirst()) |node| {
            const item: *QueueItem = @fieldParentPtr("node", node);
            gpa.destroy(item);
        }

        // std.debug.print("      min presses = {}\n\n\n", .{minPresses});

        sumMinPresses += minPresses;
    }

    std.debug.print("    Button Presses = {}\n", .{sumMinPresses});

    std.debug.print("  Day 10 - Part 2\n", .{});
}

fn _printButtons(machine: *const Machine, pressedButtons: usize) void {
    // for every flipped bit in the pressed buttons, print out the button itself.

    for (0..machine.buttons.items.len) |i| {
        if (_isButtonPressed(pressedButtons, i)) {
            // print the button.
        }
    }
}

fn _isButtonPressed(pressedButtons: usize, buttonIdx: usize) bool {
    return (pressedButtons & (1 << buttonIdx)) == 1;
}

// fn _pressButton(item: *QueueItem) usize {
// item.lights ^= btn;
// item.presses += 1;

// item.pressedButtons |= (@as(usize, 1) << @as(u6, @intCast(item.nextButton)));
// }

// fn _applyButtonToLights(button: usize, lights: usize) void {
//
// }

// Instead of []bool and []usize for lights and buttons, we just use bits and XOR them
// const Button = usize;
// const Lights = usize;
const PressCount = usize;

const Machine = struct {
    lights: Lights = .{},
    buttons: std.ArrayList(Button) = .{},
    joltages: std.ArrayList(usize) = .{},

    fn deinit(self: *Machine, gpa: std.mem.Allocator) void {
        self.buttons.deinit(gpa);
        self.joltages.deinit(gpa);
    }
};

const QueueItem = struct {
    lights: Lights = .{},
    // presses: usize = 0,
    // pressedButtons: usize = 0,
    pressedButtons: std.ArrayList(Button) = .{},
    pressedButtonsBitField: usize = 0,
    nextButton: Button = .{},
    node: std.DoublyLinkedList.Node = .{},

    fn apply(self: *QueueItem, gpa: std.mem.Allocator) !void {
        self.nextButton.apply(&self.lights);
        try self.pressedButtons.append(gpa, self.nextButton);
        self.pressedButtonsBitField |= (@as(usize, 1) << @as(u6, @intCast(self.nextButton.id)));
    }

    fn hasPressedButton(self: *const QueueItem, btnId: usize) bool {
        return (self.pressedButtonsBitField & (@as(usize, 1) << @as(u6, @intCast(btnId)))) > 0;
    }

    fn printPressedButtons(self: *const QueueItem) void {
        var printed = false;
        for (self.pressedButtons.items) |btn| {
            if (printed) {
                std.debug.print(" ", .{});
            }
            btn.print();
            printed = true;
        }
    }

    fn createNext(self: *const QueueItem, button: Button, gpa: std.mem.Allocator) !*QueueItem {
        var copy = try gpa.create(QueueItem);

        copy.lights = self.lights;
        copy.pressedButtons = .{};
        try copy.pressedButtons.appendSlice(gpa, self.pressedButtons.items[0..]);
        copy.pressedButtonsBitField = self.pressedButtonsBitField;
        copy.nextButton = button;
        // don't copy `node`, only for use by `DoublyLinkedList`.

        return copy;
    }
};

const Lights = struct {
    lights: usize = 0,
    len: usize = 0,

    fn print(self: *const Lights) void {
        std.debug.print("[", .{});

        for (0..self.len) |i| {
            if (self.isLightOn(i)) {
                std.debug.print("{s}", .{"#"});
            } else {
                std.debug.print("{s}", .{"."});
            }
        }

        std.debug.print("]", .{});
    }

    fn isLightOn(self: *const Lights, idx: usize) bool {
        return (self.lights & (@as(usize, 1) << @as(u6, @intCast(idx)))) > 0;
    }
};

const Button = struct {
    id: usize = 0,
    modifier: usize = 0,

    fn apply(self: *const Button, lights: *Lights) void {
        lights.lights ^= self.modifier;
    }

    fn print(self: *const Button) void {
        std.debug.print("(", .{});

        var printed = false;
        for (0..64) |i| {
            if (self.affectsLight(i)) {
                if (printed) {
                    std.debug.print(",", .{});
                }
                std.debug.print("{}", .{i});
                printed = true;
            }
        }

        std.debug.print(")", .{});
    }

    fn affectsLight(self: *const Button, lightId: usize) bool {
        const lightMask = @as(usize, 1) << @as(u6, @intCast(lightId));
        // return (self.modifier & (@as(usize, 1) << @as(u6, @intCast(lightId)))) == 1;
        const result = (self.modifier & lightMask) > 0;
        return result;
    }
};
