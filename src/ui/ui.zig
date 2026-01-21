const std = @import("std");
const desktop = @import("../app/desktop.zig");
const config = @import("../config.zig");

pub const State = struct {
    text_buffer: [config.ui.text_buffer_size]u8 = [_]u8{0} ** config.ui.text_buffer_size,
    text_len: usize = 0,
    selected_index: usize = 0,
    scroll_offset: usize = 0,
    apps: std.ArrayListUnmanaged(desktop.AppEntry) = .{},
    filtered_indices: std.ArrayListUnmanaged(usize) = .{},
    filtered_count: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) State {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *State) void {
        for (self.apps.items) |item| {
            self.allocator.free(item.name);
            self.allocator.free(item.exec);
        }
        self.apps.deinit(self.allocator);
        self.filtered_indices.deinit(self.allocator);
    }

    pub fn filterApps(self: *State) void {
        const search_text = self.text_buffer[0..self.text_len];

        self.filtered_indices.clearRetainingCapacity();

        if (self.text_len == 0) {
            var i: usize = 0;
            while (i < self.apps.items.len) : (i += 1) {
                self.filtered_indices.append(self.allocator, i) catch {};
            }
        } else {
            var i: usize = 0;
            while (i < self.apps.items.len) : (i += 1) {
                if (std.ascii.indexOfIgnoreCase(self.apps.items[i].name, search_text) != null) {
                    self.filtered_indices.append(self.allocator, i) catch {};
                }
            }
        }

        self.filtered_count = self.filtered_indices.items.len;
        self.scroll_offset = 0;

        if (self.selected_index >= self.filtered_count) {
            self.selected_index = if (self.filtered_count > 0) self.filtered_count - 1 else 0;
        }
    }

    pub fn initFilteredIndices(self: *State) !void {
        var i: usize = 0;
        while (i < self.apps.items.len) : (i += 1) {
            try self.filtered_indices.append(self.allocator, i);
        }
        self.filtered_count = self.filtered_indices.items.len;
        self.scroll_offset = 0;
    }
};
