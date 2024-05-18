pub const PREP_RESULT = enum {
    SUCCESS,
    FAIL,
    INVALID_COMMAND,
    INVALID_KEY,
};

pub const CMD_GET = "GET";
pub const CMD_PUT = "PUT";

pub const PreparedGetCommand = struct {
    result: PREP_RESULT,
    op: OpGet,
};

pub const PreparedPutCommand = struct {
    result: PREP_RESULT,
    op: OpPut,
};

pub const OpGet = struct {
    key: []const u8,
};

pub const OpPut = struct {
    key: []const u8,
    value: [5]u8,
};
