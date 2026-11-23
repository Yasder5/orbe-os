# Terminal Orbe : couleurs de fish, invite Starship, fastfetch à l'ouverture, ls et bat en couleurs.
# Chargé par fish pour tous les comptes (vendor_conf.d). Pour s'en passer : variables ou fonctions
# du même nom dans ~/.config/fish/config.fish, qui est lu après ce fichier.

status is-interactive; or return

# Couleurs de la saisie (palette Orbe)
set -g fish_color_normal f5f5f0
set -g fish_color_command d3fd50
set -g fish_color_keyword d3fd50 --bold
set -g fish_color_param f5f5f0
set -g fish_color_option c9c9c3
set -g fish_color_quote f5d76e
set -g fish_color_redirection 7cb4ff
set -g fish_color_end 7cb4ff
set -g fish_color_operator 6fdcd2
set -g fish_color_escape 6fdcd2
set -g fish_color_comment 8f8f8a --italics
set -g fish_color_error ff6b5a
set -g fish_color_autosuggestion 6f6f6a
set -g fish_color_valid_path --underline
set -g fish_color_selection 0a0a0a --background=d3fd50
set -g fish_color_search_match --background=262624
set -g fish_pager_color_prefix d3fd50 --bold
set -g fish_pager_color_completion f5f5f0
set -g fish_pager_color_description 8f8f8a
set -g fish_pager_color_progress 0a0a0a --background=d3fd50
set -g fish_pager_color_selected_background --background=262624

# Couleur d'accent choisie dans Réglages Orbe (Apparence) : copie recolorée des lignes ci-dessus,
# écrite par orbe-accent. Absente pour le citron.
set -l orbe_couleurs ~/.config/orbe/couleurs
set -q XDG_CONFIG_HOME; and set orbe_couleurs $XDG_CONFIG_HOME/orbe/couleurs
test -r $orbe_couleurs/couleurs.fish; and source $orbe_couleurs/couleurs.fish

# ls et eza : couleurs ANSI, donc celles de la palette du terminal.
set -gx LS_COLORS "di=1;34:ln=36:so=35:pi=33:ex=1;32:bd=33;1:cd=33;1:su=30;41:sg=30;43:tw=30;42:ow=34;42:or=31:mi=31:*.tar=35:*.zip=35:*.zst=35:*.gz=35:*.xz=35:*.7z=35:*.iso=35:*.png=95:*.jpg=95:*.webp=95:*.mp4=95:*.mkv=95:*.mp3=96:*.flac=96:*.md=37:*.pdf=33"
set -gx EZA_COLORS "da=90:uu=37:gu=37:sn=37:sb=90"
set -gx BAT_THEME ansi

if type -q eza
    alias ls "eza --group-directories-first --icons=auto"
    alias ll "eza -l --group-directories-first --icons=auto --git --time-style=relative"
    alias la "eza -la --group-directories-first --icons=auto --git --time-style=relative"
    alias tree "eza --tree --icons=auto"
end

# fastfetch avec le logo Orbe, sauf si l'utilisateur a sa propre configuration.
function fastfetch --wraps fastfetch
    # Copie aux couleurs choisies dans Réglages Orbe (écrite par orbe-accent), sinon celle d'Orbe.
    set -l recoloree ~/.config/orbe/couleurs/fastfetch.jsonc
    set -q XDG_CONFIG_HOME; and set recoloree $XDG_CONFIG_HOME/orbe/couleurs/fastfetch.jsonc
    if test -e ~/.config/fastfetch/config.jsonc
        command fastfetch $argv
    else if test -r $recoloree
        command fastfetch --config $recoloree $argv
    else
        command fastfetch --config /usr/share/orbe/fastfetch/config.jsonc $argv
    end
end

# Accueil : fastfetch dans le premier terminal ouvert de la session, si la fenêtre est assez large.
# La fenêtre peut s'ouvrir petite puis grandir : on relit la largeur réelle un instant plus tard.
function fish_greeting
    set -l marker $XDG_RUNTIME_DIR/orbe-terminal-accueil
    test -n "$XDG_RUNTIME_DIR"; and not test -e $marker; or return
    set -l cols $COLUMNS
    if test $cols -lt 90
        sleep 0.2
        set cols (tput cols 2>/dev/null; or echo $COLUMNS)
    end
    if test $cols -ge 90
        touch $marker
        fastfetch
    end
end

# Invite Starship (configuration Orbe, sauf ~/.config/starship.toml).
if type -q starship
    if not test -e ~/.config/starship.toml
        set -gx STARSHIP_CONFIG /usr/share/orbe/starship.toml
        test -r $orbe_couleurs/starship.toml; and set -gx STARSHIP_CONFIG $orbe_couleurs/starship.toml
    end
    starship init fish | source
end
