const std = @import("std");

const Transpiler = @import("../../Transpiler.zig");
const Token = @import("Token.zig");

pub const Parser = struct {
    current: usize,
    tokList: std.ArrayList(*Token),

    pub fn nextTok(self: *Parser) Token.Type {
        defer self.current += 1;
        if (self.current >= self.tokList.items.len) {
            return .Unknown;
        }
        while (self.tokList.items[self.current].type == .Whitespace) {
            self.current += 1;
            if (self.current >= self.tokList.items.len) {
                return .Unknown;
            }
        }
        return self.tokList.items[self.current].type;
    }
};

pub fn keywordsFromList(comptime keywords: []const u8) std.StaticStringMap(void) {
    @setEvalBranchQuota(2000);

    const count = comptime blk: {
        var iter = std.mem.splitScalar(u8, keywords, '\n');
        var i = 0;
        while (iter.next()) |_| {
            i += 1;
        }
        break :blk i;
    };

    const array: [count]struct { []const u8 } = comptime blk: {
        var i = 0;
        var array: [count]struct { []const u8 } = undefined;
        var iter = std.mem.splitScalar(u8, keywords, '\n');
        while (iter.next()) |line| {
            array[i] = .{line};
            i += 1;
        }
        break :blk array;
    };

    return .initComptime(array);
}

pub inline fn isEnd(i: usize, data: []const u8) bool {
    return i >= data.len;
}

fn append(ctx: *Transpiler, tok_list: *std.ArrayList(*Token), value: Token) void {
    tok_list.append(ctx.allocator, Token.create(ctx.allocator, value)) catch @panic("Out of Memory");
}

pub fn whitespace(ctx: *Transpiler, i: *usize, data: []const u8, tok_list: *std.ArrayList(*Token)) bool {
    if (std.ascii.isWhitespace(data[i.*])) {
        const start = i.*;
        while (!isEnd(i.*, data) and std.ascii.isWhitespace(data[i.*])) {
            i.* += 1;
        }
        append(ctx, tok_list, .{
            .data = data[start..i.*],
            .type = .Whitespace,
        });
        return true;
    }
    return false;
}

pub fn identifier(
    ctx: *Transpiler,
    i: *usize,
    data: []const u8,
    tok_list: *std.ArrayList(*Token),
    keywords: std.StaticStringMap(void),
) bool {
    if (std.ascii.isAlphabetic(data[i.*]) or data[i.*] == '_') {
        const start = i.*;
        while (!isEnd(i.*, data) and (std.ascii.isAlphanumeric(data[i.*]) or data[i.*] == '_')) {
            i.* += 1;
        }
        const lexeme = data[start..i.*];

        append(ctx, tok_list, .{
            .data = lexeme,
            .type = if (keywords.get(lexeme)) |_| .Keyword else .Ident,
        });
        return true;
    }
    return false;
}

pub fn decimal(ctx: *Transpiler, i: *usize, data: []const u8, tok_list: *std.ArrayList(*Token)) bool {
    if (std.ascii.isDigit(data[i.*])) {
        const start = i.*;
        while (!isEnd(i.*, data) and std.ascii.isDigit(data[i.*])) {
            i.* += 1;
        }
        const lexeme = data[start..i.*];

        append(ctx, tok_list, .{
            .data = lexeme,
            .type = .Number,
        });
        return true;
    }
    return false;
}

pub fn string(
    ctx: *Transpiler,
    i: *usize,
    data: []const u8,
    tok_list: *std.ArrayList(*Token),
    delimeter: u8,
) bool {
    if (data[i.*] == delimeter) {
        const start = i.*;
        i.* += 1;
        while (!isEnd(i.*, data) and data[i.*] != delimeter) {
            if (data[i.*] == '\\') {
                i.* += 1;
            }
            if (isEnd(i.*, data)) break;
            i.* += 1;
        }
        if (!isEnd(i.*, data)) i.* += 1;
        append(ctx, tok_list, .{
            .data = data[start..i.*],
            .type = .String,
        });
        return true;
    }
    return false;
}
