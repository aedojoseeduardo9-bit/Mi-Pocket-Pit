## Pocket Pip — minijuegos 2D a pantalla completa (estilo Pou / Talking Tom):
##  - "salto":   Salto Nova — Pip salta de nube en nube hacia arriba; se mueve con el dedo (izquierda/derecha).
##  - "lluvia":  Lluvia de bellotas — atrapa lo que cae del árbol, evita las piñas (3 vidas).
##  - "memoria": Memoria — 16 cartas, encuentra las parejas antes de que se acabe el tiempo.
##  - "cohete":  Cohete Avellana — toca para subir, pasa entre los asteroides.
## Al terminar: puntaje, récord y bellotas ganadas (con tope por partida). Cuesta un poco de energía y da diversión.
class_name Minijuego
extends Control

signal terminado(tipo: String, puntos: int, bellotas: int)

const TOPE := 40                   ## bellotas máximas por partida

var tipo := ""
var t := 0.0
var puntos := 0
var fin := false
var _fin_t := 0.0
var _toque := false
var _dedo := Vector2.ZERO
var _rnd := RandomNumberGenerator.new()
var _btn: Array = []
var _cuenta := 3.0                 ## cuenta regresiva al empezar

# salto
var px := 0.0
var py := 0.0
var vy := 0.0
var camy := 0.0
var nubes: Array = []              ## [x, y, tipo(0 normal,1 se mueve,2 frágil), vivo, fase]
var altura := 0.0
# lluvia
var cae: Array = []                ## [x, y, vy, clase("bellota","fresa","pina","estrella")]
var vidas := 3
var _gen := 0.0
# memoria
var cartas: Array = []             ## {icono, abierta, hecha, giro}
var _abiertas: Array = []
var _espera := 0.0
var tiempo_mem := 60.0
# cohete
var rv := 0.0
var ry := 0.0
var rocas: Array = []              ## [x, hueco_y, contado]

func _init(tp: String) -> void:
	tipo = tp
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rnd.randomize()

func _ready() -> void:
	_reiniciar()

func _reiniciar() -> void:
	t = 0.0
	puntos = 0
	fin = false
	_cuenta = 2.4 if tipo != "memoria" else 0.0
	for b in _btn:
		b.queue_free()
	_btn.clear()
	var W := size.x if size.x > 0 else 720.0
	var H := size.y if size.y > 0 else 1280.0
	match tipo:
		"salto":
			px = W * 0.5
			py = H - 260.0
			vy = -1150.0
			camy = 0.0
			altura = 0.0
			nubes.clear()
			var y := H - 200.0
			while y > -H * 2.0:
				_nube_nueva(y)
				y -= _rnd.randf_range(130, 190)
		"lluvia":
			px = W * 0.5
			cae.clear()
			vidas = 3
			_gen = 0.0
		"memoria":
			var iconos := ["bellota", "corazon", "estrella", "pocion", "nota", "pelota", "regalo", "luna"]
			var lista: Array = []
			for i in iconos:
				lista.append(i)
				lista.append(i)
			lista.shuffle()
			cartas.clear()
			for i in lista:
				cartas.append({"icono": i, "abierta": false, "hecha": false, "giro": 0.0})
			_abiertas.clear()
			tiempo_mem = 60.0
		"cohete":
			ry = H * 0.45
			rv = 0.0
			rocas.clear()
			for i in 4:
				rocas.append([W + 200.0 + i * 380.0, _rnd.randf_range(H * 0.3, H * 0.7), false])

func _nube_nueva(y: float) -> void:
	var W := size.x if size.x > 0 else 720.0
	var tp := 0
	var r := _rnd.randf()
	if altura > 1500 and r < 0.25:
		tp = 1
	elif altura > 3000 and r < 0.4:
		tp = 2
	nubes.append([_rnd.randf_range(80, W - 80), y, tp, true, _rnd.randf() * TAU])

func _gui_input(e: InputEvent) -> void:
	accept_event()
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_toque = e.pressed
		_dedo = e.position
		if e.pressed and not fin:
			if tipo == "cohete" and _cuenta <= 0.0:
				rv = -620.0
				Sfx.play("jump", 1.3, -6.0)
			elif tipo == "memoria":
				_tocar_carta(e.position)
	elif e is InputEventMouseMotion:
		_dedo = e.position

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	t += dt
	if fin:
		_fin_t += dt
		queue_redraw()
		return
	if _cuenta > 0.0:
		_cuenta -= dt
		queue_redraw()
		return
	match tipo:
		"salto": _salto(dt)
		"lluvia": _lluvia(dt)
		"memoria": _memoria(dt)
		"cohete": _cohete(dt)
	queue_redraw()

func _terminar() -> void:
	if fin:
		return
	fin = true
	_fin_t = 0.0
	var gana := mini(TOPE, _bellotas())
	var rec: Dictionary = Estado.d.records
	var nuevo := puntos > int(rec.get(tipo, 0))
	if nuevo:
		rec[tipo] = puntos
	Estado.dar_bellotas(gana)
	Estado.subir("diversion", 14.0)
	Estado.subir("energia", -6.0)
	Estado.dar_xp(3 + mini(10, puntos / 20))
	Sfx.play("level" if nuevo else "chest")
	set_meta("nuevo", nuevo)
	set_meta("gana", gana)
	var W := size.x
	var H := size.y
	var otra := UI.Boton.new("check", "Otra vez", UI.MENTA, Vector2(250, 86))
	otra.color_icono = Color.WHITE
	otra.tam_texto = 24
	otra.position = Vector2(W * 0.5 - 262, H * 0.5 + 150)
	otra.presionado.connect(_reiniciar)
	var sal := UI.Boton.new("cerrar", "Salir", Color.WHITE, Vector2(220, 86))
	sal.color_icono = UI.CAFE2
	sal.tam_texto = 24
	sal.position = Vector2(W * 0.5 + 12, H * 0.5 + 150)
	sal.presionado.connect(func(): terminado.emit(tipo, puntos, gana))
	add_child(otra)
	add_child(sal)
	_btn = [otra, sal]

func _bellotas() -> int:
	match tipo:
		"salto": return puntos / 60
		"lluvia": return puntos / 2
		"memoria": return puntos / 10
		"cohete": return puntos * 2
	return 0

# ---------------- Salto Nova ----------------
func _salto(dt: float) -> void:
	var W := size.x
	var H := size.y
	if _toque:
		px += clampf(_dedo.x - px, -1.0, 1.0) * minf(absf(_dedo.x - px), 900.0 * dt)
	px = fposmod(px, W)
	vy += 2300.0 * dt
	var y0 := py
	py += vy * dt
	if vy > 0.0:
		for n in nubes:
			if not n[3]:
				continue
			var ny: float = n[1]
			if y0 <= ny - 30.0 and py >= ny - 30.0 and absf(px - float(n[0])) < 80.0:
				vy = -1150.0
				py = ny - 30.0
				Sfx.play("jump", randf_range(1.0, 1.2), -8.0)
				if n[2] == 2:
					n[3] = false
				break
	for n in nubes:
		if n[2] == 1:
			n[4] += dt * 1.6
			n[0] = clampf(float(n[0]) + cos(float(n[4])) * 140.0 * dt, 70.0, W - 70.0)
	# la cámara sube con Pip (nunca baja)
	var lim := H * 0.42
	if py - camy < lim:
		camy = py - lim
	altura = maxf(altura, -camy)
	puntos = int(altura / 10.0)
	var tope := camy - H * 0.3
	while nubes.size() > 0 and float(nubes[nubes.size() - 1][1]) > tope:
		_nube_nueva(float(nubes[nubes.size() - 1][1]) - _rnd.randf_range(140, 200 + minf(80.0, altura / 80.0)))
	var i := 0
	while i < nubes.size():
		if float(nubes[i][1]) - camy > H + 100.0:
			nubes.remove_at(i)
		else:
			i += 1
	if py - camy > H + 80.0:
		_terminar()

# ---------------- Lluvia de bellotas ----------------
func _lluvia(dt: float) -> void:
	var W := size.x
	var H := size.y
	if _toque:
		px += (_dedo.x - px) * minf(1.0, dt * 14.0)
	_gen -= dt
	if _gen <= 0.0:
		_gen = maxf(0.28, 0.85 - t * 0.012)
		var r := _rnd.randf()
		var cl := "bellota"
		if r < 0.22 + minf(0.15, t * 0.003):
			cl = "pina"
		elif r < 0.32:
			cl = "fresa"
		elif r < 0.35:
			cl = "estrella"
		cae.append([_rnd.randf_range(60, W - 60), 180.0, 260.0 + t * 6.0 + _rnd.randf() * 120.0, cl])
	var y_pip := H - 230.0
	var i := cae.size() - 1
	while i >= 0:
		var c: Array = cae[i]
		c[1] += c[2] * dt
		if absf(float(c[1]) - y_pip) < 50.0 and absf(float(c[0]) - px) < 80.0:
			match c[3]:
				"pina":
					vidas -= 1
					Sfx.play("deny")
					if vidas <= 0:
						_terminar()
				"estrella":
					puntos += 5
					Sfx.play("crystal")
				"fresa":
					puntos += 2
					Sfx.play("coin", 1.2)
				_:
					puntos += 1
					Sfx.play("coin", randf_range(0.95, 1.1), -4.0)
			cae.remove_at(i)
		elif float(c[1]) > H + 40.0:
			cae.remove_at(i)
		i -= 1

# ---------------- Memoria ----------------
func _rect_carta(i: int) -> Rect2:
	var W := size.x
	var H := size.y
	var cw := minf((W - 80.0) / 4.0, (H - 520.0) / 4.0)
	var x0 := (W - cw * 4.0) * 0.5
	var y0 := 300.0
	return Rect2(Vector2(x0 + (i % 4) * cw + 6, y0 + (i / 4) * cw + 6), Vector2(cw - 12, cw - 12))

func _tocar_carta(p: Vector2) -> void:
	if _espera > 0.0:
		return
	for i in cartas.size():
		var c: Dictionary = cartas[i]
		if c.hecha or c.abierta:
			continue
		if _rect_carta(i).has_point(p):
			c.abierta = true
			_abiertas.append(i)
			Sfx.play("tic", 1.2)
			if _abiertas.size() == 2:
				var a: Dictionary = cartas[_abiertas[0]]
				var b: Dictionary = cartas[_abiertas[1]]
				if a.icono == b.icono:
					a.hecha = true
					b.hecha = true
					puntos += 10 + int(tiempo_mem / 6.0)
					_abiertas.clear()
					Sfx.play("coin", 1.2)
				else:
					_espera = 0.8
			return

func _memoria(dt: float) -> void:
	tiempo_mem -= dt
	for c in cartas:
		c.giro = move_toward(c.giro, 1.0 if (c.abierta or c.hecha) else 0.0, dt * 5.0)
	if _espera > 0.0:
		_espera -= dt
		if _espera <= 0.0:
			for i in _abiertas:
				cartas[i].abierta = false
			_abiertas.clear()
	var hechas := 0
	for c in cartas:
		if c.hecha:
			hechas += 1
	if hechas == cartas.size():
		puntos += int(tiempo_mem) * 2
		_terminar()
	elif tiempo_mem <= 0.0:
		_terminar()

# ---------------- Cohete Avellana ----------------
func _cohete(dt: float) -> void:
	var W := size.x
	var H := size.y
	rv += 1500.0 * dt
	ry += rv * dt
	var vel := 260.0 + minf(200.0, t * 4.0)
	var hueco := maxf(250.0, 360.0 - t * 2.0)
	for r in rocas:
		r[0] -= vel * dt
		if float(r[0]) < -120.0:
			var mx := 0.0
			for q in rocas:
				mx = maxf(mx, float(q[0]))
			r[0] = mx + 380.0
			r[1] = _rnd.randf_range(H * 0.28, H * 0.72)
			r[2] = false
		var rx := W * 0.3
		if not r[2] and float(r[0]) < rx:
			r[2] = true
			puntos += 1
			Sfx.play("coin", 1.3, -6.0)
		if absf(float(r[0]) - rx) < 75.0 and absf(ry - float(r[1])) > hueco * 0.5 - 30.0:
			_terminar()
	if ry < 140.0 or ry > H - 90.0:
		_terminar()

# ---------------- dibujo ----------------
func _draw() -> void:
	var W := size.x
	var H := size.y
	match tipo:
		"salto": _dibujar_salto()
		"lluvia": _dibujar_lluvia()
		"memoria": _dibujar_memoria()
		"cohete": _dibujar_cohete()
	# barra de arriba
	UI.caja(self, Rect2(Vector2(W * 0.5 - 170, 46), Vector2(340, 84)), Color(1, 1, 1, 0.9), 42)
	UI.texto(self, Vector2(W * 0.5, 76), _titulo(), 22, UI.CAFE2, 600)
	UI.texto(self, Vector2(W * 0.5, 106), str(puntos), 34, UI.CAFE, 700)
	if tipo == "lluvia":
		for i in 3:
			draw_colored_polygon(UI.corazon_pts(Vector2(W - 150 + i * 46, 88), 34), UI.ROSA if i < vidas else Color(0, 0, 0, 0.15))
	if tipo == "memoria":
		UI.texto(self, Vector2(W - 90, 88), "%d s" % maxi(0, int(tiempo_mem)), 28, UI.CAFE, 700)
	if _cuenta > 0.0 and not fin:
		var n := int(ceil(_cuenta / 0.8))
		var k := fmod(_cuenta, 0.8) / 0.8
		UI.texto_borde(self, Vector2(W * 0.5, H * 0.42), str(n), int(140 * (0.8 + 0.4 * k)), UI.ORO, UI.CAFE, 18)
		UI.texto_borde(self, Vector2(W * 0.5, H * 0.52), _ayuda(), 30, Color.WHITE, UI.CAFE, 10)
	if fin:
		var a := minf(1.0, _fin_t * 4.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.05, 0.02, 0.45 * a))
		var r := Rect2(Vector2(W * 0.5 - 300, H * 0.5 - 250), Vector2(600, 520))
		r = r.grow(-30.0 * (1.0 - a))
		UI.caja(self, r, UI.CREMA, 40)
		UI.texto(self, Vector2(W * 0.5, r.position.y + 70), "¡Muy bien!" if puntos > 0 else "¡Otra vez!", 42, UI.CAFE, 700)
		UI.texto(self, Vector2(W * 0.5, r.position.y + 150), L.f("Puntos: %d", [puntos]), 34, UI.CAFE, 600)
		var rec := int(Estado.d.records.get(tipo, 0))
		UI.texto(self, Vector2(W * 0.5, r.position.y + 200), L.f("¡Nuevo récord!", []) if get_meta("nuevo", false) else L.f("Récord: %d", [rec]), 26,
			UI.NARANJO if get_meta("nuevo", false) else UI.CAFE2, 600)
		UI.icono(self, "bellota", Vector2(W * 0.5 - 50, r.position.y + 285), 70)
		UI.texto(self, Vector2(W * 0.5 + 30, r.position.y + 285), "+%d" % int(get_meta("gana", 0)), 40, UI.CAFE, 700)

func _titulo() -> String:
	return {"salto": "Salto Nova", "lluvia": "Lluvia de bellotas", "memoria": "Memoria", "cohete": "Cohete Avellana"}.get(tipo, "")

func _ayuda() -> String:
	return {"salto": "Mueve el dedo para guiar a Pip", "lluvia": "Atrapa las bellotas, ¡no las piñas!",
		"cohete": "Toca para subir"}.get(tipo, "")

func _fondo(c1: Color, c2: Color) -> void:
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	draw_polygon(pts, PackedColorArray([c1, c1, c2, c2]))

func _dibujar_salto() -> void:
	var k := clampf(altura / 8000.0, 0.0, 1.0)
	_fondo(Color("#7cc4ff").lerp(Color("#1a0b3d"), k), Color("#e4f5ff").lerp(Color("#6a2c91"), k))
	if k > 0.3:
		for i in 40:
			var x := fposmod(i * 173.0, size.x)
			var y := fposmod(i * 311.0 - camy * 0.2, size.y)
			draw_circle(Vector2(x, y), 2.0, Color(1, 1, 1, (k - 0.3) * 1.4))
	for n in nubes:
		if not n[3]:
			continue
		var p := Vector2(float(n[0]), float(n[1]) - camy)
		var col := Color.WHITE if n[2] == 0 else (Color("#ffe6f2") if n[2] == 1 else Color("#d8d8e0"))
		for j in 3:
			draw_circle(p + Vector2((j - 1) * 38, -6 if j == 1 else 0), 30 if j == 1 else 24, col)
		draw_rect(Rect2(p + Vector2(-62, -2), Vector2(124, 22)), col)
		if n[2] == 2:
			draw_line(p + Vector2(-20, -10), p + Vector2(10, 14), Color(0.5, 0.5, 0.6), 3)
	UI.pip2d(self, Vector2(px, py - camy - 30), 46, vy < 0.0)

func _dibujar_lluvia() -> void:
	_fondo(Color("#bfe8ff"), Color("#e9fbd9"))
	draw_rect(Rect2(Vector2(0, size.y - 170), Vector2(size.x, 170)), Color("#8fd16a"))
	# copa del árbol arriba
	for i in 8:
		draw_circle(Vector2(i * size.x / 7.0, 120), 110, Color("#5fae4a").lightened((i % 3) * 0.06))
	for c in cae:
		var p := Vector2(float(c[0]), float(c[1]))
		match c[3]:
			"pina":
				draw_circle(p, 30, Color("#8d5d32"))
				for j in 5:
					draw_arc(p, 30 - j * 5, 0.5, 2.6, 8, Color("#5b3720"), 3)
			"fresa":
				UI.icono_comida(self, "fresa", p, 64)
			"estrella":
				draw_colored_polygon(UI.estrella_pts(p, 32, t * 3.0), UI.ORO)
			_:
				UI.icono(self, "bellota", p, 58)
	UI.pip2d(self, Vector2(px, size.y - 230), 52, true)

func _dibujar_memoria() -> void:
	_fondo(Color("#ffe9d6"), Color("#ffd0e0"))
	for i in cartas.size():
		var c: Dictionary = cartas[i]
		var r := _rect_carta(i)
		var g: float = c.giro
		var sx := absf(cos(g * PI))
		var rr := Rect2(Vector2(r.get_center().x - r.size.x * 0.5 * sx, r.position.y), Vector2(r.size.x * sx, r.size.y))
		if g < 0.5:
			UI.caja(self, rr, UI.NARANJO, 20)
			if sx > 0.3:
				UI.icono(self, "bellota", rr.get_center(), r.size.x * 0.5 * sx, Color.WHITE)
		else:
			UI.caja(self, rr, Color.WHITE if not c.hecha else Color("#e6fff4"), 20)
			if sx > 0.3:
				var cols := {"corazon": UI.ROSA, "estrella": UI.ORO, "pocion": UI.LILA, "nota": UI.AZUL, "pelota": Color("#ff6b6b"), "regalo": UI.MENTA, "luna": UI.LILA}
				UI.icono(self, "habitacion" if c.icono == "luna" else str(c.icono), rr.get_center(), r.size.x * 0.6 * sx, cols.get(c.icono, UI.CAFE))

func _dibujar_cohete() -> void:
	_fondo(Color("#0d1340"), Color("#3a2468"))
	for i in 60:
		var x := fposmod(i * 211.0 - t * (40.0 + (i % 3) * 30.0), size.x)
		var y := fposmod(i * 97.0, size.y)
		draw_circle(Vector2(x, y), 1.5 + (i % 3), Color(1, 1, 1, 0.6))
	var hueco := maxf(250.0, 360.0 - t * 2.0)
	for r in rocas:
		var x: float = r[0]
		var hy: float = r[1]
		_columna(x, 0.0, hy - hueco * 0.5)
		_columna(x, hy + hueco * 0.5, size.y)
	var p := Vector2(size.x * 0.3, ry)
	var ang := clampf(rv / 900.0, -0.5, 0.6)
	draw_set_transform(p, ang, Vector2.ONE)
	# cohete Avellana
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -24), Vector2(30, -24), Vector2(70, 0), Vector2(30, 24), Vector2(-60, 24)]), Color("#e8eef7"))
	draw_colored_polygon(PackedVector2Array([Vector2(30, -24), Vector2(70, 0), Vector2(30, 24)]), Color("#ff5a5f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -24), Vector2(-80, -44), Vector2(-40, -24)]), Color("#ff5a5f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-60, 24), Vector2(-80, 44), Vector2(-40, 24)]), Color("#ff5a5f"))
	draw_circle(Vector2(5, 0), 15, Color("#7fd8ff"))
	var fl := 18.0 + sin(t * 40.0) * 6.0 + (12.0 if rv < 0.0 else 0.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-60, -14), Vector2(-60 - fl * 2.0, 0), Vector2(-60, 14)]), Color("#ffb347"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	UI.pip2d(self, p + Vector2(8, -6).rotated(ang), 13, true)

func _columna(x: float, y0: float, y1: float) -> void:
	if y1 - y0 < 2.0:
		return
	var r := Rect2(Vector2(x - 60, y0), Vector2(120, y1 - y0))
	UI._sb(self, r, Color("#8a7aa8"), 40)
	var y := y0 + 30.0
	while y < y1 - 20.0:
		draw_circle(Vector2(x - 20 + fmod(y, 40.0), y), 10, Color("#6f6090"))
		y += 70.0
