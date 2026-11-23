#!/usr/bin/env bash
# Pocket Pip — "los ojos": abre el juego en una pantalla virtual (Xvfb + OpenGL por software), lo juega solo,
# toma capturas y hace las pruebas automáticas. Uso: bash godot/tools/ojos.sh <godot> <carpeta_salida>
set -u
GODOT="${1:?falta la ruta de Godot}"
OUT="$(mkdir -p "${2:?falta la carpeta de salida}" && cd "$2" && pwd)"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
"$GODOT" --headless --path "$PROJ" --import > "$OUT/import.log" 2>&1
export XDG_DATA_HOME="$OUT/datos"
timeout 600 xvfb-run -a -s "-screen 0 720x1280x24" "$GODOT" --path "$PROJ" --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 720x1280 -- --ojos="$OUT" > "$OUT/juego.log" 2>&1
CODE=$?
[ -f "$OUT/report.txt" ] || { echo "FALLO: no hubo informe" > "$OUT/report.txt"; tail -40 "$OUT/juego.log" >> "$OUT/report.txt"; CODE=1; }
if grep -hE "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Invalid assignment" "$OUT/juego.log" "$OUT/import.log" > "$OUT/errores.txt"; then
  echo "ERROR: hay errores en el registro (ver errores.txt)" >> "$OUT/report.txt"
  CODE=1
fi
cat "$OUT/report.txt"
exit $CODE
