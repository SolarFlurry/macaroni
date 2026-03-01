const std = @import("std");

const Span = @import("Span.zig");

const Self = @This();

type: Type,
data: []const u8,
location: Span,

pub const Type = enum {
    Eof,
    ParaSep,
    Raw,
    Backslash,
    RightBrace,
    LeftBrace,
    Ident,
    Number,
    String,
    RightParen,
    LeftParen,
    Comma,
};

pub fn print(self: *Self) void {
    std.debug.print("{s}: '{s}'\n", .{ @tagName(self.type), self.data });
}
