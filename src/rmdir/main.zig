// AnmiTaliDev CoreUtils4Win - rmdir
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
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "rmdir", "[OPTION]... DIRECTORY...");
            try w.writeAll(
                \\Remove the DIRECTORY(ies), if they are empty.
                \\
                \\  --ignore-fail-on-non-empty  ignore failures due to non-empty directories
                \\  -p, --parents               remove directory and its ancestors
                \\  -v, --verbose               output a diagnostic for every directory processed
                \\  --help                      display this help and exit
                \\  --version                   output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "rmdir");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--parents")) {
            opts.parents = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (std.mem.eql(u8, arg, "--ignore-fail-on-non-empty")) {
            opts.ignore_fail_on_non_empty = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const dirs = args[i..];
    if (dirs.len == 0) common.dieMsg("missing operand");

    for (dirs) |dir| {
        std.fs.cwd().deleteDir(dir) catch |err| {
            if (opts.ignore_fail_on_non_empty and err == error.DirNotEmpty) continue;
            try std.fs.File.stderr().deprecatedWriter().print("rmdir: failed to remove '{s}': {s}\r\n", .{ dir, @errorName(err) });
            continue;
        };
        if (opts.verbose) {
            try std.fs.File.stdout().deprecatedWriter().print("rmdir: removing directory, '{s}'\r\n", .{dir});
        }
    }
}
