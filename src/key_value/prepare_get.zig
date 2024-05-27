const std = @import("std");
const commands = @import("./commands.zig");

pub fn prepareGetRepl(command: []const u8) commands.PreparedGetCommand {
    var iter = std.mem.tokenizeAny(u8, command, " \r\n");

    const op = iter.next() orelse "";
    const key = iter.next() orelse "";

    if (!std.mem.eql(u8, op, commands.CMD_GET)) {
        return commands.PreparedGetCommand{
            .result = commands.PREP_RESULT.INVALID_COMMAND,
            .op = commands.OpGet{
                .key = key,
            },
        };
    }

    if (key.len < 1) {
        return commands.PreparedGetCommand{
            .result = commands.PREP_RESULT.INVALID_KEY,
            .op = commands.OpGet{
                .key = key,
            },
        };
    }

    return commands.PreparedGetCommand{
        .result = commands.PREP_RESULT.SUCCESS,
        .op = commands.OpGet{
            .key = key,
        },
    };
}

pub fn prepareGetKV(key: []const u8) commands.PreparedGetCommand {
    if (key.len < 1) {
        return commands.PreparedGetCommand{
            .result = commands.PREP_RESULT.INVALID_KEY,
            .op = commands.OpGet{
                .key = key,
            },
        };
    }

    return commands.PreparedGetCommand{
        .result = commands.PREP_RESULT.SUCCESS,
        .op = commands.OpGet{
            .key = key,
        },
    };
}

test "Test prepareGetRepl success" {
    const res = prepareGetRepl("GET test0");
    try std.testing.expectEqual(std.mem.eql(u8, res.op.key, "test0"), true);
}

test "Test prepareGetRepl invalid key" {
    const res = prepareGetRepl("GET");
    try std.testing.expectEqual(res.result, commands.PREP_RESULT.INVALID_KEY);
}

test "Test prepareGetRepl invalid command" {
    const res = prepareGetRepl("MOOO test0");
    try std.testing.expectEqual(res.result, commands.PREP_RESULT.INVALID_COMMAND);
}

test "Test prepareGetKV success" {
    const res = prepareGetKV("moo");
    try std.testing.expectEqual(std.mem.eql(u8, res.op.key, "moo"), true);
}

test "Test prepareGetKV invalid key" {
    const res = prepareGetKV("");
    try std.testing.expectEqual(res.result, commands.PREP_RESULT.INVALID_KEY);
}
