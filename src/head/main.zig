// AnmiTaliDev CoreUtils4Win - head
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const reader_mod = @import("reader.zig");

pub fn main() void {
    run() catch |err| {
        if (err == error.BrokenPipe) return;
        std.fs.File.stderr().deprecatedWriter().print("head: {s}\r\n", .{@errorName(err)}) catch {};
        std.process.exit(1);
    };
}

fn run() !void {
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
            try common.printUsageHeader(w, "head", "[OPTION]... [FILE]...");
            try w.writeAll(
                \\Print the first 10 lines of each FILE to standard output.
                \\
                \\  -c, --bytes=NUM   print the first NUM bytes
                \\  -n, --lines=NUM   print the first NUM lines (default: 10)
                \\  -q, --quiet       never print headers giving file names
                \\  -v, --verbose     always print headers giving file names
                \\  --help            display this help and exit
                \\  --version         output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "head");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-q") or std.mem.eql(u8, arg, "--quiet") or std.mem.eql(u8, arg, "--silent")) {
            opts.quiet = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (std.mem.startsWith(u8, arg, "--lines=")) {
            opts.mode = .{ .lines = std.fmt.parseInt(u64, arg[8..], 10) catch common.die("invalid line count: '{s}'", .{arg[8..]}) };
        } else if (std.mem.startsWith(u8, arg, "--bytes=")) {
            opts.mode = .{ .bytes = std.fmt.parseInt(u64, arg[8..], 10) catch common.die("invalid byte count: '{s}'", .{arg[8..]}) };
        } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "-c")) {
            const flag = arg;
            i += 1;
            if (i >= args.len) common.die("option requires an argument -- '{s}'", .{flag});
            const n = std.fmt.parseInt(u64, args[i], 10) catch common.die("invalid count: '{s}'", .{args[i]});
            if (flag[1] == 'n') { opts.mode = .{ .lines = n }; } else { opts.mode = .{ .bytes = n }; }
        } else if (arg.len > 1 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const out = std.fs.File.stdout().deprecatedWriter();
    const files = args[i..];

    if (files.len == 0) {
        try reader_mod.readHead(std.fs.File.stdin().deprecatedReader(), out, opts.mode);
    } else {
        for (files, 0..) |path, fi| {
            const show_header = opts.verbose or (files.len > 1 and !opts.quiet);
            if (show_header) {
                if (fi > 0) try out.writeAll("\r\n");
                try out.print("==> {s} <==\r\n", .{path});
            }
            if (std.mem.eql(u8, path, "-")) {
                try reader_mod.readHead(std.fs.File.stdin().deprecatedReader(), out, opts.mode);
            } else {
                const file = std.fs.cwd().openFile(path, .{}) catch |err| {
                    try std.fs.File.stderr().deprecatedWriter().print("head: {s}: {s}\r\n", .{ path, @errorName(err) });
                    continue;
                };
                defer file.close();
                try reader_mod.readHead(file.deprecatedReader(), out, opts.mode);
            }
        }
    }
}
