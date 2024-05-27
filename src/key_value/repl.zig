const std = @import("std");

pub const CMD_EXIT: []const u8 = "exit";
pub const CMD_PUT: []const u8 = "PUT";
pub const CMD_GET: []const u8 = "GET";

pub const COMMAND_RESULT = enum {
    EXIT,

    PUT,
    GET,

    FAIL,
    UNRECOGNIZED_COMMAND,
};

pub fn parseCommand(command: []const u8) COMMAND_RESULT {
    if (std.mem.startsWith(u8, command, CMD_GET)) {
        return COMMAND_RESULT.GET;
    } else if (std.mem.startsWith(u8, command, CMD_PUT)) {
        return COMMAND_RESULT.PUT;
    } else if (std.mem.eql(u8, command, CMD_EXIT)) {
        return COMMAND_RESULT.EXIT;
    } else {
        return COMMAND_RESULT.UNRECOGNIZED_COMMAND;
    }
}
