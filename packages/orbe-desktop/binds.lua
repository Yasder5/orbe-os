-- Raccourcis clavier Orbe (docs/raccourcis.md). Super est la touche principale.
-- Les chiffres sont liés aux codes de touches (code:10 à code:18) : en AZERTY, ils
-- demandent Maj, mais la touche physique reste la même quelle que soit la disposition.

local mod      = "SUPER"
local terminal = "foot"
local files    = "nautilus"
local shell    = "qs -c orbe ipc call "

-- Orbe Shell : Super seul ouvre le lanceur (au relâchement, pour ne pas gêner Super + touche).
hl.bind(mod .. " + Super_L", hl.dsp.exec_cmd(shell .. "launcher toggle"), { release = true, description = "Lanceur d'applications" })
hl.bind(mod .. " + Escape",  hl.dsp.exec_cmd(shell .. "session toggle"),  { description = "Menu de session" })
hl.bind(mod .. " + N",       hl.dsp.exec_cmd(shell .. "center toggle"),   { description = "Centre de notifications" })

-- Applications
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E",      hl.dsp.exec_cmd(files))

-- Fenêtres
hl.bind(mod .. " + Q",     hl.dsp.window.close())
hl.bind(mod .. " + F",     hl.dsp.window.fullscreen())
hl.bind(mod .. " + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + J",     hl.dsp.layout("togglesplit"))

hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Espaces de travail 1 à 9
for i = 1, 9 do
    local key = "code:" .. (9 + i)
    hl.bind(mod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Capture d'une zone : copiée dans le presse-papiers et enregistrée dans ~/Images/Captures.
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(
    "mkdir -p ~/Images/Captures && f=~/Images/Captures/$(date +%Y-%m-%d_%H-%M-%S).png && " ..
    "grim -g \"$(slurp)\" \"$f\" && wl-copy < \"$f\""))

-- Son, luminosité et lecture, y compris écran verrouillé.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
-- Luminosité par Orbe Shell (pour l'OSD), brightnessctl directement si le shell ne répond pas.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(shell .. "brightness up || brightnessctl -e4 -n2 set 5%+"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(shell .. "brightness down || brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
-- Verrouillage majuscules : la touche garde son effet, le shell affiche l'OSD.
hl.bind("Caps_Lock", hl.dsp.exec_cmd(shell .. "keyboard capslock"), { non_consuming = true, locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Quitter la session sans passer par le shell (secours si Orbe Shell ne répond plus).
hl.bind(mod .. " + SHIFT + M", hl.dsp.exit())
