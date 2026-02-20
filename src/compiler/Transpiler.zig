const std = @import("std");

const Self = @This();
const AstNode = @import("AstNode.zig");
const Scope = @import("symtable/Scope.zig");
const Compiler = @import("../Compiler.zig");

const AllocError = error{OutOfMemory};

pub const HtmlTree = @import("Transpiler/HtmlTree.zig");

allocator: std.mem.Allocator,

pub fn transpileNode(self: *Self, node: *const AstNode, scope: *Scope) AllocError!*HtmlTree {
    const tree: ?*HtmlTree = switch (node.data) {
        .section => |doc| blk: {
            const data = inner: {
                var first: ?*HtmlTree = null;
                var last: ?*HtmlTree = null;
                for (doc.elements.items) |inner| {
                    const inner_tree = try self.transpileNode(inner, scope);
                    if (first == null) {
                        first = inner_tree;
                        last = first;
                        continue;
                    }
                    last.?.addSibling(inner_tree);
                    last = inner_tree;
                }
                break :inner first;
            };

            if (!doc.is_paragraph) {
                break :blk data;
            }

            const tree = try self.allocator.create(HtmlTree);

            tree.* = .{
                .kind = .{ .tag = .{
                    .first_child = data,
                    .name = "p",
                } },
                .sibling = null,
            };

            break :blk tree;
        },
        .macro => |macro| blk: {
            if (scope.findSymbol(macro.name)) |symbol| {
                switch (symbol.value) {
                    .builtin => |builtin| {
                        break :blk try builtin(
                            self,
                            macro.args,
                            macro.body,
                            scope,
                        );
                    },
                    else => unreachable,
                }
            } else std.debug.panic("cannot find name '{s}' in symbol table", .{macro.name});
        },
        .raw => blk: {
            const tree = try self.allocator.create(HtmlTree);
            tree.* = .{
                .kind = .{
                    .leaf = node.token.data,
                },
                .sibling = null,
            };

            break :blk tree;
        },
    };

    if (tree) |inner| {
        return inner;
    }

    const result = try self.allocator.create(HtmlTree);
    result.* = .{
        .kind = .{ .leaf = "" },
        .sibling = null,
    };
    return result;
}

pub fn transpile(self: *Self, nodes: std.ArrayList(*AstNode), scope: *Scope) AllocError!std.ArrayList(*HtmlTree) {
    var tree = std.ArrayList(*HtmlTree).empty;

    for (nodes.items) |node| {
        const slot = try tree.addOne(self.allocator);
        slot.* = try self.transpileNode(node, scope);
    }

    return tree;
}

pub fn init(compiler: Compiler) Self {
    return .{ .allocator = compiler.allocator };
}
