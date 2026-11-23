# Pocket Pip — revisión de errores (versión 0.2)

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
