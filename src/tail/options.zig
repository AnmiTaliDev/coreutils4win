// AnmiTaliDev CoreUtils4Win - tail options
// Copyright (C) 2026 AnmiTaliDev

pub const Mode = union(enum) {
    lines: u64,
    bytes: u64,
};

pub const Options = struct {
    mode: Mode = .{ .lines = 10 },
    follow: bool = false,
    sleep_ns: u64 = 1_000_000_000,
};
