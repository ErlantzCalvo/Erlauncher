# Erlauncher

<div align="center">

A fast, lightweight application launcher written in Zig for X11 desktop environments.

[![Zig Version](https://img.shields.io/badge/Zig-0.16.0--dev-red)](https://ziglang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[Demo Video](#demo) • [Installation](#installation) • [Usage](#usage) • [Key Bindings](#key-bindings)

</div>

## Demo

https://github.com/user-attachments/assets/erlauncher_demo.mp4

## Features

- **🚀 Lightweight** - Written in Zig, minimal dependencies, fast startup
- **🎨 Modern UI** - Frameless window with smooth rounded corners
- **⌨️ Keyboard-First** - Arrow keys to navigate, Enter to launch, Escape to close
- **🔍 Real-time Filtering** - Instantly filter applications as you type
- **🖥️ Multi-Monitor Aware** - Detects cursor position and centers on active monitor
- **📦 Auto-Discovery** - Loads `.desktop` files from standard system locations
- **🎯 Focus Handling** - Click outside or lose focus to close

## Tested Platforms

| Platform | Status |
|----------|--------|
| Ubuntu 24.04 | ✅ Tested |
| X11 | ✅ Supported |
| GNOME | ✅ Tested |

## Installation

### Prerequisites

Install required development libraries for X11:

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

### Building

```bash
# Clone the repository
git clone https://github.com/yourusername/erlauncher.git
cd erlauncher

# Build the project
zig build

# The executable will be at: zig-out/bin/erlauncher
```

## Usage

### Running

```bash
# Run directly
./zig-out/bin/erlauncher

# Or use zig build run
zig build run
```

### Setting Up a Keyboard Shortcut (GNOME)

Launch Erlauncher with Super/Windows key:

```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Erlauncher"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "/home/your-path-to/erlauncher/zig-out/bin/erlauncher"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "Super_L"
```

To remove:
```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[]"
```

**GUI Method:** Settings → Keyboard → View and Customize Shortcuts → Custom Shortcuts → + → Add with name "Erlauncher", full command path, and press Super key.

## Key Bindings

| Key | Action |
|-----|--------|
| `Type` | Filter applications by name |
| `Arrow Up` | Navigate up in filtered list |
| `Arrow Down` | Navigate down in filtered list |
| `Enter` | Launch selected application |
| `Escape` | Close launcher |
| `Click outside` | Click outside window closes it |

## Configuration

Window settings are defined in `src/config.zig`:

```zig
// Window dimensions
window.width: 600
window.height: 400
window.corner_radius: 12

// UI settings
ui.input_height: 50
ui.item_height: 28
ui.max_visible_items: 10

// Font
font.name: "DejaVu Sans-14"

// Colors
colors.selection: #7588F0
```

## Architecture

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

## Technical Details

### Window Features

- **Centered Window**: Calculates screen center using XRandR to detect individual monitors
- **Frameless**: Uses `override_redirect` and `_MOTIF_WM_HINTS` for window decoration bypass
- **Rounded Corners**: Smooth corners implemented via XShape extension
- **Multi-Monitor**: Positions window at cursor's monitor center for optimal UX

### Display System Support

Works with X11-based display servers:

- ✅ X.Org
- ✅ XWayland (X11 compatibility layer in Wayland)
- ✅ Traditional X11 window managers

Check your display system:
```bash
echo $XDG_SESSION_TYPE  # Displays "wayland" or "x11"
```

### Application Loading

Scans standard desktop entry directories:
- `~/.local/share/applications`
- `/usr/share/applications`
- `/usr/local/share/applications`
- `/var/lib/flatpak/exports/share/applications`
- `/var/lib/snapd/desktop/applications`

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
