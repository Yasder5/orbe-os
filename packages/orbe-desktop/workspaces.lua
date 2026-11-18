-- Espaces de travail propres à chaque écran.
-- L'écran n (0 pour le premier, 1 pour le second…) utilise les espaces n×10+1 à n×10+9 :
-- Super + 1 à 9 agit toujours sur l'écran qui a le focus, et la barre de chaque écran
-- n'affiche que les siens. Les chiffres sont liés aux codes de touches (code:10 à code:18) :
-- en AZERTY ils demandent Maj, mais la touche physique reste la même.

local function base(monitor)
    return (monitor and monitor.id or 0) * 10
end

local function active_base()
    return base(hl.get_active_monitor())
end

for i = 1, 9 do
    local key = "code:" .. (9 + i)
    hl.bind("SUPER + " .. key, function()
        hl.dispatch(hl.dsp.focus({ workspace = active_base() + i }))
    end, { description = "Aller à l'espace de travail " .. i })
    hl.bind("SUPER + SHIFT + " .. key, function()
        hl.dispatch(hl.dsp.window.move({ workspace = active_base() + i }))
    end, { description = "Envoyer la fenêtre sur l'espace " .. i })
end

hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Un écran ajouté démarre sur son premier espace (11 pour le deuxième écran, 21 pour le troisième…).
local function start_on_own_workspace(monitor)
    if monitor and monitor.id and monitor.id > 0 then
        pcall(function() monitor:set_workspace(base(monitor) + 1) end)
    end
end

hl.on("monitor.added", start_on_own_workspace)
hl.on("hyprland.start", function()
    for _, monitor in ipairs(hl.get_monitors()) do
        start_on_own_workspace(monitor)
    end
end)
