// AnmiTaliDev CoreUtils4Win - cat
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const processor = @import("processor.zig");

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
            try common.printUsageHeader(w, "cat", "[OPTION]... [FILE]...");
            try w.writeAll(
                \\Concatenate FILE(s) to standard output.
                \\With no FILE, or when FILE is -, read standard input.
                \\
                \\  -A, --show-all           equivalent to -vET
                \\  -b, --number-nonblank    number nonempty output lines
                \\  -e                       equivalent to -vE
                \\  -E, --show-ends          display $ at end of each line
                \\  -n, --number             number all output lines
                \\  -s, --squeeze-blank      suppress repeated empty output lines
                \\  -t                       equivalent to -vT
                \\  -T, --show-tabs          display TAB characters as ^I
                \\  -v, --show-nonprinting   use ^ and M- notation
                \\  --help                   display this help and exit
                \\  --version                output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "cat");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "--show-all")          or std.mem.eql(u8, arg, "-A")) { opts.show_nonprinting = true; opts.show_ends = true; opts.show_tabs = true; }
        else if (std.mem.eql(u8, arg, "--number-nonblank") or std.mem.eql(u8, arg, "-b")) opts.number_nonblank = true
        else if (std.mem.eql(u8, arg, "--show-ends")    or std.mem.eql(u8, arg, "-E")) opts.show_ends = true
        else if (std.mem.eql(u8, arg, "--number")       or std.mem.eql(u8, arg, "-n")) opts.number = true
        else if (std.mem.eql(u8, arg, "--squeeze-blank") or std.mem.eql(u8, arg, "-s")) opts.squeeze_blank = true
        else if (std.mem.eql(u8, arg, "--show-tabs")    or std.mem.eql(u8, arg, "-T")) opts.show_tabs = true
        else if (std.mem.eql(u8, arg, "--show-nonprinting") or std.mem.eql(u8, arg, "-v")) opts.show_nonprinting = true
        else if (std.mem.eql(u8, arg, "-e")) { opts.show_nonprinting = true; opts.show_ends = true; }
        else if (std.mem.eql(u8, arg, "-t")) { opts.show_nonprinting = true; opts.show_tabs = true; }
        else if (arg.len > 0 and arg[0] == '-' and arg.len > 1) {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const out = std.fs.File.stdout().deprecatedWriter();
    const stdin = std.fs.File.stdin();
    var line_num: u64 = 0;

    const files = args[i..];
    if (files.len == 0) {
        try processor.process(stdin.deprecatedReader(), out, opts, &line_num);
    } else {
        for (files) |path| {
            if (std.mem.eql(u8, path, "-")) {
                try processor.process(stdin.deprecatedReader(), out, opts, &line_num);
            } else {
                const file = std.fs.cwd().openFile(path, .{}) catch |err| {
                    try std.fs.File.stderr().deprecatedWriter().print("cat: {s}: {s}\r\n", .{ path, @errorName(err) });
                    continue;
                };
                defer file.close();
                try processor.process(file.deprecatedReader(), out, opts, &line_num);
            }
        }
    }
}
