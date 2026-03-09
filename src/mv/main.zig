// AnmiTaliDev CoreUtils4Win - mv
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
            try common.printUsageHeader(w, "mv", "[OPTION]... SOURCE DEST or: mv [OPTION]... SOURCE... DIRECTORY");
            try w.writeAll(
                \\Rename SOURCE to DEST, or move SOURCE(s) to DIRECTORY.
                \\
                \\  -f, --force        do not prompt before overwriting
                \\  -n, --no-clobber   do not overwrite an existing file
                \\  -v, --verbose      explain what is being done
                \\  --help             display this help and exit
                \\  --version          output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "mv");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--force")) {
            opts.force = true;
        } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--no-clobber")) {
            opts.no_clobber = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
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
                const joined = try std.fs.path.join(allocator, &.{ dest, base });
                break :blk joined;
            }
            break :blk dest;
        };
        defer if (dest_is_dir) allocator.free(dest_path);

        if (opts.no_clobber) {
            const exists = blk: {
                std.fs.cwd().access(dest_path, .{}) catch break :blk false;
                break :blk true;
            };
            if (exists) continue;
        }

        std.fs.cwd().rename(src, dest_path) catch |err| {
            try std.fs.File.stderr().deprecatedWriter().print("mv: cannot move '{s}' to '{s}': {s}\r\n", .{ src, dest_path, @errorName(err) });
            continue;
        };
        if (opts.verbose) {
            try std.fs.File.stdout().deprecatedWriter().print("renamed '{s}' -> '{s}'\r\n", .{ src, dest_path });
        }
    }
}
