const std = @import("std");
const util = @import("../util.zig");
const Regex = @import("regex").Regex;

pub fn run() !void {
    const gpa = std.heap.page_allocator;

    var rlr = try util.readLines(gpa, "src/day10/input.txt");
    defer rlr.deinit(gpa);

    std.debug.print("  Day 10-1-2 - Part 1\n", .{});

    const machines = try _parseMachines(rlr.lines, gpa);

    var sumMinPresses: usize = 0;
    for (machines) |machine| {
        sumMinPresses += try _findMinPressesForLights(machine, gpa);
    }

    std.debug.print("    Button Presses = {}\n", .{sumMinPresses});

    std.debug.print("  Day 10 - Part 2\n", .{});

    sumMinPresses = 0;
    for (machines) |machine| {
        sumMinPresses += try _findMinPressesForJoltage(machine, gpa);
    }

    std.debug.print("    Button Presses = {}\n", .{sumMinPresses});
}

fn _parseMachines(lines: []const []const u8, gpa: std.mem.Allocator) ![]Machine {
    var regex = try Regex.compile(gpa, "\\[([\\.#]+)\\] (\\(.*\\)) \\{(.*)\\}");
    defer regex.deinit();

    var machines = try gpa.alloc(Machine, lines.len);
    for (0..lines.len) |l| {
        const line = lines[l];

        if (try regex.find(line)) |match| {
            const lightsStr = match.captures[0];
            const buttonsStr = match.captures[1];
            const joltagesStr = match.captures[2];

            var lights: Lights = Lights.initEmpty();
            for (0..lightsStr.len) |i| {
                if (lightsStr[i] == '#') {
                    lights.set(i);
                }
            }

            var buttons: std.ArrayList(Button) = .{};
            var btnsIter = std.mem.splitScalar(u8, buttonsStr, ' ');
            while (btnsIter.next()) |btnStr| {
                var btn: Button = Button.initEmpty();

                var btnIter = std.mem.splitScalar(u8, btnStr[1 .. btnStr.len - 1], ',');
                while (btnIter.next()) |lightIdStr| {
                    const lightId = try std.fmt.parseInt(u64, lightIdStr, 10);
                    btn.set(lightId);
                }

                try buttons.append(gpa, btn);
            }

            var joltages: std.ArrayList(usize) = .{};
            var joltageIter = std.mem.splitScalar(u8, joltagesStr, ',');
            while (joltageIter.next()) |joltageStr| {
                const joltage = try std.fmt.parseInt(u64, joltageStr, 10);
                try joltages.append(gpa, joltage);
            }

            const machine = &machines[l];
            machine.* = .{
                .lights = lights,
                .buttons = try buttons.toOwnedSlice(gpa),
                .joltages = try joltages.toOwnedSlice(gpa),
            };
        }
    }

    return machines;
}

fn _findMinPressesForLights(machine: Machine, gpa: std.mem.Allocator) !usize {
    var combos: std.ArrayList(ButtonSet) = .{};
    for (0..machine.buttons.len) |i| {
        var buttons = ButtonSet.initEmpty();
        buttons.set(i);

        var lights: Lights = Lights.initEmpty();
        lights = lights.xorWith(machine.buttons[i]);
        if (lights.eql(machine.lights)) {
            return 1;
        }

        try combos.append(gpa, buttons);
    }

    return _findMinPressesForLightsRecursive(machine, combos, gpa);
}

fn _findMinPressesForLightsRecursive(machine: Machine, combos: std.ArrayList(ButtonSet), gpa: std.mem.Allocator) !usize {
    var newCombos: std.ArrayList(ButtonSet) = .{};
    for (combos.items) |buttons| {

        // try adding each button higher than what we have now.
        if (buttons.findLastSet()) |prev| {
            for (prev + 1..machine.buttons.len) |newBtn| {
                var newButtons = buttons;
                newButtons.set(newBtn);

                var lights: Lights = Lights.initEmpty();

                var iter = newButtons.iterator(.{});
                while (iter.next()) |btn| {
                    lights = lights.xorWith(machine.buttons[btn]);
                }

                if (lights.eql(machine.lights)) {
                    return newButtons.count();
                }

                try newCombos.append(gpa, newButtons);
            }
        }
    }

    return _findMinPressesForLightsRecursive(machine, newCombos, gpa);
}

fn _findMinPressesForJoltage(machine: Machine, gpa: std.mem.Allocator) !usize {

    // The way this works is:
    // Based on the parity of each joltage, we can determine the light pattern that would be produced.
    // (i.e. an odd joltage would be an on light, an even joltage an off light)
    // So, we determine what the lights would be, and find out how many presses it would take to get there.
    // Now we're left with all even joltages, which means all the lights were turned on and off again.
    // So, we can find out how many presses it would take to get to _half_ of all joltages, and count those twice.
    // Wh halve the joltages, until we have numbers that are both odd and even.
    // Then we perform the same steps again - finding the light pattern, determining the min buttons to get there,
    // and counting twice the butons presses needed to get to half the remaining joltages.
    // This continues until the joltages are all 0.

    var lightCache = try LightCache.init(machine.buttons, gpa);
    defer lightCache.deinit(gpa);

    var results: std.ArrayList(usize) = .{};
    defer results.deinit(gpa);

    // We actually try the above algorithm multiple times with different input.
    // Once as defined by the input, and again for each combinations of initial button presses.
    var result = try _findMinPressesForJoltageRecursive(machine, machine.joltages, &lightCache, gpa);
    if (result) |r| {
        try results.append(gpa, r);
    }

    for (lightCache.combos.items) |btnSet| {
        var newJoltages = try gpa.alloc(usize, machine.joltages.len);
        defer gpa.free(newJoltages);
        @memcpy(newJoltages[0..], machine.joltages);

        if (_applyButtonSetToJoltages(machine, btnSet, newJoltages)) {
            result = try _findMinPressesForJoltageRecursive(machine, newJoltages, &lightCache, gpa);
            if (result) |r| {
                try results.append(gpa, btnSet.count() + r);
            }
        }
    }

    return _getResultsMin(results);
}

fn _findMinPressesForJoltageRecursive(machine: Machine, joltages: []usize, lightCache: *const LightCache, gpa: std.mem.Allocator) !?usize {
    if (_joltagesZeroed(joltages)) {
        // Recursion end condition.
        return 0;
    }

    var lights = _joltagesToLights(joltages);

    // If lights is empty, it means we just need to divide by 2 again.
    if (lights.count() == 0) {
        var newJoltages = try gpa.alloc(usize, joltages.len);
        defer gpa.free(newJoltages);
        @memcpy(newJoltages[0..], joltages);

        for (0..newJoltages.len) |i| {
            newJoltages[i] /= 2;
        }

        const result = try _findMinPressesForJoltageRecursive(machine, newJoltages, lightCache, gpa);
        if (result) |r| {
            // If a recursion returns a value, it's a possible solution.
            return 2 * r;
        }
        return null;
    }

    const buttonSetsOpt = lightCache.getButtonSetsByLights(lights);
    if (buttonSetsOpt) |buttonSets| {
        var results: std.ArrayList(usize) = .{};
        defer results.deinit(gpa);

        for (buttonSets.items) |btnSet| {
            var newJoltages = try gpa.alloc(usize, joltages.len);
            defer gpa.free(newJoltages);
            @memcpy(newJoltages[0..], joltages);

            // Apply the button set to the joltages.
            if (!_applyButtonSetToJoltages(machine, btnSet, newJoltages)) {
                continue;
            }

            // Recurse with half.
            for (0..newJoltages.len) |ji| {
                newJoltages[ji] /= 2;
            }

            // We need the smallest result, which won't necessarily be the first.
            const result = try _findMinPressesForJoltageRecursive(machine, newJoltages, lightCache, gpa);
            // If a recursion returns a value, it's a solution.
            if (result) |r| {
                try results.append(gpa, 2 * r + btnSet.count());
            }
        }

        if (results.items.len > 0) {
            // Return the min solution.
            return _getResultsMin(results);
        }
    }

    // If we get here, no solution was found along this branch.
    return null;
}

fn _applyButtonToJoltages(btn: Button, joltages: []usize) bool {
    var iter = btn.iterator(.{});
    while (iter.next()) |i| {
        if (joltages[i] == 0) {
            return false;
        }
        joltages[i] -= 1;
    }
    return true;
}

fn _applyButtonSetToJoltages(machine: Machine, buttonSet: ButtonSet, joltages: []usize) bool {
    var btnIter = buttonSet.iterator(.{});
    while (btnIter.next()) |btnId| {
        if (!_applyButtonToJoltages(machine.buttons[btnId], joltages)) {
            return false;
        }
    }
    return true;
}

fn _getResultsMin(results: std.ArrayList(usize)) usize {
    var minResult: usize = 999999;
    for (results.items) |result| {
        minResult = @min(minResult, result);
    }
    return minResult;
}

fn _joltagesZeroed(joltages: []usize) bool {
    for (joltages) |joltage| {
        if (joltage > 0) {
            return false;
        }
    }
    return true;
}

fn _joltagesToLights(joltages: []usize) Lights {
    var lights = Lights.initEmpty();
    for (0..joltages.len) |i| {
        if (joltages[i] % 2 == 1) {
            lights.set(i);
        }
    }
    return lights;
}

const LightCache = struct {
    buttonSetsByLights: std.AutoHashMap(Lights, std.ArrayList(ButtonSet)),
    combos: std.ArrayList(ButtonSet),

    fn init(buttons: []Button, gpa: std.mem.Allocator) !LightCache {
        var self: LightCache = .{
            .buttonSetsByLights = std.AutoHashMap(Lights, std.ArrayList(ButtonSet)).init(gpa),
            .combos = .{},
        };

        var buttonSets = std.ArrayList(ButtonSet).empty;
        defer buttonSets.deinit(gpa);

        var lightsByButtonSet = std.AutoHashMap(ButtonSet, Lights).init(gpa);
        defer lightsByButtonSet.deinit();

        // Seed the cache with all light patterns resulting from 1 button press.
        for (0..buttons.len) |i| {
            const btn = buttons[i];
            var lights: Lights = Lights.initEmpty();
            lights = lights.xorWith(btn);

            var btns = ButtonSet.initEmpty();
            btns.set(i);

            // Either insert a new list or append to an existing one.
            var v = try self.buttonSetsByLights.getOrPut(lights);
            if (!v.found_existing) {
                v.value_ptr.* = .{};
            }
            try v.value_ptr.append(gpa, btns);

            try lightsByButtonSet.put(btns, lights);
            try buttonSets.append(gpa, btns);
        }

        try self.combos.appendSlice(gpa, buttonSets.items[0..]);

        // We now construct all buttons sets and track their resulting light pattern.
        for (1..buttons.len) |_| {
            const newButtonSets = try self._expand(buttonSets, buttons.len, &lightsByButtonSet, gpa);
            defer gpa.free(newButtonSets);

            buttonSets.clearRetainingCapacity();
            try buttonSets.appendSlice(gpa, newButtonSets);
            try self.combos.appendSlice(gpa, newButtonSets);
        }

        return self;
    }

    fn deinit(self: *LightCache, gpa: std.mem.Allocator) void {
        var iter = self.buttonSetsByLights.valueIterator();
        while (iter.next()) |l| {
            l.deinit(gpa);
        }
        self.buttonSetsByLights.deinit();
        self.combos.deinit(gpa);
    }

    fn getButtonSetsByLights(self: *const LightCache, lights: Lights) ?std.ArrayList(ButtonSet) {
        return self.buttonSetsByLights.get(lights);
    }

    fn _expand(self: *LightCache, buttonSets: std.ArrayList(ButtonSet), numBtns: usize, lightsByButtonSet: *std.AutoHashMap(ButtonSet, Lights), gpa: std.mem.Allocator) ![]ButtonSet {
        var newCombos: std.ArrayList(ButtonSet) = .{};
        defer newCombos.deinit(gpa);

        for (buttonSets.items) |buttons| {

            // Try adding each button higher than what we have now.
            if (buttons.findLastSet()) |prev| {
                for (prev + 1..numBtns) |newBtn| {
                    var newButtons = ButtonSet.initEmpty();
                    newButtons.set(newBtn);

                    var lights: Lights = lightsByButtonSet.get(buttons).?;
                    const btnEffect: Lights = lightsByButtonSet.get(newButtons).?;

                    newButtons.setUnion(buttons);
                    lights = lights.xorWith(btnEffect);

                    // Either insert a new list or append to an existing one.
                    var v = try self.buttonSetsByLights.getOrPut(lights);
                    if (!v.found_existing) {
                        v.value_ptr.* = .{};
                    }
                    try v.value_ptr.append(gpa, newButtons);

                    try lightsByButtonSet.put(newButtons, lights);
                    try newCombos.append(gpa, newButtons);
                }
            }
        }

        return newCombos.toOwnedSlice(gpa);
    }
};

// I checked my input - there's at most 10 lights and 13 buttons in any machine.
const Lights = std.StaticBitSet(10);
const Button = std.StaticBitSet(10);
const ButtonSet = std.StaticBitSet(13);

const Machine = struct {
    lights: Lights,
    buttons: []Button,
    joltages: []usize,
};
