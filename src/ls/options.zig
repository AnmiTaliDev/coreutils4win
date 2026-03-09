// AnmiTaliDev CoreUtils4Win - ls options
// Copyright (C) 2026 AnmiTaliDev

pub const SortMode = enum { name, size, time, none };
pub const ColorMode = enum { always, auto, never };

pub const Options = struct {
    show_all: bool = false,
    long_format: bool = false,
    human_readable: bool = false,
    reverse: bool = false,
    recursive: bool = false,
    one_per_line: bool = false,
    sort: SortMode = .name,
    color: ColorMode = .auto,
};
