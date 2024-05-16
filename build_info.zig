const fmt = @import("std").fmt;
const builtin = @import("builtin");

export const os_name = @tagName(builtin.os.tag);
export const os_arch = @tagName(builtin.target.cpu.arch);

export const buildstring: [*c]const u8 = fmt.comptimePrint(
    "- {s} - Zig v{s}",
    .{
        @tagName(builtin.mode),
        builtin.zig_version_string,
    },
);
