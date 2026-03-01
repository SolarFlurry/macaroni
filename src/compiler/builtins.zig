const std = @import("std");

const Scope = @import("symtable/Scope.zig");
const Symbol = @import("symtable/Symbol.zig");
const AstNode = @import("AstNode.zig");
const Transpiler = @import("Transpiler.zig");

const Compiler = @import("../Compiler.zig");

const highlight = @import("Transpiler/highlight.zig");

pub fn boldBuiltin(
    ctx: *Transpiler,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{OutOfMemory}!*Transpiler.HtmlTree {
    const tree = try ctx.allocator.create(Transpiler.HtmlTree);

    tree.* = if (body) |value| .{
        .kind = .{ .tag = .{
            .first_child = try ctx.transpileNode(value, scope),
            .name = "b",
            .props = .init(ctx.allocator),
        } },
        .sibling = null,
    } else .{
        .kind = .{ .leaf = "" },
        .sibling = null,
    };

    return tree;
}

pub fn italicBuiltin(
    ctx: *Transpiler,
    _: std.ArrayList(*AstNode),
    body: ?*AstNode,
    scope: *Scope,
) error{OutOfMemory}!*Transpiler.HtmlTree {
    const tree = try ctx.allocator.create(Transpiler.HtmlTree);

    tree.* = if (body) |value| .{
        .kind = .{ .tag = .{
            .first_child = try ctx.transpileNode(value, scope),
            .name = "i",
            .props = .init(ctx.allocator),
        } },
        .sibling = null,
    } else .{
        .kind = .{ .leaf = "" },
        .sibling = null,
    };

    return tree;
}

pub fn codeblockBuiltin(
    ctx: *Transpiler,
    args: std.ArrayList(*AstNode),
    body: ?*AstNode,
    _: *Scope,
) error{OutOfMemory}!*Transpiler.HtmlTree {
    if (args.items.len != 1) @panic("Expected 1 argument");

    return if (body) |value| {
        var string = std.ArrayList(u8).empty;
        try value.rawContents(ctx.allocator, &string, false);
        return try highlight.highlight(ctx, args.items[0].data.expression.literal_string, string.items);
    } else blk: {
        const tree = try ctx.allocator.create(Transpiler.HtmlTree);
        tree.* = .{
            .kind = .{ .leaf = "" },
            .sibling = null,
        };
        break :blk tree;
    };
}

pub fn populateSymtable(compiler: Compiler, symtable: *Scope) !void {
    const num_builtins = comptime @typeInfo(@This()).@"struct".decls.len - 1;

    const slots = try symtable.symbols.addManyAsArray(compiler.allocator, num_builtins);
    slots.* = [_]*const Symbol{
        &Symbol{ .name = "b", .value = .{ .builtin = boldBuiltin } },
        &Symbol{ .name = "i", .value = .{ .builtin = italicBuiltin } },
        &Symbol{ .name = "codeblock", .value = .{ .builtin = codeblockBuiltin } },
    };
}
