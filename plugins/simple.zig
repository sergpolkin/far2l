const std = @import("std");

const INVALID_HANDLE_VALUE = std.os.windows.INVALID_HANDLE_VALUE;

const FarManagerVersion = struct {
    const major = 2;
    const minor = 5;
    fn getVersion() c_int {
        return major << 16 | minor;
    }
};

export fn GetMinFarVersionW() c_int {
    return FarManagerVersion.getVersion();
}

export fn SetStartupInfoW(info: *anyopaque) void {
    _ = info;
}

export fn OpenPluginW(open_from: c_int, item: *c_int) *anyopaque {
    _ = open_from;
    _ = item;
    return INVALID_HANDLE_VALUE;
}

// enum PLUGIN_FLAGS
const PF = struct {
    // early dlopen and initialize plugin
    const PRELOAD = 0x0001;
    const DISABLEPANELS = 0x0002;
    const EDITOR = 0x0004;
    const VIEWER = 0x0008;
    const FULLCMDLINE = 0x0010;
    const DIALOG = 0x0020;
    // early dlopen plugin but initialize it later, when it will be really needed
    const PREOPEN = 0x8000;
};

const PluginInfo = extern struct {
    struct_size: c_int align(1),
    flags: c_uint align(1),
    disk_menu_strings: [*c]const [*c]const u8 align(1),
    reserved0: [*c]c_int align(1),
    disk_menu_strings_number: c_int align(1),
    plugin_menu_strings: [*c]const [*c]const u8 align(1),
    plugin_menu_strings_number: c_int align(1),
    plugin_config_strings: [*c]const [*c]const u8 align(1),
    plugin_config_strings_number: c_int align(1),
    command_prefix: [*c]const u8 align(1),
    sys_id: c_uint align(1),
};

fn toWCHAR(comptime str: []const u8) *const [str.len:0]u32 {
    return comptime blk: {
        const len: usize = str.len;
        var buf: [len:0]u32 = [_:0]u32{0} ** len;
        inline for (str, &buf) |b, *p| {
            p.* = b;
        }
        break :blk &buf;
    };
}

export fn GetPluginInfoW(info: *PluginInfo) void {
    const static = struct {
        var strings: [1][*c]const u32 = undefined;
    };
    info.struct_size = @sizeOf(PluginInfo);
    info.flags = PF.EDITOR | PF.VIEWER;
    info.disk_menu_strings_number = 0;
    static.strings[0] = toWCHAR("Zig simple plugin");
    info.plugin_menu_strings = @ptrCast(&static.strings);
    info.plugin_menu_strings_number = 1;
    info.plugin_config_strings_number = 0;
}
