# Welcome to mi-shell
This is my version of a quickshell bar and tools.

It is vertical and for now there is no settings panel, everything is done via the config files. This may change over time but I am just setting this up for me. 

This started off as project to use https://github.com/doannc2212/quickshell-config instead of the legacy Noctalia.

It ended up becoming an new system which is growing as I get the time. 

It has pinned apps with chosen icons, the icon lights up when in use and dims when closed. Running apps appear below. 

![The main Bar](assets/bar.png)

The pop out calendar links directly to khal and the system widget has information.

![Popout Widgets from the main bar](assets/widgets.png)

![The application launcher](assets/launcher.png)

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
- swayidle
- awww

optional, depending on which modules you use:

- `brightnessctl` — for brightness display and control in the bar and OSD
- `nmcli` — for wifi network info from the tray
- `/sys/class/power_supply/` — for battery info (standard on most laptops)
- `swww` — for the wallpaper manager
- blueman - bluetooth control
- khal - Calendar app
- Vdirsyncer - to sync the calendar data

