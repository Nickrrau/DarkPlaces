const std = @import("std");
const builtin = @import("builtin");
const c = @cImport({
    @cInclude("darkplaces.h");
    @cInclude("time.h");
    @cInclude("sys.h");
});

pub const sys_t = extern struct {
    argc: c_int,
    argv: [*c][*c]const u8,
    selffd: c_int,
    outfd: c_int,
    nicelevel: c_int,
    nicepossible: bool,
    isnice: bool,
};
pub export var sys: sys_t = undefined;

// static cvar_t sys_stdout = {CF_SHARED, "sys_stdout", "1", "0: nothing is written to stdout (-nostdout cmdline option sets this), 1: normal messages are written to stdout, 2: normal messages are written to stderr (-stderr cmdline option sets this)"};
pub export var sys_stdout = .{};

var sys_timestring: [128]u8 = [_]u8{0} ** 128;
pub export fn Sys_TimeString(timeformat: [*c]const u8) [*c]u8 {
    const mytime = c.time(null);
    _ = c.strftime(&sys_timestring, sys_timestring.len, timeformat, c.localtime(&mytime));
    return @as([*c]u8, @ptrCast(@alignCast(&sys_timestring)));
}

pub export fn Sys_AllowProfiling(enable: bool) void {
    _ = enable; // autofix
    return;
}

pub export fn Sys_Print(msg: [*c]const u8, len: usize) void {
    _ = len; // autofix
    const out = std.io.getStdOut();
    const writer = out.writer();

    if (std.fmt.format(writer, "{s}", .{msg})) {
        return;
    } else |_| {
        return;
    }
}

pub export fn Sys_HaveSSE() bool {
    return comptime switch (builtin.cpu.arch) {
        .x86_64, .x86 => std.Target.x86.featureSetHas(builtin.cpu.features, .sse),
        .aarch64 => std.Target.aarch64.featureSetHas(builtin.cpu.features, .sse),
        .aarch64_32 => std.Target.aarch64_32.featureSetHas(builtin.cpu.features, .sse),
        else => false,
    };
}
pub export fn Sys_HaveSSE2() bool {
    return comptime switch (builtin.cpu.arch) {
        .x86_64, .x86 => std.Target.x86.featureSetHas(builtin.cpu.features, .sse2),
        .aarch64 => std.Target.aarch64.featureSetHas(builtin.cpu.features, .sse2),
        .aarch64_32 => std.Target.aarch64_32.featureSetHas(builtin.cpu.features, .sse2),
        else => false,
    };
}

// pub export fn Sys_Init_Commands() void {
//
// }

// pub export fn Sys_LoadDependencyFunctions()

// pub export fn Sys_LoadSelf(handle: ?*anyopaque) bool {
//     if (handle == null) {
//         return false;
//     }
//
//     const dll = try std.DynLib.open("");
//     _ = dll; // autofix
// }

// pub export fn Sys_CheckParm(parm: [*c]const u8) c_uint {
//     for (0..sys.argc) |i| {
//         if (std.mem.eql(u8, sys.argv[i], "")) continue;
//         if (std.mem.eql(u8, parm, sys.argv[i])) return i;
//     }
//     return 0;
// }
