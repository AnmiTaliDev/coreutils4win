// AnmiTaliDev CoreUtils4Win - cp
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const copy_mod = @import("copy.zig");

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
            try common.printUsageHeader(w, "cp", "[OPTION]... SOURCE DEST or: cp [OPTION]... SOURCE... DIRECTORY");
            try w.writeAll(
                \\Copy SOURCE to DEST, or multiple SOURCEs to DIRECTORY.
                \\
                \\  -f, --force       if an existing destination cannot be opened, remove and retry
                \\  -n, --no-clobber  do not overwrite an existing file
                \\  -r, -R, --recursive  copy directories recursively
                \\  -v, --verbose     explain what is being done
                \\  --help            display this help and exit
                \\  --version         output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "cp");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            opts.force = true;
        } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--no-clobber")) {
            opts.no_clobber = true;
        } else if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "-R") or std.mem.eql(u8, arg, "--recursive")) {
            opts.recursive = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (arg.len > 1 and arg[0] == '-' and arg[1] != '-') {
            for (arg[1..]) |c| switch (c) {
                'f' => opts.force = true,
                'n' => opts.no_clobber = true,
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

    const operands = args[i..];
    if (operands.len < 2) common.dieMsg("missing file operand");

    const dest = operands[operands.len - 1];
    const sources = operands[0 .. operands.len - 1];

    const dest_is_dir = blk: {
        const stat = std.fs.cwd().statFile(dest) catch break :blk false;
        break :blk stat.kind == .directory;
    };

    if (sources.len > 1 and !dest_is_dir) {
        common.die("target '{s}' is not a directory", .{dest});
    }

    for (sources) |src| {
        const dest_path: []const u8 = blk: {
            if (dest_is_dir) {
                const base = std.fs.path.basename(src);
                break :blk try std.fs.path.join(allocator, &.{ dest, base });
            }
            break :blk dest;
        };
        defer if (dest_is_dir) allocator.free(dest_path);

        copy_mod.copy(src, dest_path, opts, allocator) catch |err| {
            try std.fs.File.stderr().deprecatedWriter().print("cp: {s}: {s}\r\n", .{ src, @errorName(err) });
        };
    }
}
