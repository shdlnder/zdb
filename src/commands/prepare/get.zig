const std = @import("std");
const commands = @import("../commands.zig");

pub fn prepareGet(command: []u8) commands.PreparedGetCommand {
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
