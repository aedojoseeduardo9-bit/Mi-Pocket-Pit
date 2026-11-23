## Pocket Pip — la interfaz sobre el juego: nivel, necesidades y bellotas arriba; botones a los lados (tienda,
## regalo, sonido / armario, pociones, bailes, decorar); barra de habitaciones abajo; el área de acción de cada
## habitación (comida, luz, pelota, jabón y ducha); los paneles que suben desde abajo y las ventanas (regalo diario,
## confirmar compra). Todo se anima: botones con rebote, paneles con resorte, números que corren.
class_name Hud
extends Control

var main
var _bel_vista := 0.0
var _nec_vista := {"hambre": 50.0, "energia": 50.0, "diversion": 50.0, "higiene": 50.0}
var _nivel_vista := 0.0
var _pulso := 0.0
var m_top := 40.0

var b_tienda: UI.Boton
var b_regalo: UI.Boton
var b_sonido: UI.Boton
var b_armario: UI.Boton
var b_pociones: UI.Boton
var b_bailes: UI.Boton
var b_decorar: UI.Boton
var tabs: Array[UI.Boton] = []
var accion: Control           ## área de acción de la habitación
var _acc_botones: Array = []
var hoja: Control             ## panel que sube desde abajo
var hoja_tipo := ""
var _velo: ColorRect
var _hoja_tab := 0
var _hoja_sel := ""
var _hoja_grid: GridContainer
var _hoja_tabs: HBoxContainer
var _hoja_pie: HBoxContainer
var _prueba_ropa := {}
var modal: Control
var _toast_txt := ""
var _toast_col := UI.NARANJO
var _toast_t := 0.0
var _marcador := ""

const NEC_ICONO := {"hambre": "hambre", "energia": "energia", "diversion": "diversion", "higiene": "higiene"}
const NEC_HAB := {"hambre": 0, "energia": 1, "diversion": 2, "higiene": 3}
const NEC_COLOR := {"hambre": Color("#ff8a5c"), "energia": Color("#ffc93c"), "diversion": Color("#8b7cf6"), "higiene": Color("#4aa8ff")}

func _init(m) -> void:
	main = m
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bel_vista = Estado.bellotas()
	for n in _nec_vista:
		_nec_vista[n] = Estado.nec(n)
	_nivel_vista = Estado.avance_nivel()
	b_tienda = _boton("tienda", "Tienda", UI.MENTA, func(): abrir_panel("tienda"))
	b_regalo = _boton("regalo", "Regalo", UI.ROSA, func(): abrir_regalo())
	b_sonido = _boton("altavoz", "", UI.CREMA, func(): _sonido())
	b_armario = _boton("ropa", "Armario", UI.NARANJO, func(): abrir_panel("armario"))
	b_pociones = _boton("pocion", "Pociones", UI.LILA, func(): abrir_panel("pociones"))
	b_bailes = _boton("nota", "Bailes", UI.AZUL, func(): abrir_panel("bailes"))
	b_decorar = _boton("pincel", "Decorar", Color("#f5b14c"), func(): abrir_panel("decorar"))
	for b in [b_tienda, b_regalo, b_armario, b_pociones, b_bailes, b_decorar]:
		b.color_icono = Color.WHITE
	for i in Casa.HABS.size():
		var h: String = Casa.HABS[i]
		var t := UI.Boton.new(h, Casa.NOMBRES[h], UI.CREMA, Vector2(156, 112))
		t.radio = 34
		t.tam_texto = 20
		t.sonido = ""
		var idx := i
		t.presionado.connect(func(): main.ir_a(idx))
		add_child(t)
		tabs.append(t)
	accion = Control.new()
	accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accion)
	resized.connect(_layout)
	Estado.cambio.connect(refrescar)
	_layout()
	cambio_habitacion()

func _boton(ic: String, tx: String, col: Color, cb: Callable) -> UI.Boton:
	var b := UI.Boton.new(ic, tx, col, Vector2(104, 104))
	b.tam_texto = 17
	b.presionado.connect(cb)
	add_child(b)
	return b

func _layout() -> void:
	var W := size.x
	var H := size.y
	var y0 := m_top + 150.0
	var gap := 122.0
	b_tienda.position = Vector2(18, y0)
	b_regalo.position = Vector2(18, y0 + gap)
	b_sonido.size = Vector2(76, 76)
	b_sonido.custom_minimum_size = b_sonido.size
	b_sonido.position = Vector2(32, y0 + gap * 2.0 + 4)
	var xr := W - 18 - 104
	b_armario.position = Vector2(xr, y0)
	b_pociones.position = Vector2(xr, y0 + gap)
	b_bailes.position = Vector2(xr, y0 + gap * 2.0)
	b_decorar.position = Vector2(xr, y0 + gap * 3.0)
	var tw := 156.0
	var sep := (W - 4 * tw - 24) / 3.0
	for i in tabs.size():
		tabs[i].position = Vector2(12 + i * (tw + sep), H - 112 - 26)
	accion.position = Vector2(0, H - 138 - 190)
	accion.size = Vector2(W, 180)
	if hoja:
		hoja.size = Vector2(W, _alto_hoja())
		if hoja_tipo != "":
			hoja.position.y = H - hoja.size.y
	queue_redraw()

func _alto_hoja() -> float:
	return clampf(size.y * 0.47, 560.0, 760.0)

func pos_bellotas() -> Vector2:
	return Vector2(size.x - 160, m_top + 44)

# ---------------- dibujo de la barra de arriba ----------------
func _process(dt: float) -> void:
	_pulso += dt
	var cambio := false
	var b := float(Estado.bellotas())
	if absf(_bel_vista - b) > 0.5:
		_bel_vista = move_toward(_bel_vista, b, maxf(3.0, absf(b - _bel_vista) * 4.0) * dt)
		cambio = true
	for n in _nec_vista:
		var v := Estado.nec(n)
		if absf(_nec_vista[n] - v) > 0.05:
			_nec_vista[n] = lerpf(_nec_vista[n], v, minf(1.0, dt * 4.0))
			cambio = true
	var nv := Estado.avance_nivel()
	if absf(_nivel_vista - nv) > 0.002:
		_nivel_vista = lerpf(_nivel_vista, nv, minf(1.0, dt * 4.0))
		cambio = true
	if _toast_t > 0.0:
		_toast_t -= dt
		cambio = true
	if cambio or int(_pulso * 4.0) != int((_pulso - dt) * 4.0):
		queue_redraw()

func _draw() -> void:
	var W := size.x
	# nivel
	var c := Vector2(70, m_top + 44)
	draw_circle(c + Vector2(0, 4), 46, UI.SOMBRA)
	draw_circle(c, 46, UI.CREMA)
	draw_arc(c, 38, -PI / 2, -PI / 2 + TAU * clampf(_nivel_vista, 0.0, 1.0), 48, UI.ORO, 10, true)
	draw_arc(c, 38, -PI / 2 + TAU * clampf(_nivel_vista, 0.0, 1.0), PI * 1.5, 48, Color(UI.ORO, 0.18), 10, true)
	UI.texto(self, c + Vector2(0, -6), str(Estado.nivel()), 34, UI.CAFE, 700)
	UI.texto(self, c + Vector2(0, 20), "nivel", 15, UI.CAFE2, 500)
	# necesidades
	var x0 := 160.0
	var paso := (W - 160.0 - 230.0) / 4.0
	var i := 0
	for n in Estado.NECESIDADES:
		var p := Vector2(x0 + paso * (i + 0.5), m_top + 44)
		var v: float = _nec_vista[n] / 100.0
		var bajo := v < 0.25
		var r := 34.0 * (1.0 + (0.08 * sin(_pulso * 8.0) if bajo else 0.0))
		draw_circle(p + Vector2(0, 4), r + 4, UI.SOMBRA)
		draw_circle(p, r + 4, UI.CREMA)
		var col: Color = NEC_COLOR[n]
		if bajo:
			col = UI.ROJO
		draw_arc(p, r - 2, PI / 2, PI / 2 + TAU * v, 40, col, 8, true)
		UI.icono(self, NEC_ICONO[n], p, r * 1.15, col.darkened(0.05))
		i += 1
	# bellotas
	var pill := Rect2(Vector2(W - 228, m_top + 14), Vector2(210, 62))
	UI.caja(self, pill, UI.CREMA, 31)
	UI.icono(self, "bellota", pill.position + Vector2(36, 31), 50)
	UI.texto(self, pill.position + Vector2(108, 30), _fmt(int(round(_bel_vista))), 30, UI.CAFE, 700, true, 100)
	draw_circle(pill.position + Vector2(180, 31), 22, UI.MENTA)
	UI.icono(self, "mas", pill.position + Vector2(180, 31), 30, Color.WHITE)
	# marcador del juego de la pelota
	if main.modo == "pelota":
		UI.texto_borde(self, Vector2(W * 0.5, m_top + 200), str(main.toques_pelota), 110, UI.ORO, UI.CAFE, 18)
		UI.texto(self, Vector2(W * 0.5, m_top + 275), "¡Toca la pelota!", 28, UI.CAFE, 700)
	# aviso
	if _toast_t > 0.0:
		var a := clampf(minf(_toast_t * 3.0, (2.6 - _toast_t) * 5.0), 0.0, 1.0)
		var w := UI.fuente(600).get_string_size(_toast_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 60
		var rr := Rect2(Vector2(W * 0.5 - w * 0.5, m_top + 110 - (1.0 - a) * 30), Vector2(w, 58))
		UI._sb(self, Rect2(rr.position + Vector2(0, 4), rr.size), Color(UI.SOMBRA, UI.SOMBRA.a * a), 29)
		UI._sb(self, rr, Color(_toast_col, a), 29)
		UI.texto(self, rr.get_center(), _toast_txt, 26, Color(1, 1, 1, a), 600)

static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

func _gui_input(_e: InputEvent) -> void:
	pass

func _input(e: InputEvent) -> void:
	# toques en la barra de arriba (no son botones: se miran aquí)
	if not visible or modal != null or not (e is InputEventMouseButton) or not e.pressed or e.button_index != MOUSE_BUTTON_LEFT:
		return
	var p: Vector2 = (get_global_transform_with_canvas().affine_inverse() * e.position)
	var W := size.x
	if Rect2(Vector2(W - 228, m_top + 14), Vector2(210, 62)).has_point(p):
		Sfx.play("select", 1.0, -4.0)
		abrir_panel("tienda")
		get_viewport().set_input_as_handled()
		return
	if hoja_tipo != "":
		return
	var x0 := 160.0
	var paso := (W - 160.0 - 230.0) / 4.0
	for i in 4:
		var c := Vector2(x0 + paso * (i + 0.5), m_top + 44)
		if p.distance_to(c) < 40:
			var n: String = Estado.NECESIDADES[i]
			Sfx.play("select", 1.0, -4.0)
			toast(_nombre_nec(n) + ": %d%%" % int(Estado.nec(n)), NEC_COLOR[n])
			main.ir_a(NEC_HAB[n])
			get_viewport().set_input_as_handled()
			return

static func _nombre_nec(n: String) -> String:
	return {"hambre": "Comida", "energia": "Energía", "diversion": "Diversión", "higiene": "Higiene"}[n]

func toast(msg: String, col := UI.NARANJO) -> void:
	_toast_txt = msg
	_toast_col = col
	_toast_t = 2.6
	queue_redraw()

func sin_bellotas() -> void:
	toast("Te faltan bellotas", UI.ROJO)
	Sfx.play("deny")

func _sonido() -> void:
	var on: bool = not Estado.d.get("musica", true)
	Estado.d.musica = on
	Estado.d.sonido = on
	Estado.marcar()
	b_sonido.color = UI.CREMA if on else Color("#d9cfc6")
	b_sonido.queue_redraw()
	toast("Sonido activado" if on else "Sonido apagado", UI.CAFE2)

func refrescar() -> void:
	b_regalo.insignia = "1" if Estado.regalo_disponible() else ""
	b_regalo.queue_redraw()
	for i in tabs.size():
		tabs[i].seleccionado = i == main.hab
		tabs[i].color = Color("#ffe2c2") if i == main.hab else UI.CREMA
		tabs[i].queue_redraw()
	_refrescar_accion()
	queue_redraw()

# ---------------- área de acción de cada habitación ----------------
func cambio_habitacion() -> void:
	for b in _acc_botones:
		if is_instance_valid(b):
			b.queue_free()
	_acc_botones.clear()
	var h: String = Casa.HABS[main.hab]
	var W := size.x if size.x > 0 else 720.0
	match h:
		"cocina":
			var sc := ScrollContainer.new()
			sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			sc.position = Vector2(16, 0)
			sc.size = Vector2(W - 32, 176)
			sc.scroll_deadzone = 14
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 12)
			sc.add_child(fila)
			for c in Estado.cat.comida:
				var t := UI.Tarjeta.new(Vector2(128, 168))
				t.icono = "comida_" + c.id
				t.nombre = c.nombre
				t.precio = int(c.precio)
				t.color = Color(str(c.color)).lightened(0.55)
				var id: String = c.id
				t.elegida.connect(func(): main.alimentar(id, t.get_global_rect().get_center()))
				fila.add_child(t)
			accion.add_child(sc)
			_acc_botones.append(sc)
		"habitacion":
			var b := UI.Boton.new("foco", "Apagar la luz", Color("#2f3170"), Vector2(300, 96))
			b.color_icono = Color("#fff3c4")
			b.tam_texto = 24
			b.position = Vector2(W * 0.5 - 150, 70)
			b.presionado.connect(func(): main.apagar_luz(not main.luz_apagada))
			accion.add_child(b)
			_acc_botones.append(b)
		"patio":
			var b := UI.Boton.new("pelota", "Jugar a la pelota", UI.MENTA, Vector2(330, 96))
			b.color_icono = Color.WHITE
			b.tam_texto = 24
			b.position = Vector2(W * 0.5 - 165, 70)
			b.presionado.connect(func(): main.jugar_pelota())
			accion.add_child(b)
			_acc_botones.append(b)
		"bano":
			var j := UI.Boton.new("jabon", "Jabón", Color("#ff9fb0"), Vector2(220, 96))
			j.color_icono = Color.WHITE
			j.tam_texto = 24
			j.position = Vector2(W * 0.5 - 232, 70)
			j.presionado.connect(func(): main.usar_jabon())
			var d := UI.Boton.new("ducha", "Ducha", UI.AZUL, Vector2(220, 96))
			d.color_icono = Color.WHITE
			d.tam_texto = 24
			d.position = Vector2(W * 0.5 + 12, 70)
			d.presionado.connect(func(): main.ducha())
			accion.add_child(j)
			accion.add_child(d)
			_acc_botones.append(j)
			_acc_botones.append(d)
	# entra deslizándose
	accion.modulate.a = 0.0
	accion.position.x = 40.0
	var tw := create_tween().set_parallel()
	tw.tween_property(accion, "modulate:a", 1.0, 0.35)
	tw.tween_property(accion, "position:x", 0.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	refrescar()

func _refrescar_accion() -> void:
	var h: String = Casa.HABS[main.hab]
	var ocupado: bool = main.modo in ["pelota", "baile", "ducha", "viaje"]
	accion.visible = hoja_tipo == "" and not (main.modo in ["pelota", "baile"])
	for b in _acc_botones:
		if not is_instance_valid(b):
			continue
		if b is UI.Boton:
			var bb := b as UI.Boton
			bb.activo = not ocupado or (h == "habitacion")
			if h == "habitacion":
				bb.texto = "Encender la luz" if main.luz_apagada else "Apagar la luz"
				bb.color = Color("#ffcf6a") if main.luz_apagada else Color("#2f3170")
				bb.color_icono = UI.CAFE if main.luz_apagada else Color("#fff3c4")
			if bb.icono == "jabon":
				bb.seleccionado = main.jabon
			bb.queue_redraw()
	for b in [b_armario, b_pociones, b_bailes, b_decorar, b_tienda, b_regalo, b_sonido]:
		b.visible = hoja_tipo == "" and main.modo != "pelota"
	for t in tabs:
		t.visible = hoja_tipo == ""

## Un ícono que vuela en arco de `desde` a `hasta` (la comida hacia la boca de Pip).
func volar_icono(ic: String, desde: Vector2, hasta: Vector2, dur: float, fin: Callable) -> void:
	var v := Control.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.size = Vector2(90, 90)
	v.pivot_offset = v.size * 0.5
	v.draw.connect(func(): UI.icono(v, ic, v.size * 0.5, 90))
	add_child(v)
	var arco := func(u: float):
		var p := desde.lerp(hasta, u) + Vector2(0, -260.0 * sin(u * PI))
		v.position = p - v.size * 0.5
		v.scale = Vector2.ONE * lerpf(1.0, 0.45, u)
		v.rotation = u * 2.5
	arco.call(0.0)
	var tw := create_tween()
	tw.tween_method(arco, 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		v.queue_free()
		fin.call())

# ================= paneles =================
func abrir_panel(tipo: String) -> void:
	if main.modo in ["viaje", "pelota", "ducha", "intro"]:
		return
	if main.modo == "baile":
		main._terminar_actividad()
	if main.modo == "dormir" and tipo != "tienda":
		main.apagar_luz(false)
	cerrar_panel(true)
	hoja_tipo = tipo
	_hoja_tab = 0
	_hoja_sel = ""
	_prueba_ropa = Estado.d.puesto.duplicate()
	_velo = ColorRect.new()
	_velo.color = Color(0.1, 0.05, 0.02, 0.0)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			cerrar_panel())
	add_child(_velo)
	hoja = Control.new()
	hoja.size = Vector2(size.x, _alto_hoja())
	hoja.position = Vector2(0, size.y + 10)
	hoja.mouse_filter = Control.MOUSE_FILTER_STOP
	hoja.draw.connect(_dibujar_hoja)
	add_child(hoja)
	var x := UI.Boton.new("cerrar", "", UI.CREMA, Vector2(72, 72))
	x.position = Vector2(size.x - 92, 22)
	x.color_icono = UI.CAFE2
	x.presionado.connect(func(): cerrar_panel())
	hoja.add_child(x)
	_hoja_tabs = HBoxContainer.new()
	_hoja_tabs.position = Vector2(24, 104)
	_hoja_tabs.add_theme_constant_override("separation", 10)
	hoja.add_child(_hoja_tabs)
	var sc := ScrollContainer.new()
	sc.position = Vector2(14, 184)
	sc.size = Vector2(size.x - 28, hoja.size.y - 184 - 112)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.scroll_deadzone = 14
	hoja.add_child(sc)
	_hoja_grid = GridContainer.new()
	_hoja_grid.columns = 4
	_hoja_grid.add_theme_constant_override("h_separation", 14)
	_hoja_grid.add_theme_constant_override("v_separation", 14)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_top", 8)
	mc.add_child(_hoja_grid)
	sc.add_child(mc)
	_hoja_pie = HBoxContainer.new()
	_hoja_pie.position = Vector2(0, hoja.size.y - 104)
	_hoja_pie.size = Vector2(size.x, 92)
	_hoja_pie.alignment = BoxContainer.ALIGNMENT_CENTER
	_hoja_pie.add_theme_constant_override("separation", 16)
	hoja.add_child(_hoja_pie)
	_armar_tabs()
	_armar_tarjetas()
	main.zoom_panel = 0.0 if tipo == "tienda" else 1.0
	var tw := create_tween().set_parallel()
	tw.tween_property(hoja, "position:y", size.y - hoja.size.y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_velo, "color:a", 0.22 if tipo in ["tienda"] else 0.0, 0.3)
	Sfx.play("swipe", 1.3, -6.0)
	refrescar()

func cerrar_panel(rapido := false) -> void:
	if hoja == null:
		return
	if hoja_tipo == "armario":
		Atuendos.vestir(main.pip, Estado.d.puesto)
	elif hoja_tipo == "decorar":
		var h: String = Casa.HABS[main.hab]
		for slot in Estado.cat.deco[h]:
			main.casa.rearmar(h, slot)
	hoja_tipo = ""
	main.zoom_panel = 0.0
	var hj := hoja
	var vl := _velo
	hoja = null
	_velo = null
	if rapido:
		hj.queue_free()
		vl.queue_free()
	else:
		var tw := create_tween().set_parallel()
		tw.tween_property(hj, "position:y", size.y + 20, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(vl, "color:a", 0.0, 0.25)
		tw.chain().tween_callback(func():
			hj.queue_free()
			vl.queue_free())
	refrescar()

func _titulo_hoja() -> String:
	match hoja_tipo:
		"armario": return "Armario"
		"tienda": return "Tienda de bellotas"
		"pociones": return "Pociones"
		"bailes": return "Bailes"
		"decorar": return "Decorar: " + Casa.NOMBRES[Casa.HABS[main.hab]]
	return ""

func _dibujar_hoja() -> void:
	var r := Rect2(Vector2.ZERO, hoja.size + Vector2(0, 60))
	UI._sb(hoja, Rect2(r.position + Vector2(0, -6), r.size), UI.SOMBRA, 44)
	UI._sb(hoja, r, UI.CREMA, 44)
	UI._sb(hoja, Rect2(Vector2(hoja.size.x * 0.5 - 40, 12), Vector2(80, 8)), Color(UI.CAFE2, 0.25), 4)
	UI.texto(hoja, Vector2(34, 58), _titulo_hoja(), 36, UI.CAFE, 700, false)
	if hoja_tipo == "tienda":
		UI.texto(hoja, Vector2(hoja.size.x * 0.5, 130), "Versión de prueba: las compras no cobran nada", 21, UI.MENTA.darkened(0.2), 600)

func _armar_tabs() -> void:
	for c in _hoja_tabs.get_children():
		c.queue_free()
	var nombres: Array = []
	match hoja_tipo:
		"armario":
			nombres = ["Cabeza", "Ojos", "Cuerpo", "Cuello"]
		"decorar":
			for slot in Estado.cat.deco[Casa.HABS[main.hab]]:
				nombres.append(_nombre_slot(slot))
	for i in nombres.size():
		var b := UI.Boton.new("", nombres[i], UI.NARANJO if i == _hoja_tab else Color.WHITE, Vector2(150, 62))
		b.color_icono = Color.WHITE if i == _hoja_tab else UI.CAFE2
		b.tam_texto = 22
		b.radio = 31
		var idx := i
		b.presionado.connect(func():
			_hoja_tab = idx
			_hoja_sel = ""
			_armar_tabs()
			_armar_tarjetas())
		_hoja_tabs.add_child(b)

static func _nombre_slot(s: String) -> String:
	return {"pared": "Pared", "piso": "Piso", "nevera": "Nevera", "mesa": "Mesa", "cama": "Cama", "lampara": "Lámpara",
		"alfombra": "Alfombra", "fondo": "Fondo", "cerca": "Cerca", "arbol": "Árbol", "banera": "Bañera", "cortina": "Cortina"}.get(s, s)

const ZONAS := ["cabeza", "ojos", "cuerpo", "cuello"]

func _armar_tarjetas() -> void:
	for c in _hoja_grid.get_children():
		c.queue_free()
	var W := size.x - 28 - 16
	var cw := floorf((W - 14 * 3) / 4.0)
	var csz := Vector2(cw, cw * 1.25)
	match hoja_tipo:
		"armario":
			var zona: String = ZONAS[_hoja_tab]
			var nada := UI.Tarjeta.new(csz)
			nada.icono = "cerrar"
			nada.nombre = "Nada"
			nada.color = Color("#f1ebe4")
			nada.color_icono = Color("#c9b8a8")
			nada.estado = "puesto" if str(_prueba_ropa.get(zona, "")) == "" else "tiene"
			nada.elegida.connect(func(): _probar_ropa(zona, ""))
			_hoja_grid.add_child(nada)
			for r in Estado.cat.ropa:
				if r.zona != zona:
					continue
				var t := UI.Tarjeta.new(csz)
				t.icono = "ropa_" + r.id
				t.nombre = r.nombre
				t.precio = int(r.precio)
				t.color = Color("#fff1e0")
				var tiene := Estado.tiene(r.id)
				if str(_prueba_ropa.get(zona, "")) == r.id:
					t.estado = "puesto"
				elif tiene:
					t.estado = "tiene"
				elif Estado.nivel() < int(r.nivel):
					t.estado = "bloqueado"
				var id: String = r.id
				t.elegida.connect(func(): _probar_ropa(zona, id))
				_hoja_grid.add_child(t)
		"decorar":
			var h: String = Casa.HABS[main.hab]
			var slots: Array = Estado.cat.deco[h].keys()
			var slot: String = slots[_hoja_tab]
			for v in Estado.cat.deco[h][slot]:
				var t := UI.Tarjeta.new(csz)
				t.icono = "pincel"
				t.nombre = v.nombre
				t.precio = int(v.precio)
				t.color = _color_deco(h, slot, v.id)
				t.color_icono = Color(1, 1, 1, 0.85)
				var clave: String = "deco_%s_%s_%s" % [h, slot, v.id]
				var sel := _hoja_sel if _hoja_sel != "" else Estado.deco(h, slot)
				if sel == v.id:
					t.estado = "puesto"
				elif Estado.tiene(clave):
					t.estado = "tiene"
				var id: String = v.id
				t.elegida.connect(func(): _probar_deco(h, slot, id))
				_hoja_grid.add_child(t)
		"pociones":
			for p in Estado.cat.pociones:
				var t := UI.Tarjeta.new(csz)
				t.icono = "pocion"
				t.nombre = p.nombre
				t.precio = int(p.precio)
				t.color = Color(str(p.color)).lightened(0.55)
				t.color_icono = Color(str(p.color))
				t.cantidad = Estado.pociones(p.id)
				if _hoja_sel == p.id:
					t.estado = "puesto"
				var id: String = p.id
				t.elegida.connect(func():
					_hoja_sel = id
					_armar_tarjetas())
				_hoja_grid.add_child(t)
		"bailes":
			for b in Estado.cat.bailes:
				var t := UI.Tarjeta.new(csz)
				t.icono = "nota"
				t.nombre = b.nombre
				t.precio = int(b.precio)
				t.color = Color("#dfeeff")
				t.color_icono = UI.AZUL
				var clave: String = "baile_" + b.id
				if _hoja_sel == b.id:
					t.estado = "puesto"
				elif Estado.tiene(clave) or int(b.precio) == 0:
					t.estado = "tiene"
				var id: String = b.id
				t.elegida.connect(func():
					_hoja_sel = id
					if Estado.tiene("baile_" + id) or int(Estado.busca(Estado.cat.bailes, id).precio) == 0:
						cerrar_panel()
						main.bailar(id)
					else:
						_armar_tarjetas())
				_hoja_grid.add_child(t)
		"tienda":
			for p in Estado.cat.paquetes:
				var t := UI.Tarjeta.new(csz)
				t.icono = "bellota"
				t.nombre = _fmt(int(p.bellotas))
				t.precio_txt = "Gratis"
				t.color = Color("#ffe9c9")
				var id: String = p.id
				t.elegida.connect(func(): _confirmar_compra(id))
				_hoja_grid.add_child(t)
	_armar_pie()

func _color_deco(h: String, slot: String, id: String) -> Color:
	var c := {"crema": "#fff1dc", "menta": "#9fd6c2", "cerezo": "#ffb3c7", "madera": "#c08552", "ajedrez": "#3c3f58",
		"clasica": "#dfe6ee", "retro": "#ffb3c1", "azul": "#7fb8ff", "lavanda": "#c8b8f0", "noche": "#2f3170",
		"durazno": "#f2b796", "nido": "#a8743f", "nube": "#cfe0ff", "cohete": "#ff5a5f", "hongo": "#ff6b6b",
		"luna": "#c9c3e8", "redonda": "#ffb3c7", "estrella": "#ffd36e", "dia": "#7cc4ff", "atardecer": "#ff9f7a",
		"galaxia": "#6a2c91", "blanca": "#e9e4dc", "roble": "#5fae4a", "azulejo": "#bfe1ee", "coral": "#f4a38f",
		"dorada": "#ffcf4a", "rayas": "#7fc8ff", "burbujas": "#b8f0ff", "estrellas": "#4b4fa8"}
	if h == "habitacion" and slot == "pared" and id == "noche":
		return Color("#2f3170")
	return Color(c.get(id, "#dddddd"))

func _probar_ropa(zona: String, id: String) -> void:
	_prueba_ropa[zona] = id
	_hoja_sel = id
	Atuendos.vestir(main.pip, _prueba_ropa)
	main.pip.hacer("celebrar" if id != "" else "mirar_cola")
	if id == "" or Estado.tiene(id):
		Estado.poner(zona, id)
	_armar_tarjetas()

func _probar_deco(h: String, slot: String, id: String) -> void:
	_hoja_sel = id
	main.casa.rearmar(h, slot, id)
	if Estado.tiene("deco_%s_%s_%s" % [h, slot, id]):
		Estado.poner_deco(h, slot, id)
	Sfx.play("pop", 1.2, -6.0)
	_armar_tarjetas()

func _armar_pie() -> void:
	for c in _hoja_pie.get_children():
		c.queue_free()
	var b: UI.Boton = null
	match hoja_tipo:
		"armario":
			var zona: String = ZONAS[_hoja_tab]
			var id := str(_prueba_ropa.get(zona, ""))
			if id != "" and not Estado.tiene(id):
				var r: Dictionary = Estado.ropa_por_id[id]
				if Estado.nivel() < int(r.nivel):
					b = UI.Boton.new("candado", "Desde el nivel %d" % int(r.nivel), Color("#d9cfc6"), Vector2(380, 84))
					b.activo = false
				else:
					b = _boton_comprar(int(r.precio), func():
						if Estado.gastar(int(r.precio)):
							Estado.agregar(id)
							Estado.poner(zona, id)
							_celebrar_compra()
							_armar_tarjetas()
						else:
							sin_bellotas())
		"decorar":
			var h: String = Casa.HABS[main.hab]
			var slot: String = Estado.cat.deco[h].keys()[_hoja_tab]
			if _hoja_sel != "" and not Estado.tiene("deco_%s_%s_%s" % [h, slot, _hoja_sel]):
				var v: Dictionary = Estado.busca(Estado.cat.deco[h][slot], _hoja_sel)
				var id := _hoja_sel
				b = _boton_comprar(int(v.precio), func():
					if Estado.gastar(int(v.precio)):
						Estado.agregar("deco_%s_%s_%s" % [h, slot, id])
						Estado.poner_deco(h, slot, id)
						_celebrar_compra()
						_armar_tarjetas()
					else:
						sin_bellotas())
		"pociones":
			if _hoja_sel != "":
				var p: Dictionary = Estado.busca(Estado.cat.pociones, _hoja_sel)
				var id := _hoja_sel
				if Estado.pociones(id) > 0:
					var u := UI.Boton.new("pocion", "Tomar", UI.LILA, Vector2(220, 84))
					u.color_icono = Color.WHITE
					u.tam_texto = 26
					u.presionado.connect(func():
						cerrar_panel()
						main.pocion(id))
					_hoja_pie.add_child(u)
				b = _boton_comprar(int(p.precio), func():
					if Estado.gastar(int(p.precio)):
						Estado.sumar_pocion(id, 1)
						Sfx.play("item")
						_armar_tarjetas()
					else:
						sin_bellotas(), Vector2(240, 84))
		"bailes":
			if _hoja_sel != "" and not Estado.tiene("baile_" + _hoja_sel):
				var bl: Dictionary = Estado.busca(Estado.cat.bailes, _hoja_sel)
				var id := _hoja_sel
				b = _boton_comprar(int(bl.precio), func():
					if Estado.gastar(int(bl.precio)):
						Estado.agregar("baile_" + id)
						_celebrar_compra()
						cerrar_panel()
						main.bailar(id)
					else:
						sin_bellotas())
	if b:
		_hoja_pie.add_child(b)

func _boton_comprar(precio: int, cb: Callable, sz := Vector2(300, 84)) -> UI.Boton:
	var b := UI.Boton.new("bellota", "Comprar  %d" % precio, UI.NARANJO, sz)
	b.color_icono = Color.WHITE
	b.tam_texto = 26
	b.sonido = ""
	b.presionado.connect(cb)
	return b

func _celebrar_compra() -> void:
	Sfx.play("chest")
	main.pip.hacer("celebrar")
	main.fx.emitir("chispa", main.pip_en_pantalla() + Vector2(0, -80), 20, UI.ORO)
	main.fx.emitir("estrella", main.pip_en_pantalla() + Vector2(0, -120), 5)

# ================= ventanas =================
func _abrir_modal(alto: float) -> Control:
	cerrar_modal()
	var fondo := ColorRect.new()
	fondo.color = Color(0.1, 0.05, 0.02, 0.0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fondo)
	modal = fondo
	var card := Control.new()
	card.size = Vector2(minf(size.x - 60, 640), alto)
	card.position = (size - card.size) * 0.5
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2.ONE * 0.7
	card.modulate.a = 0.0
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	fondo.add_child(card)
	var tw := create_tween().set_parallel()
	tw.tween_property(fondo, "color:a", 0.45, 0.25)
	tw.tween_property(card, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	return card

func cerrar_modal() -> void:
	if modal and is_instance_valid(modal):
		var m := modal
		modal = null
		var tw := create_tween()
		tw.tween_property(m, "modulate:a", 0.0, 0.18)
		tw.tween_callback(m.queue_free)
	modal = null

func abrir_regalo() -> void:
	var card := _abrir_modal(560)
	var hoy := Estado.dia_regalo()
	var disp := Estado.regalo_disponible()
	card.draw.connect(func():
		UI.caja(card, Rect2(Vector2.ZERO, card.size), UI.CREMA, 40)
		UI.texto(card, Vector2(card.size.x * 0.5, 60), "Regalo diario", 40, UI.CAFE, 700)
		UI.texto(card, Vector2(card.size.x * 0.5, 108), "Vuelve cada día: ¡el séptimo es enorme!", 22, UI.CAFE2, 500)
		var w := (card.size.x - 60) / 4.0
		for i in 7:
			var fila := i / 4
			var col := i % 4
			var n_en_fila := 4 if fila == 0 else 3
			var x0 := 30.0 + (card.size.x - 60 - n_en_fila * w) * 0.5
			var r := Rect2(Vector2(x0 + col * w + 6, 150 + fila * 150), Vector2(w - 12, 136))
			var pasado := i < hoy or (i == hoy and not disp)
			var c := UI.ORO if i == hoy and disp else (Color("#e9e0d6") if pasado else Color.WHITE)
			UI.caja(card, r, c, 22, true, false)
			UI.texto(card, r.position + Vector2(r.size.x * 0.5, 22), "Día %d" % (i + 1), 19, UI.CAFE, 600)
			UI.icono(card, "regalo" if i == 6 else "bellota", r.get_center() + Vector2(0, 2), 54, UI.ROSA)
			UI.texto(card, r.position + Vector2(r.size.x * 0.5, r.size.y - 22), str(int(Estado.cat.regalo_diario[i])), 22, UI.CAFE, 700)
			if pasado:
				UI.icono(card, "check", r.get_center(), 60, Color(UI.MENTA, 0.9)))
	var b := UI.Boton.new("regalo" if disp else "check", "Reclamar" if disp else "Mañana hay más", UI.MENTA if disp else Color("#d9cfc6"), Vector2(340, 86))
	b.color_icono = Color.WHITE
	b.tam_texto = 26
	b.position = Vector2(card.size.x * 0.5 - 170, card.size.y - 112)
	b.presionado.connect(func():
		if Estado.regalo_disponible():
			var n := Estado.reclamar_regalo()
			Sfx.play("chest")
			main.fx.volar(card.get_global_rect().get_center(), pos_bellotas(), mini(16, 4 + n / 15))
			toast("+%d bellotas" % n, UI.MENTA)
			main.pip.hacer("celebrar")
		cerrar_modal()
		refrescar())
	card.add_child(b)

func _confirmar_compra(id: String) -> void:
	var p: Dictionary = Estado.busca(Estado.cat.paquetes, id)
	var card := _abrir_modal(470)
	card.draw.connect(func():
		UI.caja(card, Rect2(Vector2.ZERO, card.size), UI.CREMA, 40)
		UI.texto(card, Vector2(card.size.x * 0.5, 58), str(p.nombre), 34, UI.CAFE, 700)
		UI.icono(card, "bellota", Vector2(card.size.x * 0.5 - 70, 160), 110)
		UI.texto(card, Vector2(card.size.x * 0.5 + 60, 160), _fmt(int(p.bellotas)), 48, UI.CAFE, 700)
		UI.texto(card, Vector2(card.size.x * 0.5, 248), "Precio en Google Play: " + str(p.precio), 22, UI.CAFE2, 500)
		UI.texto(card, Vector2(card.size.x * 0.5, 284), "Prueba: no se cobra nada", 24, UI.MENTA.darkened(0.15), 700))
	var no := UI.Boton.new("", "Cancelar", Color.WHITE, Vector2(220, 84))
	no.color_icono = UI.CAFE2
	no.tam_texto = 24
	no.position = Vector2(card.size.x * 0.5 - 236, card.size.y - 112)
	no.presionado.connect(func(): cerrar_modal())
	var si := UI.Boton.new("check", "Comprar gratis", UI.MENTA, Vector2(260, 84))
	si.color_icono = Color.WHITE
	si.tam_texto = 24
	si.position = Vector2(card.size.x * 0.5 - 4, card.size.y - 112)
	si.presionado.connect(func():
		si.activo = false
		si.texto = "Procesando..."
		si.queue_redraw()
		Pagos.comprar(id)
		await Pagos.compra_lista
		cerrar_modal())
	card.add_child(no)
	card.add_child(si)
