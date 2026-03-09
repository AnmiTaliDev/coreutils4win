// AnmiTaliDev CoreUtils4Win - build
// Copyright (C) 2026 AnmiTaliDev
// Licensed under the Apache License, Version 2.0

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .abi = .gnu,
    });
    const optimize = b.standardOptimizeOption(.{});

    const utils = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "basename", .path = "src/basename/main.zig" },
        .{ .name = "cat",      .path = "src/cat/main.zig" },
        .{ .name = "cp",       .path = "src/cp/main.zig" },
        .{ .name = "dirname",  .path = "src/dirname/main.zig" },
        .{ .name = "echo",     .path = "src/echo/main.zig" },
        .{ .name = "head",     .path = "src/head/main.zig" },
        .{ .name = "ls",       .path = "src/ls/main.zig" },
        .{ .name = "mkdir",    .path = "src/mkdir/main.zig" },
        .{ .name = "mv",       .path = "src/mv/main.zig" },
        .{ .name = "pwd",      .path = "src/pwd/main.zig" },
        .{ .name = "rm",       .path = "src/rm/main.zig" },
        .{ .name = "rmdir",    .path = "src/rmdir/main.zig" },
        .{ .name = "tail",     .path = "src/tail/main.zig" },
        .{ .name = "touch",    .path = "src/touch/main.zig" },
        .{ .name = "true",     .path = "src/true/main.zig" },
        .{ .name = "false",    .path = "src/false/main.zig" },
        .{ .name = "uname",    .path = "src/uname/main.zig" },
        .{ .name = "whoami",   .path = "src/whoami/main.zig" },
    };

    const common_mod = b.createModule(.{
        .root_source_file = b.path("src/lib/common.zig"),
        .target = target,
        .optimize = optimize,
    });

    for (utils) |u| {
        const mod = b.createModule(.{
            .root_source_file = b.path(u.path),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "common", .module = common_mod },
            },
        });
        const exe = b.addExecutable(.{
            .name = u.name,
            .root_module = mod,
        });
        b.installArtifact(exe);

        const run_step = b.step(u.name, b.fmt("Build {s}.exe", .{u.name}));
        run_step.dependOn(&exe.step);
    }

    const test_sources = [_]struct { name: []const u8, path: []const u8 }{
        .{ .name = "basename", .path = "src/basename/core.zig" },
        .{ .name = "dirname",  .path = "src/dirname/core.zig" },
    };

    const test_target = b.standardTargetOptions(.{});
    const test_step = b.step("test", "Run unit tests (native)");
    for (test_sources) |ts| {
        const mod = b.createModule(.{
            .root_source_file = b.path(ts.path),
            .target = test_target,
            .optimize = optimize,
        });
        const unit_test = b.addTest(.{ .name = ts.name, .root_module = mod });
        const run_test = b.addRunArtifact(unit_test);
        test_step.dependOn(&run_test.step);
    }
}
