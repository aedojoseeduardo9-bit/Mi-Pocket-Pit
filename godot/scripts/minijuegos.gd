## Pocket Pip — minijuegos 2D a pantalla completa (estilo Pou / Talking Tom):
##  - "salto":   Salto Nova — Pip salta de nube en nube hacia arriba; se mueve con el dedo (izquierda/derecha).
##  - "lluvia":  Lluvia de bellotas — atrapa lo que cae del árbol, evita las piñas (3 vidas).
##  - "memoria": Memoria — 16 cartas, encuentra las parejas antes de que se acabe el tiempo.
##  - "cohete":  Cohete Avellana — toca para subir, pasa entre los asteroides.
## Al terminar: puntaje, récord y bellotas ganadas (con tope por partida). Cuesta un poco de energía y da diversión.
## Diseños que se ganan subiendo de nivel: naves (cohete), dorsos de cartas (memoria) y nubes (salto); se eligen
## antes de empezar con el botón de abajo. Todo se dibuja a mano: fondos en capas, partículas y sacudidas.
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

# efectos
var _parts: Array = []             ## {p, v, vida, max, col, r, g}
var _textos: Array = []            ## {p, txt, vida, col}
var _sacudir := 0.0
var _flash := 0.0
var _flash_col := Color.WHITE

# salto
var px := 0.0
var py := 0.0
var vy := 0.0
var camy := 0.0
var nubes: Array = []              ## [x, y, tipo(0 normal,1 se mueve,2 frágil), vivo, fase, aplaste]
var altura := 0.0
var _aplaste := 0.0                ## Pip se aplasta al rebotar
# lluvia
var cae: Array = []                ## [x, y, vy, clase("bellota","fresa","pina","estrella"), giro]
var vidas := 3
var _gen := 0.0
# memoria
var cartas: Array = []             ## {icono, abierta, hecha, giro, brillo, temblor}
var _abiertas: Array = []
var _espera := 0.0
var tiempo_mem := 60.0
var _empezo := false               ## el reloj de Memoria corre desde la primera carta
# cohete
var rv := 0.0
var ry := 0.0
var rocas: Array = []              ## [x, hueco_y, contado, semilla]
var _dist := 0.0

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
	_parts.clear()
	_textos.clear()
	_sacudir = 0.0
	_flash = 0.0
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
				cartas.append({"icono": i, "abierta": false, "hecha": false, "giro": 0.0, "brillo": 0.0, "temblor": 0.0})
			_abiertas.clear()
			tiempo_mem = 60.0
			_empezo = false
		"cohete":
			ry = H * 0.45
			rv = 0.0
			_dist = 0.0
			rocas.clear()
			for i in 4:
				rocas.append([W + 200.0 + i * 380.0, _rnd.randf_range(H * 0.3, H * 0.7), false, _rnd.randi()])

func _nube_nueva(y: float) -> void:
	var W := size.x if size.x > 0 else 720.0
	var tp := 0
	var r := _rnd.randf()
	if altura > 1500 and r < 0.25:
		tp = 1
	elif altura > 3000 and r < 0.4:
		tp = 2
	nubes.append([_rnd.randf_range(80, W - 80), y, tp, true, _rnd.randf() * TAU, 0.0])

# ---------------- elegir diseño (naves, cartas, nubes) ----------------
func _tipo_skin() -> String:
	return {"cohete": "nave", "memoria": "cartas", "salto": "nubes"}.get(tipo, "")

func _puede_elegir() -> bool:
	var ts := _tipo_skin()
	if ts == "" or fin or Estado.skins_libres(ts).size() < 2:
		return false
	if tipo == "memoria":
		return not _empezo
	return _cuenta > 0.0

func _rect_elegir() -> Rect2:
	return Rect2(Vector2(size.x * 0.5 - 210, size.y - 190), Vector2(420, 100))

func _gui_input(e: InputEvent) -> void:
	accept_event()
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_toque = e.pressed
		_dedo = e.position
		if e.pressed and _puede_elegir() and _rect_elegir().has_point(e.position):
			Estado.cambiar_skin(_tipo_skin())
			Sfx.play("select", 1.1)
			_chispas(_rect_elegir().get_center(), 10, UI.ORO, 220.0, 0.0)
			if tipo != "memoria":
				_cuenta = maxf(_cuenta, 1.6)   # da tiempo para mirar la nave elegida
			return
		if e.pressed and not fin:
			if tipo == "cohete" and _cuenta <= 0.0:
				rv = -620.0
				Sfx.play("jump", 1.3, -6.0)
				_chispas(Vector2(size.x * 0.3 - 70, ry), 6, Color("#ffcf4a"), 160.0, 0.0)
			elif tipo == "memoria":
				_tocar_carta(e.position)
	elif e is InputEventMouseMotion:
		_dedo = e.position

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	t += dt
	_efectos(dt)
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

# ---------------- partículas, textos y sacudida ----------------
func _chispas(p: Vector2, n: int, col: Color, vel := 260.0, grav := 600.0, r := 7.0) -> void:
	for i in n:
		var a := _rnd.randf() * TAU
		var v := Vector2(cos(a), sin(a)) * vel * _rnd.randf_range(0.4, 1.0)
		var m := _rnd.randf_range(0.45, 0.8)
		_parts.append({"p": p, "v": v, "vida": m, "max": m, "col": col, "r": r * _rnd.randf_range(0.6, 1.2), "g": grav})
	if _parts.size() > 220:
		_parts = _parts.slice(_parts.size() - 220)

func _texto_vuela(p: Vector2, txt: String, col: Color) -> void:
	_textos.append({"p": p, "txt": txt, "vida": 0.9, "col": col})

func _efectos(dt: float) -> void:
	var i := _parts.size() - 1
	while i >= 0:
		var q: Dictionary = _parts[i]
		q.vida -= dt
		if q.vida <= 0.0:
			_parts.remove_at(i)
		else:
			q.v.y += float(q.g) * dt
			q.p += q.v * dt
		i -= 1
	i = _textos.size() - 1
	while i >= 0:
		var q: Dictionary = _textos[i]
		q.vida -= dt
		q.p.y -= 90.0 * dt
		if q.vida <= 0.0:
			_textos.remove_at(i)
		i -= 1
	_sacudir = move_toward(_sacudir, 0.0, dt * 40.0)
	_flash = move_toward(_flash, 0.0, dt * 2.5)

func _dibujar_efectos() -> void:
	for q in _parts:
		var k: float = q.vida / q.max
		draw_circle(q.p, float(q.r) * (0.4 + 0.6 * k), Color(q.col, k))
	for q in _textos:
		UI.texto_borde(self, q.p, str(q.txt), 34, Color(q.col, minf(1.0, q.vida * 2.0)), Color(UI.CAFE, minf(1.0, q.vida * 2.0)), 6)

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
	if nuevo:
		for k in 4:
			_chispas(Vector2(W * (0.2 + k * 0.2), H * 0.3), 14, [UI.ORO, UI.ROSA, UI.MENTA, UI.AZUL][k], 420.0, 500.0, 9.0)
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
	_aplaste = move_toward(_aplaste, 0.0, dt * 4.0)
	if vy > 0.0:
		for n in nubes:
			if not n[3]:
				continue
			var ny: float = n[1]
			if y0 <= ny - 30.0 and py >= ny - 30.0 and absf(px - float(n[0])) < 80.0:
				vy = -1150.0
				py = ny - 30.0
				_aplaste = 1.0
				n[5] = 1.0
				Sfx.play("jump", randf_range(1.0, 1.2), -8.0)
				_chispas(Vector2(px, ny - camy - 6), 8, Color(1, 1, 1, 0.9), 200.0, 200.0, 9.0)
				if n[2] == 2:
					n[3] = false
					_chispas(Vector2(float(n[0]), ny - camy), 14, Color("#d8d8e0"), 260.0, 900.0, 10.0)
				break
	for n in nubes:
		n[5] = move_toward(float(n[5]), 0.0, dt * 4.0)
		if n[2] == 1:
			n[4] += dt * 1.6
			n[0] = clampf(float(n[0]) + cos(float(n[4])) * 140.0 * dt, 70.0, W - 70.0)
	# estela de brillitos mientras sube rápido
	if vy < -700.0 and int(t * 30.0) != int((t - dt) * 30.0):
		_chispas(Vector2(px, py - camy + 10), 1, Color("#fff3c4"), 40.0, 0.0, 6.0)
	# la cámara sube con Pip (nunca baja)
	var lim := H * 0.42
	if py - camy < lim:
		var dy := (py - camy) - lim
		camy = py - lim
		for q in _parts:
			q.p.y -= dy
	altura = maxf(altura, -camy)
	var antes := puntos
	puntos = int(altura / 10.0)
	if puntos / 100 > antes / 100:
		_texto_vuela(Vector2(W * 0.5, H * 0.3), L.f("%d m", [puntos / 100 * 100]), UI.ORO)
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
		cae.append([_rnd.randf_range(60, W - 60), 180.0, 260.0 + t * 6.0 + _rnd.randf() * 120.0, cl, _rnd.randf_range(-3.0, 3.0)])
	var y_pip := H - 230.0
	var i := cae.size() - 1
	while i >= 0:
		var c: Array = cae[i]
		c[1] += c[2] * dt
		var p := Vector2(float(c[0]), float(c[1]))
		if absf(float(c[1]) - y_pip) < 50.0 and absf(float(c[0]) - px) < 80.0:
			match c[3]:
				"pina":
					vidas -= 1
					Sfx.play("deny")
					_sacudir = 18.0
					_flash = 0.6
					_flash_col = Color("#ff3b30")
					_chispas(p, 12, Color("#8d5d32"), 300.0, 900.0, 9.0)
					if vidas <= 0:
						_terminar()
				"estrella":
					puntos += 5
					Sfx.play("crystal")
					_chispas(p, 16, UI.ORO, 360.0, 300.0, 8.0)
					_texto_vuela(p + Vector2(0, -40), "+5", UI.ORO)
				"fresa":
					puntos += 2
					Sfx.play("coin", 1.2)
					_chispas(p, 8, Color("#ff5a6e"), 240.0, 500.0)
					_texto_vuela(p + Vector2(0, -40), "+2", Color("#ff8fb3"))
				_:
					puntos += 1
					Sfx.play("coin", randf_range(0.95, 1.1), -4.0)
					_chispas(p, 6, Color("#ffd36e"), 200.0, 500.0)
					_texto_vuela(p + Vector2(0, -40), "+1", Color.WHITE)
			cae.remove_at(i)
		elif float(c[1]) > H - 150.0:
			_chispas(Vector2(p.x, H - 150.0), 4, Color("#6fc157"), 140.0, 700.0, 6.0)
			cae.remove_at(i)
		i -= 1

# ---------------- Memoria ----------------
func _rect_carta(i: int) -> Rect2:
	var W := size.x
	var H := size.y
	var cw := minf((W - 80.0) / 4.0, (H - 560.0) / 4.0)
	var x0 := (W - cw * 4.0) * 0.5
	var y0 := 290.0
	return Rect2(Vector2(x0 + (i % 4) * cw + 6, y0 + (i / 4) * cw + 6), Vector2(cw - 12, cw - 12))

func _tocar_carta(p: Vector2) -> void:
	if _espera > 0.0:
		return
	for i in cartas.size():
		var c: Dictionary = cartas[i]
		if c.hecha or c.abierta:
			continue
		if _rect_carta(i).has_point(p):
			_empezo = true
			c.abierta = true
			_abiertas.append(i)
			Sfx.play("tic", 1.2)
			if _abiertas.size() == 2:
				var a: Dictionary = cartas[_abiertas[0]]
				var b: Dictionary = cartas[_abiertas[1]]
				if a.icono == b.icono:
					a.hecha = true
					b.hecha = true
					a.brillo = 1.0
					b.brillo = 1.0
					var gana := 10 + int(tiempo_mem / 6.0)
					puntos += gana
					for k in _abiertas:
						var rc := _rect_carta(k)
						_chispas(rc.get_center(), 12, UI.ORO, 300.0, 300.0, 8.0)
					_texto_vuela(_rect_carta(_abiertas[1]).get_center(), "+%d" % gana, UI.ORO)
					_abiertas.clear()
					Sfx.play("coin", 1.2)
				else:
					a.temblor = 1.0
					b.temblor = 1.0
					_espera = 0.8
			return

func _memoria(dt: float) -> void:
	if _empezo:
		tiempo_mem -= dt
	for c in cartas:
		c.giro = move_toward(c.giro, 1.0 if (c.abierta or c.hecha) else 0.0, dt * 5.0)
		c.brillo = move_toward(c.brillo, 0.0, dt * 1.2)
		c.temblor = move_toward(c.temblor, 0.0, dt * 2.0)
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
	_dist += vel * dt
	var hueco := maxf(250.0, 360.0 - t * 2.0)
	var rx := W * 0.3
	# humo del motor
	if int(t * 40.0) != int((t - dt) * 40.0):
		var ang := clampf(rv / 900.0, -0.5, 0.6)
		_parts.append({"p": Vector2(rx, ry) + Vector2(-72, 0).rotated(ang), "v": Vector2(-vel * 0.9, _rnd.randf_range(-30, 30)),
			"vida": 0.5, "max": 0.5, "col": Color("#ffb347") if _rnd.randf() < 0.5 else Color("#ffe08a"), "r": 9.0, "g": 0.0})
	for r in rocas:
		r[0] -= vel * dt
		if float(r[0]) < -140.0:
			var mx := 0.0
			for q in rocas:
				mx = maxf(mx, float(q[0]))
			r[0] = mx + 380.0
			r[1] = _rnd.randf_range(H * 0.28, H * 0.72)
			r[2] = false
			r[3] = _rnd.randi()
		if not r[2] and float(r[0]) < rx:
			r[2] = true
			puntos += 1
			Sfx.play("coin", 1.3, -6.0)
			_chispas(Vector2(float(r[0]), float(r[1])), 8, UI.ORO, 220.0, 0.0)
			_texto_vuela(Vector2(float(r[0]), float(r[1]) - 30), "+1", UI.ORO)
		if absf(float(r[0]) - rx) < 75.0 and absf(ry - float(r[1])) > hueco * 0.5 - 30.0:
			_choque()
	if ry < 140.0 or ry > H - 90.0:
		_choque()

func _choque() -> void:
	_sacudir = 26.0
	_flash = 0.8
	_flash_col = Color("#ffb347")
	var p := Vector2(size.x * 0.3, ry)
	_chispas(p, 30, Color("#ffb347"), 520.0, 300.0, 11.0)
	_chispas(p, 16, Color("#e8eef7"), 380.0, 600.0, 8.0)
	Sfx.play("deny")
	_terminar()

# ---------------- dibujo ----------------
func _draw() -> void:
	var W := size.x
	var H := size.y
	var off := Vector2.ZERO
	if _sacudir > 0.0:
		off = Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir
	draw_set_transform(off, 0.0, Vector2.ONE)
	match tipo:
		"salto": _dibujar_salto()
		"lluvia": _dibujar_lluvia()
		"memoria": _dibujar_memoria()
		"cohete": _dibujar_cohete()
	_dibujar_efectos()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(_flash_col, _flash * 0.35))
	# barra de arriba
	UI.caja(self, Rect2(Vector2(W * 0.5 - 170, 46), Vector2(340, 84)), Color(1, 1, 1, 0.92), 42)
	UI.texto(self, Vector2(W * 0.5, 76), _titulo(), 22, UI.CAFE2, 600)
	UI.texto(self, Vector2(W * 0.5, 106), str(puntos), 34, UI.CAFE, 700)
	if tipo == "lluvia":
		for i in 3:
			draw_colored_polygon(UI.corazon_pts(Vector2(W - 150 + i * 46, 88), 34), UI.ROSA if i < vidas else Color(0, 0, 0, 0.15))
	if tipo == "memoria":
		var k := clampf(tiempo_mem / 60.0, 0.0, 1.0)
		var r := Rect2(Vector2(60, 160), Vector2(W - 120, 22))
		UI._sb(self, r, Color(1, 1, 1, 0.7), 11)
		UI._sb(self, Rect2(r.position, Vector2(maxf(22.0, r.size.x * k), r.size.y)), UI.MENTA if k > 0.3 else UI.ROJO, 11)
		UI.texto(self, Vector2(W - 90, 88), "%d s" % maxi(0, int(tiempo_mem)), 28, UI.CAFE, 700)
	if _puede_elegir():
		_dibujar_elegir()
	if _cuenta > 0.0 and not fin:
		var n := int(ceil(_cuenta / 0.8))
		var k := fmod(_cuenta, 0.8) / 0.8
		draw_set_transform(Vector2(W * 0.5, H * 0.42), 0.0, Vector2.ONE * (0.8 + 0.4 * k))
		UI.texto_borde(self, Vector2.ZERO, str(n), 140, UI.ORO, UI.CAFE, 18)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
		if get_meta("nuevo", false):
			_dibujar_efectos()

## Botón de abajo para cambiar la nave, las cartas o las nubes (solo antes de empezar).
func _dibujar_elegir() -> void:
	var r := _rect_elegir()
	var ts := _tipo_skin()
	var x: Dictionary = Estado.busca(Estado.lista_skin(ts), Estado.skin(ts))
	UI.caja(self, r, Color(1, 1, 1, 0.95), 50)
	var ic := Rect2(r.position + Vector2(14, 10), Vector2(80, 80))
	match ts:
		"nave": dibujar_nave(self, str(x.id), ic.get_center(), 0.42, 0.0, t)
		"cartas": dibujar_dorso(self, str(x.id), ic.grow(-8), t)
		"nubes": dibujar_nube(self, str(x.id), ic.get_center() + Vector2(0, 6), 0.55, t)
	UI.texto(self, Vector2(r.position.x + 250, r.position.y + 36), Estado.nombre(x), 24, UI.CAFE, 700)
	UI.texto(self, Vector2(r.position.x + 250, r.position.y + 70), "Toca para cambiar", 19, UI.CAFE2, 500)

func _titulo() -> String:
	return {"salto": "Salto Nova", "lluvia": "Lluvia de bellotas", "memoria": "Memoria", "cohete": "Cohete Avellana"}.get(tipo, "")

func _ayuda() -> String:
	return {"salto": "Mueve el dedo para guiar a Pip", "lluvia": "Atrapa las bellotas, ¡no las piñas!",
		"cohete": "Toca para subir"}.get(tipo, "")

func _fondo(c1: Color, c2: Color) -> void:
	var pts := PackedVector2Array([Vector2(-40, -40), Vector2(size.x + 40, -40), size + Vector2(40, 40), Vector2(-40, size.y + 40)])
	draw_polygon(pts, PackedColorArray([c1, c1, c2, c2]))

## Cerro suave de fondo (una sola figura) para dar profundidad.
func _cerros(y: float, alto: float, col: Color, fase: float, onda := 0.006) -> void:
	var pts := PackedVector2Array()
	var W := size.x
	for i in 25:
		var x := -40.0 + (W + 80.0) * i / 24.0
		pts.append(Vector2(x, y - alto * (0.5 + 0.5 * sin(x * onda + fase)) - alto * 0.3 * sin(x * onda * 2.3 + fase * 1.7)))
	pts.append(Vector2(W + 40, size.y + 40))
	pts.append(Vector2(-40, size.y + 40))
	draw_colored_polygon(pts, col)

func _dibujar_salto() -> void:
	var W := size.x
	var H := size.y
	var k := clampf(altura / 8000.0, 0.0, 1.0)
	_fondo(Color("#7cc4ff").lerp(Color("#1a0b3d"), k), Color("#e4f5ff").lerp(Color("#6a2c91"), k))
	# cerros lejanos que se quedan abajo al subir
	var base := H + 60.0 - camy * 0.25
	if base < H + 500.0:
		_cerros(base - 160.0, 120.0, Color("#b9e3c6", 1.0 - k), 1.0)
		_cerros(base - 60.0, 90.0, Color("#8fd16a", 1.0 - k), 3.0, 0.009)
	# nubes grandes y suaves de fondo (más lentas)
	for i in 6:
		var x := fposmod(i * 251.0 + t * 12.0, W + 300.0) - 150.0
		var y := fposmod(i * 389.0 - camy * 0.45, H + 300.0) - 150.0
		var col := Color(1, 1, 1, 0.35 * (1.0 - k * 0.7))
		for j in 3:
			draw_circle(Vector2(x + (j - 1) * 60, y - (14 if j == 1 else 0)), 56 if j == 1 else 42, col)
	# estrellas y planetas cuando ya es de noche
	if k > 0.25:
		for i in 50:
			var x := fposmod(i * 173.0, W)
			var y := fposmod(i * 311.0 - camy * 0.2, H)
			var tw := 0.6 + 0.4 * sin(t * 3.0 + i)
			draw_circle(Vector2(x, y), 1.5 + (i % 3) * 0.8, Color(1, 1, 1, (k - 0.25) * 1.3 * tw))
		var pp := Vector2(W * 0.78, fposmod(300.0 - camy * 0.1, H + 400.0) - 200.0)
		draw_circle(pp, 70, Color("#ff8f6b", (k - 0.25) * 1.3))
		draw_arc(pp, 105, 0.2, PI - 0.2, 24, Color("#ffe0b0", (k - 0.25)), 8)
	var sk := Estado.skin("nubes")
	for n in nubes:
		if not n[3]:
			continue
		var p := Vector2(float(n[0]), float(n[1]) - camy + float(n[5]) * 8.0)
		draw_set_transform(p + Vector2(0, 12) + (Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir), 0.0, Vector2(1.0, 0.25))
		draw_circle(Vector2.ZERO, 62, Color(0, 0, 0, 0.08))
		draw_set_transform(Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2.ONE)
		dibujar_nube(self, sk, p, 1.0, t + float(n[4]), int(n[2]))
	# Pip se estira al subir y se aplasta al rebotar
	var est := clampf(-vy / 1150.0, -0.6, 1.0)
	var sc := Vector2(1.0 + _aplaste * 0.25 - maxf(0.0, est) * 0.08, 1.0 - _aplaste * 0.22 + maxf(0.0, est) * 0.1)
	draw_set_transform(Vector2(px, py - camy - 30), 0.0, sc)
	UI.pip2d(self, Vector2.ZERO, 46, vy < 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _dibujar_lluvia() -> void:
	var W := size.x
	var H := size.y
	_fondo(Color("#9fd8ff"), Color("#eaffd9"))
	# sol con rayos que giran
	var sol := Vector2(W - 120, 330)
	for i in 12:
		var a := TAU * i / 12.0 + t * 0.3
		draw_colored_polygon(PackedVector2Array([sol + Vector2(cos(a - 0.12), sin(a - 0.12)) * 70, sol + Vector2(cos(a), sin(a)) * 118, sol + Vector2(cos(a + 0.12), sin(a + 0.12)) * 70]), Color("#ffe066", 0.6))
	draw_circle(sol, 64, Color("#ffd23f"))
	draw_circle(sol + Vector2(-16, -16), 18, Color(1, 1, 1, 0.35))
	_cerros(H - 260.0, 110.0, Color("#bfe8c0"), 0.5)
	_cerros(H - 190.0, 80.0, Color("#9ed98a"), 2.2, 0.01)
	# pasto con matitas
	draw_rect(Rect2(Vector2(-40, H - 170), Vector2(W + 80, 210)), Color("#8fd16a"))
	draw_rect(Rect2(Vector2(-40, H - 170), Vector2(W + 80, 14)), Color("#a8e07f"))
	for i in 22:
		var x := fposmod(i * 97.0, W)
		var y := H - 150.0 + (i % 4) * 32.0
		for j in 3:
			draw_line(Vector2(x, y), Vector2(x + (j - 1) * 8, y - 18 - j * 3), Color("#6fb84f"), 3)
	# árbol: tronco, ramas y copa en capas con bellotas colgando
	draw_rect(Rect2(Vector2(W * 0.5 - 40, -10), Vector2(80, 150)), Color("#8d5d32"))
	for i in 9:
		var cx := -60.0 + i * (W + 120.0) / 8.0
		draw_circle(Vector2(cx, 70), 125, Color("#4f9a3e"))
	for i in 9:
		var cx := -20.0 + i * (W + 40.0) / 8.0
		draw_circle(Vector2(cx, 120 + (i % 2) * 14), 92, Color("#5fae4a").lightened((i % 3) * 0.05))
	for i in 8:
		var cx := 30.0 + i * (W - 60.0) / 7.0
		draw_circle(Vector2(cx - 20, 110), 34, Color(1, 1, 1, 0.08))
		var by := 200.0 + (i % 3) * 14.0 + sin(t * 2.0 + i) * 3.0
		UI.icono(self, "bellota", Vector2(cx, by), 34)
	# sombras en el suelo de lo que cae
	for c in cae:
		var k := clampf((float(c[1]) - 180.0) / (H - 380.0), 0.0, 1.0)
		draw_set_transform(Vector2(float(c[0]), H - 160.0) + Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, 10.0 + 22.0 * k, Color(0, 0, 0, 0.06 + 0.12 * k))
	draw_set_transform(Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2.ONE)
	for c in cae:
		var p := Vector2(float(c[0]), float(c[1]))
		var off := Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir
		draw_set_transform(p + off, t * float(c[4]) * 0.4, Vector2.ONE)
		match c[3]:
			"pina":
				draw_circle(Vector2.ZERO, 32, Color("#8d5d32"))
				for j in 4:
					for q in 3:
						draw_circle(Vector2(-14 + q * 14 + (j % 2) * 7, -18 + j * 12), 6, Color("#6b4226"))
				draw_colored_polygon(PackedVector2Array([Vector2(-10, -30), Vector2(0, -50), Vector2(10, -30)]), Color("#5fae4a"))
			"fresa":
				UI.icono_comida(self, "fresa", Vector2.ZERO, 64)
			"estrella":
				draw_circle(Vector2.ZERO, 40, Color(UI.ORO, 0.25 + 0.15 * sin(t * 10.0)))
				draw_colored_polygon(UI.estrella_pts(Vector2.ZERO, 32, t * 3.0), UI.ORO)
			_:
				UI.icono(self, "bellota", Vector2.ZERO, 58)
	draw_set_transform(Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2.ONE)
	# Pip con una canasta
	var pp := Vector2(px, H - 230)
	draw_set_transform(pp + Vector2(0, 52) + Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2(1.0, 0.25))
	draw_circle(Vector2.ZERO, 60, Color(0, 0, 0, 0.12))
	draw_set_transform(Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2.ONE)
	UI.pip2d(self, pp, 52, true)
	UI._sb(self, Rect2(pp + Vector2(-64, 26), Vector2(128, 40)), Color("#c58a4a"), 16)
	for j in 4:
		draw_line(pp + Vector2(-56 + j * 36, 30), pp + Vector2(-48 + j * 36, 62), Color("#a8743f"), 4)
	draw_arc(pp + Vector2(0, 28), 58, PI + 0.3, TAU - 0.3, 16, Color("#a8743f"), 6)

func _dibujar_memoria() -> void:
	var W := size.x
	var H := size.y
	_fondo(Color("#ffe9d6"), Color("#ffd0e0"))
	# fondo con corazones y estrellitas que flotan
	for i in 14:
		var p := Vector2(fposmod(i * 157.0, W), fposmod(i * 263.0 - t * 18.0, H + 80.0) - 40.0)
		if i % 2 == 0:
			draw_colored_polygon(UI.corazon_pts(p, 30), Color(1, 1, 1, 0.35))
		else:
			draw_colored_polygon(UI.estrella_pts(p, 14, t * 0.5 + i), Color(1, 1, 1, 0.4))
	var sk := Estado.skin("cartas")
	for i in cartas.size():
		var c: Dictionary = cartas[i]
		var r := _rect_carta(i)
		r.position.x += sin(float(c.temblor) * 30.0) * 8.0 * float(c.temblor)
		var g: float = c.giro
		var sx := absf(cos(g * PI))
		var alza := sin(g * PI) * 14.0
		var rr := Rect2(Vector2(r.get_center().x - r.size.x * 0.5 * sx, r.position.y - alza), Vector2(r.size.x * sx, r.size.y))
		if g < 0.5:
			UI.caja(self, rr, Color.WHITE, 20)
			if sx > 0.05:
				dibujar_dorso(self, sk, rr.grow(-4), t + i * 0.3)
		else:
			if c.brillo > 0.0:
				UI._sb(self, rr.grow(10.0 * float(c.brillo)), Color(UI.ORO, 0.6 * float(c.brillo)), 26)
			UI.caja(self, rr, Color.WHITE if not c.hecha else Color("#e6fff4"), 20)
			if sx > 0.3:
				var cols := {"corazon": UI.ROSA, "estrella": UI.ORO, "pocion": UI.LILA, "nota": UI.AZUL, "pelota": Color("#ff6b6b"), "regalo": UI.MENTA, "luna": UI.LILA}
				UI.icono(self, "habitacion" if c.icono == "luna" else str(c.icono), rr.get_center(), r.size.x * 0.6 * sx, cols.get(c.icono, UI.CAFE))
				if c.hecha:
					UI.icono(self, "check", rr.position + Vector2(rr.size.x - 22, 22), 30 * sx, UI.MENTA)

func _dibujar_cohete() -> void:
	var W := size.x
	var H := size.y
	_fondo(Color("#0b1033"), Color("#3a2468"))
	# nebulosas lejanas
	for i in 4:
		var x := fposmod(i * 340.0 - _dist * 0.05, W + 600.0) - 300.0
		var y := 260.0 + (i * 293) % int(H - 400)
		var col: Color = [Color("#ff8fe0"), Color("#7fd8ff"), Color("#b49cff"), Color("#7be08a")][i]
		for j in 3:
			draw_circle(Vector2(x + j * 70 - 70, y + sin(j * 2.0 + i) * 40), 130 - j * 20, Color(col, 0.07))
	# estrellas en 3 capas
	for i in 70:
		var capa := i % 3
		var x := fposmod(i * 211.0 - _dist * (0.15 + capa * 0.25), W)
		var y := fposmod(i * 97.0 + capa * 41.0, H)
		draw_circle(Vector2(x, y), 1.2 + capa, Color(1, 1, 1, 0.35 + capa * 0.2))
	# planeta que pasa muy lento
	var pp := Vector2(fposmod(W * 0.8 - _dist * 0.08, W + 500.0) - 250.0, H * 0.25)
	var sh := Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir
	draw_set_transform(pp + sh, -0.25, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 150, PI, TAU, 32, Color("#e0b890"), 14)
	draw_set_transform(sh, 0.0, Vector2.ONE)
	draw_circle(pp, 90, Color("#ff8f6b"))
	draw_circle(pp + Vector2(-25, -25), 60, Color("#ffb08f"))
	draw_circle(pp + Vector2(20, 30), 18, Color("#e06d4f"))
	draw_set_transform(pp + Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, -0.25, Vector2(1.0, 0.28))
	draw_arc(Vector2.ZERO, 150, 0.0, PI, 32, Color("#ffe0b0"), 14)
	draw_set_transform(Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 0.0, Vector2.ONE)
	var hueco := maxf(250.0, 360.0 - t * 2.0)
	for r in rocas:
		var x: float = r[0]
		var hy: float = r[1]
		_asteroides(x, 0.0, hy - hueco * 0.5, int(r[3]))
		_asteroides(x, hy + hueco * 0.5, size.y, int(r[3]) + 7)
	var p := Vector2(size.x * 0.3, ry)
	var ang := clampf(rv / 900.0, -0.5, 0.6)
	if not fin:
		dibujar_nave(self, Estado.skin("nave"), p + Vector2(sin(t * 90.0), cos(t * 77.0)) * _sacudir, 1.0, ang, t, rv < 0.0)

## Columna de rocas espaciales: piedras irregulares apiladas con cráteres (siempre iguales para cada columna).
func _asteroides(x: float, y0: float, y1: float, semilla: int) -> void:
	if y1 - y0 < 2.0:
		return
	var rnd := RandomNumberGenerator.new()
	rnd.seed = semilla
	var y := y0 - 20.0
	while y < y1 + 20.0:
		var r := rnd.randf_range(44.0, 62.0)
		var c := Vector2(x + rnd.randf_range(-14, 14), clampf(y + r * 0.6, y0 + r * 0.6, y1 - r * 0.6) if y1 - y0 > r * 1.2 else (y0 + y1) * 0.5)
		var pts := PackedVector2Array()
		for i in 11:
			var a := TAU * i / 11.0
			pts.append(c + Vector2(cos(a), sin(a)) * r * rnd.randf_range(0.8, 1.05))
		draw_colored_polygon(pts, Color("#7d6e9a"))
		draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.45, Color("#9586b2"))
		for k in 2:
			var cp := c + Vector2(rnd.randf_range(-r * 0.4, r * 0.4), rnd.randf_range(-r * 0.3, r * 0.4))
			draw_circle(cp, r * 0.17, Color("#5f5280"))
			draw_circle(cp + Vector2(-2, -2), r * 0.12, Color("#6f6290"))
		y += r * 1.1

# ================= diseños (también los usa la ventana de regalos de nivel) =================
## Nave del Cohete Avellana. esc 1.0 = tamaño de juego (~140 px de largo).
static func dibujar_nave(ci: CanvasItem, id: String, p: Vector2, esc: float, ang: float, tt: float, empuje := false) -> void:
	ci.draw_set_transform(p, ang, Vector2.ONE * esc)
	var fl := 18.0 + sin(tt * 40.0) * 6.0 + (12.0 if empuje else 0.0)
	match id:
		"platillo":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-30, 14), Vector2(30, 14), Vector2(50, 40), Vector2(-50, 40)]), Color(0.6, 0.95, 1.0, 0.25))
			ci.draw_set_transform(p, ang, Vector2(esc, esc * 0.35))
			ci.draw_circle(Vector2.ZERO, 74, Color("#9aa3b5"))
			ci.draw_circle(Vector2(0, -6), 68, Color("#cfd6e2"))
			ci.draw_set_transform(p, ang, Vector2.ONE * esc)
			ci.draw_circle(Vector2(0, -14), 30, Color(0.55, 0.9, 1.0, 0.85))
			UI.pip2d(ci, Vector2(0, -12), 15, true)
			for i in 6:
				var on := int(tt * 6.0 + i) % 3 == 0
				ci.draw_circle(Vector2(-55 + i * 22, 6), 6, Color("#ffe066") if on else Color("#ff8fe0"))
		"dorado":
			_cuerpo_cohete(ci, Color("#ffd36e"), Color("#e0a020"), Color("#7fd8ff"), fl)
			for k in 2:
				ci.draw_rect(Rect2(Vector2(-40 + k * 34, -24), Vector2(8, 48)), Color("#fff3c4"))
			ci.draw_colored_polygon(UI.estrella_pts(Vector2(-18, 0), 12, 0.0), Color.WHITE)
			UI.pip2d(ci, Vector2(8, -6), 13, true)
		"ovni_alien":
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-66, 10), Vector2(-20, -30), Vector2(40, -26), Vector2(72, 4), Vector2(40, 26), Vector2(-30, 26)]), Color("#4cc38a"))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-50, 10), Vector2(-16, -20), Vector2(34, -18), Vector2(58, 4)]), Color("#7be08a"))
			ci.draw_circle(Vector2(10, -10), 20, Color(0.8, 0.6, 1.0, 0.85))
			UI.pip2d(ci, Vector2(10, -8), 12, true)
			for i in 3:
				var tl := Vector2(-66 - fl * 0.6, -8 + i * 10)
				ci.draw_line(Vector2(-60, -8 + i * 10), tl + Vector2(0, sin(tt * 12.0 + i) * 6.0), Color("#c77dff"), 5)
			for i in 4:
				ci.draw_circle(Vector2(-36 + i * 22, 20), 4, Color("#c77dff") if int(tt * 5.0 + i) % 2 else Color("#ffffff"))
		"cristal":
			var cr := Color(0.7, 0.95, 1.0, 0.85)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, 0), Vector2(-10, -36), Vector2(76, 0), Vector2(-10, 36)]), cr)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, -36), Vector2(76, 0), Vector2(10, 0)]), Color(1, 1, 1, 0.6))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, 0), Vector2(-10, 36), Vector2(10, 0)]), Color(0.5, 0.8, 1.0, 0.7))
			ci.draw_circle(Vector2(0, 0), 46, Color(0.7, 0.95, 1.0, 0.12 + 0.08 * sin(tt * 6.0)))
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, -10), Vector2(-60 - fl * 2.2, 0), Vector2(-60, 10)]), Color("#b8f0ff"))
			UI.pip2d(ci, Vector2(10, -4), 12, true)
		"estrella_nova":
			ci.draw_circle(Vector2.ZERO, 62, Color(1.0, 0.85, 0.3, 0.18 + 0.1 * sin(tt * 5.0)))
			ci.draw_colored_polygon(UI.estrella_pts(Vector2.ZERO, 56, tt * 1.5), Color("#ffcf4a"))
			ci.draw_colored_polygon(UI.estrella_pts(Vector2.ZERO, 40, tt * 1.5), Color("#ffe58a"))
			for i in 3:
				ci.draw_circle(Vector2(-60 - i * 18 - fl * 0.4, sin(tt * 10.0 + i) * 8.0), 8 - i * 2, Color("#fff3c4", 0.8 - i * 0.2))
			UI.pip2d(ci, Vector2(0, 2), 16, true)
		_:
			_cuerpo_cohete(ci, Color("#e8eef7"), Color("#ff5a5f"), Color("#7fd8ff"), fl)
			UI.pip2d(ci, Vector2(8, -6), 13, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

static func _cuerpo_cohete(ci: CanvasItem, cuerpo: Color, detalle: Color, vidrio: Color, fl: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, -14), Vector2(-60 - fl * 2.0, 0), Vector2(-60, 14)]), Color("#ffb347"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, -8), Vector2(-60 - fl * 1.2, 0), Vector2(-60, 8)]), Color("#fff3c4"))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, -24), Vector2(30, -24), Vector2(70, 0), Vector2(30, 24), Vector2(-60, 24)]), cuerpo)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, 10), Vector2(30, 10), Vector2(50, 12), Vector2(30, 24), Vector2(-60, 24)]), cuerpo.darkened(0.12))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(30, -24), Vector2(70, 0), Vector2(30, 24)]), detalle)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, -24), Vector2(-80, -44), Vector2(-40, -24)]), detalle)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-60, 24), Vector2(-80, 44), Vector2(-40, 24)]), detalle)
	ci.draw_circle(Vector2(5, 0), 15, vidrio)
	ci.draw_circle(Vector2(0, -5), 5, Color(1, 1, 1, 0.6))

## Dorso de una carta de Memoria dentro del rectángulo r.
static func dibujar_dorso(ci: CanvasItem, id: String, r: Rect2, tt: float) -> void:
	if r.size.x < 2.0:
		return
	var c := r.get_center()
	var m := minf(r.size.x, r.size.y)
	match id:
		"estrellas":
			UI._sb(ci, r, Color("#2f3170"), 16)
			for i in 6:
				var p := r.position + Vector2(r.size.x * fposmod(i * 0.37 + 0.1, 0.9) + r.size.x * 0.05, r.size.y * (0.12 + i * 0.15))
				ci.draw_colored_polygon(UI.estrella_pts(p, m * (0.06 + (i % 2) * 0.03), tt * 0.5 + i), Color("#ffe066"))
			ci.draw_colored_polygon(UI.estrella_pts(c, m * 0.24, 0.0), Color("#ffcf4a"))
		"galaxia":
			UI._sb(ci, r, Color("#3a1d6e"), 16)
			UI._sb(ci, r.grow(-m * 0.1), Color("#5b2a91"), 12)
			for k in 3:
				ci.draw_arc(c, m * (0.12 + k * 0.1), tt * (0.8 + k * 0.3) + k, tt * (0.8 + k * 0.3) + k + 2.2, 16, Color(["#ff8fe0", "#7fd8ff", "#c3a6ff"][k]), maxf(1.5, m * 0.04))
			ci.draw_circle(c, m * 0.08, Color("#fff3c4"))
			for i in 5:
				ci.draw_circle(r.position + Vector2(r.size.x * fposmod(i * 0.29 + 0.12, 0.85) + r.size.x * 0.07, r.size.y * (0.1 + i * 0.19)), maxf(1.0, m * 0.02), Color.WHITE)
		"dulces":
			UI._sb(ci, r, Color("#ffd1e8"), 16)
			var w := r.size.x / 6.0
			for i in 6:
				if i % 2 == 0:
					ci.draw_rect(Rect2(Vector2(r.position.x + i * w, r.position.y + m * 0.08), Vector2(w, r.size.y - m * 0.16)), Color("#ffffff", 0.7))
			ci.draw_line(c + Vector2(0, m * 0.05), c + Vector2(0, m * 0.38), Color("#ffffff"), maxf(2.0, m * 0.05))
			ci.draw_circle(c - Vector2(0, m * 0.06), m * 0.2, Color("#ff5a8a"))
			ci.draw_arc(c - Vector2(0, m * 0.06), m * 0.12, tt, tt + 4.0, 12, Color.WHITE, maxf(2.0, m * 0.04))
		"neon":
			UI._sb(ci, r, Color("#14102a"), 16)
			var b := 0.7 + 0.3 * sin(tt * 4.0)
			var rr := r.grow(-m * 0.08)
			for k in 2:
				var col := Color("#3cf0ff", b) if k == 0 else Color("#ff4fd8", b)
				var q := rr.grow(-k * m * 0.07)
				ci.draw_polyline(PackedVector2Array([q.position, Vector2(q.end.x, q.position.y), q.end, Vector2(q.position.x, q.end.y), q.position]), col, maxf(1.5, m * 0.03))
			ci.draw_colored_polygon(UI.corazon_pts(c, m * 0.4), Color("#ff4fd8", b))
		_:
			UI._sb(ci, r, UI.NARANJO, 16)
			if r.size.x > m * 0.3:
				UI.icono(ci, "bellota", c, m * 0.55, Color.WHITE)

## Plataforma de Salto Nova (tp: 0 normal, 1 se mueve, 2 frágil).
static func dibujar_nube(ci: CanvasItem, id: String, p: Vector2, esc: float, tt: float, tp := 0) -> void:
	ci.draw_set_transform(p, 0.0, Vector2.ONE * esc)
	match id:
		"arcoiris":
			var cols := [Color("#ff6b6b"), Color("#ffb347"), Color("#ffe066"), Color("#7be08a"), Color("#6fb8ff"), Color("#b49cff")]
			for i in cols.size():
				ci.draw_rect(Rect2(Vector2(-62, 6 + i * 4), Vector2(124, 4)), cols[i])
			var col := Color.WHITE if tp != 2 else Color("#e2e2ea")
			for j in 3:
				ci.draw_circle(Vector2((j - 1) * 38, -6 if j == 1 else 0), 30 if j == 1 else 24, col)
			ci.draw_rect(Rect2(Vector2(-62, -2), Vector2(124, 10)), col)
			ci.draw_colored_polygon(UI.estrella_pts(Vector2(30, -22), 9, tt), Color("#ffe066"))
		"planetas":
			var base: Color = [Color("#7fc8ff"), Color("#ff8fb3"), Color("#d6d6e2")][tp]
			ci.draw_circle(Vector2(0, 0), 34, base)
			ci.draw_circle(Vector2(-10, -10), 18, base.lightened(0.25))
			ci.draw_circle(Vector2(12, 12), 7, base.darkened(0.2))
			ci.draw_set_transform(p, -0.15, Vector2(esc, esc * 0.3))
			ci.draw_arc(Vector2.ZERO, 62, 0.0, PI, 24, Color("#ffe0b0"), 10)
			ci.draw_set_transform(p, 0.0, Vector2.ONE * esc)
		_:
			var col := Color.WHITE if tp == 0 else (Color("#ffe6f2") if tp == 1 else Color("#d8d8e0"))
			ci.draw_rect(Rect2(Vector2(-62, -2), Vector2(124, 22)), col.darkened(0.06))
			for j in 3:
				ci.draw_circle(Vector2((j - 1) * 38, -6 if j == 1 else 0), 30 if j == 1 else 24, col)
			ci.draw_rect(Rect2(Vector2(-62, -2), Vector2(124, 16)), col)
			ci.draw_circle(Vector2(-12, -18), 9, Color(1, 1, 1, 0.8))
	if tp == 2:
		ci.draw_line(Vector2(-20, -10), Vector2(-4, 4), Color(0.45, 0.45, 0.55), 3)
		ci.draw_line(Vector2(-4, 4), Vector2(10, 14), Color(0.45, 0.45, 0.55), 3)
	elif tp == 1:
		for s in [-1.0, 1.0]:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(s * 70, -8), Vector2(s * 82, 2), Vector2(s * 70, 12)]), Color("#ff8fb3"))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
