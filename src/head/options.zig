// AnmiTaliDev CoreUtils4Win - head options
// Copyright (C) 2026 AnmiTaliDev

pub const Mode = union(enum) {
    lines: u64,
    bytes: u64,
};

pub const Options = struct {
    mode: Mode = .{ .lines = 10 },
    verbose: bool = false,
    quiet: bool = false,
};
