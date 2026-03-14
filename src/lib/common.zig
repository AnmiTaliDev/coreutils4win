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

pub fn argsAlloc(allocator: std.mem.Allocator) ![][]u8 {
    var list: std.ArrayListUnmanaged([]u8) = .{};
    errdefer {
        for (list.items) |a| allocator.free(a);
        list.deinit(allocator);
    }
    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();
    while (iter.next()) |arg| {
        try list.append(allocator, try allocator.dupe(u8, arg));
    }
    return list.toOwnedSlice(allocator);
}

pub fn argsFree(allocator: std.mem.Allocator, args_slice: [][]u8) void {
    for (args_slice) |a| allocator.free(a);
    allocator.free(args_slice);
}
