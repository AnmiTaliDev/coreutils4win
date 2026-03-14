// AnmiTaliDev CoreUtils4Win - dirname
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");
const common = @import("common");
const core = @import("core.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try common.argsAlloc(allocator);
    defer common.argsFree(allocator, args);

    var zero = false;
    var i: usize = 1;

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "--help")) {
            const w = std.fs.File.stdout().deprecatedWriter();
            try common.printUsageHeader(w, "dirname", "[OPTION] NAME...");
            try w.writeAll(
                \\Output each NAME with its last non-slash component and trailing slashes removed.
                \\
                \\  -z, --zero  end each output line with NUL, not newline
                \\  --help      display this help and exit
                \\  --version   output version information and exit
                \\
            );
            return;
        }
        if (std.mem.eql(u8, arg, "--version")) {
            try common.printVersion(std.fs.File.stdout().deprecatedWriter(), "dirname");
            return;
        }
        if (std.mem.eql(u8, arg, "--")) { i += 1; break; }
        if (std.mem.eql(u8, arg, "-z") or std.mem.eql(u8, arg, "--zero")) {
            zero = true;
        } else if (arg.len > 0 and arg[0] == '-') {
            common.die("invalid option -- '{s}'", .{arg});
        } else {
            break;
        }
    }

    if (i >= args.len) common.dieMsg("missing operand");

    const out = std.fs.File.stdout().deprecatedWriter();
    const eol: []const u8 = if (zero) "\x00" else "\r\n";

    for (args[i..]) |name| {
        try out.print("{s}{s}", .{ core.dirname(name), eol });
    }
}
