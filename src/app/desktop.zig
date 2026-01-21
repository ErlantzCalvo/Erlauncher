const std = @import("std");
const x11 = @import("../x11/c_bindings.zig").x11;

pub const AppEntry = struct {
    name: []const u8,
    exec: []const u8,
};

pub fn loadDesktopFile(allocator: std.mem.Allocator, path: []const u8) ?AppEntry {
    const file = x11.fopen(path.ptr, "r");
    if (file == null) return null;
    defer _ = x11.fclose(file);

    var buffer: [4096]u8 = undefined;
    var name: ?[]const u8 = null;
    var exec: ?[]const u8 = null;
    var no_display = false;
    var in_desktop_entry = false;

    while (x11.fgets(&buffer[0], @intCast(buffer.len), file) != null) {
        const line = std.mem.sliceTo(buffer[0..], 0);
        const trimmed = std.mem.trim(u8, line, " \t\r\n");

        if (std.mem.eql(u8, trimmed, "[Desktop Entry]")) {
            in_desktop_entry = true;
            continue;
        }

        if (std.mem.startsWith(u8, trimmed, "[") and !std.mem.eql(u8, trimmed, "[Desktop Entry]")) {
            if (in_desktop_entry) {
                break;
            }
            continue;
        }

        if (!in_desktop_entry) {
            continue;
        }

        if (std.mem.startsWith(u8, line, "Name=")) {
            if (name) |n| allocator.free(n);
            name = allocator.dupe(u8, std.mem.trim(u8, line["Name=".len..], " \t\r\n")) catch null;
        } else if (std.mem.startsWith(u8, line, "Exec=")) {
            if (exec) |e| allocator.free(e);
            const exec_str = std.mem.trim(u8, line["Exec=".len..], " \t\r\n");
            exec = allocator.dupe(u8, exec_str) catch null;
        } else if (std.mem.startsWith(u8, line, "NoDisplay=true") or std.mem.startsWith(u8, line, "Hidden=true")) {
            no_display = true;
            break;
        }
    }

    if (no_display or name == null or exec == null) {
        if (name) |n| allocator.free(n);
        if (exec) |e| allocator.free(e);
        return null;
    }

    return AppEntry{ .name = name.?, .exec = exec.? };
}

pub fn sanitizeExec(exec_cmd: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    var result: std.ArrayListUnmanaged(u8) = .{};
    defer result.deinit(allocator);

    var i: usize = 0;
    while (i < exec_cmd.len) : (i += 1) {
        if (i < exec_cmd.len - 1 and exec_cmd[i] == '%') {
            const next_char = exec_cmd[i + 1];
            if (std.ascii.isAlphanumeric(next_char)) {
                i += 1;
                continue;
            }
        }
        try result.append(allocator, exec_cmd[i]);
    }

    return allocator.dupe(u8, result.items);
}

test "sanitizeExec removes percent codes" {
    const input = "firefox %u %F";
    const expected = "firefox ";

    const result = try sanitizeExec(input, std.testing.allocator);
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "sanitizeExec handles multiple percent codes" {
    const input = "app %f %u %d";
    const expected = "app ";

    const result = try sanitizeExec(input, std.testing.allocator);
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "sanitizeExec keeps regular percent signs" {
    const input = "app %test%";
    const expected = "app %test%";

    const result = try sanitizeExec(input, std.testing.allocator);
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "sanitizeExec handles empty input" {
    const input = "";
    const expected = "";

    const result = try sanitizeExec(input, std.testing.allocator);
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}

test "sanitizeExec keeps normal characters" {
    const input = "normal-command --arg value";
    const expected = "normal-command --arg value";

    const result = try sanitizeExec(input, std.testing.allocator);
    defer std.testing.allocator.free(result);

    try std.testing.expectEqualStrings(expected, result);
}
