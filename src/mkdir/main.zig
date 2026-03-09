// AnmiTaliDev CoreUtils4Win - mkdir
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;

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
            try common.printUsageHeader(w, "mkdir", "[OPTION]... DIRECTORY...");
            try w.writeAll(
                \\Create the DIRECTORY(ies), if they do not already exist.
                \\
                \\  -p, --parents   no error if existing, make parent directories as needed
                \\  -v, --verbose   print a message for each created directory
                \\  --help          display this help and exit
                \\  --version       output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "mkdir");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--parents")) {
            opts.parents = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const dirs = args[i..];
    if (dirs.len == 0) common.dieMsg("missing operand");

    for (dirs) |dir| {
        if (opts.parents) {
            std.fs.cwd().makePath(dir) catch |err| {
                try std.fs.File.stderr().deprecatedWriter().print("mkdir: cannot create directory '{s}': {s}\r\n", .{ dir, @errorName(err) });
                continue;
            };
        } else {
            std.fs.cwd().makeDir(dir) catch |err| {
                try std.fs.File.stderr().deprecatedWriter().print("mkdir: cannot create directory '{s}': {s}\r\n", .{ dir, @errorName(err) });
                continue;
            };
        }
        if (opts.verbose) {
            try std.fs.File.stdout().deprecatedWriter().print("mkdir: created directory '{s}'\r\n", .{dir});
        }
    }
}
