-- Lancement de la session : Orbe Shell et les services de bureau.

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c orbe")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)
