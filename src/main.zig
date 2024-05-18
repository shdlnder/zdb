const std = @import("std");
const eql = std.mem.eql;
const parseInt = std.fmt.parseInt;
const startsWith = std.mem.startsWith;
const Allocator = std.mem.Allocator;
const meta = std.meta;
const key_value = @import("./key_value.zig");

pub fn main() !void {

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    const result = key_value.runRepl(allocator, stdin, stdout) catch {
        std.process.exit(1);
    };
    std.process.exit(result);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
