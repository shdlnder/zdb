const std = @import("std");

// if len > 1, check branches. else check leaves
pub const Branch = struct {
    key: u8,
    branches: std.AutoHashMap(u8, Branch),
    leaves: std.AutoHashMap(u8, []u8),
};
