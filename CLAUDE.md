# Pocket Pip — guía para Claude

Mascota virtual (género "Talking Tom", pero **original**) protagonizada por **Pip**, la ardilla de Star Nova.
Hecho con **Godot 4.7** (GDScript, renderizador Compatibility) y **100% nativo** en el teléfono.
El dueño habla **español**: responde siempre en español, claro y sin tecnicismos innecesarios.

> **Nada web**: ni versión de navegador, ni WebView, ni "jugar en la web". Solo la app nativa.
> **Sin anuncios, nunca.** Ingresos solo por micropagos (bellotas) con Google Play.

## Reglas del dueño
- Toda app del dueño empieza con la **intro "nioro"** (la de Color Flow, `scripts/intro.gd`) y **no se puede saltar**.
- Animaciones fluidas en todo: botones con rebote, paneles con resorte, cámara suave, Pip siempre vivo.
- Hacerlo bien y sin apuro: revisar las capturas de "los ojos" después de cada cambio visual.
- La lista de ideas está en `docs/LISTA.md`: marcar `[x]` lo que se termina. El dueño elige qué sigue.
- Al terminar un cambio: push → esperar "Compilar Pocket Pip" en verde → **crear el PR a `main` y fusionarlo**
  (el dueño lo autorizó). En `main` se publica el release `latest` con `PocketPip.apk`.
- Versión de prueba: compras simuladas gratis (`Pagos.MODO_PRUEBA`). Plan de Google Play en `docs/PAGOS.md`.
- Nunca subir llaves ni contraseñas (el repo es público). La firma vive en Secrets o en la caché de Actions.
- Nada de identificadores de modelo en commits, PR ni código.

## Ver el juego ("los ojos")
- En el contenedor: `bash godot/tools/ojos.sh <godot> <carpeta>` (Xvfb + OpenGL por software): recorre todo,
  deja ~30 capturas `NN_nombre.png` + `report.txt`. Falla si hay `FALLO` o errores de guion. Mirar con **Read**
  (conviene juntarlas con `montage` de ImageMagick). Godot 4.7 para Linux:
  `https://github.com/godotengine/godot/releases/download/4.7-stable/Godot_v4.7-stable_linux.x86_64.zip`.
- En GitHub: cada push publica capturas en el release **`diagnostico`** y la APK de la rama en el release **`rama`**.
- Atajos: `-- --sin-intro` (empieza sin la intro, solo para pruebas), `--prueba` (no guarda), `--ojos=CARPETA`.
- En el contenedor **no se puede exportar la APK** (falta el SDK de Android: `dl.google.com` bloqueado); la compila
  GitHub Actions (`.github/workflows/build.yml`).

## Mapa del código (`godot/scripts/`)
- `main.gd` — núcleo: luz, cámara, casa, Pip, toques (rayo a las zonas de Pip), viajes entre habitaciones,
  comer, dormir, ducha/jabón, pelota, bailes, pociones. Modos: intro, juego, viaje, dormir, pelota, baile, ducha.
- `pip.gd` (`PipModel`) — modelo de Star Nova + cara, zonas tocables, acciones (`hacer`), reacciones (`toque`),
  caricias, dormir, bailes (`_baile`) y pociones.
- `atuendos.gd` — la ropa en 3D colgada de los huesos. Prenda nueva: `data/catalogo.json` + su forma en `_armar`.
- `casa.gd` — 4 habitaciones; cada ranura de decoración es una función `_<hab>_<ranura>(nodo, estilo)`.
- `hud.gd` — interfaz: barra de arriba, botones, barra de habitaciones, área de acción, paneles, ventanas.
- `ui.gd` — colores, tipografía (Fredoka), íconos dibujados, `Boton`, `Tarjeta`, `Fx` (efectos 2D).
- `estado.gd` (autoload `Estado`) — partida y catálogo. `pagos.gd` (autoload `Pagos`). `sfx.gd` (autoload `Sfx`,
  con sonidos de Pip sintetizados). `intro.gd` — intro nioro. `ojos.gd` — pruebas y capturas.
- Datos: `godot/data/catalogo.json` (ropa, pociones, bailes, comida, decoración, paquetes, regalo diario).
- Sonidos y música en `godot/audio/` (de Star Nova y Color Flow, del mismo dueño).
