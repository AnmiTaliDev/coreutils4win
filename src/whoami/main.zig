// AnmiTaliDev CoreUtils4Win - whoami
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const windows = std.os.windows;

extern "advapi32" fn GetUserNameW(
    lpBuffer: [*:0]u16,
    pcbBuffer: *windows.DWORD,
) callconv(.winapi) windows.BOOL;

extern "advapi32" fn GetUserNameExW(
    NameFormat: u32,
    lpNameBuffer: [*:0]u16,
    nSize: *windows.ULONG,
) callconv(.winapi) windows.BOOL;

fn getUsername(allocator: std.mem.Allocator) ![]const u8 {
    var buf: [257:0]u16 = undefined;
    var size: windows.DWORD = 257;
    if (GetUserNameW(&buf, &size) == 0) {
        // Fallback to environment variable
        return std.process.getEnvVarOwned(allocator, "USERNAME") catch
            allocator.dupe(u8, "unknown");
    }
    const name_w = buf[0 .. size - 1]; // size includes null terminator
    return std.unicode.utf16LeToUtf8Alloc(allocator, name_w);
}

fn getDomain(allocator: std.mem.Allocator) ![]const u8 {
    return std.process.getEnvVarOwned(allocator, "USERDOMAIN") catch
        allocator.dupe(u8, ".");
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try common.argsAlloc(allocator);
    defer common.argsFree(allocator, args);

    var opts = Options{};

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "whoami", "[OPTION]...");
            try w.writeAll(
                \\Print the user name associated with the current effective user ID.
                \\
                \\  -v, --verbose   display additional information (domain\user)
                \\  --help          display this help and exit
                \\  --version       output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "whoami");
            return;
        }
        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        }
    }

    const out = std.fs.File.stdout().deprecatedWriter();

    if (opts.verbose) {
        const domain = try getDomain(allocator);
        defer allocator.free(domain);
        const username = try getUsername(allocator);
        defer allocator.free(username);
        try out.print("{s}\\{s}\r\n", .{ domain, username });
    } else {
        const username = try getUsername(allocator);
        defer allocator.free(username);
        try out.print("{s}\r\n", .{username});
    }
}
