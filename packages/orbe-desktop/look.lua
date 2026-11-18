-- Apparence : palette, rayons et animations Orbe (docs/PROMPT.md, section 1).
-- accent #d3fd50, line #262624, fond #0a0a0a, ombre 0 18px 40px rgba(0,0,0,.55).

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = "rgb(d3fd50)",
            inactive_border = "rgb(262624)",
        },
        resize_on_border = true,
        -- Autorise le tearing pour les jeux qui le demandent (règle « immediate » dans rules.lua).
        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,
        shadow = {
            enabled      = true,
            range        = 40,
            render_power = 3,
            offset       = { 0, 18 },
            color        = "rgba(0000008c)",
        },
        -- Flou léger, appliqué seulement aux panneaux du shell (voir rules.lua).
        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.1,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "rgb(0a0a0a)",
        -- Fréquence variable (FreeSync, G-Sync compatible) seulement en plein écran : idéal pour les jeux.
        vrr                      = 2,
        focus_on_activate        = true,
    },

    ecosystem = {
        no_update_news  = true,
        no_donation_nag = true,
    },
})

-- Courbe Orbe cubic-bezier(.2,.8,.2,1). Vitesses en dixièmes de seconde : 1,5 = 150 ms, 3 = 300 ms, 6 = 600 ms.
hl.curve("orbe", { type = "bezier", points = { {0.2, 0.8}, {0.2, 1} } })

hl.animation({ leaf = "global",      enabled = true, speed = 3,   bezier = "orbe" })
hl.animation({ leaf = "border",      enabled = true, speed = 1.5, bezier = "orbe" })
-- Ouverture en fondu avec une légère mise à l'échelle, sans rebond.
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3,   bezier = "orbe", style = "popin 94%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1.5, bezier = "orbe", style = "popin 94%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3,   bezier = "orbe" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3,   bezier = "orbe" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3,   bezier = "orbe", style = "fade" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3,   bezier = "orbe", style = "slidefade 6%" })
