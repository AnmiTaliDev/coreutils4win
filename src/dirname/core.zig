// AnmiTaliDev CoreUtils4Win - dirname core logic
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");

fn isSep(c: u8) bool {
    return c == '/' or c == '\\';
}

pub fn dirname(path: []const u8) []const u8 {
    var p = path;

    // Strip trailing separators
    while (p.len > 1 and isSep(p[p.len - 1])) {
        p = p[0 .. p.len - 1];
    }

    // Check for drive root like C:\ or C:/
    if (p.len >= 2 and p[1] == ':') {
        if (p.len == 2) return p; // "C:" => "C:"
        // Find last separator after drive letter
        var i: usize = p.len;
        while (i > 2) {
            i -= 1;
            if (isSep(p[i])) {
                if (i == 2) return p[0..3]; // "C:\file" => "C:\"
                return p[0..i];
            }
        }
        return p[0..2]; // "C:file" => "C:"
    }

    // Find last separator
    var i: usize = p.len;
    while (i > 0) {
        i -= 1;
        if (isSep(p[i])) {
            if (i == 0) return "/";
            // Strip trailing separators from dirname part
            var end = i;
            while (end > 1 and isSep(p[end - 1])) end -= 1;
            if (end == 0) return "/";
            return p[0..end];
        }
    }
    return ".";
}

test "dirname: forward slash" {
    try std.testing.expectEqualStrings("/path/to", dirname("/path/to/file.txt"));
}

test "dirname: backslash" {
    try std.testing.expectEqualStrings("C:\\Users", dirname("C:\\Users\\file.txt"));
}

test "dirname: drive root" {
    try std.testing.expectEqualStrings("C:\\", dirname("C:\\file.txt"));
}

test "dirname: no separator" {
    try std.testing.expectEqualStrings(".", dirname("file.txt"));
}

test "dirname: trailing backslash" {
    try std.testing.expectEqualStrings("C:\\path", dirname("C:\\path\\dir\\"));
}
