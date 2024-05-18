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
