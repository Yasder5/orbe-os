-- Configuration Hyprland d'Orbe OS (valeurs par défaut du système).
-- Ne modifie pas ce fichier : il est remplacé à chaque mise à jour du paquet orbe-desktop.
-- Tes réglages vont dans ~/.config/hypr/hyprland.lua, après la ligne qui charge ce fichier.
--
-- Chaque module est chargé à part : une erreur dans l'un n'empêche pas les autres de s'appliquer.

local base = "/usr/share/orbe/hypr/"

require(base .. "environment")
require(base .. "look")
require(base .. "input")
require(base .. "binds")
require(base .. "workspaces")
require(base .. "rules")
require(base .. "autostart")

-- Réglages propres au matériel (pilote NVIDIA, etc.), générés au démarrage s'ils existent.
pcall(require, "/run/orbe/hypr-hardware")

-- Réglages faits dans l'application « Réglages Orbe » (écrans, clavier, souris, pavé tactile),
-- réécrits par elle dans ~/.config/orbe/hyprland.lua, puis appliqués par hyprctl reload.
local home = os.getenv("HOME")
if home then
    pcall(require, home .. "/.config/orbe/hyprland")
    -- Couleur d'accent choisie dans Réglages Orbe (Apparence), écrite par orbe-accent.
    pcall(require, home .. "/.config/orbe/couleurs")
end
