const std = @import("std");

const HtmlTree = @import("HtmlTree.zig");
const Transpiler = @import("../Transpiler.zig");

pub const Token = @import("highlight/Token.zig");

const ts = @import("highlight/ts.zig");

const langs: std.StaticStringMap(
    *const fn (ctx: *Transpiler, data: []const u8) std.ArrayList(*Token),
) = .initComptime(.{
    .{ "ts", ts.highlight },
});

pub fn highlight(ctx: *Transpiler, language: []const u8, data: []const u8) error{OutOfMemory}!*HtmlTree {
    const tree = try ctx.allocator.create(HtmlTree);
    if (langs.get(language)) |highlightFn| {
        const tok_list = highlightFn(ctx, data);

        tree.* = .{
            .kind = .{ .tag = .{
                .name = "code-block",
                .first_child = null,
            } },
            .sibling = null,
        };

        for (tok_list.items) |token| {
            const leaf = try ctx.allocator.create(HtmlTree);
            leaf.* = .{
                .kind = .{ .leaf = token.data },
                .sibling = null,
            };
            if (token.type == .Whitespace) {
                tree.addChild(leaf);
                continue;
            }
            const intermediate = try ctx.allocator.create(HtmlTree);
            intermediate.* = .{
                .kind = .{ .tag = .{
                    .first_child = leaf,
                    .name = @tagName(token.type),
                } },
                .sibling = null,
            };
            tree.addChild(intermediate);
        }

        return tree;
    }

    tree.* = .{
        .kind = .{ .leaf = data },
        .sibling = null,
    };

    return tree;
}
