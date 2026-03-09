// AnmiTaliDev CoreUtils4Win - rm
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const remove_mod = @import("remove.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
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
            try common.printUsageHeader(w, "rm", "[OPTION]... [FILE]...");
            try w.writeAll(
                \\Remove (unlink) the FILE(s).
                \\
                \\  -f, --force      ignore nonexistent files, never prompt
                \\  -r, -R, --recursive  remove directories and their contents recursively
                \\  -v, --verbose    explain what is being done
                \\  --help           display this help and exit
                \\  --version        output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "rm");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            opts.force = true;
        } else if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "-R") or std.mem.eql(u8, arg, "--recursive")) {
            opts.recursive = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (arg.len > 1 and arg[0] == '-' and arg[1] != '-') {
            for (arg[1..]) |c| switch (c) {
                'f' => opts.force = true,
                'r', 'R' => opts.recursive = true,
                'v' => opts.verbose = true,
                else => common.die("invalid option -- '{c}'", .{c}),
            };
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const files = args[i..];
    if (files.len == 0 and !opts.force) common.dieMsg("missing operand");

    for (files) |path| {
        remove_mod.remove(path, opts) catch |err| {
            if (opts.force and err == error.FileNotFound) continue;
            try std.fs.File.stderr().deprecatedWriter().print("rm: cannot remove '{s}': {s}\r\n", .{ path, @errorName(err) });
        };
    }
}
