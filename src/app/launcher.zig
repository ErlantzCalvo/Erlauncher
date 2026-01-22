const std = @import("std");
const x11 = @import("../x11/c_bindings.zig").x11;
const desktop = @import("desktop.zig");
const config = @import("../config.zig");

pub fn scanDesktopDirectory(allocator: std.mem.Allocator, dir_path: []const u8, apps_list: *std.ArrayListUnmanaged(desktop.AppEntry)) !void {
    const dir = x11.opendir(dir_path.ptr);
    if (dir == null) return;
    defer _ = x11.closedir(dir);

    var entry: [*c]x11.dirent = undefined;
    while (true) {
        entry = x11.readdir(dir);
        if (entry == null) break;

        const name_array = entry.*.d_name[0..256];
        const name = std.mem.sliceTo(name_array, 0);

        if (std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) continue;

        if (std.mem.endsWith(u8, name, ".desktop")) {
            const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir_path, name });
            defer allocator.free(full_path);

            if (desktop.loadDesktopFile(allocator, full_path)) |app| {
                try apps_list.append(allocator, app);
            }
        }
    }
}

pub fn loadSystemApplications(allocator: std.mem.Allocator) !std.ArrayListUnmanaged(desktop.AppEntry) {
    var apps_list: std.ArrayListUnmanaged(desktop.AppEntry) = .{};

    const home = x11.getenv("HOME");
    if (home != null) {
        const home_dir = std.mem.sliceTo(home, 0);
        const local_apps = try std.fmt.allocPrint(allocator, "{s}/.local/share/applications", .{home_dir});
        defer allocator.free(local_apps);
        try scanDesktopDirectory(allocator, local_apps, &apps_list);
    }

    for (config.desktop.paths) |path| {
        try scanDesktopDirectory(allocator, path, &apps_list);
    }

    std.sort.block(desktop.AppEntry, apps_list.items, {}, struct {
        fn compare(_: void, a: desktop.AppEntry, b: desktop.AppEntry) bool {
            return std.ascii.lessThanIgnoreCase(a.name, b.name);
        }
    }.compare);

    return apps_list;
}

pub fn launchApplication(allocator: std.mem.Allocator, exec_cmd: []const u8) !void {
    std.debug.print("Launching: {s}\n", .{exec_cmd});

    const sanitized_exec = try desktop.sanitizeExec(exec_cmd, allocator);
    defer allocator.free(sanitized_exec);

    const pid = x11.fork();
    if (pid < 0) {
        std.debug.print("Fork failed\n", .{});
        return error.ForkFailed;
    }

    if (pid == 0) {
        const result = x11.execlp("sh", "sh", "-c", sanitized_exec.ptr, @as([*c]const u8, null));
        _ = result;
        x11._exit(1);
    }
}
