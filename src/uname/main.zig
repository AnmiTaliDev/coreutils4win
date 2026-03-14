// AnmiTaliDev CoreUtils4Win - uname
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const Options = @import("options.zig").Options;
const sysinfo = @import("sysinfo.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try common.argsAlloc(allocator);
    defer common.argsFree(allocator, args);

    var opts = Options{};
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "uname", "[OPTION]...");
            try w.writeAll(
                \\Print certain system information. With no OPTION, same as -s.
                \\
                \\  -a, --all                 print all information
                \\  -s, --kernel-name         print the kernel name
                \\  -n, --nodename            print the network node hostname
                \\  -r, --kernel-release      print the kernel release
                \\  -v, --kernel-version      print the kernel version
                \\  -m, --machine             print the machine hardware name
                \\  -p, --processor           print the processor type
                \\  -i, --hardware-platform   print the hardware platform
                \\  -o, --operating-system    print the operating system
                \\  --help                    display this help and exit
                \\  --version                 output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "uname");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--all")) { opts.all = true; }
        else if (std.mem.eql(u8, arg, "--kernel-name")     or std.mem.eql(u8, arg, "-s")) opts.kernel_name = true
        else if (std.mem.eql(u8, arg, "--nodename")        or std.mem.eql(u8, arg, "-n")) opts.nodename = true
        else if (std.mem.eql(u8, arg, "--kernel-release")  or std.mem.eql(u8, arg, "-r")) opts.kernel_release = true
        else if (std.mem.eql(u8, arg, "--kernel-version")  or std.mem.eql(u8, arg, "-v")) opts.kernel_version = true
        else if (std.mem.eql(u8, arg, "--machine")         or std.mem.eql(u8, arg, "-m")) opts.machine = true
        else if (std.mem.eql(u8, arg, "--processor")       or std.mem.eql(u8, arg, "-p")) opts.processor = true
        else if (std.mem.eql(u8, arg, "--hardware-platform") or std.mem.eql(u8, arg, "-i")) opts.hardware_platform = true
        else if (std.mem.eql(u8, arg, "--operating-system") or std.mem.eql(u8, arg, "-o")) opts.operating_system = true
        else if (arg.len > 1 and arg[0] == '-' and arg[1] != '-') {
            for (arg[1..]) |c| switch (c) {
                'a' => opts.all = true,
                's' => opts.kernel_name = true,
                'n' => opts.nodename = true,
                'r' => opts.kernel_release = true,
                'v' => opts.kernel_version = true,
                'm' => opts.machine = true,
                'p' => opts.processor = true,
                'i' => opts.hardware_platform = true,
                'o' => opts.operating_system = true,
                else => common.die("invalid option -- '{c}'", .{c}),
            };
        } else {
            common.die("invalid option -- '{s}'", .{arg});
        }
    }

    const any = opts.all or opts.kernel_name or opts.nodename or opts.kernel_release or
        opts.kernel_version or opts.machine or opts.processor or
        opts.hardware_platform or opts.operating_system;
    if (!any) opts.kernel_name = true;

    const info = try sysinfo.gather(allocator);
    defer sysinfo.free(info, allocator);

    const out = std.fs.File.stdout().deprecatedWriter();
    var first = true;

    const print_field = struct {
        fn f(w: anytype, val: []const u8, sep: *bool) !void {
            if (!sep.*) try w.writeByte(' ') else sep.* = false;
            try w.writeAll(val);
        }
    }.f;

    if (opts.all or opts.kernel_name)      try print_field(out, info.kernel_name, &first);
    if (opts.all or opts.nodename)         try print_field(out, info.nodename, &first);
    if (opts.all or opts.kernel_release)   try print_field(out, info.kernel_release, &first);
    if (opts.all or opts.kernel_version)   try print_field(out, info.kernel_version, &first);
    if (opts.all or opts.machine)          try print_field(out, info.machine, &first);
    if (opts.all or opts.processor)        try print_field(out, info.processor, &first);
    if (opts.all or opts.hardware_platform) try print_field(out, info.hardware_platform, &first);
    if (opts.all or opts.operating_system) try print_field(out, info.operating_system, &first);

    try out.writeAll("\r\n");
}
