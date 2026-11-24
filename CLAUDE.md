# Pocket Pip — guía para Claude

Mascota virtual (género "Talking Tom", pero **original**) protagonizada por **Pip**, la ardilla de Star Nova.
Hecho con **Godot 4.7** (GDScript, renderizador Compatibility) y **100% nativo** en el teléfono.
El dueño habla **español**: responde siempre en español, claro y sin tecnicismos innecesarios.

> **Nada web**: ni versión de navegador, ni WebView, ni "jugar en la web". Solo la app nativa.
> **Sin anuncios, nunca.** Ingresos solo por micropagos (bellotas) con Google Play.

## Reglas del dueño
- Menús: **dock inferior** (Armario, Tienda, Juegos, Decorar, Más) y **burbuja de habitaciones** junto a Más
  (tocar = siguiente; mantener y deslizar = elegir). Lo eligió el dueño.
- Economía: nada de bellotas por cariño; bellotas gratis para comer limitadas; empujar suave a la tienda cuando faltan.
  Pip debe necesitar atención (sus necesidades bajan también con la app cerrada).
- Rendimiento: **sin luces puntuales** (cada una redibuja todo en teléfonos); materiales en caché; todo material nuevo
  se precalienta en `main._precalentar()` con la pantalla en negro, ANTES de que corra la intro. Durante la intro y los
  minijuegos `disable_3d = true`. Nunca cambiar tamaño de letra ni grosor de contorno cada cuadro (el teléfono redibuja
  las letras): usar tamaños fijos y escalar con `draw_set_transform`.
- Decoración con efectos: `Casa.efecto(nodo, tipo)` y `Casa.particulas_en(...)`; solo se anima la habitación activa
  (`Casa.activar`). La ropa se reacomoda a la capibara en `Atuendos._ajustar_capibara`.
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
- `minijuegos.gd` (`Minijuego`) — Salto Nova, Lluvia de bellotas, Memoria y Cohete Avellana (2D, pantalla completa),
  con partículas y fondos en capas. Diseños por nivel: `dibujar_nave`, `dibujar_dorso`, `dibujar_nube` (estáticas,
  también las usa la ventana de regalos); se eligen antes de jugar (`Estado.skin` / `cambiar_skin`).
- Regalos por nivel (2 a 25): `recompensas` del catálogo; `Estado._dar_regalos(n)` y `hud.abrir_regalo_nivel(n)`.
  Prendas con `"regalo": true` no se venden (precio 0, se tienen al llegar al nivel). Subir de nivel pagando:
  `Estado.costo_subir_nivel()` (caro a propósito), ventana `hud.abrir_subir_nivel()`.
- `l.gd` (`L`) — idiomas: los textos van en español en el código; `data/en.json` tiene el inglés. `UI.texto` traduce
  solo; textos con números: `L.f("¡Nivel %d!", [n])`. Los "ojos" listan los textos sin traducir: debe quedar vacío.
- Datos: `godot/data/catalogo.json` lo **genera** `python3 godot/tools/generar_catalogo.py` (no editar a mano): ropa
  (146, 9 de ellas regalos de nivel; con forma + colores + animación), decoración (30+ por habitación), pociones, bailes, comida, minijuegos,
  paquetes en pesos chilenos y especiales (pack de bienvenida, capibara para siempre). También escribe `docs/CATALOGO.md`.
- Revisión de errores: `docs/REVISION.md` (actualizarla en cada versión).
- **Modelo editable de Pip y la capibara**: `data/modelos/pip.json` (huesos con nombre, piezas con forma/color/posición,
  colores y cola). `PipModel.aplicar_modelo` lo carga encima del modelo de fábrica del código; los huesos y las
  animaciones no cambian. `data/modelos/pip_fabrica.json` = el original (exportar de nuevo con
  `godot --headless --path godot -- --exportar-modelo=<archivo.json>` si se cambia el código de `pip.gd`).
- **Taller de Pip** (editor 3D del dueño): https://claude.ai/artifact/6rAs93cqTbmmArikNCQ1F3 (copia en
  `godot/tools/taller_pip.html`). Cuando el dueño diga "usa el modelo del taller": leer con `ArtifactData`
  `get` colección `modelos`, documento `actual`; su campo `modelo` se escribe tal cual en `data/modelos/pip.json`;
  correr los ojos, mirar las capturas de Pip y de la capibara, y subir (PR + fusionar). Las versiones con nombre
  están en la colección `versiones`.
- Sonidos y música en `godot/audio/` (de Star Nova y Color Flow, del mismo dueño).
