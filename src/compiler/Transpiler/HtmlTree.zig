const std = @import("std");

const Self = @This();

sibling: ?*Self,
kind: Kind,

pub const Kind = union(enum) {
    tag: struct {
        first_child: ?*Self,
        name: []const u8,
    },
    leaf: []const u8,
};

pub fn addSibling(self: *Self, sibling: *Self) void {
    var current: *?*Self = &self.sibling;
    while (current.*) |tree| {
        current = &tree.sibling;
    }
    current.* = sibling;
}

pub fn addChild(self: *Self, child: *Self) void {
    switch (self.kind) {
        .leaf => std.debug.panic("cannot add a child on a leaf", .{}),
        .tag => |*tag| {
            if (tag.first_child) |first_child| {
                first_child.addSibling(child);
                return;
            }
            tag.first_child = child;
        },
    }
}

pub fn writeHtml(self: *Self, writer: *std.Io.Writer) error{WriteFailed}!void {
    switch (self.kind) {
        .tag => |tag| {
            try writer.print("<{s}>", .{tag.name});
            if (tag.first_child) |child| {
                try child.writeHtml(writer);
            }
            try writer.print("</{s}>", .{tag.name});
            if (tag.name.len == 1 and tag.name.ptr[0] == 'p') {
                try writer.writeByte('\n');
            }
        },
        .leaf => |data| _ = try writer.write(data),
    }
    if (self.sibling) |sibling| {
        try sibling.writeHtml(writer);
    }
}
