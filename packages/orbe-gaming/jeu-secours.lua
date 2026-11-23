-- Mode jeu de secours d'Orbe OS : Steam en mode Big Picture, en plein écran dans Hyprland,
-- quand gamescope ne fonctionne pas sur ce PC. Lancé par orbe-game-session :
--   start-hyprland -- --config /usr/share/orbe/hypr/jeu-secours.lua
-- Pas de barre ni d'Orbe Shell : Steam seul, sans animation, déchirement autorisé.

local base = "/usr/share/orbe/hypr/"
require(base .. "environment")
require(base .. "input")

hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })

hl.config({
    general = { gaps_in = 0, gaps_out = 0, border_size = 0, allow_tearing = true },
    decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } },
    animations = { enabled = false },
    misc = {
        vrr = 1,
        background_color = "rgb(0a0a0a)",
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

-- Toutes les fenêtres en plein écran, les jeux en présentation immédiate.
hl.window_rule({ name = "secours-plein-ecran", match = { class = ".*" }, fullscreen = true })
hl.window_rule({ name = "secours-jeux-immediat", match = { class = "^steam_app_.*" }, immediate = true })

-- Secours : Super + Maj + M quitte (retour au bureau par orbe-session).
hl.bind("SUPER + SHIFT + M", hl.dsp.exit())

hl.on("hyprland.start", function()
    -- Quand Steam se ferme (« Revenir au bureau » ou plantage), la session se termine.
    hl.exec_cmd("sh -c 'steam -gamepadui -steamos3 -steampal; hyprctl dispatch \"hl.dsp.exit()\"'")
end)
