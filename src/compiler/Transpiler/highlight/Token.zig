const std = @import("std");

const Self = @This();

pub const Type = enum {
    Whitespace,
    Unknown,
    Ident,
    Keyword,
    Number,
    String,
    Symbol,
};

type: Type,
data: []const u8,

pub fn create(allocator: std.mem.Allocator, value: Self) *Self {
    const token = allocator.create(Self) catch @panic("Out of memory");
    token.* = value;
    return token;
}
