#!/usr/bin/env bash
# Aperçu rapide d'Orbe Shell sans construire l'ISO : Quickshell lancé depuis shell/ dans un
# compositeur Wayland sans écran (sway, rendu logiciel), dans un conteneur Arch.
# Les modules propres à Hyprland (espaces de travail…) restent vides : seul l'aspect compte ici.
#
# Usage : tools/shell-preview.sh [options]
#   --wait N         secondes avant la capture (défaut : 6)
#   --ipc "CIBLE FONCTION [ARGS]"  appel IPC Quickshell avant la capture, option répétable
#   --run "COMMANDE" commande lancée avant la capture (ex. notify-send), option répétable
#   --pre "COMMANDE" commande lancée avant Quickshell (ex. écrire ~/.config/orbe/shell.json), option répétable
#   --type "TEXTE"   texte tapé au clavier (wtype) avant la capture, option répétable
#   --name NOM       nom de la capture : out/captures/shell-NOM.png (défaut : apercu)
#   --res 1920x1080  définition de l'écran virtuel
#   --greeter        lance l'écran de connexion (greeter.qml) au lieu du bureau
#   --perf N         mesure le processeur utilisé par Quickshell pendant N secondes (après les étapes)
# Journal de Quickshell : out/captures/shell-NOM.log
set -euo pipefail

ROOT=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
wait_s=6 name=apercu res=1920x1080 entry="-c orbe" perf=0
steps=""
pre=""
while (( $# )); do
  case "$1" in
    --wait) wait_s=$2; shift ;;
    --ipc) read -ra words <<< "$2"; steps+="qs -c orbe ipc call $(printf '%q ' "${words[@]}"); sleep 0.8; "; shift ;;
    --run) steps+="$2; sleep 1.5; "; shift ;;
    --pre) pre+="$2; "; shift ;;
    --type) steps+="wtype -d 60 $(printf '%q' "$2"); sleep 1; "; shift ;;
    --name) name=$2; shift ;;
    --res) res=$2; shift ;;
    --greeter) entry="-p /etc/xdg/quickshell/orbe/greeter.qml" ;;
    --perf) perf=$2; shift ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
  shift
done

preview_image=orbe-shell-preview:5
docker_args=(--privileged -v orbe-pacman-cache:/var/cache/pacman/pkg)
if [[ -n "${HTTPS_PROXY:-}${https_proxy:-}" ]]; then
  docker_args+=(--network host -e HTTPS_PROXY="${HTTPS_PROXY:-$https_proxy}" -e https_proxy="${https_proxy:-$HTTPS_PROXY}")
fi
[[ -n "${ORBE_EXTRA_CA:-}" ]] && docker_args+=(-v "$(readlink -f "$ORBE_EXTRA_CA"):/run/orbe-extra-ca.crt:ro")

# Image préparée une fois (sway, Quickshell, grim), puis réutilisée.
if ! docker image inspect "$preview_image" >/dev/null 2>&1; then
  base=""
  for candidate in archlinux:latest orbe-archlinux-bootstrap:latest; do
    docker image inspect "$candidate" >/dev/null 2>&1 && { base=$candidate; break; }
  done
  [[ -n "$base" ]] || { echo "Aucune image Arch : lance d'abord ./build.sh." >&2; exit 1; }
  echo "Préparation de l'image d'aperçu depuis $base..."
  cid=$(docker create "${docker_args[@]}" "$base" bash -c '
    set -e
    if [[ -f /run/orbe-extra-ca.crt ]]; then
      cp /run/orbe-extra-ca.crt /etc/ca-certificates/trust-source/anchors/orbe-extra-ca.crt && update-ca-trust
    fi
    echo "Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
    pacman-key --init >/dev/null 2>&1; pacman-key --populate archlinux >/dev/null 2>&1
    pacman -Syu --noconfirm --needed sway quickshell grim wtype qt6-svg qt6-5compat mesa ttf-jetbrains-mono noto-fonts noto-fonts-emoji libnotify foot htop hicolor-icon-theme adwaita-icon-theme fish starship fastfetch eza bat btop ttf-nerd-fonts-symbols-mono git qt6-shadertools cava playerctl python >/dev/null')
  docker start -a "$cid"
  docker commit "$cid" "$preview_image" >/dev/null
  docker rm "$cid" >/dev/null
fi

mkdir -p "$ROOT/out/captures"

docker run --rm "${docker_args[@]}" \
  -v "$ROOT/shell:/etc/xdg/quickshell/orbe" \
  -v "$ROOT/tools:/orbe/tools:ro" \
  -v "$ROOT/themes:/orbe/themes:ro" \
  -v "$ROOT/packages:/orbe/packages:ro" \
  -v "$ROOT/wallpapers:/orbe/wallpapers:ro" \
  -v "$ROOT/out/captures:/out" \
  -e RES="$res" -e WAIT="$wait_s" -e NAME="$name" -e STEPS="$steps" -e PRE="$pre" -e ENTRY="$entry" -e PERF="$perf" -e HOST_UID="$(id -u)" \
  "$preview_image" dbus-run-session -- bash -c '
    bash /orbe/tools/build-shaders.sh /etc/xdg/quickshell/orbe/shaders
    # Fichiers des paquets orbe-themes et orbe-desktop, pris directement dans le dépôt.
    install -Dm644 -t /usr/share/fonts/orbe /orbe/themes/fonts/*.ttf
    install -Dm644 -t /usr/share/backgrounds/orbe /orbe/wallpapers/rendus/*.png
    install -Dm644 /orbe/themes/terminal/foot-orbe.ini /usr/share/orbe/foot/orbe.ini
    install -Dm644 /orbe/themes/terminal/orbe.fish /usr/share/fish/vendor_conf.d/orbe.fish
    install -Dm644 /orbe/themes/terminal/starship.toml /usr/share/orbe/starship.toml
    install -Dm644 /orbe/themes/terminal/fastfetch.jsonc /usr/share/orbe/fastfetch/config.jsonc
    install -Dm644 /orbe/themes/terminal/orbe-logo.txt /usr/share/orbe/fastfetch/orbe-logo.txt
    install -Dm644 /orbe/themes/terminal/btop-orbe.theme /usr/share/btop/themes/orbe.theme
    install -Dm644 /orbe/packages/orbe-desktop/foot.ini /root/.config/foot/foot.ini
    install -Dm644 /orbe/packages/orbe-desktop/btop.conf /root/.config/btop/btop.conf
    export SHELL=/usr/bin/fish
    fc-cache -f >/dev/null 2>&1
    export XDG_RUNTIME_DIR=/tmp/xdg LANG=C.UTF-8
    mkdir -p -m700 "$XDG_RUNTIME_DIR"
    printf "output HEADLESS-1 resolution %s bg #0a0a0a solid_color\n" "$RES" > /tmp/sway.conf
    WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -c /tmp/sway.conf >/tmp/sway.log 2>&1 &
    for _ in $(seq 50); do ls "$XDG_RUNTIME_DIR" | grep -q "^wayland-[0-9]*$" && break; sleep 0.1; done
    export WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR" | grep -m1 "^wayland-[0-9]*$")
    # Rendu OpenGL sur le processeur (llvmpipe), comme dans une VM sans accélération.
    eval "$PRE"
    LIBGL_ALWAYS_SOFTWARE=1 qs $ENTRY > "/out/shell-$NAME.log" 2>&1 &
    sleep "$WAIT"
    eval "$STEPS"
    if (( PERF > 0 )); then
      # Temps processeur (utilisateur + système) de Quickshell sur PERF secondes, 100 % = un cœur.
      pid=$(pgrep -x qs | head -n1); tck=$(getconf CLK_TCK)
      t0=$(awk "{print \$14+\$15}" /proc/$pid/stat); sleep "$PERF"; t1=$(awk "{print \$14+\$15}" /proc/$pid/stat)
      echo "Quickshell : $(awk -v a=$t0 -v b=$t1 -v t=$tck -v s=$PERF "BEGIN{printf \"%.2f\", (b-a)/t/s*100}") % (100 % = un cœur) sur $PERF s, mémoire $(awk "/VmRSS/{printf \"%d Mo\", \$2/1024}" /proc/$pid/status)"
    fi
    grim "/out/shell-$NAME.png"
    chown "$HOST_UID" "/out/shell-$NAME.png" "/out/shell-$NAME.log" /etc/xdg/quickshell/orbe/shaders/*.qsb
    sed "s/\x1b\[[0-9;]*m//g" "/out/shell-$NAME.log" | grep -E "ERROR|WARN|caused by" | grep -v "locale" | head -20 || true'
echo "Capture : out/captures/shell-$name.png"
