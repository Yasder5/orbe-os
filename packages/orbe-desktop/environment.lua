-- Variables d'environnement de la session Orbe.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Applications Qt et Electron en Wayland natif, avec repli X11 si besoin.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- /usr/share/orbe en premier : entrées du lanceur masquées ou retouchées par Orbe.
hl.env("XDG_DATA_DIRS", "/usr/share/orbe:" .. (os.getenv("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"))

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
