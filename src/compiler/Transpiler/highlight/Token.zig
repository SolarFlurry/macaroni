const std = @import("std");

const Self = @This();

pub const Type = enum {
    Whitespace,
    Unknown,
    Comment,
    Ident,
    Function,
    Keyword,
    Number,
    String,
    LeftParen,
    RightParen,
    Symbol,
};

type: Type,
data: []const u8,

pub fn create(allocator: std.mem.Allocator, value: Self) *Self {
    const token = allocator.create(Self) catch @panic("Out of memory");
    token.* = value;
    return token;
}
