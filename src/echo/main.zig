// AnmiTaliDev CoreUtils4Win - echo
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try common.argsAlloc(allocator);
    defer common.argsFree(allocator, args);

    var opts = Options{};
    var first_pos: usize = 1;

    outer: while (first_pos < args.len) : (first_pos += 1) {
        const arg = args[first_pos];
        if (arg.len == 0 or arg[0] != '-') break;
        if (std.mem.eql(u8, arg, "--")) { first_pos += 1; break; }
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "echo", "[OPTION]... [STRING]...");
            try w.writeAll(
                \\Echo the STRING(s) to standard output.
                \\
                \\  -n        do not output the trailing newline
                \\  -e        enable interpretation of backslash escapes
                \\  -E        disable interpretation of backslash escapes (default)
                \\  --help    display this help and exit
                \\  --version output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "echo");
            return;
        }
        for (arg[1..]) |c| {
            switch (c) {
                'n' => opts.no_newline = true,
                'e' => opts.enable_escapes = true,
                'E' => opts.enable_escapes = false,
                else => break :outer,
            }
        }
    }

    const out = std.fs.File.stdout().deprecatedWriter();

    for (args[first_pos..], 0..) |arg, i| {
        if (i > 0) try out.writeByte(' ');
        if (opts.enable_escapes) {
            try writeEscaped(out, arg);
        } else {
            try out.writeAll(arg);
        }
    }

    if (!opts.no_newline) try out.writeAll("\r\n");
}

fn writeEscaped(out: anytype, s: []const u8) !void {
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        if (s[i] != '\\' or i + 1 >= s.len) {
            try out.writeByte(s[i]);
            continue;
        }
        i += 1;
        switch (s[i]) {
            '\\' => try out.writeByte('\\'),
            'a'  => try out.writeByte(0x07),
            'b'  => try out.writeByte(0x08),
            'c'  => return,
            'e'  => try out.writeByte(0x1B),
            'f'  => try out.writeByte(0x0C),
            'n'  => try out.writeAll("\r\n"),
            'r'  => try out.writeByte('\r'),
            't'  => try out.writeByte('\t'),
            'v'  => try out.writeByte(0x0B),
            '0'  => {
                var val: u8 = 0;
                var j: usize = 0;
                while (j < 3 and i + 1 < s.len and s[i + 1] >= '0' and s[i + 1] <= '7') : (j += 1) {
                    i += 1;
                    val = val *% 8 +% (s[i] - '0');
                }
                try out.writeByte(val);
            },
            else => { try out.writeByte('\\'); try out.writeByte(s[i]); },
        }
    }
}
