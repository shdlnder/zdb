const std = @import("std");
const eql = std.mem.eql;
const parseInt = std.fmt.parseInt;
const startsWith = std.mem.startsWith;
const Allocator = std.mem.Allocator;
const meta = std.meta;
const repl = @import("./repl.zig");
const commands = @import("./commands/commands.zig");
const prepareGet = @import("./commands/prepare/get.zig");
const preparePut = @import("./commands/prepare/put.zig");
const executeGet = @import("./commands/execute/get.zig");
const executePut = @import("./commands/execute/put.zig");

pub fn printPrompt(stdout: anytype) !void {
    try stdout.print("db > ", .{});
}

pub fn readInput(input: *[500]u8, stdin: anytype) anyerror!?[]u8 {
    return (try stdin.readUntilDelimiterOrEof(input, '\n')).?;
}

pub fn main() !void {

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    var dataHash = std.StringHashMap([5]u8).init(allocator);

    var input: [500]u8 = undefined;
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    while (true) {
        printPrompt(stdout) catch {
            std.process.exit(1);
        };

        const command: []u8 = stdin.readUntilDelimiterOrEof(&input, '\n') catch {
            std.process.exit(1);
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
                std.process.exit(0);
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

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
