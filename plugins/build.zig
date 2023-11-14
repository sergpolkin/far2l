const std = @import("std");
const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;

pub const PluginsBuildOptions = struct {
    target: CrossTarget,
    optimize: std.builtin.OptimizeMode,
    far2l_upstream: *Build.Dependency,
    far2l_utils: *Build.Step.Compile,
};

pub fn build(b: *Build, options: PluginsBuildOptions) void {
    const target = options.target;
    const optimize = options.optimize;

    const upstream = options.far2l_upstream;
    const utils = options.far2l_utils;

    const plug_simple = b.addSharedLibrary(.{
        .name = "simple",
        .root_source_file = .{ .path = "plugins/simple.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.getInstallStep().dependOn(&b.addInstallArtifact(plug_simple, .{
        .dest_sub_path = "Plugins/simple/plug/simple.far-plug-wide",
        .dest_dir = .{ .override = .{ .custom = "install" } },
    }).step);

    const plug_align = b.addSharedLibrary(.{
        .name = "align",
        .target = target,
        .optimize = optimize,
    });
    plug_align.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "align/src/Align.cpp",
        },
        .flags = &.{},
    });
    plug_align.addIncludePath(upstream.path("align"));
    plug_align.addIncludePath(upstream.path("far2l/far2sdk"));
    plug_align.addIncludePath(upstream.path("WinPort"));
    plug_align.addIncludePath(upstream.path("utils/include"));
    plug_align.defineCMacro("UNICODE", null);
    plug_align.defineCMacro("WINPORT_DIRECT", null);
    plug_align.defineCMacro("FAR_DONT_USE_INTERNALS", null);
    plug_align.linkLibrary(utils);
    plug_align.linkLibCpp();
    b.getInstallStep().dependOn(&b.addInstallArtifact(plug_align, .{
        .dest_sub_path = "Plugins/align/plug/align.far-plug-wide",
        .dest_dir = .{ .override = .{ .custom = "install" } },
    }).step);
    b.installDirectory(.{
        .source_dir = upstream.path("align/configs/plug"),
        .install_dir = .{ .custom = "install" },
        .install_subdir = "Plugins/align/plug",
    });

    const plug_calc = b.addSharedLibrary(.{
        .name = "calc",
        .target = target,
        .optimize = optimize,
    });
    plug_calc.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "calc/src/plugcalc/api.cpp",
            "calc/src/plugcalc/api-far2.cpp",
            "calc/src/plugcalc/calc.cpp",
            "calc/src/plugcalc/config.cpp",
            "calc/src/plugcalc/newparse.cpp",
            "calc/src/plugcalc/sarg.cpp",
            "calc/src/plugcalc/syntax.cpp",
            "calc/src/shared/sgml/sgml.cpp",
            "calc/src/shared/trex/trex.c",
        },
        .flags = &.{},
    });
    plug_calc.addIncludePath(upstream.path("calc/src/shared"));
    plug_calc.addIncludePath(upstream.path("far2l/far2sdk"));
    plug_calc.addIncludePath(upstream.path("WinPort"));
    plug_calc.addIncludePath(upstream.path("utils/include"));
    plug_calc.defineCMacro("UNICODE", null);
    plug_calc.defineCMacro("_UNICODE", null);
    plug_calc.defineCMacro("TTMATH_NOASM", null);
    plug_calc.linkLibrary(utils);
    plug_calc.linkLibCpp();
    b.getInstallStep().dependOn(&b.addInstallArtifact(plug_calc, .{
        .dest_sub_path = "Plugins/calc/plug/calc.far-plug-wide",
        .dest_dir = .{ .override = .{ .custom = "install" } },
    }).step);
    b.installDirectory(.{
        .source_dir = upstream.path("calc/configs"),
        .install_dir = .{ .custom = "install" },
        .install_subdir = "Plugins/calc/plug",
    });

    const plug_inside = b.addSharedLibrary(.{
        .name = "inside",
        .target = target,
        .optimize = optimize,
    });
    plug_inside.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "inside/src/inside.cpp",
            "inside/src/Globals.cpp",
            "inside/src/Commands.cpp",
            "inside/src/ItemList.cpp",
            "inside/src/PluginImpl.cpp",
            "inside/src/Storage.cpp",
            "inside/src/plain/PluginImplPlain.cpp",
            "inside/src/elf/Dumper.cpp",
            "inside/src/elf/PluginImplELF.cpp",
        },
        .flags = &.{},
    });
    plug_inside.addIncludePath(upstream.path("inside/src"));
    plug_inside.addIncludePath(upstream.path("inside/plain"));
    plug_inside.addIncludePath(upstream.path("inside/elf"));
    plug_inside.addIncludePath(upstream.path("far2l/far2sdk"));
    plug_inside.addIncludePath(upstream.path("WinPort"));
    plug_inside.addIncludePath(upstream.path("utils/include"));
    plug_inside.linkLibrary(utils);
    plug_inside.linkLibCpp();
    b.getInstallStep().dependOn(&b.addInstallArtifact(plug_inside, .{
        .dest_sub_path = "Plugins/inside/plug/inside.far-plug-mb",
        .dest_dir = .{ .override = .{ .custom = "install" } },
    }).step);
    b.installDirectory(.{
        .source_dir = upstream.path("inside/configs/plug"),
        .install_dir = .{ .custom = "install" },
        .install_subdir = "Plugins/inside/plug",
    });
}
