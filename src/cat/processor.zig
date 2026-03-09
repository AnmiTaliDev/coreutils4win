// AnmiTaliDev CoreUtils4Win - cat processor
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const Options = @import("options.zig").Options;

pub fn process(reader: anytype, writer: anytype, opts: Options, line_num: *u64) !void {
    var buf: [65536]u8 = undefined;
    var prev_blank = false;

    if (!opts.number and !opts.number_nonblank and !opts.show_ends and
        !opts.show_tabs and !opts.show_nonprinting and !opts.squeeze_blank)
    {
        while (true) {
            const n = try reader.read(&buf);
            if (n == 0) break;
            try writer.writeAll(buf[0..n]);
        }
        return;
    }

    const page_alloc = std.heap.page_allocator;
    var line = std.ArrayList(u8){};
    defer line.deinit(page_alloc);

    while (true) {
        line.clearRetainingCapacity();
        reader.streamUntilDelimiter(line.writer(page_alloc), '\n', null) catch |err| switch (err) {
            error.EndOfStream => {
                if (line.items.len > 0) {
                    try writeLine(writer, line.items, opts, line_num, false);
                }
                break;
            },
            else => return err,
        };

        // Strip trailing \r for Windows-style line endings
        var content = line.items;
        if (content.len > 0 and content[content.len - 1] == '\r') {
            content = content[0 .. content.len - 1];
        }

        const is_blank = content.len == 0;
        if (opts.squeeze_blank and is_blank and prev_blank) continue;
        prev_blank = is_blank;

        try writeLine(writer, content, opts, line_num, true);
    }
}

fn writeLine(writer: anytype, line: []const u8, opts: Options, line_num: *u64, has_newline: bool) !void {
    const is_blank = line.len == 0;

    if (opts.number and !opts.number_nonblank) {
        line_num.* += 1;
        try writer.print("{d:>6}\t", .{line_num.*});
    } else if (opts.number_nonblank and !is_blank) {
        line_num.* += 1;
        try writer.print("{d:>6}\t", .{line_num.*});
    }

    if (opts.show_nonprinting or opts.show_tabs) {
        for (line) |c| try writeChar(writer, c, opts);
    } else {
        try writer.writeAll(line);
    }

    if (opts.show_ends and has_newline) try writer.writeByte('$');
    if (has_newline) try writer.writeAll("\r\n");
}

fn writeChar(writer: anytype, c: u8, opts: Options) !void {
    if (opts.show_tabs and c == '\t') {
        try writer.writeAll("^I");
        return;
    }
    if (opts.show_nonprinting) {
        if (c < 32 and c != '\t' and c != '\n') {
            try writer.print("^{c}", .{c + 64});
            return;
        }
        if (c == 127) {
            try writer.writeAll("^?");
            return;
        }
        if (c > 127 and c < 160) {
            try writer.print("M-^{c}", .{c - 128 + 64});
            return;
        }
        if (c >= 160) {
            try writer.print("M-{c}", .{c - 128});
            return;
        }
    }
    try writer.writeByte(c);
}
