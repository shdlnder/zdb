const std = @import("std");
const repl = @import("./key_value/repl.zig");
const commands = @import("./key_value/commands.zig");
const prepareGet = @import("./key_value/prepare_get.zig");
const preparePut = @import("./key_value/prepare_put.zig");

fn printPrompt(stdout: anytype) !void {
    try stdout.print("db > ", .{});
}

fn readInput(input: *[500]u8, stdin: anytype) anyerror!?[]u8 {
    return (try stdin.readUntilDelimiterOrEof(input, '\n')).?;
}

pub fn runRepl(allocator: std.mem.Allocator, stdin: anytype, stdout: anytype) anyerror!u2 {

    var dataHash = std.StringHashMap([5]u8).init(allocator);
    var input: [500]u8 = undefined;

    while (true) {
        printPrompt(stdout) catch {
            return 1;
        };

        const command: []u8 = stdin.readUntilDelimiterOrEof(&input, '\n') catch {
            return 1;
        } orelse "";

        // require something, ANYTHING!
        if (command.len < 1) {
            continue;
        }

        try stdout.print("User Input: {s}\n", .{command});

        const result = repl.parseCommand(command);

        switch (result) {
        repl.COMMAND_RESULT.GET => {
            const prepared: commands.PreparedGetCommand = prepareGet.prepareGet(command);

            if (prepared.result != commands.PREP_RESULT.SUCCESS) {
                try stdout.print("Prepare Command Failed\n", .{});
                continue;
            }

            const executed = dataHash.get(prepared.op.key) orelse [5]u8{' ', ' ', ' ', ' ', ' '};

            try stdout.print("Execute Command Success\n", .{});
            try stdout.print("Key: <{s}> Value: <{s}>\n", .{prepared.op.key, executed});
            continue;
        },
        repl.COMMAND_RESULT.PUT => {
            const prepared: commands.PreparedPutCommand = preparePut.preparePut(command);

            if (prepared.result != commands.PREP_RESULT.SUCCESS) {
                try stdout.print("Prepare Command Failed\n", .{});
                continue;
            }

            dataHash.put(prepared.op.key, prepared.op.value) catch {
                try stdout.print("Execute Command Failed\n", .{});
                continue;
            };

            try stdout.print("Execute Command Success\n", .{});
            try stdout.print("Key: <{s}> Value: <{s}>\n", .{prepared.op.key, prepared.op.value});
            continue;
        },
        repl.COMMAND_RESULT.EXIT => {
            return 0;
        },
        repl.COMMAND_RESULT.FAIL => {
            errdefer stdout.print("Parse Command Failed\n", .{});
            continue;
        },
        repl.COMMAND_RESULT.UNRECOGNIZED_COMMAND => {
            errdefer stdout.print("Unrecognized Statement\n", .{});
            continue;
        },
        }
    }

}

pub fn NaiveKeyValue(
    comptime V: type,
) type {
    return struct {
        allocator: std.mem.Allocator,
        backingMap: std.StringHashMap(V),
        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .backingMap = std.StringHashMap(V).init(allocator),
            };
        }

        pub fn put(self: *Self, key: []const u8, value: []const u8) std.mem.Allocator.Error!u2 {
            const prepared: commands.PreparedPutCommand = preparePut.preparePutKV(key, value);

            if (prepared.result != commands.PREP_RESULT.SUCCESS) {
                return 1;
            }

            self.backingMap.put(prepared.op.key, prepared.op.value) catch {
                return 1;
            };

            return 0;
        }

        pub fn get(self: Self, key: []const u8) ?V {
            const prepared: commands.PreparedGetCommand = prepareGet.prepareGetKV(key);

            if (prepared.result != commands.PREP_RESULT.SUCCESS) {
                return null;
            }

            return self.backingMap.get(prepared.op.key) orelse [5]u8{' ', ' ', ' ', ' ', ' '};
        }
    };
}

test "Test NaiveKeyValue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.put("test0", "moo") catch {
        return;
    };
    try std.testing.expectEqual(res1, 0);

    const res2 = kv.put("test1", "moo2") catch {
        return;
    };
    try std.testing.expectEqual(res2, 0);

    const res = kv.get("test0");
    try std.testing.expectEqual(res.?.len, 5);
}

test "Test NaiveKeyValue truncates large value" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.put("test0", "0123456789") catch {
        return;
    };
    try std.testing.expectEqual(res1, 0);

    const res = kv.get("test0");
    try std.testing.expectEqual(res.?.len, 5);
}
