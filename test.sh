#!/usr/bin/env bash
# Lance l'ISO Orbe OS ou un disque installé dans QEMU.
# Usage : ./test.sh [options]
#   --bios               démarrage BIOS (défaut : UEFI)
#   --iso FICHIER        ISO à lancer (défaut : la plus récente de out/iso)
#   --disk FICHIER       disque virtuel qcow2, créé en 64 Go s'il n'existe pas
#   --no-iso             démarre seulement le disque (système installé)
#   --gl                 rendu 3D virtio-gpu (virgl), utile pour Hyprland
#   --headless           sans fenêtre (pour les captures automatiques)
#   --xvfb               écran X virtuel (Xvfb) : rendu 3D sans carte graphique, avec --gl,
#                        captures prises sur l'écran X (screendump ne voit pas le rendu GL),
#                        demande xwininfo (x11-utils) et Pillow
#   --res 1920x1080      définition de l'écran de la machine virtuelle
#   --serial             journal du port série dans out/qemu/serial.log
#   --at "S:ACTION"      action S secondes après le lancement, option répétable :
#                          shot[:nom]  capture PNG dans out/captures/
#                          keys:a b c  touches QEMU (ex. keys:ret, keys:ctrl-alt-f2)
#                          type:texte  tape un texte (lettres, chiffres, espace)
#                          quit        arrête la machine virtuelle
#                          autre       commande brute du moniteur QEMU
#   --mem 4G  --cpus 4   ressources de la machine virtuelle
# Variable : ORBE_QEMU_DISPLAY remplace l'affichage (ex. sdl,gl=on).
set -euo pipefail

ROOT=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cd "$ROOT"

mode=uefi iso="" disk="" use_iso=1 gl=0 headless=0 xvfb=0 serial=0 res=1920x1080 mem=4G cpus=4
actions=()
while (( $# )); do
  case "$1" in
    --bios) mode=bios ;;
    --uefi) mode=uefi ;;
    --iso) iso=$2; shift ;;
    --disk) disk=$2; shift ;;
    --no-iso) use_iso=0 ;;
    --gl) gl=1 ;;
    --headless) headless=1 ;;
    --xvfb) xvfb=1 ;;
    --res) res=$2; shift ;;
    --serial) serial=1 ;;
    --at) actions+=("$2"); shift ;;
    --mem) mem=$2; shift ;;
    --cpus) cpus=$2; shift ;;
    -h|--help) sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $1 (voir --help)" >&2; exit 2 ;;
  esac
  shift
done

die() { echo "ERREUR : $*" >&2; exit 1; }
command -v qemu-system-x86_64 >/dev/null || die "QEMU absent (voir tools/preflight.sh)."

mkdir -p out/qemu out/captures
args=(-name "Orbe OS ($mode)" -machine q35 -m "$mem" -smp "$cpus"
  -nic user,model=virtio-net-pci
  -device qemu-xhci -device usb-tablet -device usb-kbd)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  args+=(-accel kvm -cpu host)
else
  echo "Attention : /dev/kvm indisponible, émulation logicielle (TCG) très lente." >&2
  args+=(-accel tcg,thread=multi -cpu max)
fi

xres=${res%x*} yres=${res#*x}
xvfb_pid=""
if (( xvfb )); then
  # Écran X virtuel à la définition de la machine virtuelle, QEMU en plein écran dessus.
  command -v Xvfb >/dev/null || die "Xvfb absent (sudo apt install -y xvfb)."
  for n in $(seq 90 120); do [[ -e /tmp/.X11-unix/X$n ]] || { xdisplay=:$n; break; }; done
  # Écran deux fois plus grand : sans gestionnaire de fenêtres, QEMU ne se place pas en 0,0.
  Xvfb "$xdisplay" -screen 0 "$((xres * 2))x$((yres * 2))x24" +extension GLX -nolisten tcp >/dev/null 2>&1 &
  xvfb_pid=$!
  export DISPLAY=$xdisplay
  for _ in $(seq 50); do [[ -e /tmp/.X11-unix/X${xdisplay#:} ]] && break; sleep 0.1; done
  args+=(-full-screen)
fi
if (( gl )); then
  args+=(-device "virtio-vga-gl,xres=$xres,yres=$yres")
  if (( xvfb )); then default_display=sdl,gl=on
  elif (( headless )); then default_display=egl-headless
  else default_display=gtk,gl=on; fi
else
  args+=(-device "virtio-vga,xres=$xres,yres=$yres")
  if (( xvfb )); then default_display=sdl
  elif (( headless )); then default_display=none
  else default_display=gtk; fi
fi
display=${ORBE_QEMU_DISPLAY:-$default_display}
args+=(-display "$display")
(( serial )) && args+=(-serial file:out/qemu/serial.log)

if [[ "$mode" == uefi ]]; then
  code=""
  for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
           /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
           /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    [[ -f "$c" ]] && { code=$c; break; }
  done
  [[ -n "$code" ]] || die "OVMF introuvable (sudo apt install -y ovmf)."
  vars_src=${code/CODE/VARS}
  # Variables UEFI propres à chaque disque, pour garder ses entrées de démarrage.
  vars=out/qemu/$( [[ -n "$disk" ]] && basename "$disk" .qcow2 || echo live ).vars.fd
  [[ -f "$vars" ]] || cp "$vars_src" "$vars"
  args+=(-drive "if=pflash,format=raw,readonly=on,file=$code" -drive "if=pflash,format=raw,file=$vars")
fi

if (( use_iso )); then
  if [[ -z "$iso" ]]; then
    iso=$(ls -t out/iso/orbe-os-*.iso 2>/dev/null | head -1 || true)
    [[ -n "$iso" ]] || die "Aucune ISO dans out/iso : lance ./build.sh."
  fi
  [[ -f "$iso" ]] || die "ISO introuvable : $iso"
  args+=(-drive "if=none,id=cd0,media=cdrom,readonly=on,format=raw,file=$iso"
         -device "ide-cd,drive=cd0,bus=ide.1,bootindex=0")
fi
if [[ -n "$disk" ]]; then
  [[ -f "$disk" ]] || qemu-img create -q -f qcow2 "$disk" 64G
  args+=(-drive "if=none,id=hd0,format=qcow2,file=$disk" -device "virtio-blk-pci,drive=hd0,bootindex=1")
fi
(( use_iso )) || [[ -n "$disk" ]] || die "Rien à démarrer : --no-iso demande --disk."

sock=out/qemu/monitor-$$.sock
args+=(-monitor "unix:$sock,server,nowait")

# Envoie une commande au moniteur QEMU.
monitor() {
  python3 -I - "$sock" "$1" <<'PY'
import socket, sys, time
s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[1])
s.settimeout(1)
def drain():
    try:
        while s.recv(65536):
            pass
    except OSError:
        pass
drain()
s.sendall((sys.argv[2] + "\n").encode())
time.sleep(0.5)
drain()
PY
}

# Convertit un texte en touches QEMU (lettres minuscules, chiffres, espace, . - /).
# sendkey envoie des positions de touches QWERTY : ORBE_QEMU_LAYOUT=fr (défaut) les adapte à l'AZERTY.
type_keys() {
  local text=$1 i ch k keys=()
  for (( i = 0; i < ${#text}; i++ )); do
    ch=${text:i:1}
    if [[ "${ORBE_QEMU_LAYOUT:-fr}" == fr ]]; then
      case "$ch" in
        a) k=q ;; q) k=a ;; z) k=w ;; w) k=z ;; m) k=semicolon ;;
        [0-9]) k=shift-$ch ;; ' ') k=spc ;; '.') k=shift-comma ;; '-') k=6 ;; '/') k=shift-dot ;; '*') k=backslash ;;
        *) k=$ch ;;
      esac
    else
      case "$ch" in ' ') k=spc ;; '.') k=dot ;; '-') k=minus ;; '/') k=slash ;; *) k=$ch ;; esac
    fi
    keys+=("$k")
  done
  for k in "${keys[@]}"; do monitor "sendkey $k"; done
}

echo "QEMU : $mode, $( (( use_iso )) && echo "ISO $iso" ) ${disk:+disque $disk}, affichage $display"
qemu-system-x86_64 "${args[@]}" &
qemu_pid=$!
trap 'rm -f "$sock"; [[ -n "$xvfb_pid" ]] && kill "$xvfb_pid" 2>/dev/null' EXIT

if (( ${#actions[@]} )); then
  start=$(date +%s)
  mapfile -t sorted < <(printf '%s\n' "${actions[@]}" | sort -t: -k1,1n)
  for action in "${sorted[@]}"; do
    at=${action%%:*} what=${action#*:}
    while (( $(date +%s) - start < at )); do
      kill -0 "$qemu_pid" 2>/dev/null || die "QEMU s'est arrêté avant ${at} s."
      sleep 1
    done
    case "$what" in
      shot|shot:*)
        name=${what#shot}; name=${name#:}
        file=out/captures/$mode-${name:-${at}s}.png
        if (( xvfb )); then
          python3 -I "$ROOT/tools/xshot.py" "$DISPLAY" "$file"
        else
          monitor "screendump $file -f png"
        fi
        echo "Capture : $file" ;;
      keys:*) for k in ${what#keys:}; do monitor "sendkey $k"; done ;;
      type:*) type_keys "${what#type:}" ;;
      quit) monitor quit ;;
      *) monitor "$what" ;;
    esac
  done
fi
wait "$qemu_pid"
