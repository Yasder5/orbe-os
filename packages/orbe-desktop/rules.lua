-- Règles de fenêtres et de calques.

-- Flou léger derrière les panneaux d'Orbe Shell (calques nommés orbe-*), pas derrière les fenêtres.
hl.layer_rule({
    name         = "orbe-shell-blur",
    match        = { namespace = "^orbe-.*" },
    blur         = true,
    ignore_alpha = 0.2,
})

-- Jeux Steam : tearing autorisé pour réduire la latence, s'ils le demandent.
hl.window_rule({
    name      = "jeux-steam-tearing",
    match     = { class = "^steam_app_.*" },
    immediate = true,
})

-- Les fenêtres ne demandent pas à se maximiser d'elles-mêmes.
hl.window_rule({
    name           = "sans-maximisation-auto",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Glisser-déposer XWayland : évite le vol de focus par les fenêtres fantômes.
hl.window_rule({
    name  = "xwayland-glisser",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
