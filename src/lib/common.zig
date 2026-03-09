// AnmiTaliDev CoreUtils4Win - common helpers
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");

pub const version = "1.0.0";

pub fn printVersion(writer: anytype, name: []const u8) !void {
    try writer.print("{s} (AnmiTaliDev CoreUtils4Win) {s}\n", .{ name, version });
    try writer.writeAll("Copyright (C) 2026 AnmiTaliDev\n");
    try writer.writeAll("Licensed under the Apache License, Version 2.0\n");
}

pub fn printUsageHeader(writer: anytype, name: []const u8, synopsis: []const u8) !void {
    try writer.print("Usage: {s} {s}\n\n", .{ name, synopsis });
}

pub fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.fs.File.stderr().deprecatedWriter().print(fmt ++ "\n", args) catch {};
    std.process.exit(1);
}

pub fn dieMsg(msg: []const u8) noreturn {
    std.fs.File.stderr().deprecatedWriter().print("{s}\n", .{msg}) catch {};
    std.process.exit(1);
}
