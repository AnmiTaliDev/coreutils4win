// AnmiTaliDev CoreUtils4Win - ls directory entries
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const SortMode = @import("options.zig").SortMode;

pub const Entry = struct {
    name: []const u8,
    kind: std.fs.File.Kind,
    size: u64,
    mtime: i128,
    attrs: u32,
};

pub fn collect(dir: std.fs.Dir, allocator: std.mem.Allocator, show_all: bool) ![]Entry {
    var entries = std.ArrayList(Entry){};
    var it = dir.iterate();
    while (try it.next()) |item| {
        if (!show_all and item.name.len > 0 and item.name[0] == '.') continue;

        const stat = dir.statFile(item.name) catch continue;
        const name = try allocator.dupe(u8, item.name);

        try entries.append(allocator, .{
            .name  = name,
            .kind  = item.kind,
            .size  = stat.size,
            .mtime = stat.mtime,
            .attrs = 0,
        });
    }
    return entries.toOwnedSlice(allocator);
}

pub fn freeEntries(entries: []Entry, allocator: std.mem.Allocator) void {
    for (entries) |e| allocator.free(e.name);
    allocator.free(entries);
}

pub fn sortEntries(entries: []Entry, mode: SortMode, reverse: bool) void {
    const Ctx = struct {
        mode: SortMode,
        pub fn lessThan(ctx: @This(), a: Entry, b: Entry) bool {
            return switch (ctx.mode) {
                .name => std.mem.lessThan(u8, a.name, b.name),
                .size => a.size < b.size,
                .time => a.mtime < b.mtime,
                .none => false,
            };
        }
    };
    std.sort.pdq(Entry, entries, Ctx{ .mode = mode }, Ctx.lessThan);
    if (reverse) std.mem.reverse(Entry, entries);
}
