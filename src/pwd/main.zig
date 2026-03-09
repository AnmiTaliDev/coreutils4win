// AnmiTaliDev CoreUtils4Win - pwd
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "pwd", "[OPTION]...");
            try w.writeAll(
                \\Print the full filename of the current working directory.
                \\
                \\  -L, --logical   use PWD from environment (default)
                \\  -P, --physical  avoid all symlinks
                \\  --help          display this help and exit
                \\  --version       output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "pwd");
            return;
        }
    }

    const cwd = try std.process.getCwdAlloc(allocator);
    defer allocator.free(cwd);

    const out = std.fs.File.stdout().deprecatedWriter();
    try out.print("{s}\r\n", .{cwd});
}
