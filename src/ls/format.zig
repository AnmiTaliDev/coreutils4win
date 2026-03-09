// AnmiTaliDev CoreUtils4Win - ls output formatting (Windows)
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const windows = std.os.windows;
const Entry = @import("entry.zig").Entry;
const Options = @import("options.zig").Options;

const RESET = "\x1b[0m";
const BLUE  = "\x1b[1;34m";
const CYAN  = "\x1b[1;36m";

const STD_OUTPUT_HANDLE: windows.DWORD = @bitCast(@as(i32, -11));
const ENABLE_VIRTUAL_TERMINAL_PROCESSING: windows.DWORD = 0x0004;

extern "kernel32" fn GetStdHandle(nStdHandle: windows.DWORD) callconv(.winapi) ?windows.HANDLE;
extern "kernel32" fn GetConsoleMode(hConsoleHandle: windows.HANDLE, lpMode: *windows.DWORD) callconv(.winapi) windows.BOOL;
extern "kernel32" fn SetConsoleMode(hConsoleHandle: windows.HANDLE, dwMode: windows.DWORD) callconv(.winapi) windows.BOOL;

var ansi_enabled: bool = false;
var ansi_checked: bool = false;

pub fn enableAnsi() void {
    if (ansi_checked) return;
    ansi_checked = true;
    const handle = GetStdHandle(STD_OUTPUT_HANDLE) orelse return;
    var mode: windows.DWORD = 0;
    if (GetConsoleMode(handle, &mode) == 0) return;
    mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
    ansi_enabled = SetConsoleMode(handle, mode) != 0;
}

pub fn useColor(opts: Options) bool {
    return switch (opts.color) {
        .always => true,
        .never  => false,
        .auto   => blk: {
            enableAnsi();
            break :blk ansi_enabled;
        },
    };
}

pub fn printShort(writer: anytype, entries: []const Entry, opts: Options) !void {
    const color = useColor(opts);
    for (entries) |e| {
        if (color) {
            try writeColored(writer, e);
        } else {
            try writer.writeAll(e.name);
        }
        if (opts.one_per_line) {
            try writer.writeAll("\r\n");
        } else {
            try writer.writeAll("  ");
        }
    }
    if (!opts.one_per_line and entries.len > 0) try writer.writeAll("\r\n");
}

pub fn printLong(writer: anytype, entries: []const Entry, opts: Options) !void {
    const color = useColor(opts);
    for (entries) |e| {
        const kind_char: u8 = switch (e.kind) {
            .directory => 'd',
            .sym_link  => 'l',
            else       => '-',
        };

        const mtime_sec = @as(i64, @intCast(@divTrunc(e.mtime, std.time.ns_per_s)));
        const epoch = std.time.epoch.EpochSeconds{ .secs = @as(u64, @intCast(@max(0, mtime_sec))) };
        const day = epoch.getDaySeconds();
        const year_day = epoch.getEpochDay();
        const year_and_day = year_day.calculateYearDay();
        const month_and_day = year_and_day.calculateMonthDay();

        const size_str = if (opts.human_readable) blk: {
            break :blk humanSize(e.size);
        } else blk: {
            var buf: [20]u8 = undefined;
            break :blk try std.fmt.bufPrint(&buf, "{d}", .{e.size});
        };

        try writer.print("{c}--------- {s:>8} {s} {d:0>2} {d:0>2}:{d:0>2} ",
            .{
                kind_char,
                size_str,
                monthName(month_and_day.month.numeric()),
                month_and_day.day_index + 1,
                day.getHoursIntoDay(),
                day.getMinutesIntoHour(),
            });

        if (color) {
            try writeColored(writer, e);
        } else {
            try writer.writeAll(e.name);
        }
        try writer.writeAll("\r\n");
    }
}

fn writeColored(writer: anytype, e: Entry) !void {
    switch (e.kind) {
        .directory => {
            try writer.writeAll(BLUE);
            try writer.writeAll(e.name);
            try writer.writeAll(RESET);
        },
        .sym_link => {
            try writer.writeAll(CYAN);
            try writer.writeAll(e.name);
            try writer.writeAll(RESET);
        },
        else => try writer.writeAll(e.name),
    }
}

fn monthName(m: u4) []const u8 {
    return switch (m) {
        1  => "Jan", 2  => "Feb", 3  => "Mar", 4  => "Apr",
        5  => "May", 6  => "Jun", 7  => "Jul", 8  => "Aug",
        9  => "Sep", 10 => "Oct", 11 => "Nov", 12 => "Dec",
        else => "???",
    };
}

fn humanSize(size: u64) []const u8 {
    const static = struct { var buf: [16]u8 = undefined; };
    if (size < 1024) return std.fmt.bufPrint(&static.buf, "{d}B", .{size}) catch "?";
    if (size < 1024 * 1024) return std.fmt.bufPrint(&static.buf, "{d:.0}K", .{@as(f64, @floatFromInt(size)) / 1024.0}) catch "?";
    if (size < 1024 * 1024 * 1024) return std.fmt.bufPrint(&static.buf, "{d:.0}M", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0)}) catch "?";
    return std.fmt.bufPrint(&static.buf, "{d:.0}G", .{@as(f64, @floatFromInt(size)) / (1024.0 * 1024.0 * 1024.0)}) catch "?";
}
