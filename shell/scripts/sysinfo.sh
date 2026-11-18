#!/bin/sh
# Mesures système pour le tableau de bord d'Orbe Shell (une ligne par mesure, valeurs brutes).
# Lancé toutes les deux secondes, seulement pendant que l'onglet Système est affiché.
awk '/^cpu /{print "cpu", $2+$3+$4+$7+$8+$9, $2+$3+$4+$5+$6+$7+$8+$9}' /proc/stat
awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print "mem", t, a}' /proc/meminfo
for d in /sys/class/hwmon/hwmon*; do
  case "$(cat "$d/name" 2>/dev/null)" in
    k10temp|coretemp|zenpower|cpu_thermal) echo "cputemp $(cat "$d/temp1_input" 2>/dev/null)"; break ;;
  esac
done
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
  nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,name --format=csv,noheader,nounits \
    | head -n1 | awk -F', ' '{print "gpu", $1, $2*1000, $3}'
else
  for c in /sys/class/drm/card*/device; do
    if [ -r "$c/gpu_busy_percent" ]; then
      t=$(cat "$c"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
      echo "gpu $(cat "$c/gpu_busy_percent") ${t:-0} AMD"
      break
    fi
  done
fi
df -B1 --output=used,size / | awk 'NR==2{print "disk", $1, $2}'
awk -F'[: ]+' 'NR>2 && $2 != "lo" {rx+=$3; tx+=$11} END{print "net", rx, tx}' /proc/net/dev
