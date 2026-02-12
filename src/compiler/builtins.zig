const std = @import("std");

const Scope = @import("symtable/Scope.zig");
const Symbol = @import("symtable/Symbol.zig");
const AstNode = @import("AstNode.zig");

const compiler = @import("../compiler.zig");

pub fn boldBuiltin(
    writer: *std.Io.Writer,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{WriteFailed}!void {
    if (body) |value| {
        try writer.writeAll("<b>");
        try value.writeHtml(writer, scope);
        try writer.writeAll("</b>");
    }
}

pub fn italicBuiltin(
    writer: *std.Io.Writer,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{WriteFailed}!void {
    if (body) |value| {
        try writer.writeAll("<i>");
        try value.writeHtml(writer, scope);
        try writer.writeAll("</i>");
    }
}

pub fn populateSymtable(symtable: *Scope) !void {
    const num_builtins = comptime @typeInfo(@This()).@"struct".decls.len - 1;

    const slots = try symtable.symbols.addManyAsArray(compiler.allocator, num_builtins);
    slots.* = [_]*const Symbol{
        &Symbol{ .name = "b", .value = .{ .builtin = boldBuiltin } },
        &Symbol{ .name = "i", .value = .{ .builtin = italicBuiltin } },
    };
}
