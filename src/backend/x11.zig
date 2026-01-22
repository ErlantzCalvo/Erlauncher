const std = @import("std");
const x11 = @import("../x11/c_bindings.zig").x11;
const desktop = @import("../app/desktop.zig");
const launcher = @import("../app/launcher.zig");
const ui = @import("../ui/ui.zig");
const config = @import("../config.zig");
const backend = @import("backend.zig");

const X11Backend = struct {
    display: ?*x11.Display = null,
    window: x11.Window = 0,
    screen: ?*x11.Screen = null,
    draw: ?*x11.XftDraw = null,
    font: ?*x11.XftFont = null,
    visual: ?*x11.Visual = null,
    colormap: x11.Colormap = 0,
    gc: ?x11.GC = null,
    running: bool = true,

    fn drawCornerArc(app: *X11Backend, drawable: x11.Drawable, gc: x11.GC, width: i32, height: i32, use_lines: bool) void {
        const radius = config.window.corner_radius;

        var y: i32 = 0;
        while (y < radius) : (y += 1) {
            const dx: i32 = @intFromFloat(@sqrt(@as(f64, @floatFromInt(radius * radius - y * y))));

            if (use_lines) {
                _ = x11.XDrawLine(app.display, drawable, gc, 0, y, radius - dx, y);
                _ = x11.XDrawLine(app.display, drawable, gc, width - radius + dx, y, width, y);
                _ = x11.XDrawLine(app.display, drawable, gc, 0, height - 1 - y, radius - dx, height - 1 - y);
                _ = x11.XDrawLine(app.display, drawable, gc, width - radius + dx, height - 1 - y, width, height - 1 - y);
            } else {
                _ = x11.XDrawPoint(app.display, drawable, gc, radius - dx, y);
                _ = x11.XDrawPoint(app.display, drawable, gc, width - radius + dx, y);
                _ = x11.XDrawPoint(app.display, drawable, gc, radius - dx, height - 1 - y);
                _ = x11.XDrawPoint(app.display, drawable, gc, width - radius + dx, height - 1 - y);
            }
        }

        var x: i32 = 0;
        while (x < radius) : (x += 1) {
            const dy: i32 = @intFromFloat(@sqrt(@as(f64, @floatFromInt(radius * radius - x * x))));

            if (use_lines) {
                _ = x11.XDrawLine(app.display, drawable, gc, x, 0, x, radius - dy);
                _ = x11.XDrawLine(app.display, drawable, gc, width - 1 - x, 0, width - 1 - x, radius - dy);
                _ = x11.XDrawLine(app.display, drawable, gc, x, height - 1 - radius + dy, x, height - 1);
                _ = x11.XDrawLine(app.display, drawable, gc, width - 1 - x, height - 1 - radius + dy, width - 1 - x, height - 1);
            } else {
                _ = x11.XDrawPoint(app.display, drawable, gc, x, radius - dy);
                _ = x11.XDrawPoint(app.display, drawable, gc, width - 1 - x, radius - dy);
                _ = x11.XDrawPoint(app.display, drawable, gc, x, height - 1 - radius + dy);
                _ = x11.XDrawPoint(app.display, drawable, gc, width - 1 - x, height - 1 - radius + dy);
            }
        }
    }

    fn drawBorder(app: *X11Backend, width: i32, height: i32) void {
        if (app.gc) |gc| {
            _ = x11.XSetForeground(app.display, gc, x11.XBlackPixel(app.display, x11.XDefaultScreen(app.display)));
            _ = x11.XSetLineAttributes(app.display, gc, @intCast(config.window.border_width), x11.LineSolid, x11.CapButt, x11.JoinMiter);

            _ = x11.XDrawLine(app.display, app.window, gc, config.window.corner_radius, 0, width - config.window.corner_radius - 1, 0);
            _ = x11.XDrawLine(app.display, app.window, gc, config.window.corner_radius, height - 1, width - config.window.corner_radius - 1, height - 1);
            _ = x11.XDrawLine(app.display, app.window, gc, 0, config.window.corner_radius, 0, height - config.window.corner_radius - 1);
            _ = x11.XDrawLine(app.display, app.window, gc, width - 1, config.window.corner_radius, width - 1, height - config.window.corner_radius - 1);

            drawCornerArc(app, app.window, gc, width, height, false);
        }
    }

    fn drawApplications(app: *X11Backend, ui_state: *ui.State, width: i32, height: i32) void {
        const list_start_y: i32 = config.ui.input_height + config.layout.list_start_y_offset;

        _ = x11.XClearWindow(app.display, app.window);

        var text_color: x11.XftColor = undefined;
        _ = x11.XftColorAllocValue(app.display, app.visual, app.colormap, &x11.XRenderColor{ .red = 0, .green = 0, .blue = 0, .alpha = 65535 }, &text_color);

        var item_color_black: x11.XftColor = undefined;
        _ = x11.XftColorAllocValue(app.display, app.visual, app.colormap, &x11.XRenderColor{ .red = 0, .green = 0, .blue = 0, .alpha = 65535 }, &item_color_black);

        var item_color_white: x11.XftColor = undefined;
        _ = x11.XftColorAllocValue(app.display, app.visual, app.colormap, &x11.XRenderColor{ .red = 65535, .green = 65535, .blue = 65535, .alpha = 65535 }, &item_color_white);

        var sel_bg_color = x11.XColor{ .red = config.colors.selection_red, .green = config.colors.selection_green, .blue = config.colors.selection_blue, .flags = 7, .pixel = 0, .pad = 0 };
        _ = x11.XAllocColor(app.display, app.colormap, &sel_bg_color);

        _ = x11.XftDrawString8(app.draw, &text_color, app.font, config.layout.padding_x, @divTrunc(config.ui.input_height, 2), &ui_state.text_buffer[0], @intCast(ui_state.text_len));

        if (app.gc) |gc| {
            _ = x11.XSetForeground(app.display, gc, x11.XBlackPixel(app.display, x11.XDefaultScreen(app.display)));
            _ = x11.XDrawLine(app.display, app.window, gc, config.layout.padding_x, config.ui.input_height, width - config.layout.padding_x, config.ui.input_height);
        }

        const display_count = @min(ui_state.filtered_count - ui_state.scroll_offset, config.ui.max_visible_items);
        var i: usize = 0;
        while (i < display_count) : (i += 1) {
            const filtered_idx = ui_state.scroll_offset + i;
            const app_idx = ui_state.filtered_indices.items[filtered_idx];
            const app_entry = ui_state.apps.items[app_idx];

            const y: i32 = list_start_y + @as(i32, @intCast(i)) * config.ui.item_height + @divTrunc(config.ui.item_height, 2) + config.layout.text_offset_y;

            if (filtered_idx == ui_state.selected_index) {
                if (app.gc) |gc| {
                    _ = x11.XSetForeground(app.display, gc, sel_bg_color.pixel);
                    _ = x11.XFillRectangle(app.display, app.window, gc, config.layout.padding_x, list_start_y + @as(i32, @intCast(i)) * config.ui.item_height + config.layout.selection_padding_top, @intCast(width - 2 * config.layout.padding_x), @intCast(config.ui.item_height - config.layout.selection_padding_top - config.layout.selection_padding_bottom));
                }
                _ = x11.XftDrawString8(app.draw, &item_color_white, app.font, config.layout.padding_x, y, app_entry.name.ptr, @intCast(app_entry.name.len));
            } else {
                _ = x11.XftDrawString8(app.draw, &item_color_black, app.font, config.layout.padding_x, y, app_entry.name.ptr, @intCast(app_entry.name.len));
            }
        }

        drawBorder(app, width, height);
    }

    fn handleKeyPress(backend_ctx: *X11Backend, ui_state: *ui.State, event: *x11.XEvent, allocator: std.mem.Allocator) !bool {
        const keysym = x11.XLookupKeysym(&event.xkey, 0);

        if (keysym == x11.XK_Escape) {
            backend_ctx.running = false;
            return false;
        } else if (keysym == x11.XK_BackSpace or keysym == x11.XK_Delete) {
            if (ui_state.text_len > 0) {
                ui_state.text_len -= 1;
                ui_state.text_buffer[ui_state.text_len] = 0;
                ui_state.filterApps();
                return true;
            }
        } else if (keysym == x11.XK_Up) {
            if (ui_state.selected_index > 0) {
                ui_state.selected_index -= 1;
                if (ui_state.selected_index < ui_state.scroll_offset) {
                    ui_state.scroll_offset = ui_state.selected_index;
                }
                return true;
            }
        } else if (keysym == x11.XK_Down) {
            if (ui_state.selected_index < ui_state.filtered_count - 1) {
                ui_state.selected_index += 1;
                if (ui_state.selected_index >= ui_state.scroll_offset + config.ui.max_visible_items) {
                    ui_state.scroll_offset += 1;
                }
                return true;
            }
        } else if (keysym == x11.XK_Return) {
            const app_idx = ui_state.filtered_indices.items[ui_state.selected_index];
            const app_entry = ui_state.apps.items[app_idx];
            launcher.launchApplication(allocator, app_entry.exec) catch {};
            backend_ctx.running = false;
            return false;
        } else {
            var keybuf: [32]u8 = undefined;
            const nchars = x11.XLookupString(&event.xkey, &keybuf, keybuf.len, null, null);
            if (nchars > 0 and ui_state.text_len + @as(usize, @intCast(nchars)) <= ui_state.text_buffer.len - 1) {
                @memcpy(ui_state.text_buffer[ui_state.text_len..][0..@as(usize, @intCast(nchars))], keybuf[0..@as(usize, @intCast(nchars))]);
                ui_state.text_len += @as(usize, @intCast(nchars));
                ui_state.text_buffer[ui_state.text_len] = 0;
                ui_state.selected_index = 0;
                ui_state.filterApps();
                return true;
            }
        }

        return false;
    }

    fn runX11(backend_ctx: *X11Backend, allocator: std.mem.Allocator) !void {
        var ui_state = ui.State.init(allocator);
        defer ui_state.deinit();

        backend_ctx.display = x11.XOpenDisplay(null) orelse {
            std.debug.print("Failed to open X11 display\n", .{});
            return error.X11ConnectionFailed;
        };
        defer {
            if (backend_ctx.display != null) {
                _ = x11.XCloseDisplay(backend_ctx.display);
            }
        }

        std.debug.print("Loading applications...\n", .{});
        ui_state.apps = try launcher.loadSystemApplications(allocator);
        std.debug.print("Loaded {} applications\n", .{ui_state.apps.items.len});

        try ui_state.initFilteredIndices();

        std.debug.print("Connected to X11 display\n", .{});

        const screen_num = x11.XDefaultScreen(backend_ctx.display);
        backend_ctx.screen = @ptrCast(x11.XScreenOfDisplay(backend_ctx.display, screen_num));
        backend_ctx.visual = x11.XDefaultVisual(backend_ctx.display, screen_num);
        backend_ctx.colormap = x11.XCreateColormap(backend_ctx.display, x11.XRootWindow(backend_ctx.display, screen_num), backend_ctx.visual, x11.AllocNone);
        defer {
            if (backend_ctx.colormap != 0) {
                _ = x11.XFreeColormap(backend_ctx.display, backend_ctx.colormap);
            }
        }

        const width: c_int = config.window.width;
        const height: c_int = config.window.height;

        const screen_width = x11.DisplayWidth(backend_ctx.display, screen_num);
        const screen_height = x11.DisplayHeight(backend_ctx.display, screen_num);

        const root = x11.XRootWindow(backend_ctx.display, screen_num);
        var x: i32 = @divTrunc(screen_width - width, 2);
        var y: i32 = @divTrunc(screen_height - height - config.layout.window_height_extra_offset - config.layout.window_height_proximity_factor, 2);

        var nmonitors: c_int = 0;
        const monitors = x11.XRRGetMonitors(backend_ctx.display, root, 1, &nmonitors);
        if (monitors != null) {
            defer x11.XRRFreeMonitors(monitors);

            var root_return: x11.Window = undefined;
            var child_return: x11.Window = undefined;
            var root_x: c_int = 0;
            var root_y: c_int = 0;
            var win_x: c_int = 0;
            var win_y: c_int = 0;
            var mask: c_uint = 0;
            var found_monitor = false;

            if (x11.XQueryPointer(backend_ctx.display, root, &root_return, &child_return, &root_x, &root_y, &win_x, &win_y, &mask) != 0) {
                var i: usize = 0;
                while (i < nmonitors) : (i += 1) {
                    const monitor = monitors[i];
                    if (root_x >= monitor.x and root_x < monitor.x + monitor.width and
                        root_y >= monitor.y and root_y < monitor.y + monitor.height)
                    {
                        x = monitor.x + @divTrunc(monitor.width - width, 2);
                        y = monitor.y + @divTrunc(monitor.height, 2);
                        found_monitor = true;
                        break;
                    }
                }
            }

            if (!found_monitor and nmonitors > 0) {
                var primary_monitor_index: ?usize = null;
                var i: usize = 0;
                while (i < nmonitors) : (i += 1) {
                    if (monitors[i].primary != 0) {
                        primary_monitor_index = i;
                        break;
                    }
                }

                const monitor = if (primary_monitor_index) |idx| monitors[idx] else monitors[0];
                x = monitor.x + @divTrunc(monitor.width - width, 2);
                y = monitor.y + @divTrunc(monitor.height, 2);
            }
        }

        var bg_color = x11.XColor{ .red = config.colors.window_red, .green = config.colors.window_green, .blue = config.colors.window_blue, .flags = 7, .pixel = 0, .pad = 0 };
        _ = x11.XAllocColor(backend_ctx.display, backend_ctx.colormap, &bg_color);

        var border_color = x11.XColor{ .red = config.colors.border_red, .green = config.colors.border_green, .blue = config.colors.border_blue, .flags = 7, .pixel = 0, .pad = 0 };
        _ = x11.XAllocColor(backend_ctx.display, backend_ctx.colormap, &border_color);

        var window_attrs: x11.XSetWindowAttributes = undefined;
        window_attrs.background_pixel = bg_color.pixel;
        window_attrs.border_pixel = border_color.pixel;
        window_attrs.event_mask = x11.ExposureMask | x11.KeyPressMask | x11.FocusChangeMask;
        window_attrs.colormap = backend_ctx.colormap;
        window_attrs.override_redirect = 1;

        backend_ctx.window = x11.XCreateWindow(
            backend_ctx.display,
            root,
            x,
            y,
            @intCast(width),
            @intCast(height),
            1,
            x11.XDefaultDepth(backend_ctx.display, screen_num),
            x11.InputOutput,
            backend_ctx.visual,
            x11.CWBackPixel | x11.CWBorderPixel | x11.CWEventMask | x11.CWColormap | x11.CWOverrideRedirect,
            &window_attrs,
        );
        if (backend_ctx.window == 0) {
            std.debug.print("Failed to create X11 window\n", .{});
            return error.WindowCreationFailed;
        }
        defer {
            _ = x11.XUnmapWindow(backend_ctx.display, backend_ctx.window);
            _ = x11.XDestroyWindow(backend_ctx.display, backend_ctx.window);
        }

        if (x11.XStoreName(backend_ctx.display, backend_ctx.window, "Launcher") == 0) {
            std.debug.print("Warning: Failed to set window name\n", .{});
        }

        const wm_name = x11.XInternAtom(backend_ctx.display, "_MOTIF_WM_HINTS", 0);
        if (wm_name != 0) {
            var mwmhints = [5]u32{ 0, 0, 0, 0, 0 };
            mwmhints[0] = 2;
            _ = x11.XChangeProperty(
                backend_ctx.display,
                backend_ctx.window,
                wm_name,
                wm_name,
                32,
                x11.PropModeReplace,
                @ptrCast(&mwmhints),
                5,
            );
        }

        backend_ctx.draw = x11.XftDrawCreate(backend_ctx.display, backend_ctx.window, backend_ctx.visual, backend_ctx.colormap);
        if (backend_ctx.draw == null) {
            std.debug.print("Failed to create Xft draw context\n", .{});
            return error.DrawContextFailed;
        }
        defer {
            x11.XftDrawDestroy(backend_ctx.draw.?);
        }
        backend_ctx.font = x11.XftFontOpenName(backend_ctx.display, screen_num, config.font.name);
        if (backend_ctx.font == null) {
            std.debug.print("Failed to load font: {s}\n", .{config.font.name});
            return error.FontLoadFailed;
        }
        defer {
            x11.XftFontClose(backend_ctx.display, backend_ctx.font.?);
        }
        backend_ctx.gc = x11.XCreateGC(backend_ctx.display, backend_ctx.window, 0, null);
        if (backend_ctx.gc == null) {
            std.debug.print("Failed to create graphics context\n", .{});
            return error.GCCreationFailed;
        }
        defer {
            _ = x11.XFreeGC(backend_ctx.display, backend_ctx.gc.?);
        }

        const mask_pixmap = x11.XCreatePixmap(backend_ctx.display, backend_ctx.window, width, height, 1);
        defer _ = x11.XFreePixmap(backend_ctx.display, mask_pixmap);

        const mask_gc = x11.XCreateGC(backend_ctx.display, mask_pixmap, 0, null);
        defer _ = x11.XFreeGC(backend_ctx.display, mask_gc);

        _ = x11.XSetForeground(backend_ctx.display, mask_gc, 1);
        _ = x11.XFillRectangle(backend_ctx.display, mask_pixmap, mask_gc, 0, 0, width, height);

        _ = x11.XSetForeground(backend_ctx.display, mask_gc, 0);

        drawCornerArc(backend_ctx, mask_pixmap, mask_gc, width, height, true);

        _ = x11.XShapeCombineMask(backend_ctx.display, backend_ctx.window, x11.ShapeBounding, 0, 0, mask_pixmap, x11.ShapeSet);

        if (x11.XMapRaised(backend_ctx.display, backend_ctx.window) == 0) {
            std.debug.print("Warning: Failed to map window\n", .{});
        }
        if (x11.XSetInputFocus(backend_ctx.display, backend_ctx.window, x11.RevertToPointerRoot, x11.CurrentTime) == 0) {
            std.debug.print("Warning: Failed to set input focus\n", .{});
        }
        if (x11.XFlush(backend_ctx.display) == 0) {
            std.debug.print("Warning: Failed to flush display\n", .{});
        }

        while (backend_ctx.running) {
            var event: x11.XEvent = undefined;
            _ = x11.XNextEvent(backend_ctx.display, &event);

            switch (event.type) {
                x11.Expose => {
                    drawApplications(backend_ctx, &ui_state, width, height);
                },
                x11.FocusOut => {
                    backend_ctx.running = false;
                },
                x11.KeyPress => {
                    if (try handleKeyPress(backend_ctx, &ui_state, &event, allocator)) {
                        drawApplications(backend_ctx, &ui_state, width, height);
                    }
                },
                else => {},
            }
        }

        std.debug.print("Goodbye!\n", .{});
    }

    fn isX11Available() bool {
        const env: [*c]const u8 = x11.getenv("DISPLAY");
        return env != null;
    }
};

var x11_backend_instance: X11Backend = .{};

fn run(backend_ptr: *const backend.Backend, allocator: std.mem.Allocator) anyerror!void {
    _ = backend_ptr;
    try x11_backend_instance.runX11(allocator);
}

pub const x11_backend = backend.Backend{
    .vtable = &.{
        .run = run,
        .isAvailable = X11Backend.isX11Available,
    },
};
