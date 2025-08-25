const std = @import("std");

pub const cvar_t = extern struct {
    flags: c_uint,
    name: [*c]const u8,
    string: [*c]const u8,
    description: [*c]const u8,
    integer: c_int = undefined,
    value: c_longdouble = undefined,
    vector: [3]c_longdouble = undefined,
    defstring: [*c]const u8 = undefined,
    callback: *const fn (@This()) callconv(.C) void = undefined,
    aliases: [*c][*c]const u8 = undefined,
    aliases_size: c_int = undefined,
    initstring: [*c]const u8 = undefined,
    globaldefindex: [3]c_int = undefined,
    globaldefindex_stringno: [3]c_int = undefined,
};

pub var global_registry: *CVARRegistry(cvar_t) = undefined;

pub fn CVARRegistry(var_type: type) type {
    return struct {
        alloc: std.mem.Allocator,
        registry: std.StringArrayHashMap(*var_type),

        const Self = @This();

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .alloc = alloc,
                .registry = std.StringArrayHashMap(*var_type).init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            self.registry.deinit();
        }

        pub fn register(self: *Self, variable: *var_type) void {
            const var_name: []const u8 = std.mem.span(variable.*.name);
            if (self.registry.get(var_name)) |v| {
                _ = v; // autofix
                // Already exists
                @panic("Already Exists!");
            } else {
                self.registry.put(var_name, variable) catch @panic("Failed to allocate slot for cvar");
            }
        }
    };
}
