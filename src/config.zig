const std = @import("std");

pub const window = struct {
    pub const width: i32 = 600;
    pub const height: i32 = 400;
    pub const corner_radius: i32 = 12;
    pub const border_width: i32 = 1;
};

pub const ui = struct {
    pub const input_height: i32 = 50;
    pub const item_height: i32 = 28;
    pub const max_visible_items: usize = 10;
    pub const text_buffer_size: usize = 1024;
};

pub const layout = struct {
    pub const list_start_y_offset: i32 = 20;
    pub const padding_x: i32 = 10;
    pub const text_offset_y: i32 = 5;
    pub const selection_padding_top: i32 = 2;
    pub const selection_padding_bottom: i32 = 2;
    pub const window_height_proximity_factor: i32 = 100;
    pub const window_height_extra_offset: i32 = 400;
};

pub const font = struct {
    pub const name = "DejaVu Sans-14";
};

pub const colors = struct {
    pub const selection_red: u16 = 30056;
    pub const selection_green: u16 = 34152;
    pub const selection_blue: u16 = 61440;
    pub const window_red: u16 = 65535;
    pub const window_green: u16 = 65535;
    pub const window_blue: u16 = 65535;
    pub const border_red: u16 = 0;
    pub const border_green: u16 = 0;
    pub const border_blue: u16 = 0;
};

pub const desktop = struct {
    pub const paths = [_][]const u8{
        "/usr/share/applications",
        "/usr/local/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        "/var/lib/snapd/desktop/applications",
    };
};

test "window dimensions" {
    try std.testing.expectEqual(@as(i32, 600), window.width);
    try std.testing.expectEqual(@as(i32, 400), window.height);
    try std.testing.expectEqual(@as(i32, 12), window.corner_radius);
    try std.testing.expectEqual(@as(i32, 1), window.border_width);
}

test "ui configuration" {
    try std.testing.expectEqual(@as(i32, 50), ui.input_height);
    try std.testing.expectEqual(@as(i32, 28), ui.item_height);
    try std.testing.expectEqual(@as(usize, 10), ui.max_visible_items);
    try std.testing.expectEqual(@as(usize, 1024), ui.text_buffer_size);
}

test "layout configuration" {
    try std.testing.expectEqual(@as(i32, 20), layout.list_start_y_offset);
    try std.testing.expectEqual(@as(i32, 10), layout.padding_x);
    try std.testing.expectEqual(@as(i32, 5), layout.text_offset_y);
    try std.testing.expectEqual(@as(i32, 2), layout.selection_padding_top);
    try std.testing.expectEqual(@as(i32, 2), layout.selection_padding_bottom);
}

test "font configuration" {
    try std.testing.expectEqualStrings("DejaVu Sans-14", font.name);
}

test "desktop paths" {
    try std.testing.expectEqual(@as(usize, 4), desktop.paths.len);
}
