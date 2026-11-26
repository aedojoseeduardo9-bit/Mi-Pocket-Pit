# Pocket Pip — revisión de errores

## Versión 0.6.1
- [x] **Margarita gigante (flor blanca) tapaba el ojo** y la hojita llegaba a la nariz: estaba agrandada 2,3 veces en
  el mismo lugar de la flor chica. Ahora va al costado de la cabeza como pinche (en Pip y en la capibara).
- [x] **La app se cerraba sola en algunos teléfonos (por ejemplo Vivo).** Sin el registro del teléfono no se puede
  saber la causa exacta; lo más común es que la tarjeta gráfica no aguante sombras grandes, suavizado o brillo.
  Nuevo **modo seguro automático**: si el juego se cerró solo la vez anterior, al abrir baja un paso la calidad
  gráfica (hasta "Baja": sin sombras ni brillo, 30 cuadros) y avisa. Se puede volver a subir en Ajustes.
  Si el teléfono cierra la app estando en segundo plano (ahorro de batería de Vivo), eso lo hace el sistema: la
  partida ya se guarda al salir; en el teléfono conviene permitir "alto consumo en segundo plano" para Pocket Pip.

## Versión 0.6 (gráfica optimizada, brillo de la habitación y errores de compras)
### Compras (lo más importante)
- [x] **Compras que se entregaban dos veces.** El botón "Procesando..." se veía desactivado pero seguía respondiendo
  (los botones nunca revisaban si estaban activos): un segundo toque volvía a comprar. Ahora un botón desactivado no
  responde, y la tienda procesa una sola compra a la vez.
- [x] **Cobros dobles con bellotas** al tocar rápido dos veces mientras una ventana se cerraba (subir de nivel,
  capibara de 3 minutos): la ventana que se cierra ya no recibe toques, y ropa, decoración y bailes revisan que no los
  tengas antes de cobrar.
- [x] **Los packs de una sola vez** (bienvenida, capibara para siempre) se podían volver a comprar llamando a la
  tienda: ahora se rechaza ("Ya lo compraste").
- [x] **Compra que fallaba = ventana colgada para siempre** en "Procesando...". Ahora avisa el motivo y se cierra.
  Además, al terminar una compra el juego cerraba cualquier ventana abierta (por ejemplo "¡Nivel N!"): ahora cierra
  solo la suya, y solo escucha la respuesta de su propio paquete.
- [x] **Partida perdida si el teléfono se apagaba justo al guardar**: el archivo quedaba a medias y el juego partía
  de cero (con las compras perdidas). Ahora guarda en un archivo aparte, lo revisa y recién ahí reemplaza; la partida
  anterior queda como respaldo y se usa si la principal está dañada.
- [x] **27 decoraciones que se compraban en la 0.3 desaparecieron al rediseñarlas en la 0.4** sin devolver nada
  (por ejemplo la cama nube mágica de 320). Ahora se devuelven sus bellotas automáticamente y se avisa una vez.

### Gráfica
- [x] **Brillo muy alto en la habitación**: la ventana tenía brillo propio fuerte sobre un color casi blanco y
  encandilaba; la luz era la misma en las 4 habitaciones. Ahora cada habitación tiene su luz (la habitación más tibia
  y suave, el baño un poco menos blanco), la ventana muestra cielo y la pared lavanda tiene más color.
- [x] **Optimización**: solo se dibuja la habitación donde está Pip (las otras se muestran al viajar); las piezas
  chicas ya no proyectan sombra y usan mallas livianas; las piezas chicas de Pip (dientes, deditos, ojos) usan menos
  polígonos; la cola de Pip ya no recalcula todo en cada cuadro (colores, triángulos y senos quedan guardados y la
  forma se rehace hasta 40 veces por segundo). Piezas con sombra: de ~279 a ~80; piezas dibujadas: de ~317 a ~130.

## Versión 0.5
- [x] **Bordes de las sombras dentados y con puntitos.** La sombra cubría 11 m con una imagen de 2048 píxeles y se
  desenfocaba con poco detalle: se ve en escalera. Ahora cubre 8,5 m (la casa entera) con 4096 en calidad alta
  (2048 en media), con un desenfoque parejo: borde suave y limpio. También se subió el "sesgo" para que las
  superficies curvas no se sombreen a sí mismas en rayas.
- [x] **Rayas en zigzag en la cama nido**: no era sombra, la base del nido atravesaba el aro y el cruce salía en
  zigzag. La base ahora queda dentro del aro y no recibe sombras.
- [x] Aros (toros) de la casa con más polígonos: curvas más suaves.
- [x] La ventana de regalos de nivel tapaba el último regalo con el botón: corregido.
- [x] Memoria: el reloj partía antes de que miraras las cartas; ahora parte con la primera carta.

## Versión 0.4 (lo que pediste: "que cada compra se note")
- [x] **Compras que solo cambiaban color o partículas** (el ejemplo de los árboles). Ahora toda decoración y toda prenda
  tiene su propia forma. Revisado con una galería automática: una foto de cada una de las 141 decoraciones y las 137
  prendas (de frente y de espalda), para confirmar que ninguna se parece a otra.
- [x] **La cámara no mostraba lo que decorabas**: al abrir "Decorar" se acercaba a Pip y la nevera, la mesa, la cama o el
  árbol quedaban cortados en el borde. Ahora la cámara va al objeto de la pestaña elegida y lo deja entero sobre el panel.
  La vista normal también se abrió un poco para que se vea más de la habitación.
- [x] La planta de la cocina quedaba escondida detrás del mesón: ahora está encima.
- [x] Los adornos de pared quedaban fuera de cuadro en el teléfono (pantalla angosta): se movieron a la parte visible.
- [x] Moños, corbatas y cascabeles nuevos bajados un poco para que los cachetes de Pip no los tapen.
- [ ] Las prendas de cuello de antes (moño, corbata, cascabel) se ven poco por los cachetes de Pip.

## Versión 0.3 (lo que reportaste en la APK 2)
- [x] **Lag fuerte en la pantalla nioro.** Causas encontradas y corregidas:
  - La intro corría mientras el juego se armaba detrás (casa, Pip, ropa de muestra para preparar sombreadores): cada
    tirón del armado se veía en la animación. Ahora todo se arma con la pantalla en **negro** y la intro empieza
    recién cuando el juego está listo.
  - Durante la intro ya no se dibuja la casa 3D detrás (la intro la tapa entera).
  - El resplandor de "nioro" cambiaba de grosor cada cuadro: el teléfono redibujaba las letras gigantes cada vez.
    Ahora usa grosores fijos y solo cambia la transparencia.
- [x] **Lag de los minijuegos.** Mientras juegas ya no se dibuja la casa 3D detrás ni se anima a Pip; la cuenta
  regresiva cambiaba el tamaño de letra cada cuadro (mismo problema de arriba): ahora se escala sin redibujar letras.
  Lo mismo con las "z" de dormir y los textos que flotan.
- [x] **Ropa que calza en la capibara**: cada prenda se reacomoda al hueso del que cuelga (cabeza más larga, ojos más
  altos y separados, cuerpo más ancho, bracitos gruesos). Bajo sombreros y trajes se esconde la mandarina; bajo
  cascos, las orejitas. La cara que asoma por capuchas usa el color de quien la lleva.
- [x] **Brazos y orejas abstractos**: brazos nuevos (tubo suave que se afina, manito con tres deditos), orejas de
  ardilla (hoja gruesa curvada, interior rosado, mechón de tres puntas) y patitas con dedos.
- [x] **Decoración con más efectos**: partículas (pétalos de cerezo y de otoño, nieve, burbujas en la bañera,
  vapor de la olla, luciérnagas de noche, chispas de fogata, agua de fuente, destellos mágicos), estrellas fugaces,
  peces que nadan, columpio que se mece, patito y flotador que flotan, lámparas que laten y giran, velas con llama.
  13 diseños nuevos con efecto: nevera mágica, mesa de cumpleaños, flor mágica, bola disco, nube mágica, alfombra
  arcoíris, lluvia de estrellas, fuente, fogata, pared acuario, jacuzzi de luz y cortina de luces.
  Solo se anima la habitación donde está Pip (ahorra batería).
- [x] **Puntitos de arriba → burbuja junto a "Más"**: tocarla = siguiente habitación; mantenerla apretada y deslizar
  = se abre una píldora con las 4 habitaciones y Pip corre a la que señales (con vibración en cada paso).
- [x] Errores encontrados en esta revisión: la píldora quedaba debajo de los botones de acción; la nieve y los
  pétalos tardaban en aparecer (ahora el ambiente ya está lleno); la fogata y la fuente quedaban fuera de cuadro;
  al acercar la cámara se veía el borde del piso.

## Versión 0.2

Revisión hecha con "los ojos" (65 capturas y 35 pruebas automáticas) y leyendo el código. Cada error está
marcado `[x]` si ya se corrigió en esta versión o `[ ]` si sigue pendiente. Ordenados de más a menos importante.

## 1. Lo que reportaste en la APK 1
- [x] **Lag fuerte al empezar y en algunas acciones.** Causas encontradas:
  - 5 luces puntuales (una por habitación + lámpara): en el modo gráfico de teléfonos cada luz obliga a dibujar
    los objetos otra vez. Se quitaron todas (la luz ambiental y el sol bastan; la lámpara brilla sola).
  - El teléfono preparaba sus sombreadores la primera vez que veía cada material (ropa, pociones, agua…): ese era el
    tirón al hacer cosas nuevas. Ahora se preparan **durante la intro nioro** (que tapa la pantalla).
  - La intro dibujaba la esfera con 448 polígonos cada cuadro; ahora se arma una vez y solo se escala.
  - Al dormir/comer se avisaba a toda la interfaz en cada cuadro y se guardaba la partida cada 2 s: ahora las barras se
    leen solas y se guarda cada 4–30 s.
  - Sombras en 2 cascadas → 1 sola (escena chica).
- [x] **Estrella girando en el cuerpo de Pip**: era el broche de la bufanda heredado de Star Nova. Eliminado.
- [x] **Botones con "algo transparente que sobresale"**: era un brillo blanco semitransparente arriba de cada botón y
  una sombra muy marcada. Quitado el brillo; sombra más suave.
- [x] **Cola bizarra**: eran 8 esferas con 24 mechones encimados. Ahora es un tubo suave y esponjoso que sigue los
  huesos de la cola (curva continua, más gruesa al medio, bordes ondulados como pelaje, punta crema).
- [x] **Se daban bellotas por cariño**: eliminado.
- [x] **Bellotas gratis para comer ilimitadas**: ahora son 5 y se recarga 1 cada 30 minutos; después cuestan 2.
- [x] **Pip no se cansaba ni le daba hambre**: las necesidades bajan bastante más rápido (en ~8 horas pide atención),
  también con la app cerrada; si lo dejas durmiendo con la luz apagada, recupera energía mientras no estás.
- [x] **Sin configuración**: Ajustes con música, efectos, gráficos (baja/media/alta), idioma y vibración.
- [x] **Solo español**: inglés completo (la prueba en inglés no encontró textos sin traducir).
- [x] **Menús**: nuevo dock inferior (Armario, Tienda, Juegos, Decorar, Más) + puntitos de habitación arriba.

## 2. Errores encontrados en esta revisión (corregidos)
- [x] Disfraz de pingüino: sus aletas quedaban pegadas a Pip al quitárselo (franjas oscuras). Ahora hay una prueba
  que cuenta las piezas antes y después de vestir las 137 prendas.
- [x] La cola nueva se veía oscura por dentro a los lados (caras al revés). Corregido.
- [x] Chispas que se achicaban a cero daban error de dibujo ("triangulación"). Corregido.
- [x] Comprar la capibara permanente o el pack de bienvenida dejaba la compra esperando para siempre. Corregido.
- [x] Las paredes generadas repetían 6 patrones; ahora salen los 12 (rayas, cuadros, corazones, rombos, nubes…).
- [x] Prueba de "hambre en 8 horas" partía con poca hambre y no medía bien. Corregida.
- [x] Partidas de la versión 0.1: la ropa y decoración que ya no existen se cambian solas por las iniciales.
- [x] "¡Toca la pelota!" casi no se leía sobre el cielo morado. Ahora tiene borde.

## 3. Pendientes visuales (en orden)
- [ ] La pose de dormir es simple (sentado con la cabeza ladeada); falta que se acueste y se tape con la cola.
- [ ] Con el armario abierto la cámara baja y, sin panel, se ve el borde del piso (solo pasa en las pruebas).
- [ ] Algunas prendas se atraviesan un poco con brazos u orejas en poses extremas (risa, trompo).
- [ ] En el minijuego Memoria las cartas se ven todas iguales por detrás (bien), pero falta animación al acertar.
- [ ] Las miniaturas de las tarjetas de ropa son dibujos simples; lo ideal son fotos 3D de cada prenda.
- [ ] El tamaño de letra de las pestañas del armario (6 zonas) es chico en teléfonos angostos.
- [ ] La capibara no puede usar ropa todavía (se esconde).

## 4. Pendientes de código
- [ ] Las compras siguen en **modo prueba** (`Pagos.MODO_PRUEBA`): falta Google Play Billing (ver `docs/PAGOS.md`).
- [ ] No hay notificaciones del teléfono cuando Pip tiene hambre (necesita un plugin de Android).
- [ ] El rendimiento real solo se puede medir en tu teléfono: si sigue lento, prueba Ajustes → Gráficos → Baja
  (sin sombras, 30 cuadros, resolución 75%) y cuéntame en qué pantalla.
- [ ] La partida no se respalda en la nube (si se desinstala, se pierde).
