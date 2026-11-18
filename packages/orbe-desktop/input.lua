-- Clavier, souris et pavé tactile.

hl.config({
    input = {
        kb_layout  = "fr",
        kb_variant = "",
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
