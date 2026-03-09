// AnmiTaliDev CoreUtils4Win - ls
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const options_mod = @import("options.zig");
const entry_mod = @import("entry.zig");
const format_mod = @import("format.zig");

pub fn main() void {
    run() catch |err| {
        if (err == error.BrokenPipe) return;
        std.fs.File.stderr().deprecatedWriter().print("ls: {s}\r\n", .{@errorName(err)}) catch {};
        std.process.exit(1);
    };
}

fn run() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var opts = options_mod.Options{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "ls", "[OPTION]... [FILE]...");
            try w.writeAll(
                \\List information about the FILEs (the current directory by default).
                \\
                \\  -a, --all              do not ignore entries starting with .
                \\  -l                     use a long listing format
                \\  -h, --human-readable   with -l, print sizes in human readable format
                \\  -r, --reverse          reverse order while sorting
                \\  -R, --recursive        list subdirectories recursively
                \\  -1                     list one file per line
                \\  --sort=WORD            sort by WORD: none, name, size, time
                \\  --color=WHEN           colorize output: always, auto, never (default: auto)
                \\  --help                 display this help and exit
                \\  --version              output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "ls");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }

        if (std.mem.eql(u8, arg, "--all")           or std.mem.eql(u8, arg, "-a")) { opts.show_all = true; }
        else if (std.mem.eql(u8, arg, "-l"))          { opts.long_format = true; }
        else if (std.mem.eql(u8, arg, "--human-readable") or std.mem.eql(u8, arg, "-h")) { opts.human_readable = true; }
        else if (std.mem.eql(u8, arg, "--reverse")   or std.mem.eql(u8, arg, "-r")) { opts.reverse = true; }
        else if (std.mem.eql(u8, arg, "--recursive") or std.mem.eql(u8, arg, "-R")) { opts.recursive = true; }
        else if (std.mem.eql(u8, arg, "-1"))          { opts.one_per_line = true; }
        else if (std.mem.startsWith(u8, arg, "--sort=")) {
            const val = arg[7..];
            opts.sort = if (std.mem.eql(u8, val, "none")) .none
                else if (std.mem.eql(u8, val, "size")) .size
                else if (std.mem.eql(u8, val, "time")) .time
                else .name;
        } else if (std.mem.startsWith(u8, arg, "--color=")) {
            const val = arg[8..];
            opts.color = if (std.mem.eql(u8, val, "always")) .always
                else if (std.mem.eql(u8, val, "never")) .never
                else .auto;
        } else if (arg.len > 1 and arg[0] == '-' and arg[1] != '-') {
            for (arg[1..]) |c| switch (c) {
                'a' => opts.show_all = true,
                'l' => opts.long_format = true,
                'h' => opts.human_readable = true,
                'r' => opts.reverse = true,
                'R' => opts.recursive = true,
                '1' => opts.one_per_line = true,
                else => common.die("invalid option -- '{c}'", .{c}),
            };
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const paths = args[i..];
    const out = std.fs.File.stdout().deprecatedWriter();

    if (paths.len == 0) {
        try listDir(".", opts, allocator, out, 0);
    } else if (paths.len == 1) {
        try listDir(paths[0], opts, allocator, out, 0);
    } else {
        for (paths) |path| {
            try out.print("{s}:\r\n", .{path});
            try listDir(path, opts, allocator, out, 0);
            try out.writeAll("\r\n");
        }
    }
}

fn listDir(path: []const u8, opts: options_mod.Options, allocator: std.mem.Allocator, out: anytype, depth: usize) !void {
    var dir = std.fs.cwd().openDir(path, .{ .iterate = true }) catch |err| {
        std.fs.File.stderr().deprecatedWriter().print("ls: cannot open directory '{s}': {s}\r\n", .{ path, @errorName(err) }) catch {};
        return;
    };
    defer dir.close();

    const entries = try entry_mod.collect(dir, allocator, opts.show_all);
    defer entry_mod.freeEntries(entries, allocator);

    entry_mod.sortEntries(entries, opts.sort, opts.reverse);

    if (opts.long_format) {
        try format_mod.printLong(out, entries, opts);
    } else {
        try format_mod.printShort(out, entries, opts);
    }

    if (opts.recursive) {
        for (entries) |e| {
            if (e.kind != .directory) continue;
            const sub = try std.fs.path.join(allocator, &.{ path, e.name });
            defer allocator.free(sub);
            try out.print("\r\n{s}:\r\n", .{sub});
            try listDir(sub, opts, allocator, out, depth + 1);
        }
    }
}
