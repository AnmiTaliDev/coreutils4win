// AnmiTaliDev CoreUtils4Win - basename
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const core = @import("core.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var opts = Options{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "basename", "NAME [SUFFIX] or: basename OPTION... NAME...");
            try w.writeAll(
                \\Strip directory and suffix from filenames.
                \\
                \\  -a, --multiple       support multiple arguments
                \\  -s, --suffix=SUFFIX  remove a trailing SUFFIX
                \\  -z, --zero           end each output line with NUL, not newline
                \\  --help               display this help and exit
                \\  --version            output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "basename");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--multiple")) {
            opts.multiple = true;
        } else if (std.mem.eql(u8, arg, "-z") or std.mem.eql(u8, arg, "--zero")) {
            opts.zero = true;
        } else if (std.mem.startsWith(u8, arg, "--suffix=")) {
            opts.suffix = arg[9..];
            opts.multiple = true;
        } else if (std.mem.eql(u8, arg, "-s") and i + 1 < args.len) {
            i += 1;
            opts.suffix = args[i];
            opts.multiple = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const out = std.fs.File.stdout().deprecatedWriter();
    const eol: []const u8 = if (opts.zero) "\x00" else "\r\n";
    const names = args[i..];

    if (names.len == 0) common.dieMsg("missing operand");

    if (opts.multiple) {
        for (names) |name| {
            var result = core.basename(name);
            if (opts.suffix) |sfx| result = core.stripSuffix(result, sfx);
            try out.print("{s}{s}", .{ result, eol });
        }
    } else {
        var result = core.basename(names[0]);
        const sfx = if (opts.suffix) |s| s else if (names.len > 1) names[1] else null;
        if (sfx) |s| result = core.stripSuffix(result, s);
        try out.print("{s}{s}", .{ result, eol });
    }
}
