const std = @import("std");

const Self = @This();

const Symbol = @import("Symbol.zig");
const compiler = @import("../../compiler.zig");

symbols: std.ArrayList(*const Symbol),

pub fn init() Self {
    return Self{ .symbols = .empty };
}

pub fn addSymbol(self: *Self, symbol: *const Symbol) !void {
    const slot = try self.symbols.addOne(compiler.allocator);
    slot.* = symbol;
}

pub fn findSymbol(self: *Self, name: []const u8) ?*const Symbol {
    for (self.symbols.items) |symbol| {
        if (std.mem.eql(u8, name, symbol.name)) {
            return symbol;
        }
    }
    return null;
}
