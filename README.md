# Erlauncher

A simple application launcher written in Zig that creates a **frameless popup window** on X11 display systems. Search and launch applications from your desktop environment with keyboard navigation.

## Features

- **Frameless window** with rounded corners
- **Keyboard navigation**: Arrow keys to navigate, Enter to launch, Escape to close
- **Real-time filtering**: Type to filter applications by name
- **Multi-monitor aware**: Automatically detects which monitor has the mouse cursor and centers there
- **Application detection**: Loads `.desktop` files from standard system locations

## Prerequisites

Before building this application, you need to install development libraries for X11.

### Installing Development Libraries

The required development packages depend on your Linux distribution:

#### Debian/Ubuntu
```bash
sudo apt-get install libx11-dev libxext-dev libxrandr-dev libxft-dev libfontconfig1-dev libfreetype6-dev
```

#### Fedora/RHEL
```bash
sudo dnf install libX11-devel libXext-devel libXrandr-devel libXft-devel fontconfig-devel freetype-devel
```

#### Arch Linux
```bash
sudo pacman -S libx11 libxext libxrandr libxft fontconfig freetype2
```

## Building

Once you have required dependencies installed, build the project:

```bash
# If Zig is not in your PATH, use the full path
~/zig-linux-x86_64-0.16.0/zig build

# Or if you've added Zig to your PATH
zig build
```

The built executable will be located at `zig-out/bin/erlauncher`.

## Running

To run the application:

```bash
# From project directory
./zig-out/bin/erlauncher

# Or using zig build run
~/zig-linux-x86_64-0.14.0/zig build run
```

## Usage

- **Type**: Start typing to filter applications by name
- **Arrow Up/Down**: Navigate through filtered list
- **Enter**: Launch selected application
- **Escape**: Close the launcher
- **Click outside**: Clicking outside the window closes it

## Window Features

### Centered Window
- Automatically calculates screen center position
- Uses XRandR to detect individual monitors
- Positions window at the cursor's monitor center
- Works correctly with multi-monitor setups

### Frameless Window
- Uses `override_redirect` to bypass window manager decorations
- Sets `_MOTIF_WM_HINTS` to disable decorations
- Sets `_NET_WM_WINDOW_TYPE_NOTIFICATION` to indicate popup nature
- No title bar, no minimize/maximize/close buttons
- Rounded corners using XShape extension

## Display System

The application works with X11 display servers such as:
- X.Org
- XWayland (X11 compatibility layer in Wayland)
- Traditional X11 window managers

To check your current display system type:
```bash
echo $XDG_SESSION_TYPE  # Displays "wayland" or "x11"
```

## Configuration

Window settings are defined in `src/config.zig`:
- Window dimensions: 600x400 pixels
- Corner radius: 12 pixels
- Font: DejaVu Sans 14pt
- Selection color: Blue (#7588F0)

## Setting Keyboard Shortcut

To launch Erlauncher with the Super/Windows key:

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Erlauncher"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "/home/PATH-TO-ERLAUNCHER/zig-out/bin/erlauncher"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "Super_L"
```

To remove:
```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[]"
```

Or use GUI: Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts → + → Add shortcut with name "Erlauncher", command full path, and press Super key.

## Architecture

The project is structured with clear separation of concerns:

```
src/
├── main.zig              # Entry point
├── config.zig            # Configuration constants
├── app/
│   ├── desktop.zig       # .desktop file parsing
│   └── launcher.zig     # Application loading & launching
├── ui/
│   └── ui.zig           # UI state & filtering logic
├── backend/
│   ├── backend.zig       # Backend interface
│   └── x11.zig          # X11 implementation
└── x11/
    └── c_bindings.zig    # X11 C bindings
```

## Notes

- Window appears centered on the active monitor (using XRandR)
- Application loads from standard desktop entry directories
- Press Escape or click outside to close
- Works best with systems having `.desktop` files installed
