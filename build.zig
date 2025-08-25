const std = @import("std");

var base_dir: ?[]const u8 = undefined;
var game: ?[]const u8 = undefined;
var custom_name: ?[]const u8 = undefined;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    base_dir = b.option([]const u8, "basedir", "Location of local base game directory");
    game = b.option([]const u8, "game", "Game to run for");
    custom_name = b.option([]const u8, "custom_name", "Custom Name for executable");

    try buildClient(b, target, optimize);
    try buildServer(b, target, optimize);
}

fn buildClient(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
    const cl = b.step("client", "Build Darkplaces Client");

    const exe = b.addExecutable(.{
        .name = custom_name orelse "darkplaces",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("main_sdl.zig"),
    });

    exe.addWin32ResourceFile(.{
        .file = b.path("darkplaces.rc"),
        .flags = &.{ "/D_UNICODE", "/DUNICODE" },
    });

    exe.linkLibC();

    // TODO: I don't think this is needed...
    if (target.result.isMinGW()) {
        exe.root_module.addCMacro("WIN32", "0");
        exe.root_module.addCMacro("_WIN64", "0");
    }

    // exe.addCMacro("CONFIG_VIDEO_CAPTURE", "0");
    exe.root_module.addCMacro("CONFIG_PEDANTIC", "0");
    exe.root_module.addCMacro("_DEFAULT_SOURCE", "0");
    exe.root_module.addCMacro("SSE", "0");
    exe.root_module.addCMacro("SSE2", "0");
    exe.root_module.addCMacro("CONFIG_MENU", "1");
    exe.root_module.addCMacro("DP_FREETYPE_STATIC", "0"); // Force static linking of Freetype
    exe.root_module.addCMacro("LINK_TO_ZLIB", "0"); // Force static linking of ZLib
    // exe.addCMacro("LINK_TO_LIBJPEG", "0");

    exe.linkSystemLibrary("psapi");
    exe.linkSystemLibrary("wsock32");
    exe.linkSystemLibrary("ws2_32");
    exe.linkSystemLibrary("winmm");
    // exe.subsystem = .Windows;

    for (common_static_libs) |cfg| {
        if (cfg.c) {
            const l = b.addStaticLibrary(.{
                .name = cfg.name,
                .root_source_file = b.path(cfg.root_source_file),
                .target = target,
                .optimize = optimize,
            });
            l.linkLibC();
            l.addIncludePath(b.path("./"));
            l.bundle_compiler_rt = true;
            exe.linkLibrary(l);
        } else {
            const mod = b.createModule(.{
                .root_source_file = b.path(cfg.root_source_file),
                .target = target,
                .optimize = optimize,
                .link_libc = cfg.c,
            });
            mod.addIncludePath(b.path("./"));
            exe.root_module.addImport(cfg.name, mod);
        }
    }

    const sdl_dep = b.dependency("SDL2", .{
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibrary(sdl_dep.artifact("SDL2"));
    exe.addIncludePath(sdl_dep.path("include"));

    const freetype_dep = b.dependency("freetype", .{
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibrary(freetype_dep.artifact("freetype"));
    exe.addIncludePath(freetype_dep.path("include"));

    const ogg_dep = b.dependency("libogg", .{
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibrary(ogg_dep.artifact("ogg"));
    exe.addIncludePath(ogg_dep.path("include"));

    const vorbis_dep = b.dependency("libvorbis", .{
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibrary(vorbis_dep.artifact("vorbis"));
    exe.addIncludePath(vorbis_dep.path("include"));

    const zlib_dep = b.dependency("zlib", .{
        .optimize = optimize,
        .target = target,
    });
    exe.linkLibrary(zlib_dep.artifact("zlib"));
    exe.addIncludePath(zlib_dep.path(""));

    exe.addIncludePath(b.path(""));
    exe.addCSourceFiles(.{
        .files = &client ++ &common,
        .flags = &c_flags,
    });

    b.installArtifact(exe);
    cl.dependOn(b.getInstallStep());

    const run = b.addRunArtifact(exe);
    if (base_dir != null) {
        run.addArg("-basedir");
        run.addArg(base_dir.?);
    }
    if (game != null) {
        run.addArg("-game");
        run.addArg(game.?);
    }
    const run_step = b.step("run_client", "Run Darkplaces Client");
    run_step.dependOn(&run.step);
}

fn buildServer(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
    const sv = b.step("server", "Build Darkplaces Server");
    const exe = b.addExecutable(.{
        .name = "darkplaces_server",
        .target = target,
        .optimize = optimize,
    });

    exe.linkLibC();
    if (target.result.isMinGW()) {
        exe.root_module.addCMacro("WIN32", "1");
        exe.root_module.addCMacro("_WIN64", "1");
    }
    exe.root_module.addCMacro("CONFIG_PEDANTIC", "0");
    exe.root_module.addCMacro("_DEFAULT_SOURCE", "0");
    exe.root_module.addCMacro("SSE", "0");
    exe.root_module.addCMacro("SSE2", "0");
    exe.root_module.addCMacro("DLINK_TO_ZLIB", "0");

    exe.linkSystemLibrary("psapi");
    exe.linkSystemLibrary("wsock32");
    exe.linkSystemLibrary("ws2_32");
    exe.linkSystemLibrary("winmm");
    exe.subsystem = .Console;

    for (common_static_libs) |cfg| {
        const l = b.addStaticLibrary(.{
            .name = cfg.name,
            .root_source_file = b.path(cfg.root_source_file),
            .target = target,
            .optimize = optimize,
        });
        if (cfg.c) {
            l.linkLibC();
            l.addIncludePath(b.path("./"));
        }
        l.bundle_compiler_rt = true;
        exe.linkLibrary(l);
    }

    exe.addCSourceFiles(.{
        .files = &common ++ &server,
        .flags = &c_flags,
    });

    const install = b.addInstallArtifact(exe, .{});
    sv.dependOn(&install.step);
    b.default_step.dependOn(&install.step);

    const run = b.addRunArtifact(exe);
    if (base_dir != null) {
        run.addArg("-basedir");
        run.addArg(base_dir.?);
    }
    if (game != null) {
        run.addArg("-game");
        run.addArg(game.?);
    }
    const run_step = b.step("run_server", "Run Darkplaces Server");
    run_step.dependOn(&run.step);
}

const common_static_libs = [_]struct {
    name: []const u8,
    root_source_file: []const u8,
    bundle_compiler_rt: bool,
    c: bool,
}{
    .{
        .name = "build_info",
        .root_source_file = "build_info.zig",
        .bundle_compiler_rt = true,
        .c = true,
    },
    .{
        .name = "sys",
        .root_source_file = "sys.zig",
        .bundle_compiler_rt = true,
        .c = true,
    },
    .{
        .name = "zvar",
        .root_source_file = "zigvar.zig",
        .bundle_compiler_rt = true,
        .c = false,
    },
    .{
        .bundle_compiler_rt = true,
        .c = false,
    },
};
const cl_static_libs = []std.Build.StaticLibraryOptions{};
const sv_static_libs = []std.Build.StaticLibraryOptions{};

const c_flags = [_][]const u8{
    "-std=c17",
    "-Werror=vla",
    "-Wc++-compat",
    "-Wwrite-strings",
    "-Wshadow",
    "-Wold-style-definition",
    "-Wstrict-prototypes",
    "-Wsign-compare",
    "-Wdeclaration-after-statement",
    "-Wmissing-prototypes",
    "-Winline",
    "-Werror=implicit-function-declaration",
    "-O1",
    "-fno-omit-frame-pointer",
    "-fno-sanitize=undefined",
    "-pedantic",
};

const common = [_][]const u8{
    "bih.c",
    "crypto.c",
    "cd_shared.c",
    "cl_cmd.c",
    "cl_collision.c",
    "cl_demo.c",
    "cl_ents.c",
    "cl_ents4.c",
    "cl_ents5.c",
    "cl_ents_nq.c",
    "cl_ents_qw.c",
    "cl_input.c",
    "cl_main.c",
    "cl_parse.c",
    "cl_particles.c",
    "cl_screen.c",
    "cl_video.c",
    "cl_video_libavw.c",
    "clvm_cmds.c",
    "cmd.c",
    "collision.c",
    "com_crc16.c",
    "com_ents.c",
    "com_ents4.c",
    "com_game.c",
    "com_infostring.c",
    "com_msg.c",
    "common.c",
    "console.c",
    "csprogs.c",
    "curves.c",
    "cvar.c",
    "dpvsimpledecode.c",
    "filematch.c",
    "fractalnoise.c",
    "fs.c",
    "ft2.c",
    "utf8lib.c",
    "gl_backend.c",
    "gl_draw.c",
    "gl_rmain.c",
    "gl_rsurf.c",
    "gl_textures.c",
    "hmac.c",
    "host.c",
    "image.c",
    "image_png.c",
    "jpeg.c",
    "keys.c",
    "lhnet.c",
    "libcurl.c",
    "mathlib.c",
    "matrixlib.c",
    "mdfour.c",
    "meshqueue.c",
    "mod_skeletal_animatevertices_sse.c",
    "mod_skeletal_animatevertices_generic.c",
    "model_alias.c",
    "model_brush.c",
    "model_shared.c",
    "model_sprite.c",
    "netconn.c",
    "palette.c",
    "phys.c",
    "polygon.c",
    "portals.c",
    "protocol.c",
    "prvm_cmds.c",
    "prvm_edict.c",
    "prvm_exec.c",
    "r_explosion.c",
    "r_lightning.c",
    "r_modules.c",
    "r_shadow.c",
    "r_sky.c",
    "r_sprites.c",
    "r_stats.c",
    "sbar.c",
    "sv_ccmds.c",
    "sv_demo.c",
    "sv_ents.c",
    "sv_ents4.c",
    "sv_ents5.c",
    "sv_ents_csqc.c",
    "sv_ents_nq.c",
    "sv_main.c",
    "sv_move.c",
    "sv_phys.c",
    "sv_save.c",
    "sv_send.c",
    "sv_user.c",
    "svbsp.c",
    "svvm_cmds.c",
    "sys_shared.c",
    "taskqueue.c",
    "vid_shared.c",
    "view.c",
    "wad.c",
    "world.c",
    "zone.c",
};

const video_capture = [_][]const u8{
    "av_backend_libav.c",
    "cap_avi.c",
    "cap_ogg.c",
    "cl_video_jamdecode.c",
};

const client = [_][]const u8{
    "snd_main.c",
    "snd_mem.c",
    "snd_mix.c",
    "snd_ogg.c",
    "snd_sdl.c",
    "snd_wav.c",
    "sys_sdl.c",
    "thread_sdl.c",
    "vid_sdl.c",
    "menu.c",
    "mvm_cmds.c",
};

const server = [_][]const u8{
    "snd_null.c",
    "vid_null.c",
    "sys_null.c",
    "thread_null.c",
};
