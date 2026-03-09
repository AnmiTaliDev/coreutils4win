// AnmiTaliDev CoreUtils4Win - basename core logic
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");

fn isSep(c: u8) bool {
    return c == '/' or c == '\\';
}

pub fn basename(path: []const u8) []const u8 {
    var p = path;

    // Strip trailing separators (keep at least one char)
    while (p.len > 1 and isSep(p[p.len - 1])) {
        p = p[0 .. p.len - 1];
    }

    // Root paths: / or X:\ or X:/
    if (p.len == 1 and isSep(p[0])) return p;
    if (p.len == 3 and p[1] == ':' and isSep(p[2])) return p;

    // Find last separator
    var i: usize = p.len;
    while (i > 0) {
        i -= 1;
        if (isSep(p[i])) return p[i + 1 ..];
    }
    return p;
}

pub fn stripSuffix(name: []const u8, suffix: []const u8) []const u8 {
    if (suffix.len == 0 or suffix.len >= name.len) return name;
    if (std.mem.endsWith(u8, name, suffix)) {
        return name[0 .. name.len - suffix.len];
    }
    return name;
}

test "basename: forward slash" {
    try std.testing.expectEqualStrings("file.txt", basename("/path/to/file.txt"));
}

test "basename: backslash" {
    try std.testing.expectEqualStrings("file.txt", basename("C:\\Users\\user\\file.txt"));
}

test "basename: no separator" {
    try std.testing.expectEqualStrings("file.txt", basename("file.txt"));
}

test "basename: drive root" {
    try std.testing.expectEqualStrings("C:\\", basename("C:\\"));
}

test "basename: trailing backslash" {
    try std.testing.expectEqualStrings("dir", basename("C:\\path\\dir\\"));
}

test "stripSuffix: matching" {
    try std.testing.expectEqualStrings("file", stripSuffix("file.txt", ".txt"));
}

test "stripSuffix: non-matching" {
    try std.testing.expectEqualStrings("file.txt", stripSuffix("file.txt", ".gz"));
}
