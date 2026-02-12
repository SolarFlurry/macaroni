const std = @import("std");

const Self = @This();

const AstNode = @import("../AstNode.zig");
const Scope = @import("Scope.zig");

name: []const u8,
value: Value,

pub const Value = union(enum) {
    builtin: *const fn (
        writer: *std.Io.Writer,
        args: std.ArrayList(*AstNode),
        body: ?*AstNode,
        scope: *Scope,
    ) error{WriteFailed}!void,
    macro: *AstNode,
    str: []const u8,
};
