// AnmiTaliDev CoreUtils4Win - rm removal logic
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const Options = @import("options.zig").Options;

pub fn remove(path: []const u8, opts: Options) !void {
    const stat = std.fs.cwd().statFile(path) catch |err| {
        if (opts.force and err == error.FileNotFound) return;
        return err;
    };

    if (stat.kind == .directory) {
        if (!opts.recursive) return error.IsDir;
        try std.fs.cwd().deleteTree(path);
    } else {
        try std.fs.cwd().deleteFile(path);
    }

    if (opts.verbose) {
        std.fs.File.stdout().deprecatedWriter().print("removed '{s}'\r\n", .{path}) catch {};
    }
}
