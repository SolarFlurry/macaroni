const std = @import("std");

pub const Lexer = @import("compiler/Lexer.zig");
pub const Parser = @import("compiler/Parser.zig");
pub const AstNode = @import("compiler/AstNode.zig");
pub const Token = @import("compiler/Token.zig");
pub const Scope = @import("compiler/symtable/Scope.zig");
pub const Symbol = @import("compiler/symtable/Symbol.zig");

pub const reporter = @import("compiler/reporter.zig");

const builtins = @import("compiler/builtins.zig");

pub var allocator: std.mem.Allocator = undefined;

pub fn compile(
    source_file: []const u8,
    output_stream: *std.fs.File,
    init_allocator: std.mem.Allocator,
) !void {
    allocator = init_allocator;

    var cwd = std.fs.cwd();
    const file = try cwd.openFile(source_file, .{});
    defer file.close();

    const stat = try file.stat();
    const file_data = try allocator.alloc(u8, stat.size);

    _ = try file.read(file_data);

    var lexer = Lexer.init(file_data);
    var parser = try Parser.init(&lexer);

    var symtable = Scope.init();
    try builtins.populateSymtable(&symtable);

    const document = try parser.parse();

    reporter.printErrors(file_data);

    std.debug.print("\x1b[36mDocument\x1b[0m:\n", .{});
    for (0..document.items.len) |i| {
        if (i == document.items.len - 1) {
            document.items[i].print(0, 2, 0);
        } else {
            document.items[i].print(0, 1, 1);
        }
    }

    var buffer: [1024]u8 = undefined;
    var writer = output_stream.writer(&buffer);

    for (document.items) |node| {
        try node.writeHtml(&writer.interface, &symtable);
    }

    try writer.interface.writeByte('\n');
    try writer.interface.flush();
}
