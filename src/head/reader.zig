// AnmiTaliDev CoreUtils4Win - head reader
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const Mode = @import("options.zig").Mode;

pub fn readHead(reader: anytype, writer: anytype, mode: Mode) !void {
    switch (mode) {
        .lines => |n| try readLines(reader, writer, n),
        .bytes => |n| try readBytes(reader, writer, n),
    }
}

fn readLines(reader: anytype, writer: anytype, count: u64) !void {
    var buf: [65536]u8 = undefined;
    var lines_written: u64 = 0;
    var leftover: usize = 0;

    while (lines_written < count) {
        const n = try reader.read(buf[leftover..]);
        if (n == 0) {
            if (leftover > 0) try writer.writeAll(buf[0..leftover]);
            break;
        }
        const total = leftover + n;
        var start: usize = 0;
        var pos: usize = 0;
        while (pos < total and lines_written < count) : (pos += 1) {
            if (buf[pos] == '\n') {
                lines_written += 1;
                try writer.writeAll(buf[start .. pos + 1]);
                start = pos + 1;
            }
        }
        if (start < total and lines_written < count) {
            leftover = total - start;
            std.mem.copyForwards(u8, buf[0..leftover], buf[start..total]);
        } else {
            leftover = 0;
        }
    }
}

fn readBytes(reader: anytype, writer: anytype, count: u64) !void {
    var buf: [65536]u8 = undefined;
    var remaining = count;

    while (remaining > 0) {
        const to_read = @min(buf.len, remaining);
        const n = try reader.read(buf[0..to_read]);
        if (n == 0) break;
        try writer.writeAll(buf[0..n]);
        remaining -= n;
    }
}
