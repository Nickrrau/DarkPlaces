const std = @import("std");
const c = @cImport({
    @cInclude("SDL.h");
    @cInclude("darkplaces.h");
});

export const sys_supportsdlgetticks: bool = true;
export var nocrashdialog: bool = true;

pub fn main() void {
    const argv = std.os.argv;
    const argc: c_int = @intCast(argv.len);
    const c_ptr: [*c][*c]u8 = @ptrCast(argv.ptr);

    _ = c.Sys_Main(argc, c_ptr);
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
