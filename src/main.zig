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

const StatementType = enum {
    STATEMENT_INSERT,
    STATEMENT_SELECT,
    STATEMENT_UNKNOWN,
};

const PREPARE_STATEMENT_RESULT = enum {
    SUCCESS,
    SYNTAX_ERROR,
    UNRECOGNIZED_STATEMENT,
    FAIL,
};

const EXECUTE_STATEMENT_RESULT = enum {
    SUCCESS,
    TABLE_FULL,
    FAIL,
};

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

    var dataHash = std.StringHashMap([]const u8).init(allocator);

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

                const executed = dataHash.get(prepared.op.key) orelse "";

                try stdout.print("Execute Command Success\n", .{});
                try stdout.print("Key: <{s}> Value: <{s}>\n", .{prepared.op.key, executed});
                continue;
            },
            repl.COMMAND_RESULT.PUT => {
                const prepared: commands.PreparedPutCommand = preparePut.preparePut(command);

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

        // enum guarantees all options are accounted for
        // var statement = Statement {
        //     .type = StatementType.STATEMENT_UNKNOWN,
        //     .row_to_insert = Row {
        //         .id = 0,
        //         .str1 = "",
        //         .str2 = "",
        //     },
        // };
        // const result = prepareStatement(command, &statement, stdout) catch PREPARE_STATEMENT_RESULT.FAIL;
        //
        // switch (result) {
        //     PREPARE_STATEMENT_RESULT.SUCCESS => {
        //         try stdout.print("Prepare statement success!\n", .{});
        //     },
        //     PREPARE_STATEMENT_RESULT.SYNTAX_ERROR => {
        //         try stdout.print("Syntax Error: {s}\n", .{command});
        //     },
        //     PREPARE_STATEMENT_RESULT.UNRECOGNIZED_STATEMENT => {
        //         try stdout.print("Unrecognized Statement\n", .{});
        //         continue;
        //     },
        //     PREPARE_STATEMENT_RESULT.FAIL => {
        //         try stdout.print("Failed to prepare statement: {s}\n", .{command});
        //         continue;
        //     },
        // }
        // try stdout.print("here?\n", .{});
        //
        // const execResult = executeStatement(&statement, table, allocator, stdout) catch EXECUTE_STATEMENT_RESULT.FAIL;
        // switch (execResult) {
        //     EXECUTE_STATEMENT_RESULT.SUCCESS => {
        //         try stdout.print("Executed statement: {s}\n", .{command});
        //         break;
        //     },
        //     EXECUTE_STATEMENT_RESULT.FAIL => {
        //         try stdout.print("Failed to execute statement: {s}\n", .{command});
        //         continue;
        //     },
        //     EXECUTE_STATEMENT_RESULT.TABLE_FULL => {
        //         try stdout.print("Failed to execute statement, table is full: {s}\n", .{command});
        //         continue;
        //     },
        // }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
