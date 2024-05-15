const std = @import("std");
const commands = @import("../commands.zig");

pub fn preparePut(command: []u8) commands.PreparedPutCommand {
    var iter = std.mem.tokenizeAny(u8, command, " \r\n");

    const op = iter.next() orelse "";
    const key = iter.next() orelse "";
    const value = iter.next() orelse "";

    if (!std.mem.eql(u8, op, commands.CMD_PUT)) {
        return commands.PreparedPutCommand{
            .result = commands.PREP_RESULT.INVALID_COMMAND,
            .op = commands.OpPut{
                .key = key,
                .value = value,
            },
        };
    }

    if (key.len < 1) {
        return commands.PreparedPutCommand{
            .result = commands.PREP_RESULT.INVALID_KEY,
            .op = commands.OpPut{
                .key = key,
                .value = value,
            },
        };
    }

    return commands.PreparedPutCommand{
        .result = commands.PREP_RESULT.SUCCESS,
        .op = commands.OpPut{
            .key = key,
            .value = value,
        },
    };
}
