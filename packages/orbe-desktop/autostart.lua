-- Lancement de la session : Orbe Shell et les services de bureau.

hl.on("hyprland.start", function()
    hl.exec_cmd("orbe-first-login")
    hl.exec_cmd("qs -c orbe")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- Veille automatique (pas dans la session live) et filtre de lumière bleue, neutre au départ.
    hl.exec_cmd("orbe-idle")
    hl.exec_cmd("hyprsunset --identity")
    -- Historique du presse-papiers (Super + V) : texte et images.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
