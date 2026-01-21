pub const x11 = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
    @cInclude("stdlib.h");
    @cInclude("unistd.h");
    @cInclude("dirent.h");
    @cInclude("stdio.h");
    @cInclude("X11/extensions/Xrandr.h");
    @cInclude("X11/Xft/Xft.h");
    @cInclude("fontconfig/fontconfig.h");
    @cInclude("X11/extensions/shape.h");
});
