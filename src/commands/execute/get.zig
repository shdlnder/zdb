const std = @import("std");

pub fn executeGet(map: *std.AutoHashMap([]u8, []u8), key: []u8) ?[]u8 {
    return map.get(key);
}
