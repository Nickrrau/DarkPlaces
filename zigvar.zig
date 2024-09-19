const std = @import("std");

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
