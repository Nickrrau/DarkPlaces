const std = @import("std");
const c = @cImport({
    // @cInclude("cvar.h");
    // @cInclude("qdefs.h");
    // @cInclude("quakedef.h");
    // @cInclude("cmd.h");
});

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

// pub const cvar_hash_t = extern struct {
//     cvar: *cvar_t,
//     next: *@This(),
// };

// pub const cvar_state_t = extern struct {
//     vars: [*c]cvar_t,
//     // hashtable: [c.CVAR_HASHSIZE]*cvar_hash_t,
//     hashtable: std.AutoArrayHashMap(usize, *cvar_hash_t),
// };

//
// pub extern fn Cvar_FindVar(cvars: [*c]cvar_state_t, var_name: [*c]const u8, neededflags: c_uint) [*c]cvar_t;
// pub export fn Cvar_FindVar(cvars: [*c]cvar_state_t, var_name: [*c]const u8, neededflags: c_uint) [*c]cvar_t {
//     const z_var_name = std.mem.span(var_name);
//     const hashindex: usize = @intCast(c.CRC_Block(var_name, std.mem.len(var_name)) % c.CVAR_HASHSIZE);
//     var hash: *cvar_hash_t = cvars.*.hashtable[hashindex];
//
//     while (hash.next != undefined) {
//         const z_hash_name = std.mem.span(hash.cvar.name);
//         if (std.mem.eql(u8, z_var_name, z_hash_name) and (hash.cvar.flags & neededflags == 1)) {
//             return hash.cvar;
//         } else {}
//
//         hash = hash.next;
//     }
//
//     return null;
// }

// pub export fn Cvar_FindVar(cvars: [*c]cvar_state_t, var_name: [*c]const u8, neededflags: c_uint) [*c]cvar_t {
//     const z_var_name = std.mem.span(var_name);
//     const hashindex: usize = @intCast(c.CRC_Block(var_name, std.mem.len(var_name)) % c.CVAR_HASHSIZE);
//
//     var hash = cvars.*.hashtable[hashindex];
//     while (hash != undefined) : (hash = hash.*.next) {
//         const z_hash_name = std.mem.span(hash.cvar.name);
//         if (std.mem.eql(u8, z_var_name, z_hash_name) and (hash.cvar.flags & neededflags != 0)) {
//             return hash.*.cvar;
//         } else {
//             var alias: [*c][*c]const u8 = hash.*.cvar.*.aliases;
//             _ = &alias;
//             while ((alias != null) and (alias.* != null)) : (alias += 1) {
//                 const z_alias = std.mem.span(alias.*);
//                 if (std.mem.eql(u8, z_var_name, z_alias) and (hash.*.cvar.*.flags & neededflags) != 0) {
//                     return hash.*.cvar;
//                 }
//             }
//         }
//     }
//
//     return null;
// }
// test
