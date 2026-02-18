# Issues using Niri

Quite the struggle with Niri + DMS (Quickshell) to have the same functionality as KDE Plasma.
Went as far as to create alternative sessions, custom portal configurations, used `qt5ct` and `qt6ct`, etc.
Initially there was way more configuration and hacks, but I managed to fix most of them.

1. [ ] Zeditor in Wayland: when opening a new window, it gets stuck unless resized. Hack: after resize, will work fine. Possible future fix <https://github.com/zed-industries/zed/pull/46758>
2. [ ] Zeditor in X11 via xwayland-satellite (`WAYLAND_DISPLAY= zeditor`): opens fine, but clipboard not working outside of it, in wayland. TODO: find a workaround this or wait for the above fix?
3. [ ] Minor: sometimes DMS menus/tooltips go all the way to the left of the screen. Noticed after a full screen app (game) but not sure.
4. [ ] Proper monitor sleep support requires latest git QuckShell, and while it does work, sometimes it crashes waking up 
5. [x] Bottles: if started from DMS Launcher does not display the main window. It works well started from terminal or KLauncher (that I preffer). Fix: disable HDR via `ENABLE_HDR_WSI=0` env variable.
6. [x] Use KDE consistent look and feel. This was a lot of headache, as the Internet recommend `qt6ct`. This creates more problems, does not work well. I ended up not using it, instead:
   - Set `QT_QPA_PLATFORMTHEME=kde` - see [qt.conf](symlink/~/.config/environment.d/qt.conf)
   - Set [niri-portals.conf](symlink/~/.config/xdg-desktop-portal/niri-portals.conf) to use `kde` portals
7. [x] System tray icons did not show for autostart apps. Set up dms as a service start to start before `xdg-desktop-autostart`. See [dms.service](symlink/~/.config/systemd/user/dms.service)
8. [x] Use KDE polkit agent for step-up authentication dialogs. See [config.kdl](symlink/~/.config/niri/config.kdl)
9. [x] Screen capture / screen sharing was not working. Had to set `org.freedesktop.impl.portal.ScreenCast=wlr` in [niri-portals.conf](symlink/~/.config/xdg-desktop-portal/niri-portals.conf)
10. [x] Full screen apps (games) had a mouse issue, either not working well, or being limited to edges narrower than the screen, in multi monitor setup. Workaround: set the current display to edge `0,0`. See <https://github.com/Supreeeme/xwayland-satellite/issues/66#issuecomment-2445031344>. This is a more than 2 year issue so it will probably never be properly fixed. The predicated `gamescope` solutions are trash, I do not use gamescope at all, prefer maximum performance running games directly.
11. [x] Media controls: `dms ipc mpris playPasue` and in fact `qs -c /usr/share/quickshell/dms ipc call mpris playPause` just pauses, next/previous do not work calling them like that. Fixed using `playerctl`
