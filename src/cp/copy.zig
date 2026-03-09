// AnmiTaliDev CoreUtils4Win - cp copy logic
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const Options = @import("options.zig").Options;

pub fn copy(src: []const u8, dest: []const u8, opts: Options, allocator: std.mem.Allocator) anyerror!void {
    const stat = try std.fs.cwd().statFile(src);

    if (stat.kind == .directory) {
        if (!opts.recursive) return error.OmittingDirectory;
        try copyDir(src, dest, opts, allocator);
        return;
    }

    if (opts.no_clobber) {
        std.fs.cwd().access(dest, .{}) catch {
            try copyFile(src, dest);
            if (opts.verbose) {
                std.fs.File.stdout().deprecatedWriter().print("'{s}' -> '{s}'\r\n", .{ src, dest }) catch {};
            }
            return;
        };
        return; // dest exists, skip
    }

    try copyFile(src, dest);
    if (opts.verbose) {
        std.fs.File.stdout().deprecatedWriter().print("'{s}' -> '{s}'\r\n", .{ src, dest }) catch {};
    }
}

fn copyFile(src: []const u8, dest: []const u8) !void {
    try std.fs.cwd().copyFile(src, std.fs.cwd(), dest, .{});
}

fn copyDir(src: []const u8, dest: []const u8, opts: Options, allocator: std.mem.Allocator) !void {
    std.fs.cwd().makeDir(dest) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    var dir = try std.fs.cwd().openDir(src, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const src_path = try std.fs.path.join(allocator, &.{ src, entry.name });
        defer allocator.free(src_path);
        const dest_path = try std.fs.path.join(allocator, &.{ dest, entry.name });
        defer allocator.free(dest_path);
        try copy(src_path, dest_path, opts, allocator);
    }
}
