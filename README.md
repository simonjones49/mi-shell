# my quickshell config
This is my version of a quickshell bar and tools.

It is vertical and for now there is no settings panel, everything is done via the config files. This may change over time but I am just setting this up for me. 





## What currently works

| Module | What it does |
|--------|-------------|
| **Bar** | clock, workspaces, pinned apps and running apps, volume, brightness, network, system tray, |
| **App Launcher** | rofi style application launcher |
| **Notifications** | mako-style notification daemon with popups |
| **OSD** | on-screen display for volume and brightness changes, auto-hides |
| **Theme Switcher** | 206 themes across 6 families, persists across restarts |
| **Wallpaper Manager** | grid picker for wallpapers, preview, swww |

## prerequisites

these are needed regardless of which modules you use:

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- niri

optional, depending on which modules you use:

- `brightnessctl` — for brightness display and control in the bar and OSD
- `nmcli` — for wifi network info from the tray
- `/sys/class/power_supply/` — for battery info (standard on most laptops)
- `swww` — for the wallpaper manager
- blueman - bluetooth control

