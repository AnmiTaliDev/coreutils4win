// AnmiTaliDev CoreUtils4Win - touch
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const windows = std.os.windows;

const FILETIME = extern struct {
    dwLowDateTime: windows.DWORD,
    dwHighDateTime: windows.DWORD,
};

extern "kernel32" fn SetFileTime(
    hFile: windows.HANDLE,
    lpCreationTime: ?*const FILETIME,
    lpLastAccessTime: ?*const FILETIME,
    lpLastWriteTime: ?*const FILETIME,
) callconv(.winapi) windows.BOOL;

extern "kernel32" fn GetSystemTimeAsFileTime(
    lpSystemTimeAsFileTime: *FILETIME,
) callconv(.winapi) void;

fn touchFile(path: []const u8, opts: Options) !void {
    const file = std.fs.cwd().openFile(path, .{ .mode = .read_write }) catch |err| switch (err) {
        error.FileNotFound => {
            if (opts.no_create) return;
            _ = try std.fs.cwd().createFile(path, .{});
            return;
        },
        else => return err,
    };
    defer file.close();

    var now: FILETIME = undefined;
    GetSystemTimeAsFileTime(&now);

    const atime: ?*const FILETIME = if (!opts.modify_only) &now else null;
    const mtime: ?*const FILETIME = if (!opts.access_only) &now else null;

    const handle = file.handle;
    if (SetFileTime(handle, null, atime, mtime) == 0) {
        return error.SetTimeFailed;
    }
}

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
            try common.printUsageHeader(w, "touch", "[OPTION]... FILE...");
            try w.writeAll(
                \\Update the access and modification times of each FILE to the current time.
                \\A FILE that does not exist is created empty, unless -c is supplied.
                \\
                \\  -a            change only the access time
                \\  -c, --no-create  do not create any files
                \\  -m            change only the modification time
                \\  --help        display this help and exit
                \\  --version     output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "touch");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--no-create")) {
            opts.no_create = true;
        } else if (std.mem.eql(u8, arg, "-a")) {
            opts.access_only = true;
        } else if (std.mem.eql(u8, arg, "-m")) {
            opts.modify_only = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    const files = args[i..];
    if (files.len == 0) common.dieMsg("missing file operand");

    for (files) |path| {
        touchFile(path, opts) catch |err| {
            try std.fs.File.stderr().deprecatedWriter().print("touch: {s}: {s}\r\n", .{ path, @errorName(err) });
        };
    }
}
