const std = @import("std");
const backend = @import("backend/backend.zig");
const x11_backend = @import("backend/x11.zig").x11_backend;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    if (x11_backend.vtable.isAvailable()) {
        std.debug.print("X11 display detected, using X11...\n", .{});
        try x11_backend.vtable.run(&x11_backend, allocator);
    } else {
        std.debug.print("No display system detected (DISPLAY not set)\n", .{});
        return error.NoDisplaySystem;
    }
}
