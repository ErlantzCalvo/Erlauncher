const std = @import("std");

pub const Event = union(enum) {
    expose,
    focus_out,
    key_press: struct {
        keysym: c_long,
        bytes: []const u8,
    },
};

pub const Backend = struct {
    vtable: *const VTable,

    pub const VTable = struct {
        run: *const fn (*const Backend, std.mem.Allocator) anyerror!void,
        isAvailable: *const fn () bool,
    };
};
