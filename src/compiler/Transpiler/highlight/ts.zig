const std = @import("std");

const Token = @import("Token.zig");
const Transpiler = @import("../../Transpiler.zig");

const constructs = @import("constructs.zig");

fn append(ctx: *Transpiler, tok_list: *std.ArrayList(*Token), value: Token) void {
    tok_list.append(ctx.allocator, Token.create(ctx.allocator, value)) catch @panic("Out of Memory");
}

fn tokenise(ctx: *Transpiler, data: []const u8) std.ArrayList(*Token) {
    var tok_list: std.ArrayList(*Token) = .empty;
    var i: usize = 0;
    while (!constructs.isEnd(i, data)) {
        if (constructs.whitespace(ctx, &i, data, &tok_list)) continue;
        if (constructs.decimal(ctx, &i, data, &tok_list)) continue;
        if (constructs.string(ctx, &i, data, &tok_list, '"')) continue;
        if (constructs.identifier(
            ctx,
            &i,
            data,
            &tok_list,
            constructs.keywordsFromList(@embedFile("ts_keywords.txt")),
        )) continue;

        append(ctx, &tok_list, .{
            .data = data[i .. i + 1],
            .type = switch (data[i]) {
                '(' => .LeftParen,
                ')' => .RightParen,
                else => .Symbol,
            },
        });
        i += 1;
    }

    return tok_list;
}

pub fn highlight(ctx: *Transpiler, data: []const u8) std.ArrayList(*Token) {
    var parser = constructs.Parser{
        .current = 0,
        .tokList = tokenise(ctx, data),
    };

    while (parser.current <= parser.tokList.items.len) {
        switch (parser.nextTok()) {
            .Ident => {
                if (parser.nextTok() == .LeftParen)
                    parser.tokList.items[parser.current - 2].type = .Function;
            },
            else => {},
        }
    }

    return parser.tokList;
}
