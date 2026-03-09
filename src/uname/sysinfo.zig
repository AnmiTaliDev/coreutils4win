// AnmiTaliDev CoreUtils4Win - uname system info (Windows)
// Copyright (C) 2026 AnmiTaliDev

const std = @import("std");
const windows = std.os.windows;

pub const SysInfo = struct {
    kernel_name: []const u8,
    nodename: []const u8,
    kernel_release: []const u8,
    kernel_version: []const u8,
    machine: []const u8,
    processor: []const u8,
    hardware_platform: []const u8,
    operating_system: []const u8,
};

const RTL_OSVERSIONINFOEXW = extern struct {
    dwOSVersionInfoSize: windows.ULONG = @sizeOf(RTL_OSVERSIONINFOEXW),
    dwMajorVersion: windows.ULONG = 0,
    dwMinorVersion: windows.ULONG = 0,
    dwBuildNumber: windows.ULONG = 0,
    dwPlatformId: windows.ULONG = 0,
    szCSDVersion: [128]u16 = [_]u16{0} ** 128,
    wServicePackMajor: windows.USHORT = 0,
    wServicePackMinor: windows.USHORT = 0,
    wSuiteMask: windows.USHORT = 0,
    wProductType: windows.UCHAR = 0,
    wReserved: windows.UCHAR = 0,
};

const SYSTEM_INFO = extern struct {
    wProcessorArchitecture: windows.WORD,
    wReserved: windows.WORD,
    dwPageSize: windows.DWORD,
    lpMinimumApplicationAddress: *anyopaque,
    lpMaximumApplicationAddress: *anyopaque,
    dwActiveProcessorMask: windows.ULONG_PTR,
    dwNumberOfProcessors: windows.DWORD,
    dwProcessorType: windows.DWORD,
    dwAllocationGranularity: windows.DWORD,
    wProcessorLevel: windows.WORD,
    wProcessorRevision: windows.WORD,
};

const ComputerNameFormat = enum(u32) {
    NetBIOS = 0,
    DnsHostname = 1,
    DnsDomain = 2,
    DnsFullyQualified = 3,
    PhysicalNetBIOS = 4,
    PhysicalDnsHostname = 5,
    PhysicalDnsDomain = 6,
    PhysicalDnsFullyQualified = 7,
};

extern "ntdll" fn RtlGetVersion(
    lpVersionInformation: *RTL_OSVERSIONINFOEXW,
) callconv(.winapi) windows.NTSTATUS;

extern "kernel32" fn GetComputerNameExW(
    NameType: ComputerNameFormat,
    lpBuffer: ?[*:0]u16,
    nSize: *windows.DWORD,
) callconv(.winapi) windows.BOOL;

extern "kernel32" fn GetNativeSystemInfo(
    lpSystemInfo: *SYSTEM_INFO,
) callconv(.winapi) void;

fn getComputerName(allocator: std.mem.Allocator) ![]const u8 {
    var size: windows.DWORD = 0;
    _ = GetComputerNameExW(.DnsHostname, null, &size);

    const buf = try allocator.alloc(u16, size);
    defer allocator.free(buf);

    const buf_ptr: [*:0]u16 = @ptrCast(buf.ptr);
    if (GetComputerNameExW(.DnsHostname, buf_ptr, &size) == 0) {
        return std.process.getEnvVarOwned(allocator, "COMPUTERNAME") catch
            allocator.dupe(u8, "unknown");
    }
    return std.unicode.utf16LeToUtf8Alloc(allocator, buf[0..size]);
}

fn getMachineArch(si: *const SYSTEM_INFO) []const u8 {
    return switch (si.wProcessorArchitecture) {
        9  => "x86_64",
        5  => "arm",
        12 => "aarch64",
        6  => "ia64",
        0  => "x86",
        else => "unknown",
    };
}

pub fn gather(allocator: std.mem.Allocator) !SysInfo {
    var osvi = RTL_OSVERSIONINFOEXW{};
    _ = RtlGetVersion(&osvi);

    var si = std.mem.zeroes(SYSTEM_INFO);
    GetNativeSystemInfo(&si);

    const nodename = try getComputerName(allocator);
    const machine   = try allocator.dupe(u8, getMachineArch(&si));
    const kernel_name = try allocator.dupe(u8, "Windows");
    const operating_system = try allocator.dupe(u8, "Windows_NT");

    const release = try std.fmt.allocPrint(allocator, "{d}.{d}.{d}", .{
        osvi.dwMajorVersion, osvi.dwMinorVersion, osvi.dwBuildNumber,
    });

    const sp_w = std.mem.sliceTo(&osvi.szCSDVersion, 0);
    const sp = if (sp_w.len > 0) sp_w else &[_]u16{};
    const kernel_version: []const u8 = if (sp.len > 0)
        try std.unicode.utf16LeToUtf8Alloc(allocator, sp)
    else
        try std.fmt.allocPrint(allocator, "Build {d}", .{osvi.dwBuildNumber});

    return SysInfo{
        .kernel_name      = kernel_name,
        .nodename         = nodename,
        .kernel_release   = release,
        .kernel_version   = kernel_version,
        .machine          = machine,
        .processor        = try allocator.dupe(u8, getMachineArch(&si)),
        .hardware_platform = try allocator.dupe(u8, getMachineArch(&si)),
        .operating_system = operating_system,
    };
}

pub fn free(info: SysInfo, allocator: std.mem.Allocator) void {
    allocator.free(info.kernel_name);
    allocator.free(info.nodename);
    allocator.free(info.kernel_release);
    allocator.free(info.kernel_version);
    allocator.free(info.machine);
    allocator.free(info.processor);
    allocator.free(info.hardware_platform);
    allocator.free(info.operating_system);
}
