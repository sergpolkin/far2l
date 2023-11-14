const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const upstream = b.dependency("far2l", .{});

    const utils = b.addStaticLibrary(.{
        .name = "utils",
        .target = target,
        .optimize = optimize,
    });

    utils.addIncludePath(upstream.path("utils/include"));
    utils.addCSourceFiles(.{
        .dependency = upstream,
        .files = &utils_src,
        .flags = &.{},
    });
    utils.linkLibCpp();

    const wineguts = b.addStaticLibrary(.{
        .name = "wineguts",
        .target = target,
        .optimize = optimize,
    });
    wineguts.addIncludePath(upstream.path("WinPort/wineguts"));
    wineguts.addCSourceFiles(.{
        .dependency = upstream,
        .files = &wineguts_src,
        .flags = &.{},
    });
    wineguts.addCSourceFiles(.{
        .dependency = upstream,
        .files = &codepages_src,
        .flags = &.{},
    });
    wineguts.defineCMacro("NO_EACP", null);
    wineguts.linkLibC();

    const winport = b.addStaticLibrary(.{
        .name = "winport",
        .target = target,
        .optimize = optimize,
    });
    winport.addIncludePath(upstream.path("WinPort"));
    winport.addIncludePath(upstream.path("WinPort/src"));
    winport.addIncludePath(upstream.path("WinPort/src/Backend"));
    winport.addIncludePath(upstream.path("utils/include"));
    winport.addCSourceFiles(.{
        .dependency = upstream,
        .files = &winport_src,
        .flags = &.{},
    });

    winport.linkLibrary(utils);
    winport.linkLibrary(wineguts);

    const bootstrap = b.addSystemCommand(&.{ "sh", "bootstrap.sh" });
    bootstrap.addDirectoryArg(upstream.path(""));
    bootstrap.addDirectoryArg(.{ .path = b.getInstallPath(.prefix, "bootstrap") });

    const bootstrap_install = b.addInstallDirectory(.{
        .source_dir = .{ .path = b.getInstallPath(.prefix, "bootstrap") },
        .install_dir = .{ .custom = "install" },
        .install_subdir = "",
        .include_extensions = &.{ "lng", "hlf" },
    });
    bootstrap_install.step.dependOn(&bootstrap.step);
    b.getInstallStep().dependOn(&bootstrap_install.step);

    const far2l = b.addExecutable(.{
        .name = "far2l",
        .target = target,
        .optimize = optimize,
    });

    far2l.addIncludePath(upstream.path("far2l"));
    far2l.addIncludePath(upstream.path("far2l/far2sdk"));
    far2l.addIncludePath(upstream.path("far2l/src"));
    far2l.addIncludePath(upstream.path("far2l/src/base"));
    far2l.addIncludePath(upstream.path("far2l/src/mix"));
    far2l.addIncludePath(upstream.path("far2l/src/bookmarks"));
    far2l.addIncludePath(upstream.path("far2l/src/cfg"));
    far2l.addIncludePath(upstream.path("far2l/src/console"));
    far2l.addIncludePath(upstream.path("far2l/src/panels"));
    far2l.addIncludePath(upstream.path("far2l/src/filemask"));
    far2l.addIncludePath(upstream.path("far2l/src/hist"));
    far2l.addIncludePath(upstream.path("far2l/src/locale"));
    far2l.addIncludePath(upstream.path("far2l/src/macro"));
    far2l.addIncludePath(upstream.path("far2l/src/plug"));
    far2l.addIncludePath(upstream.path("far2l/src/vt"));
    far2l.addIncludePath(upstream.path("WinPort"));
    far2l.addIncludePath(upstream.path("utils/include"));
    far2l.addIncludePath(.{ .path = b.getInstallPath(.prefix, "") });

    far2l.defineCMacro("UNICODE", null);
    far2l.addCSourceFiles(.{
        .dependency = upstream,
        .files = &far2l_src,
        .flags = &.{},
    });
    far2l.addCSourceFile(.{
        .file = .{ .path = "farrtl.cpp" },
        .flags = &.{},
    });
    far2l.addCSourceFile(.{
        .file = upstream.path("far2l/src/macro/nomacro.cpp"),
        .flags = &.{},
    });

    far2l.rdynamic = true;
    far2l.linkSystemLibrary("dl");
    far2l.linkLibrary(winport);

    far2l.step.dependOn(&bootstrap.step);

    b.getInstallStep().dependOn(&b.addInstallArtifact(far2l, .{ .dest_dir = .{ .override = .{ .custom = "install" } } }).step);

    const run_cmd = b.addRunArtifact(far2l);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run FAR2L");
    run_step.dependOn(&run_cmd.step);

    // wx

    const gui = b.addSharedLibrary(.{
        .name = "far2l_gui",
        .target = target,
        .optimize = optimize,
    });

    gui.addCSourceFiles(.{
        .dependency = upstream,
        .files = &far2l_gui_src,
        .flags = &.{},
    });

    gui.addIncludePath(upstream.path("WinPort"));
    gui.addIncludePath(upstream.path("WinPort/src"));
    gui.addIncludePath(upstream.path("WinPort/src/Backend"));
    gui.addIncludePath(upstream.path("utils/include"));
    gui.addSystemIncludePath(.{ .path = "/usr/lib64/wx/include/gtk3-unicode-3.2" });
    gui.addSystemIncludePath(.{ .path = "/usr/include/wx-3.2" });

    gui.defineCMacro("_FILE_OFFSET_BITS", "64");
    gui.defineCMacro("WXUSINGDLL", null);
    gui.defineCMacro("__WXGTK__", null);

    gui.linkLibrary(utils);
    gui.linkLibCpp();
    gui.linkSystemLibrary("wx_gtk3u_core-3.2");
    gui.linkSystemLibrary("wx_baseu-3.2");

    b.getInstallStep().dependOn(&b.addInstallArtifact(gui, .{ .dest_dir = .{ .override = .{ .custom = "install" } } }).step);

    // plugins

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
        .files = &plug_calc_src,
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
}

const plug_calc_src = [_][]const u8{
    "calc/src/plugcalc/api.cpp",
    "calc/src/plugcalc/api-far2.cpp",
    "calc/src/plugcalc/calc.cpp",
    "calc/src/plugcalc/config.cpp",
    "calc/src/plugcalc/newparse.cpp",
    "calc/src/plugcalc/sarg.cpp",
    "calc/src/plugcalc/syntax.cpp",
    "calc/src/shared/sgml/sgml.cpp",
    "calc/src/shared/trex/trex.c",
};

const far2l_gui_src = [_][]const u8{
    "WinPort/src/Backend/WX/Paint.cpp",
    "WinPort/src/Backend/WX/CustomDrawChar.cpp",
    "WinPort/src/Backend/WX/wxMain.cpp",
    "WinPort/src/Backend/WX/wxClipboardBackend.cpp",
    "WinPort/src/Backend/WX/ExclusiveHotkeys.cpp",
    "WinPort/src/Backend/WX/wxWinTranslations.cpp",
    "WinPort/src/Backend/WX/wxConsoleInputShim.cpp",
};

const far2l_src = [_][]const u8{
    "far2l/src/farversion.cpp",
    "far2l/src/cache.cpp",
    "far2l/src/clipboard.cpp",
    "far2l/src/cmdline.cpp",
    "far2l/src/copy.cpp",
    "far2l/src/ctrlobj.cpp",
    "far2l/src/datetime.cpp",
    "far2l/src/delete.cpp",
    "far2l/src/dialog.cpp",
    "far2l/src/dirinfo.cpp",
    "far2l/src/dizlist.cpp",
    "far2l/src/DialogBuilder.cpp",
    "far2l/src/dlgedit.cpp",
    "far2l/src/DlgGuid.cpp",
    "far2l/src/edit.cpp",
    "far2l/src/editor.cpp",
    "far2l/src/EditorConfigOrg.cpp",
    "far2l/src/execute.cpp",
    "far2l/src/farwinapi.cpp",
    "far2l/src/fileattr.cpp",
    "far2l/src/fileedit.cpp",
    "far2l/src/filefilter.cpp",
    "far2l/src/filefilterparams.cpp",
    "far2l/src/FilesSuggestor.cpp",
    "far2l/src/fileowner.cpp",
    "far2l/src/filepanels.cpp",
    "far2l/src/filestr.cpp",
    "far2l/src/filetype.cpp",
    "far2l/src/fileview.cpp",
    "far2l/src/findfile.cpp",
    "far2l/src/FindPattern.cpp",
    "far2l/src/flink.cpp",
    "far2l/src/fnparce.cpp",
    "far2l/src/foldtree.cpp",
    "far2l/src/frame.cpp",
    "far2l/src/global.cpp",
    "far2l/src/help.cpp",
    "far2l/src/hilight.cpp",
    "far2l/src/hmenu.cpp",
    "far2l/src/Mounts.cpp",
    "far2l/src/keybar.cpp",
    "far2l/src/main.cpp",
    "far2l/src/manager.cpp",
    "far2l/src/menubar.cpp",
    "far2l/src/message.cpp",
    "far2l/src/mkdir.cpp",
    "far2l/src/modal.cpp",
    "far2l/src/namelist.cpp",
    "far2l/src/options.cpp",
    "far2l/src/plist.cpp",
    "far2l/src/rdrwdsk.cpp",
    "far2l/src/RefreshFrameManager.cpp",
    "far2l/src/scantree.cpp",
    "far2l/src/setattr.cpp",
    "far2l/src/setcolor.cpp",
    "far2l/src/stddlg.cpp",
    "far2l/src/synchro.cpp",
    "far2l/src/syslog.cpp",
    "far2l/src/TPreRedrawFunc.cpp",
    "far2l/src/usermenu.cpp",
    "far2l/src/viewer.cpp",
    "far2l/src/vmenu.cpp",
    "far2l/src/execute_oscmd.cpp",
    "far2l/src/ViewerStrings.cpp",
    "far2l/src/ViewerPrinter.cpp",
    "far2l/src/fileholder.cpp",
    "far2l/src/GrepFile.cpp",

    "far2l/src/panels/panel.cpp",
    "far2l/src/panels/filelist.cpp",
    "far2l/src/panels/fldata.cpp",
    "far2l/src/panels/flmodes.cpp",
    "far2l/src/panels/flplugin.cpp",
    "far2l/src/panels/flshow.cpp",
    "far2l/src/panels/flupdate.cpp",
    "far2l/src/panels/infolist.cpp",
    "far2l/src/panels/qview.cpp",
    "far2l/src/panels/treelist.cpp",

    "far2l/src/console/AnsiEsc.cpp",
    "far2l/src/console/keyboard.cpp",
    "far2l/src/console/console.cpp",
    "far2l/src/console/constitle.cpp",
    "far2l/src/console/interf.cpp",
    "far2l/src/console/grabber.cpp",
    "far2l/src/console/lockscrn.cpp",
    "far2l/src/console/palette.cpp",
    "far2l/src/console/savescr.cpp",
    "far2l/src/console/scrbuf.cpp",
    "far2l/src/console/scrobj.cpp",
    "far2l/src/console/scrsaver.cpp",

    "far2l/src/filemask/CFileMask.cpp",
    "far2l/src/filemask/FileMasksProcessor.cpp",
    "far2l/src/filemask/FileMasksWithExclude.cpp",

    "far2l/src/locale/codepage.cpp",
    "far2l/src/locale/DetectCodepage.cpp",
    "far2l/src/locale/xlat.cpp",
    "far2l/src/locale/locale.cpp",

    "far2l/src/bookmarks/Bookmarks.cpp",
    "far2l/src/bookmarks/BookmarksMenu.cpp",
    "far2l/src/bookmarks/BookmarksLegacy.cpp",

    "far2l/src/cfg/AllXLats.cpp",
    "far2l/src/cfg/config.cpp",
    "far2l/src/cfg/ConfigSaveLoad.cpp",
    "far2l/src/cfg/ConfigRW.cpp",
    "far2l/src/cfg/ConfigLegacy.cpp",
    "far2l/src/cfg/HotkeyLetterDialog.cpp",
    "far2l/src/cfg/language.cpp",

    "far2l/src/hist/history.cpp",
    "far2l/src/hist/poscache.cpp",

    "far2l/src/plug/plugapi.cpp",
    "far2l/src/plug/plugins.cpp",
    "far2l/src/plug/PluginW.cpp",
    "far2l/src/plug/PluginA.cpp",
    "far2l/src/plug/plclass.cpp",

    "far2l/src/vt/vtansi.cpp",
    "far2l/src/vt/vtshell.cpp",
    "far2l/src/vt/vtshell_translation.cpp",
    "far2l/src/vt/vtshell_compose.cpp",
    "far2l/src/vt/vtshell_leader.cpp",
    "far2l/src/vt/vtshell_ioreaders.cpp",
    "far2l/src/vt/vtshell_mouse.cpp",
    "far2l/src/vt/vtlog.cpp",
    "far2l/src/vt/vtcompletor.cpp",
    "far2l/src/vt/VTFar2lExtensios.cpp",

    "far2l/src/base/InterThreadCall.cpp",
    "far2l/src/base/SafeMMap.cpp",
    "far2l/src/base/farqueue.cpp",
    "far2l/src/base/FARString.cpp",
    "far2l/src/base/DList.cpp",

    "far2l/src/mix/format.cpp",
    "far2l/src/mix/udlist.cpp",
    "far2l/src/mix/cvtname.cpp",
    "far2l/src/mix/cddrv.cpp",
    "far2l/src/mix/chgprior.cpp",
    "far2l/src/mix/MountInfo.cpp",
    "far2l/src/mix/dirmix.cpp",
    "far2l/src/mix/drivemix.cpp",
    "far2l/src/mix/mix.cpp",
    "far2l/src/mix/panelmix.cpp",
    "far2l/src/mix/pathmix.cpp",
    "far2l/src/mix/processname.cpp",
    "far2l/src/mix/RegExp.cpp",
    "far2l/src/mix/strmix.cpp",
    "far2l/src/mix/FSFileFlags.cpp",
    "far2l/src/mix/StrCells.cpp",
    "far2l/src/mix/ChunkedData.cpp",
    "far2l/src/mix/UsedChars.cpp",
    "far2l/src/mix/CachedCreds.cpp",
};

const winport_src = [_][]const u8{
    "WinPort/src/APIClipboard.cpp",
    "WinPort/src/APIConsole.cpp",
    "WinPort/src/APIFiles.cpp",
    "WinPort/src/APIKeyboard.cpp",
    "WinPort/src/APIOther.cpp",
    "WinPort/src/APIPrintFormat.cpp",
    "WinPort/src/APIRegistry.cpp",
    "WinPort/src/APIStringCodepages.cpp",
    "WinPort/src/APIStringMap.cpp",
    "WinPort/src/APITime.cpp",
    "WinPort/src/ConsoleBuffer.cpp",
    "WinPort/src/ConsoleInput.cpp",
    "WinPort/src/ConsoleOutput.cpp",
    "WinPort/src/WinPortHandle.cpp",
    "WinPort/src/CustomPanic.cpp",
    "WinPort/src/PathHelpers.cpp",
    "WinPort/src/SavedScreen.cpp",
    "WinPort/src/sudo/sudo_common.cpp",
    "WinPort/src/sudo/sudo_client.cpp",
    "WinPort/src/sudo/sudo_client_api.cpp",
    "WinPort/src/sudo/sudo_dispatcher.cpp",
    "WinPort/src/sudo/sudo_askpass.cpp",
    "WinPort/src/sudo/sudo_askpass_ipc.cpp",
    "WinPort/src/Backend/WinPortMain.cpp",
    "WinPort/src/Backend/WinPortRGB.cpp",
    "WinPort/src/Backend/SudoAskpassImpl.cpp",
    "WinPort/src/Backend/FSClipboardBackend.cpp",
    "WinPort/src/Backend/ExtClipboardBackend.cpp",
    "WinPort/src/Backend/TTY/TTYBackend.cpp",
    "WinPort/src/Backend/TTY/TTYRevive.cpp",
    "WinPort/src/Backend/TTY/TTYInput.cpp",
    "WinPort/src/Backend/TTY/TTYInputSequenceParser.cpp",
    "WinPort/src/Backend/TTY/TTYInputSequenceParserExts.cpp",
    "WinPort/src/Backend/TTY/TTYOutput.cpp",
    "WinPort/src/Backend/TTY/TTYFar2lClipboardBackend.cpp",
    "WinPort/src/Backend/TTY/OSC52ClipboardBackend.cpp",
    "WinPort/src/Backend/TTY/TTYNegotiateFar2l.cpp",
    "WinPort/src/Backend/TTY/TTYXGlue.cpp",
};

const wineguts_src = [_][]const u8{
    "WinPort/wineguts/casemap.c",
    "WinPort/wineguts/collation.c",
    "WinPort/wineguts/compose.c",
    "WinPort/wineguts/cpsymbol.c",
    "WinPort/wineguts/cptable.c",
    "WinPort/wineguts/decompose.c",
    "WinPort/wineguts/locale.c",
    "WinPort/wineguts/mbtowc.c",
    "WinPort/wineguts/sortkey.c",
    "WinPort/wineguts/utf8.c",
    "WinPort/wineguts/wctomb.c",
    "WinPort/wineguts/wctype.c",
};

const codepages_src = [_][]const u8{
    "WinPort/wineguts/codepages/c_037.c",
    "WinPort/wineguts/codepages/c_424.c",
    "WinPort/wineguts/codepages/c_437.c",
    "WinPort/wineguts/codepages/c_500.c",
    "WinPort/wineguts/codepages/c_737.c",
    "WinPort/wineguts/codepages/c_775.c",
    "WinPort/wineguts/codepages/c_850.c",
    "WinPort/wineguts/codepages/c_852.c",
    "WinPort/wineguts/codepages/c_855.c",
    "WinPort/wineguts/codepages/c_856.c",
    "WinPort/wineguts/codepages/c_857.c",
    "WinPort/wineguts/codepages/c_860.c",
    "WinPort/wineguts/codepages/c_861.c",
    "WinPort/wineguts/codepages/c_862.c",
    "WinPort/wineguts/codepages/c_863.c",
    "WinPort/wineguts/codepages/c_864.c",
    "WinPort/wineguts/codepages/c_865.c",
    "WinPort/wineguts/codepages/c_866.c",
    "WinPort/wineguts/codepages/c_866.uk.c",
    "WinPort/wineguts/codepages/c_869.c",
    "WinPort/wineguts/codepages/c_874.c",
    "WinPort/wineguts/codepages/c_875.c",
    "WinPort/wineguts/codepages/c_1006.c",
    "WinPort/wineguts/codepages/c_1026.c",
    "WinPort/wineguts/codepages/c_1250.c",
    "WinPort/wineguts/codepages/c_1251.c",
    "WinPort/wineguts/codepages/c_1252.c",
    "WinPort/wineguts/codepages/c_1253.c",
    "WinPort/wineguts/codepages/c_1254.c",
    "WinPort/wineguts/codepages/c_1255.c",
    "WinPort/wineguts/codepages/c_1256.c",
    "WinPort/wineguts/codepages/c_1257.c",
    "WinPort/wineguts/codepages/c_1258.c",
    "WinPort/wineguts/codepages/c_10000.c",
    "WinPort/wineguts/codepages/c_10004.c",
    "WinPort/wineguts/codepages/c_10005.c",
    "WinPort/wineguts/codepages/c_10006.c",
    "WinPort/wineguts/codepages/c_10007.c",
    "WinPort/wineguts/codepages/c_10010.c",
    "WinPort/wineguts/codepages/c_10017.c",
    "WinPort/wineguts/codepages/c_10021.c",
    "WinPort/wineguts/codepages/c_10029.c",
    "WinPort/wineguts/codepages/c_10079.c",
    "WinPort/wineguts/codepages/c_10081.c",
    "WinPort/wineguts/codepages/c_10082.c",
    "WinPort/wineguts/codepages/c_20127.c",
    "WinPort/wineguts/codepages/c_20866.c",
    "WinPort/wineguts/codepages/c_20880.c",
    "WinPort/wineguts/codepages/c_21866.c",
    "WinPort/wineguts/codepages/c_28591.c",
    "WinPort/wineguts/codepages/c_28592.c",
    "WinPort/wineguts/codepages/c_28593.c",
    "WinPort/wineguts/codepages/c_28594.c",
    "WinPort/wineguts/codepages/c_28595.c",
    "WinPort/wineguts/codepages/c_28596.c",
    "WinPort/wineguts/codepages/c_28597.c",
    "WinPort/wineguts/codepages/c_28598.c",
    "WinPort/wineguts/codepages/c_28599.c",
    "WinPort/wineguts/codepages/c_28600.c",
    "WinPort/wineguts/codepages/c_28603.c",
    "WinPort/wineguts/codepages/c_28604.c",
    "WinPort/wineguts/codepages/c_28605.c",
    "WinPort/wineguts/codepages/c_28606.c",
};

const utils_src = [_][]const u8{
    "utils/src/Threaded.cpp",
    "utils/src/ThreadedWorkQueue.cpp",
    "utils/src/SharedResource.cpp",
    "utils/src/KeyFileHelper.cpp",
    "utils/src/utils.cpp",
    "utils/src/InstallPath.cpp",
    "utils/src/StrPrintf.cpp",
    "utils/src/TimeUtils.cpp",
    "utils/src/StringConfig.cpp",
    "utils/src/InMy.cpp",
    "utils/src/ZombieControl.cpp",
    "utils/src/base64.cpp",
    "utils/src/Event.cpp",
    "utils/src/StackSerializer.cpp",
    "utils/src/ScopeHelpers.cpp",
    "utils/src/crc64.c",
    "utils/src/TTYRawMode.cpp",
    "utils/src/LocalSocket.cpp",
    "utils/src/FilePathHashSuffix.cpp",
    "utils/src/Environment.cpp",
    "utils/src/Escaping.cpp",
    "utils/src/WideMB.cpp",
    "utils/src/FSNotify.cpp",
    "utils/src/TestPath.cpp",
    "utils/src/PipeIPC.cpp",
    "utils/src/PathParts.cpp",
    "utils/src/CharClasses.cpp",
    "utils/src/POpen.cpp",
    "utils/src/VT256ColorTable.cpp",
    "utils/src/ReadWholeFile.cpp",
    "utils/src/ThrowPrintf.cpp",
    "utils/src/FcntlHelpers.cpp",
    "utils/src/Panic.cpp",
    "utils/src/IntStrConv.cpp",
    "utils/src/EnsureDir.cpp",
    "utils/src/RandomString.cpp",
    "utils/src/MakePTYAndFork.cpp",
};
