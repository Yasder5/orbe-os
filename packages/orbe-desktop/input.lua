-- Clavier, souris et pavé tactile.

-- Disposition du clavier : celle choisie à l'installation (/etc/X11/xorg.conf.d/00-keyboard.conf,
-- écrit par Calamares ou localectl), AZERTY sinon (session live).
local layout, variant = "fr", ""
pcall(function()
    local f = io.open("/etc/X11/xorg.conf.d/00-keyboard.conf", "r")
    if f then
        local text = f:read("*a")
        f:close()
        layout = text:match('"XkbLayout"%s+"([^"]+)"') or layout
        variant = text:match('"XkbVariant"%s+"([^"]*)"') or variant
    end
end)

hl.config({
    input = {
        kb_layout  = layout,
        kb_variant = variant,
        kb_options = "",
        numlock_by_default = true,
        follow_mouse = 1,
        -- Pas d'accélération de la souris : la visée reste constante en jeu.
        accel_profile = "flat",
        sensitivity   = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
        },
    },
})

-- Trois doigts à l'horizontale : espace de travail suivant ou précédent.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
