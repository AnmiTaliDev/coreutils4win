// AnmiTaliDev CoreUtils4Win - tail reader
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const Mode = @import("options.zig").Mode;

pub fn readTail(reader: anytype, writer: anytype, allocator: std.mem.Allocator, mode: Mode) !void {
    switch (mode) {
        .lines => |n| try tailLines(reader, writer, allocator, n),
        .bytes => |n| try tailBytes(reader, writer, allocator, n),
    }
}

fn tailLines(reader: anytype, writer: anytype, allocator: std.mem.Allocator, count: u64) !void {
    var lines = std.ArrayList([]u8){};
    defer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

    while (true) {
        var line = std.ArrayList(u8){};
        errdefer line.deinit(allocator);
        reader.streamUntilDelimiter(line.writer(allocator), '\n', null) catch |err| switch (err) {
            error.EndOfStream => {
                if (line.items.len > 0) {
                    const owned = try line.toOwnedSlice(allocator);
                    if (lines.items.len >= count) {
                        allocator.free(lines.items[0]);
                        std.mem.copyForwards([]u8, lines.items[0..], lines.items[1..]);
                        lines.items[lines.items.len - 1] = owned;
                    } else {
                        try lines.append(allocator, owned);
                    }
                } else {
                    line.deinit(allocator);
                }
                break;
            },
            else => return err,
        };
        const owned = try line.toOwnedSlice(allocator);
        if (lines.items.len >= count) {
            allocator.free(lines.items[0]);
            std.mem.copyForwards([]u8, lines.items[0..], lines.items[1..]);
            lines.items[lines.items.len - 1] = owned;
        } else {
            try lines.append(allocator, owned);
        }
    }

    for (lines.items) |line| {
        // Strip \r if present (Windows line endings)
        var content = line;
        if (content.len > 0 and content[content.len - 1] == '\r') {
            content = content[0 .. content.len - 1];
        }
        try writer.writeAll(content);
        try writer.writeAll("\r\n");
    }
}

fn tailBytes(reader: anytype, writer: anytype, allocator: std.mem.Allocator, count: u64) !void {
    var buf = std.ArrayList(u8){};
    defer buf.deinit(allocator);

    var tmp: [65536]u8 = undefined;
    while (true) {
        const n = try reader.read(&tmp);
        if (n == 0) break;
        try buf.appendSlice(allocator, tmp[0..n]);
    }

    if (buf.items.len <= count) {
        try writer.writeAll(buf.items);
    } else {
        try writer.writeAll(buf.items[buf.items.len - count ..]);
    }
}

pub fn followFile(file: std.fs.File, writer: anytype, sleep_ns: u64) !void {
    var pos = try file.getPos();
    while (true) {
        const stat = try file.stat();
        if (stat.size < pos) {
            pos = 0;
            try file.seekTo(0);
        }
        var buf: [65536]u8 = undefined;
        while (true) {
            const n = try file.read(&buf);
            if (n == 0) break;
            try writer.writeAll(buf[0..n]);
            pos += n;
        }
        std.Thread.sleep(sleep_ns);
    }
}
