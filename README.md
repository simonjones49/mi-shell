# Welcome to mi-shell
This is my version of a quickshell bar and tools.



![The Desktop view](assets/desktop.png)

It is vertical and for now there is no settings panel, everything is done via the config files. This may change over time but I am just setting this up for me. 

This started off as project to use something instead of the legacy Noctalia.

It ended up becoming a new system which is growing as I get the time. 

It has pinned apps with chosen icons, the icon lights up when in use and dims when closed. Running apps appear below. The top button opens the control panel, the next opens the media panel and the coffee cup lights up when the system is sleep inhibited. You can also click the cup to toggle the state.

![The main Bar](assets/bar.png)

The pop out calendar links directly to khal.



![Calendar and Agenda](assets/calendar.png)



 and the system info has information about the distribution, kernel, uptime and disks.

![System information](assets/sys-info.png)

The Control panel has easy access to networks, vpns, bluetooth, wallpaper, themes, sound and session menu.

![Control Centre](assets/controlcentre.png)

The wallpaper manager can change, preview and set the desktop wallpaper.

![Wallpaper Manager](assets/wallpapermanager.png)

There are lots of themes, instantly updated for a live preview, this will theme the desktop, kitty and qutebrowser.

![Theme manager](assets/thememanager.png)

The launcher has a text filter and you can use the mouse.

![The application launcher](assets/launcher.png)

The Session menu allow you to close the session cleanly. 

![Session menu](assets/sessionmenu.png)


The notifications are also theme aware.

![Notification](assets/notification.png)

There is a "sticky" media panel which sits next to the bar on top of other windows so you can control your media without changing workspace.

![Media Panel](assets/mediapanel.png)

Now has USB drive management. You can mount, unmount and power off from the button on the bar.

![USB Popup](assets/usb.png)

Wifi Network manager

![Wifi Manager](assets/wifimanager.png)

VPN manager

![VPN Manager](assets/vpnmanager.png)


## What currently works

| Module | What it does |
|--------|-------------|
| **Bar** | clock, workspaces, pinned apps and running apps, volume, brightness, network, system tray |
| **App Launcher** | rofi style application launcher |
| **Notifications** | mako-style notification daemon with popups |
| **OSD** | on-screen display for volume and brightness changes, auto-hides |
| **Theme Switcher** | 206 themes across 6 families, persists across restarts. Now themes the desktop, kitty and qutebrowser with hot reload for instant changes |
| **Wallpaper Manager** | grid picker for wallpapers, preview, swaybg |
| **Key Lock** | Number and caps lock on the bar |
| **Power Menu** | Shut down, reboot and logout from the bar |
| **Media Panel** | Shows current media playback with album art if available |
| **USB Management** | USB Drives can be mounted, unmounted and powered off. |

## Dependencies

### Required
These will be installed automatically if you use the `PKGBUILD`:

* quickshell-git (AUR)
* qt6-wayland
* qt6-svg
* niri
* polkit-gnome
* swaybg
* swayidle
* swaylock
* libnotify
* pipewire
* brightnessctl
* khal
* networkmanager
* kitty
* udisks2
* ttf-jetbrains-mono-nerd
* network-manager-applet
* blueman
* dolphin
* kate
* pavucontrol
* qutebrowser
* playerctl
* mpv
* mpv-mpris
* python-keyring
* xwayland-satellite

### Optional

* aerc: a TUI email client
* vdirsyncer: Only needed if you want to sync your local khal calendar with Google/CalDAV
* musikcube: Flawless music player with album art MPRIS connection
* keepassxc: A system keyring manager

## Installation

To install **mi-shell** on Arch Linux, use the provided `PKGBUILD`. This will automatically install all necessary dependencies (niri, quickshell-git, etc.).

1. Install quickshell-git

2. Clone this repository, cd into it and then run

   ```makepkg -si```

Cachyos users need to clone the repository and then cd into it, from there run

```paru -Bi . ```

Endeavouros users need to clone the repository and then cd into it, then run

```yay -Bi . ```

All users have to run the mi-shell-setup after installation, this will check or create the niri files and then setup your mi-shell files. If you don't have a wallpaper directory this is also created for you. 

### Niri Configuration
To start the shell and its helper services automatically, a new file is created in  `~/.config/niri/mi-shell.kdl`:


```kdl
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
spawn-at-startup "mi-power"
spawn-at-startup "nm-applet"
spawn-at-startup "quickshell" "-c" "mi-shell"
spawn-at-startup "sh" "-c" "swaybg -i $(cat ~/.config/quickshell/mi-shell/wallpaper.conf) -m fill"
// --- Suggested Keybindings ---
binds {
    // Uncomment these to enable mi-shell shortcuts:
     Mod+D { spawn "qs" "-c" "mi-shell" "ipc" "call" "launcher" "toggle"; }
     Mod+S { spawn "mi-caffeine"; }
     Mod+Plus { consume-or-expel-window-left; }
    Mod+Dead_Grave { consume-or-expel-window-right; }
}
```

It also adds a line into ~/.config/niri/config.kdl

```include "mi-shell.kdl"```

The optional binds are also in the file but please check they do not clash with any existing ones. 

> **Note:** The `mi-shell` command ensures your local configuration directory exists at `~/.config/quickshell/mi-shell/`. The system-wide default configuration is installed at `/etc/xdg/quickshell/mi-shell/`.

You will also need to set something up as your secret tool, I use keepassxc as I got fed up with fighting with gnome-keyring and kwallet. 



Thanks to https://github.com/doannc2212/quickshell-config for the initial inspiration.
