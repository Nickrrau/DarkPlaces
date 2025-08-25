const std = @import("std");
const zvar = @import("zvar");
const cvar = @import("cvar");
// const args = @import("args");
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("darkplaces.h");
    @cInclude("sys.h");
});

pub const qbool = bool;

export const sys_supportsdlgetticks: bool = true;
export var nocrashdialog: bool = true;

pub const sys_t = extern struct {
    argc: c_int = @import("std").mem.zeroes(c_int),
    argv: [*c][*c]const u8 = @import("std").mem.zeroes([*c][*c]const u8),
    selffd: c_int = @import("std").mem.zeroes(c_int),
    outfd: c_int = @import("std").mem.zeroes(c_int),
    nicelevel: c_int = @import("std").mem.zeroes(c_int),
    nicepossible: qbool = @import("std").mem.zeroes(qbool),
    isnice: qbool = @import("std").mem.zeroes(qbool),
};
pub extern var sys: sys_t;

pub export var zig: zvar.cvar_t = .{
    .flags = c.CF_SHARED,
    .name = "zig",
    .string = "0",
    .description = "Test CVAR from Zig",
};

pub export fn testZig() void {
    const t: [*c]c.cvar_s = @ptrCast(&zig);
    c.Cvar_RegisterVariable(t);
}


pub export fn Zig_RegisterVariable(variable: [*c]zvar.cvar_t) callconv(.C) void {
    zvar.global_registry.register(variable);
}

pub fn main() !void {
    std.debug.print("Entered Main\n", .{});
    const argv = std.os.argv;
    const argc: c_int = @intCast(argv.len);
    const c_ptr: [*c][*c]u8 = @ptrCast(argv.ptr);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    // var args_arena = std.heap.ArenaAllocator.init(alloc);
    // defer args_arena.deinit();
    // const parsed_args = try args.init(args_arena.allocator()); 
    // _ = parsed_args;

    var cvar_arena = std.heap.ArenaAllocator.init(alloc);
    defer cvar_arena.deinit();

    var registry = zvar.CVARRegistry(zvar.cvar_t).init(cvar_arena.allocator());
    defer registry.deinit();
    zvar.global_registry = &registry;

    _ = c.Sys_Main(argc, c_ptr);
    std.debug.print("{?}\n", .{registry.registry.get("zig").?.integer});
}

pub export fn Sys_SDL_Delay(ms: c_uint) void {
    c.SDL_Delay(ms);
}

pub export fn Sys_SDL_GetTicks() c_uint {
    return c.SDL_GetTicks();
}

pub export fn Sys_SDL_Init() void {
    if (c.SDL_Init(0) < 0) {
        c.Sys_Error("SDL_Init failed: %s\n", c.SDL_GetError());
    }

    if (!(c.Sys_CheckParm("-nocrashdialog") == 0)) {
        nocrashdialog = false;
    }
}

pub export fn Sys_SDL_Shutdown() void {
    c.SDL_Quit();
}

pub export fn Sys_SDL_Dialog(title: [*c]const u8, string: [*c]const u8) void {
    if (!nocrashdialog) {
        _ = c.SDL_ShowSimpleMessageBox(c.SDL_MESSAGEBOX_ERROR, title, string, null);
    }
}

