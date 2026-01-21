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

pub const font = struct {
    pub const name = "DejaVu Sans-14";
};

pub const colors = struct {
    pub const selection_red: u16 = 30056;
    pub const selection_green: u16 = 34152;
    pub const selection_blue: u16 = 61440;
};

pub const desktop = struct {
    pub const paths = [_][]const u8{
        "/usr/share/applications",
        "/usr/local/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        "/var/lib/snapd/desktop/applications",
    };
};
