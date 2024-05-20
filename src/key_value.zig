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

        pub fn get(self: *Self, key: []const u8) ?V {
            const prepared: commands.PreparedGetCommand = prepareGet.prepareGetKV(key);

            if (prepared.result != commands.PREP_RESULT.SUCCESS) {
                return null;
            }

            return self.backingMap.get(prepared.op.key) orelse [5]u8{' ', ' ', ' ', ' ', ' '};
        }

        // Currently the keys are 10 and values are 5
        // reset size later
        pub fn load(self: *Self, fileName: []const u8) anyerror!u2 {
            const stdout = std.io.getStdOut().writer();
            var file = try std.fs.cwd().openFile(fileName, .{});
            defer file.close();

            var buf_reader = std.io.bufferedReader(file.reader());
            var in_stream = buf_reader.reader();

            var buf: [64]u8 = undefined;

            while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
                // try stdout.print("Buf len {d} line len {d}\n", .{buf.len, line.len});

                if (line.len != 15) {
                    try stdout.print("Something is wrong with buf len in file {s} {d}\n", .{buf, buf.len});
                }

                var it = std.mem.window(u8, line, 10, 10);
                const key = it.next() orelse "";
                const value = it.next() orelse "";

                if (key.len != 10) {
                    try stdout.print("Something is wrong with key {s} {d}\n", .{key, key.len});
                }
                if (value.len != 5) {
                    try stdout.print("Something is wrong with value {s} {d}\n", .{value, value.len});
                }

                const keyAlloc = try self.allocator.alloc(u8, 10);
                const valueAlloc = try self.allocator.alloc(u8, 5);

                @memcpy(keyAlloc, key);
                @memcpy(valueAlloc, value);

                try stdout.print("Buf len {d} buf {s} key {s} value {s}\n", .{line.len, line, keyAlloc, valueAlloc});
                // @memcpy(&buf, line);
                const res = self.put(keyAlloc, valueAlloc) catch |err| {
                    try stdout.print("Error {any}\n", .{err});
                    return err;
                };
                try stdout.print("Res {any}\n", .{res});
                if (res > 0) {
                    return res;
                }
            }

            return 0;
        }

        // Currently the keys are 10 and values are 5
        // reset size later
        pub fn fileDump(self: *Self, fileName: []const u8) anyerror!u2 {

            const stdout = std.io.getStdOut().writer();
            try stdout.print("Starting write\n", .{});

            const file = try std.fs.cwd().createFile(fileName, .{  });
            defer file.close();

            var it = self.backingMap.iterator();
            while (it.next()) |entry| {
                try stdout.print("Next!\n", .{});
                // I don't like saving like this
                var writeMe: [16]u8 = undefined;

                var mutableEndSlice: []u8 = writeMe[15..16];
                mutableEndSlice[0] = '\n';
                var mutableKeySlice: []u8 = writeMe[0..10];
                @memcpy(std.mem.asBytes(&mutableKeySlice)[0..10], std.mem.asBytes(&entry.key_ptr.*)[0..10]);
                var mutableValSlice: []u8 = writeMe[10..15];
                @memcpy(std.mem.asBytes(&mutableValSlice)[0..5], std.mem.asBytes(&entry.value_ptr.*)[0..5]);

                try stdout.print("Write this {s}\n", .{writeMe});

                try file.writeAll(&writeMe);
            }

            return 0;
        }
    };
}

test "Test NaiveKeyValue" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.put("test0", "moo") catch {
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(res1, 0);

    const res2 = kv.put("test1", "moo2") catch {
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(res2, 0);

    const res = kv.get("test0");

    try std.testing.expectEqual(res.?.len, 5);
    try std.testing.expectEqual(res, [5]u8{'m','o','o',170,170});
}

test "Test value too large" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.put("test0", "0123456789") catch {
        return;
    };
    try std.testing.expectEqual(res1, 1);
}

test "Test load file" {

    const stdout = std.io.getStdOut().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.load("./src/test-data/kv-load.dat") catch |err| {
        try stdout.print("Failed to load file {any}\n", .{err});
        try std.testing.expectEqual(false, true);
        return;
    };

    try std.testing.expectEqual(res1, 0);

    try std.testing.expectEqual(kv.backingMap.count(), 3);
    var kit = kv.backingMap.keyIterator();
    var keyCount: u8 = 0;
    while (kit.next()) |k| {
        try stdout.print("Key {s}\n", .{k});
        keyCount += 1;
    }
    try std.testing.expectEqual(keyCount, 3);

    const ress = kv.put("0011223344", "one") catch |err| {
        try stdout.print("Failed to put {any}\n", .{err});
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(ress, 0);

    const res = kv.get("0123456789");
    try std.testing.expectEqual(res.?.len, 5);
    try stdout.print("Value {s}\n", .{res.?});
    try std.testing.expectEqual(res, [5]u8{'t','e','s','t','1'});
}

test "Test NaiveKeyValue Write File" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var kv = NaiveKeyValue([5]u8).init(allocator);

    const res1 = kv.put("test0", "moo") catch {
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(res1, 0);

    const res2 = kv.put("test1", "moo2") catch {
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(res2, 0);

    const res = kv.get("test0");

    try std.testing.expectEqual(res.?.len, 5);
    try std.testing.expectEqual(res, [5]u8{'m','o','o',170,170});

    const resf = kv.fileDump("./src/out-data/kv-dump.dat") catch {
        try std.testing.expectEqual(false, true);
        return;
    };
    try std.testing.expectEqual(resf, 0);
}
