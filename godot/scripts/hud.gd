## Pocket Pip — la interfaz sobre el juego (estilo "dock inferior", elegido por el dueño):
## arriba nivel, necesidades y bellotas; debajo los puntitos de las habitaciones con su nombre; abajo un dock
## flotante (Armario, Tienda, Juegos, Decorar, Más) y, encima, la acción de cada habitación (comida, luz,
## pelota, jabón/ducha). Los paneles suben desde abajo con resorte; las ventanas (regalo, compra, capibara,
## falta de bellotas) aparecen al centro. Todo se anima.
class_name Hud
extends Control

var main
var _bel_vista := 0.0
var _nec_vista := {"hambre": 50.0, "energia": 50.0, "diversion": 50.0, "higiene": 50.0}
var _nivel_vista := 0.0
var _pulso := 0.0
var m_top := 40.0
var dock: Control
var dock_btn: Array[UI.Boton] = []
var b_regalo: UI.Boton
var accion: Control
var _acc_botones: Array = []
var hoja: Control
var hoja_tipo := ""
var _velo: ColorRect
var _hoja_tab := 0
var _hoja_sel := ""
var _hoja_grid: GridContainer
var _hoja_tabs: HBoxContainer
var _hoja_pie: HBoxContainer
var _hoja_scroll: ScrollContainer
var _prueba_ropa := {}
var modal: Control
var _toast_txt := ""
var _toast_col := UI.NARANJO
var _toast_t := 0.0
var _hab_vista := 1.0
var juego: Minijuego

const NEC_HAB := {"hambre": 0, "energia": 1, "diversion": 2, "higiene": 3}
const NEC_COLOR := {"hambre": Color("#ff8a5c"), "energia": Color("#ffc93c"), "diversion": Color("#8b7cf6"), "higiene": Color("#4aa8ff")}
const DOCK := [["ropa", "Armario", "armario"], ["tienda", "Tienda", "tienda"], ["juegos", "Juegos", "juegos"],
	["pincel", "Decorar", "decorar"], ["menu", "Más", "mas"]]
const ZONAS := ["cabeza", "ojos", "cuello", "cuerpo", "espalda", "traje"]
const ZONA_NOMBRE := {"cabeza": "Cabeza", "ojos": "Ojos", "cuello": "Cuello", "cuerpo": "Cuerpo", "espalda": "Espalda", "traje": "Trajes"}

func _init(m) -> void:
	main = m
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bel_vista = Estado.bellotas()
	for n in _nec_vista:
		_nec_vista[n] = Estado.nec(n)
	_nivel_vista = Estado.avance_nivel()
	_hab_vista = main.hab
	dock = Control.new()
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock.draw.connect(_dibujar_dock)
	add_child(dock)
	for d in DOCK:
		var b := UI.Boton.new(d[0], d[1], Color(0, 0, 0, 0), Vector2(122, 104))
		b.sin_fondo = true
		b.color_icono = UI.CAFE
		b.tam_texto = 18
		var tipo: String = d[2]
		b.presionado.connect(func(): abrir_panel(tipo))
		dock.add_child(b)
		dock_btn.append(b)
	b_regalo = UI.Boton.new("regalo", "", UI.ROSA, Vector2(84, 84))
	b_regalo.color_icono = Color.WHITE
	b_regalo.presionado.connect(abrir_regalo)
	add_child(b_regalo)
	accion = Control.new()
	accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(accion)
	resized.connect(_layout)
	Estado.cambio.connect(refrescar)
	_layout()
	cambio_habitacion()

func _layout() -> void:
	var W := size.x
	var H := size.y
	dock.position = Vector2(14, H - 128)
	dock.size = Vector2(W - 28, 112)
	var paso := (dock.size.x - 8) / DOCK.size()
	for i in dock_btn.size():
		dock_btn[i].position = Vector2(4 + i * paso + (paso - 122) * 0.5, 4)
	b_regalo.position = Vector2(20, m_top + 190)
	accion.position = Vector2(0, H - 128 - 200)
	accion.size = Vector2(W, 190)
	if hoja:
		hoja.size = Vector2(W, _alto_hoja())
		if hoja_tipo != "":
			hoja.position.y = H - hoja.size.y
	queue_redraw()

func _alto_hoja() -> float:
	return clampf(size.y * 0.5, 600.0, 820.0)

func pos_bellotas() -> Vector2:
	return Vector2(size.x - 160, m_top + 44)

func _dibujar_dock() -> void:
	var r := Rect2(Vector2.ZERO, dock.size)
	UI._sb(dock, Rect2(r.position + Vector2(0, 4), r.size), UI.SOMBRA, 40)
	UI._sb(dock, r, Color(1, 0.985, 0.96, 0.97), 40)
	# pestaña activa: una pastilla naranja detrás del botón
	var paso := (dock.size.x - 8) / DOCK.size()
	for i in DOCK.size():
		if DOCK[i][2] == hoja_tipo:
			UI._sb(dock, Rect2(Vector2(10 + i * paso, 10), Vector2(paso - 12, dock.size.y - 20)), Color("#ffe2c2"), 30)

# ---------------- barra de arriba ----------------
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
	if absf(_hab_vista - main.hab) > 0.001:
		_hab_vista = move_toward(_hab_vista, main.hab, dt * 4.0)
		cambio = true
	if _toast_t > 0.0:
		_toast_t -= dt
		cambio = true
	if main.modo == "pelota":
		cambio = true
	# el regalo salta para llamar la atención
	if b_regalo.visible:
		b_regalo.rotation = sin(_pulso * 6.0) * 0.12 * maxf(0.0, sin(_pulso * 1.3))
	if cambio or int(_pulso * 4.0) != int((_pulso - dt) * 4.0):
		queue_redraw()

func _draw() -> void:
	var W := size.x
	var c := Vector2(70, m_top + 44)
	draw_circle(c + Vector2(0, 3), 46, UI.SOMBRA)
	draw_circle(c, 46, UI.CREMA)
	draw_arc(c, 38, -PI / 2, -PI / 2 + TAU * clampf(_nivel_vista, 0.0, 1.0), 48, UI.ORO, 10, true)
	draw_arc(c, 38, -PI / 2 + TAU * clampf(_nivel_vista, 0.0, 1.0), PI * 1.5, 48, Color(UI.ORO, 0.18), 10, true)
	UI.texto(self, c + Vector2(0, -6), str(Estado.nivel()), 34, UI.CAFE, 700)
	UI.texto(self, c + Vector2(0, 20), "nivel", 15, UI.CAFE2, 500)
	var x0 := 160.0
	var paso := (W - 160.0 - 230.0) / 4.0
	for i in 4:
		var n: String = Estado.NECESIDADES[i]
		var p := Vector2(x0 + paso * (i + 0.5), m_top + 44)
		var v: float = _nec_vista[n] / 100.0
		var bajo := v < 0.25
		var r := 34.0 * (1.0 + (0.08 * sin(_pulso * 8.0) if bajo else 0.0))
		draw_circle(p + Vector2(0, 3), r + 4, UI.SOMBRA)
		draw_circle(p, r + 4, UI.CREMA)
		var col: Color = NEC_COLOR[n]
		if bajo:
			col = UI.ROJO
		draw_arc(p, r - 2, PI / 2, PI / 2 + TAU * v, 40, col, 8, true)
		UI.icono(self, n, p, r * 1.15, col)
	var pill := Rect2(Vector2(W - 228, m_top + 14), Vector2(210, 62))
	UI.caja(self, pill, UI.CREMA, 31)
	UI.icono(self, "bellota", pill.position + Vector2(36, 31), 50)
	UI.texto(self, pill.position + Vector2(108, 30), _fmt(int(round(_bel_vista))), 30, UI.CAFE, 700, true, 100)
	draw_circle(pill.position + Vector2(180, 31), 22 + sin(_pulso * 4.0) * 1.5, UI.MENTA)
	UI.icono(self, "mas", pill.position + Vector2(180, 31), 30, Color.WHITE)
	# habitaciones: puntitos y nombre
	if hoja_tipo == "" and main.modo != "pelota":
		var cy := m_top + 128.0
		var nombre: String = Casa.NOMBRES[Casa.HABS[main.hab]]
		var tw := UI.fuente(700).get_string_size(L.t(nombre), HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
		var ancho := tw + 140.0
		var rr := Rect2(Vector2(W * 0.5 - ancho * 0.5, cy - 26), Vector2(ancho, 52))
		UI._sb(self, rr, Color(1, 0.985, 0.96, 0.85), 26)
		for i in 4:
			var dp := Vector2(rr.position.x + 26 + i * 18, cy)
			var k := clampf(1.0 - absf(_hab_vista - i), 0.0, 1.0)
			draw_circle(dp, 5.0 + 2.5 * k, UI.CAFE2.lerp(UI.NARANJO, k) if k > 0.01 else Color(UI.CAFE2, 0.35))
		UI.texto(self, Vector2(rr.position.x + 104 + tw * 0.5, cy), nombre, 26, UI.CAFE, 700)
	if main.modo == "pelota":
		UI.texto_borde(self, Vector2(W * 0.5, m_top + 200), str(main.toques_pelota), 110, UI.ORO, UI.CAFE, 18)
		UI.texto_borde(self, Vector2(W * 0.5, m_top + 275), "¡Toca la pelota!", 30, Color.WHITE, UI.CAFE, 8)
	if _toast_t > 0.0:
		var a := clampf(minf(_toast_t * 3.0, (2.6 - _toast_t) * 5.0), 0.0, 1.0)
		var txt := L.t(_toast_txt)
		var w := UI.fuente(600).get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + 60
		var tr := Rect2(Vector2(W * 0.5 - w * 0.5, m_top + 175 - (1.0 - a) * 30), Vector2(w, 58))
		UI._sb(self, Rect2(tr.position + Vector2(0, 3), tr.size), Color(UI.SOMBRA, UI.SOMBRA.a * a), 29)
		UI._sb(self, tr, Color(_toast_col, a), 29)
		UI.texto(self, tr.get_center(), txt, 26, Color(1, 1, 1, a), 600)

static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var sep := "." if L.idioma == "es" else ","
	while s.length() > 3:
		out = sep + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

func _input(e: InputEvent) -> void:
	if not visible or modal != null or juego != null or not (e is InputEventMouseButton) or not e.pressed or e.button_index != MOUSE_BUTTON_LEFT:
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
			toast(L.f(_nombre_nec(n) + ": %d%%", [int(Estado.nec(n))]), NEC_COLOR[n])
			main.ir_a(NEC_HAB[n])
			get_viewport().set_input_as_handled()
			return
	# puntitos de las habitaciones
	if absf(p.y - (m_top + 128.0)) < 30.0 and absf(p.x - W * 0.5) < 160.0:
		main.ir_a((main.hab + 1) % 4)
		get_viewport().set_input_as_handled()

static func _nombre_nec(n: String) -> String:
	return {"hambre": "Comida", "energia": "Energía", "diversion": "Diversión", "higiene": "Higiene"}[n]

func toast(msg: String, col := UI.NARANJO) -> void:
	_toast_txt = msg
	_toast_col = col
	_toast_t = 2.6
	queue_redraw()

## No alcanzan las bellotas: se ofrece ir a la tienda.
func sin_bellotas(faltan := 0) -> void:
	Sfx.play("deny")
	var card := _abrir_modal(470)
	card.draw.connect(func():
		UI.caja(card, Rect2(Vector2.ZERO, card.size), UI.CREMA, 40)
		UI.texto(card, Vector2(card.size.x * 0.5, 64), "¡Te faltan bellotas!", 36, UI.CAFE, 700)
		UI.icono(card, "bellota", Vector2(card.size.x * 0.5, 170), 120)
		if faltan > 0:
			UI.texto(card, Vector2(card.size.x * 0.5, 262), L.f("Necesitas %d más", [faltan]), 26, UI.CAFE2, 600)
		UI.texto(card, Vector2(card.size.x * 0.5, 302), "Consigue más en la tienda o jugando", 22, UI.CAFE2, 500))
	var no := UI.Boton.new("", "Ahora no", Color.WHITE, Vector2(220, 84))
	no.color_icono = UI.CAFE2
	no.tam_texto = 24
	no.position = Vector2(card.size.x * 0.5 - 236, card.size.y - 112)
	no.presionado.connect(cerrar_modal)
	var si := UI.Boton.new("tienda", "Ir a la tienda", UI.NARANJO, Vector2(260, 84))
	si.color_icono = Color.WHITE
	si.tam_texto = 24
	si.position = Vector2(card.size.x * 0.5 - 4, card.size.y - 112)
	si.presionado.connect(func():
		cerrar_modal()
		abrir_panel("tienda"))
	card.add_child(no)
	card.add_child(si)

## Intenta pagar; si no alcanza, ofrece la tienda.
func pagar(precio: int) -> bool:
	if Estado.gastar(precio):
		return true
	sin_bellotas(precio - Estado.bellotas())
	return false

func refrescar() -> void:
	b_regalo.visible = Estado.regalo_disponible() and hoja_tipo == "" and main.modo != "pelota"
	dock.visible = main.modo != "pelota"
	_refrescar_accion()
	dock.queue_redraw()
	for b in dock_btn:
		b.queue_redraw()
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
			sc.position = Vector2(16, 8)
			sc.size = Vector2(W - 32, 182)
			sc.scroll_deadzone = 14
			var fila := HBoxContainer.new()
			fila.add_theme_constant_override("separation", 12)
			sc.add_child(fila)
			for c in Estado.cat.comida:
				var t := UI.Tarjeta.new(Vector2(130, 172))
				t.icono = "comida_" + c.id
				t.nombre = Estado.nombre(c)
				t.color = Color(str(c.color)).lightened(0.55)
				t.set_meta("id", c.id)
				var id: String = c.id
				t.elegida.connect(func(): main.alimentar(id, t.get_global_rect().get_center()))
				fila.add_child(t)
			accion.add_child(sc)
			_acc_botones.append(sc)
		"habitacion":
			var b := UI.Boton.new("foco", "Apagar la luz", Color("#2f3170"), Vector2(300, 96))
			b.color_icono = Color("#fff3c4")
			b.tam_texto = 24
			b.position = Vector2(W * 0.5 - 150, 80)
			b.presionado.connect(func(): main.apagar_luz(not main.luz_apagada))
			accion.add_child(b)
			_acc_botones.append(b)
		"patio":
			var b := UI.Boton.new("pelota", "Jugar a la pelota", UI.MENTA, Vector2(330, 96))
			b.color_icono = Color.WHITE
			b.tam_texto = 24
			b.position = Vector2(W * 0.5 - 165, 80)
			b.presionado.connect(func(): main.jugar_pelota())
			accion.add_child(b)
			_acc_botones.append(b)
		"bano":
			var j := UI.Boton.new("jabon", "Jabón", Color("#ff9fb0"), Vector2(220, 96))
			j.color_icono = Color.WHITE
			j.tam_texto = 24
			j.position = Vector2(W * 0.5 - 232, 80)
			j.presionado.connect(func(): main.usar_jabon())
			var d := UI.Boton.new("ducha", "Ducha", UI.AZUL, Vector2(220, 96))
			d.color_icono = Color.WHITE
			d.tam_texto = 24
			d.position = Vector2(W * 0.5 + 12, 80)
			d.presionado.connect(func(): main.ducha())
			accion.add_child(j)
			accion.add_child(d)
			_acc_botones.append(j)
			_acc_botones.append(d)
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
		if b is ScrollContainer:
			for t in (b as ScrollContainer).get_child(0).get_children():
				var tj := t as UI.Tarjeta
				var c: Dictionary = Estado.busca(Estado.cat.comida, str(tj.get_meta("id")))
				var stock := Estado.comida(str(c.id))
				tj.cantidad = stock if stock > 0 else -1
				tj.precio = 0 if stock > 0 else int(c.precio)
				tj.estado = "tiene" if stock > 0 else ""
				tj.etiqueta = ("Gratis" if c.id == "bellota" else "Tienes") if stock > 0 else ""
				tj.queue_redraw()
		elif b is UI.Boton:
			var bb := b as UI.Boton
			bb.activo = not ocupado or (h == "habitacion")
			if h == "habitacion":
				bb.texto = "Encender la luz" if main.luz_apagada else "Apagar la luz"
				bb.color = Color("#ffcf6a") if main.luz_apagada else Color("#2f3170")
				bb.color_icono = UI.CAFE if main.luz_apagada else Color("#fff3c4")
			if bb.icono == "jabon":
				bb.seleccionado = main.jabon
			bb.queue_redraw()

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
	if main.modo in ["viaje", "pelota", "ducha", "intro"] or juego != null:
		return
	if hoja_tipo == tipo:
		cerrar_panel()
		return
	if main.modo == "baile":
		main._terminar_actividad()
	if main.modo == "dormir" and tipo in ["armario", "decorar"]:
		main.apagar_luz(false)
	cerrar_panel(true)
	hoja_tipo = tipo
	_hoja_tab = 0
	_hoja_sel = ""
	_prueba_ropa = Estado.d.puesto.duplicate()
	if tipo == "armario":
		# abre en la zona de lo último que tenga puesto
		for i in ZONAS.size():
			if Estado.puesto(ZONAS[i]) != "" and ZONAS[i] != "cuello":
				_hoja_tab = i
				break
	_velo = ColorRect.new()
	_velo.color = Color(0.1, 0.05, 0.02, 0.0)
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_velo.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			cerrar_panel())
	add_child(_velo)
	move_child(_velo, dock.get_index())
	hoja = Control.new()
	hoja.size = Vector2(size.x, _alto_hoja())
	hoja.position = Vector2(0, size.y + 10)
	hoja.mouse_filter = Control.MOUSE_FILTER_STOP
	hoja.draw.connect(_dibujar_hoja)
	add_child(hoja)
	move_child(hoja, dock.get_index())
	var x := UI.Boton.new("cerrar", "", UI.CREMA, Vector2(68, 68))
	x.position = Vector2(size.x - 88, 22)
	x.color_icono = UI.CAFE2
	x.presionado.connect(func(): cerrar_panel())
	hoja.add_child(x)
	_hoja_tabs = HBoxContainer.new()
	_hoja_tabs.position = Vector2(18, 100)
	_hoja_tabs.add_theme_constant_override("separation", 8)
	hoja.add_child(_hoja_tabs)
	var arriba := 176.0 if tipo in ["armario", "decorar"] else 110.0
	if tipo == "tienda":
		arriba = 150.0
	_hoja_scroll = ScrollContainer.new()
	_hoja_scroll.position = Vector2(14, arriba)
	_hoja_scroll.size = Vector2(size.x - 28, hoja.size.y - arriba - 104 - 128)
	_hoja_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hoja_scroll.scroll_deadzone = 14
	hoja.add_child(_hoja_scroll)
	_hoja_grid = GridContainer.new()
	_hoja_grid.columns = 4
	_hoja_grid.add_theme_constant_override("h_separation", 14)
	_hoja_grid.add_theme_constant_override("v_separation", 14)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_top", 8)
	mc.add_theme_constant_override("margin_bottom", 12)
	mc.add_child(_hoja_grid)
	_hoja_scroll.add_child(mc)
	_hoja_pie = HBoxContainer.new()
	_hoja_pie.position = Vector2(0, hoja.size.y - 128 - 100)
	_hoja_pie.size = Vector2(size.x, 92)
	_hoja_pie.alignment = BoxContainer.ALIGNMENT_CENTER
	_hoja_pie.add_theme_constant_override("separation", 16)
	hoja.add_child(_hoja_pie)
	_armar_tabs()
	_armar_tarjetas()
	main.zoom_panel = 1.0 if tipo in ["armario", "decorar", "mas"] else 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(hoja, "position:y", size.y - hoja.size.y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_velo, "color:a", 0.25 if tipo in ["tienda", "juegos", "ajustes"] else 0.0, 0.3)
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
		"armario": return L.t("Armario")
		"tienda": return L.t("Tienda")
		"pociones": return L.t("Pociones")
		"bailes": return L.t("Bailes")
		"juegos": return L.t("Minijuegos")
		"mas": return L.t("Más")
		"ajustes": return L.t("Ajustes")
		"decorar":
			var tt := L.t("Decorar") + ": " + L.t(Casa.NOMBRES[Casa.HABS[main.hab]])
			L.registrar(tt)
			return tt
	return ""

func _dibujar_hoja() -> void:
	var r := Rect2(Vector2.ZERO, hoja.size + Vector2(0, 60))
	UI._sb(hoja, Rect2(r.position + Vector2(0, -4), r.size), UI.SOMBRA, 44)
	UI._sb(hoja, r, UI.CREMA, 44)
	UI._sb(hoja, Rect2(Vector2(hoja.size.x * 0.5 - 40, 12), Vector2(80, 8)), Color(UI.CAFE2, 0.25), 4)
	UI.texto(hoja, Vector2(30, 58), _titulo_hoja(), 36, UI.CAFE, 700, false)
	if hoja_tipo == "tienda":
		UI.texto(hoja, Vector2(hoja.size.x * 0.5, 110), "Versión de prueba: las compras no cobran nada", 20, UI.MENTA.darkened(0.2), 600)
	if hoja_tipo == "ajustes":
		_dibujar_ajustes()

func _armar_tabs() -> void:
	for c in _hoja_tabs.get_children():
		c.queue_free()
	var nombres: Array = []
	match hoja_tipo:
		"armario":
			for z in ZONAS:
				nombres.append(ZONA_NOMBRE[z])
		"decorar":
			for slot in Estado.cat.deco[Casa.HABS[main.hab]]:
				nombres.append(_nombre_slot(slot))
	if nombres.is_empty():
		return
	var ancho := minf(150.0, (size.x - 36 - 8 * (nombres.size() - 1)) / nombres.size())
	for i in nombres.size():
		var b := UI.Boton.new("", nombres[i], UI.NARANJO if i == _hoja_tab else Color.WHITE, Vector2(ancho, 60))
		b.color_icono = Color.WHITE if i == _hoja_tab else UI.CAFE2
		b.tam_texto = 20 if ancho > 110 else 17
		b.radio = 30
		var idx := i
		b.presionado.connect(func():
			_hoja_tab = idx
			_hoja_sel = ""
			_armar_tabs()
			_armar_tarjetas())
		_hoja_tabs.add_child(b)

static func _nombre_slot(s: String) -> String:
	return {"pared": "Pared", "piso": "Piso", "nevera": "Nevera", "mesa": "Mesa", "planta": "Planta", "cama": "Cama",
		"lampara": "Lámpara", "alfombra": "Alfombra", "fondo": "Cielo", "cerca": "Cerca", "arbol": "Árbol", "pasto": "Suelo",
		"juguete": "Juegos", "banera": "Bañera", "cortina": "Cortina"}.get(s, s)

func _tarjeta(csz: Vector2) -> UI.Tarjeta:
	var t := UI.Tarjeta.new(csz)
	_hoja_grid.add_child(t)
	return t

func _armar_tarjetas() -> void:
	for c in _hoja_grid.get_children():
		c.queue_free()
	_hoja_scroll.scroll_vertical = 0
	var W := size.x - 28 - 16
	var cw := floorf((W - 14 * 3) / 4.0)
	var csz := Vector2(cw, cw * 1.25)
	_hoja_grid.columns = 4
	match hoja_tipo:
		"armario":
			var zona: String = ZONAS[_hoja_tab]
			var nada := _tarjeta(csz)
			nada.icono = "cerrar"
			nada.nombre = "Nada"
			nada.color = Color("#f1ebe4")
			nada.color_icono = Color("#c9b8a8")
			nada.estado = "puesto" if str(_prueba_ropa.get(zona, "")) == "" else "tiene"
			nada.elegida.connect(func(): _probar_ropa(zona, ""))
			for r in Estado.cat.ropa:
				if r.zona != zona:
					continue
				var t := _tarjeta(csz)
				t.icono = "ropa_" + r.forma
				t.colores = r.c
				t.nombre = Estado.nombre(r)
				t.precio = int(r.precio)
				t.color = Color("#fff1e0")
				t.animada = str(r.get("anim", "")) != ""
				var tiene := Estado.tiene(r.id) or int(r.precio) == 0
				if str(_prueba_ropa.get(zona, "")) == r.id:
					t.estado = "puesto"
				elif tiene:
					t.estado = "tiene"
				elif Estado.nivel() < int(r.nivel):
					t.estado = "bloqueado"
				var id: String = r.id
				t.elegida.connect(func(): _probar_ropa(zona, id))
		"decorar":
			var h: String = Casa.HABS[main.hab]
			var slots: Array = Estado.cat.deco[h].keys()
			var slot: String = slots[_hoja_tab]
			for v in Estado.cat.deco[h][slot]:
				var t := _tarjeta(csz)
				t.icono = "deco_" + slot
				t.nombre = Estado.nombre(v)
				t.precio = int(v.precio)
				var p: Dictionary = v.get("p", {})
				t.color = Color(str(p.get("c1", p.get("c", "#e9e0d6"))))
				t.colores = [str(p.get("c2", p.get("c", "#ffffff"))), str(p.get("patron", p.get("forma", p.get("tipo", p.get("cielo", "")))))]
				var clave: String = "deco_%s_%s_%s" % [h, slot, v.id]
				var sel := _hoja_sel if _hoja_sel != "" else Estado.deco(h, slot)
				if sel == v.id:
					t.estado = "puesto"
				elif Estado.tiene(clave) or int(v.precio) == 0:
					t.estado = "tiene"
				var id: String = v.id
				t.elegida.connect(func(): _probar_deco(h, slot, id))
		"pociones":
			for p in Estado.cat.pociones:
				var t := _tarjeta(csz)
				t.icono = "pocion" if p.id != "capibara" else "capibara"
				t.nombre = Estado.nombre(p)
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
		"bailes":
			for b in Estado.cat.bailes:
				var t := _tarjeta(csz)
				t.icono = "nota"
				t.nombre = Estado.nombre(b)
				t.precio = int(b.precio)
				t.color = Color("#dfeeff")
				t.color_icono = UI.AZUL
				if _hoja_sel == b.id:
					t.estado = "puesto"
				elif Estado.tiene("baile_" + b.id) or int(b.precio) == 0:
					t.estado = "tiene"
				var id: String = b.id
				t.elegida.connect(func():
					_hoja_sel = id
					if Estado.tiene("baile_" + id) or int(Estado.busca(Estado.cat.bailes, id).precio) == 0:
						cerrar_panel()
						main.bailar(id)
					else:
						_armar_tarjetas())
		"juegos":
			_hoja_grid.columns = 2
			var gsz := Vector2(floorf((W - 14) / 2.0), 230)
			for j in Estado.cat.juegos:
				var t := _tarjeta(gsz)
				t.icono = str(j.icono)
				t.nombre = Estado.nombre(j)
				t.color = {"salto": Color("#cfe9ff"), "lluvia": Color("#e1f6d0"), "memoria": Color("#ffe1ec"), "cohete": Color("#e0dcff"), "pelota": Color("#fff0c9")}.get(j.id, Color.WHITE)
				t.color_icono = UI.CAFE if j.id != "salto" else Color.WHITE
				var rec := int(Estado.d.records.get(j.id, 0))
				t.etiqueta = L.f("Récord: %d", [rec]) if rec > 0 else "Jugar"
				t.estado = "tiene"
				var id: String = j.id
				t.elegida.connect(func(): _jugar(id))
		"mas":
			var items := [["nota", "Bailes", "bailes", UI.AZUL], ["pocion", "Pociones", "pociones", UI.LILA],
				["capibara", "Capibara", "capibara", Color("#b07a45")], ["regalo", "Regalo diario", "regalo", UI.ROSA],
				["engranaje", "Ajustes", "ajustes", UI.CAFE2]]
			for it in items:
				var t := _tarjeta(csz)
				t.icono = it[0]
				t.nombre = it[1]
				t.color = (it[3] as Color).lightened(0.6)
				t.color_icono = it[3]
				t.estado = "tiene"
				t.etiqueta = " "
				var dest: String = it[2]
				t.elegida.connect(_ir_mas.bind(dest))
		"ajustes":
			_armar_ajustes()
		"tienda":
			_armar_tienda(W, csz)
	_armar_pie()

func _ir_mas(dest: String) -> void:
	match dest:
		"capibara":
			cerrar_panel()
			abrir_capibara()
		"regalo":
			cerrar_panel()
			abrir_regalo()
		_:
			abrir_panel(dest)

func _jugar(id: String) -> void:
	if id == "pelota":
		cerrar_panel()
		if main.hab != 2:
			await main.ir_a(2)
		main.jugar_pelota()
		return
	if Estado.nec("energia") < 10.0:
		toast("Pip está muy cansado: hazlo dormir", UI.ROJO)
		Sfx.play("deny")
		return
	cerrar_panel(true)
	juego = Minijuego.new(id)
	add_child(juego)
	juego.size = size
	juego.terminado.connect(func(_t, _p, gana):
		if gana > 0:
			main.fx.volar(size * 0.5, pos_bellotas(), mini(14, gana))
		juego.queue_free()
		juego = null
		main.pip.hacer("celebrar")
		refrescar())
	refrescar()

func _armar_tienda(W: float, csz: Vector2) -> void:
	_hoja_grid.columns = 2
	var ancho := floorf((W - 14) / 2.0)
	for e in Estado.cat.especiales:
		if Estado.d.compras.get(e.id, false):
			continue
		var t := _tarjeta(Vector2(ancho, 250))
		t.icono = "regalo" if e.id == "pack_inicio" else "capibara"
		t.nombre = Estado.nombre(e)
		t.precio_txt = str(e.precio)
		t.color = Color("#ffe1ec") if e.id == "pack_inicio" else Color("#f3e3cf")
		t.color_icono = UI.ROSA
		t.cinta = "¡Oferta!" if e.id == "pack_inicio" else "Para siempre"
		t.etiqueta = L.f("%d bellotas + 3 capibaras", [int(e.bellotas)]) if e.id == "pack_inicio" else "Transformación permanente"
		var id: String = e.id
		t.elegida.connect(func(): _confirmar_compra(id))
	for p in Estado.cat.paquetes:
		var t := _tarjeta(Vector2(ancho, 230))
		t.icono = "bellota"
		t.nombre = L.f("%s bellotas", [_fmt(int(p.bellotas))])
		t.precio_txt = str(p.precio)
		t.color = Color("#ffe9c9")
		var tag := str(p.get("tag", ""))
		t.cinta = {"popular": "Más popular", "mejor": "Mejor valor"}.get(tag, tag)
		t.etiqueta = Estado.nombre(p)
		var id: String = p.id
		t.elegida.connect(func(): _confirmar_compra(id))

func _probar_ropa(zona: String, id: String) -> void:
	_prueba_ropa[zona] = id
	if zona == "traje" and id != "":
		pass
	_hoja_sel = id
	Atuendos.vestir(main.pip, _prueba_ropa)
	main.pip.hacer("celebrar" if id != "" else "mirar_cola")
	if id == "" or Estado.tiene(id) or int(Estado.ropa_por_id.get(id, {}).get("precio", 1)) == 0:
		Estado.poner(zona, id)
	_armar_tarjetas()

func _probar_deco(h: String, slot: String, id: String) -> void:
	_hoja_sel = id
	main.casa.rearmar(h, slot, id)
	var v: Dictionary = Estado.busca(Estado.cat.deco[h][slot], id)
	if Estado.tiene("deco_%s_%s_%s" % [h, slot, id]) or int(v.get("precio", 1)) == 0:
		Estado.agregar("deco_%s_%s_%s" % [h, slot, id])
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
			if id != "" and not Estado.tiene(id) and Estado.ropa_por_id.has(id) and int(Estado.ropa_por_id[id].precio) > 0:
				var r: Dictionary = Estado.ropa_por_id[id]
				if Estado.nivel() < int(r.nivel):
					b = UI.Boton.new("candado", L.f("Desde el nivel %d", [int(r.nivel)]), Color("#d9cfc6"), Vector2(380, 84))
					b.activo = false
				else:
					b = _boton_comprar(int(r.precio), func():
						if pagar(int(r.precio)):
							Estado.agregar(id)
							Estado.poner(zona, id)
							_celebrar_compra()
							_armar_tarjetas())
		"decorar":
			var h: String = Casa.HABS[main.hab]
			var slot: String = Estado.cat.deco[h].keys()[_hoja_tab]
			if _hoja_sel != "" and not Estado.tiene("deco_%s_%s_%s" % [h, slot, _hoja_sel]):
				var v: Dictionary = Estado.busca(Estado.cat.deco[h][slot], _hoja_sel)
				var id := _hoja_sel
				if int(v.get("precio", 0)) > 0:
					b = _boton_comprar(int(v.precio), func():
						if pagar(int(v.precio)):
							Estado.agregar("deco_%s_%s_%s" % [h, slot, id])
							Estado.poner_deco(h, slot, id)
							_celebrar_compra()
							_armar_tarjetas())
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
					if pagar(int(p.precio)):
						Estado.sumar_pocion(id, 1)
						Sfx.play("item")
						_armar_tarjetas(), Vector2(260, 84))
		"bailes":
			if _hoja_sel != "" and not Estado.tiene("baile_" + _hoja_sel):
				var bl: Dictionary = Estado.busca(Estado.cat.bailes, _hoja_sel)
				var id := _hoja_sel
				b = _boton_comprar(int(bl.precio), func():
					if pagar(int(bl.precio)):
						Estado.agregar("baile_" + id)
						_celebrar_compra()
						cerrar_panel()
						main.bailar(id))
	if b:
		_hoja_pie.add_child(b)

func _boton_comprar(precio: int, cb: Callable, sz := Vector2(300, 84)) -> UI.Boton:
	var b := UI.Boton.new("bellota", L.f("Comprar  %d", [precio]), UI.NARANJO, sz)
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

# ================= ajustes =================
var _aj_filas := []

func _armar_ajustes() -> void:
	_hoja_grid.columns = 1
	var W := size.x - 60
	var filas := [
		["Música", "musica", [["0", 0.0], ["1", 0.35], ["2", 0.7], ["3", 1.0]]],
		["Efectos", "efectos", [["0", 0.0], ["1", 0.35], ["2", 0.7], ["3", 1.0]]],
		["Gráficos", "calidad", [["Baja", 0], ["Media", 1], ["Alta", 2]]],
		["Idioma", "idioma", [["Español", "es"], ["English", "en"]]],
		["Vibración", "vibrar", [["No", false], ["Sí", true]]],
	]
	for f in filas:
		var fila := Control.new()
		fila.custom_minimum_size = Vector2(W, 96)
		var k: String = f[1]
		var lbl: String = f[0]
		fila.draw.connect(func():
			UI.texto(fila, Vector2(8, 48), lbl, 28, UI.CAFE, 700, false))
		var ops: Array = f[2]
		var bw := minf(140.0, (W - 230) / ops.size() - 8)
		for i in ops.size():
			var op: Array = ops[i]
			var txt: String = op[0]
			if k in ["musica", "efectos"]:
				txt = ["Sin", "Bajo", "Medio", "Alto"][i]
			var sel: bool = str(Estado.cfg(k)) == str(op[1]) or (k in ["musica", "efectos"] and absf(float(Estado.cfg(k)) - float(op[1])) < 0.05)
			var b := UI.Boton.new("", txt, UI.NARANJO if sel else Color.WHITE, Vector2(bw, 64))
			b.color_icono = Color.WHITE if sel else UI.CAFE2
			b.tam_texto = 21
			b.radio = 32
			b.position = Vector2(W - ops.size() * (bw + 8) + i * (bw + 8), 16)
			var val = op[1]
			b.presionado.connect(func():
				Estado.poner_cfg(k, val)
				main.aplicar_ajustes()
				_armar_tarjetas()
				queue_redraw())
			fila.add_child(b)
		_hoja_grid.add_child(fila)
	var ver := Control.new()
	ver.custom_minimum_size = Vector2(W, 60)
	ver.draw.connect(func():
		UI.texto(ver, Vector2(W * 0.5, 30), L.f("Pocket Pip · versión %s · sin anuncios", [str(ProjectSettings.get_setting("application/config/version")) + "." + str(ProjectSettings.get_setting("application/config/build"))]), 19, UI.CAFE2, 500))
	_hoja_grid.add_child(ver)

func _dibujar_ajustes() -> void:
	pass

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
			UI.texto(card, r.position + Vector2(r.size.x * 0.5, 22), L.f("Día %d", [i + 1]), 19, UI.CAFE, 600)
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
			toast(L.f("+%d bellotas", [n]), UI.MENTA)
			main.pip.hacer("celebrar")
		cerrar_modal()
		refrescar())
	card.add_child(b)

## La capibara: 3 minutos por bellotas (poción) o para siempre (compra con dinero real).
func abrir_capibara() -> void:
	var card := _abrir_modal(600)
	var perm := Estado.capibara_permanente()
	var p: Dictionary = Estado.busca(Estado.cat.pociones, "capibara")
	card.draw.connect(func():
		UI.caja(card, Rect2(Vector2.ZERO, card.size), UI.CREMA, 40)
		UI.texto(card, Vector2(card.size.x * 0.5, 60), "Capibara", 40, UI.CAFE, 700)
		UI.icono(card, "capibara", Vector2(card.size.x * 0.5, 190), 170)
		UI.texto(card, Vector2(card.size.x * 0.5, 310), "Pip se transforma en una capibara tranquila", 24, UI.CAFE2, 500)
		if perm:
			UI.texto(card, Vector2(card.size.x * 0.5, 350), "¡Es tuya para siempre!", 24, UI.MENTA.darkened(0.2), 700))
	var y := card.size.y - 210
	if perm:
		var ser := Estado.capibara_activa()
		var b := UI.Boton.new("capibara" if not ser else "check", "Volver a ser Pip" if ser else "Ser capibara", UI.NARANJO, Vector2(380, 86))
		b.color_icono = Color.WHITE
		b.tam_texto = 26
		b.position = Vector2(card.size.x * 0.5 - 190, y + 40)
		b.presionado.connect(func():
			Estado.d.forma = "pip" if ser else "capibara"
			Estado.d.capi_hasta = 0.0
			Estado.marcar()
			cerrar_modal())
		card.add_child(b)
	else:
		var b1 := UI.Boton.new("bellota", L.f("3 minutos · %d", [int(p.precio)]), UI.NARANJO, Vector2(300, 86))
		b1.color_icono = Color.WHITE
		b1.tam_texto = 22
		b1.position = Vector2(card.size.x * 0.5 - 308, y)
		b1.presionado.connect(func():
			if Estado.pociones("capibara") > 0 or pagar(int(p.precio)):
				if Estado.pociones("capibara") <= 0:
					Estado.sumar_pocion("capibara", 1)
				cerrar_modal()
				main.pocion("capibara"))
		var b2 := UI.Boton.new("capibara", "Para siempre · $1.499", UI.MENTA, Vector2(300, 86))
		b2.color_icono = Color.WHITE
		b2.tam_texto = 22
		b2.position = Vector2(card.size.x * 0.5 + 8, y)
		b2.presionado.connect(func(): _confirmar_compra("capibara_permanente"))
		card.add_child(b1)
		card.add_child(b2)
	var x := UI.Boton.new("cerrar", "", Color.WHITE, Vector2(64, 64))
	x.color_icono = UI.CAFE2
	x.position = Vector2(card.size.x - 84, 20)
	x.presionado.connect(cerrar_modal)
	card.add_child(x)

func _confirmar_compra(id: String) -> void:
	var p: Dictionary = Estado.busca(Estado.cat.paquetes, id)
	if p.is_empty():
		p = Estado.busca(Estado.cat.especiales, id)
	var card := _abrir_modal(480)
	card.draw.connect(func():
		UI.caja(card, Rect2(Vector2.ZERO, card.size), UI.CREMA, 40)
		UI.texto(card, Vector2(card.size.x * 0.5, 58), Estado.nombre(p), 34, UI.CAFE, 700)
		if int(p.get("bellotas", 0)) > 0:
			UI.icono(card, "bellota", Vector2(card.size.x * 0.5 - 70, 160), 110)
			UI.texto(card, Vector2(card.size.x * 0.5 + 60, 160), _fmt(int(p.bellotas)), 48, UI.CAFE, 700)
		else:
			UI.icono(card, "capibara", Vector2(card.size.x * 0.5, 160), 130)
		UI.texto(card, Vector2(card.size.x * 0.5, 252), L.f("Precio en Google Play: %s", [str(p.precio)]), 22, UI.CAFE2, 500)
		UI.texto(card, Vector2(card.size.x * 0.5, 290), "Prueba: no se cobra nada", 24, UI.MENTA.darkened(0.15), 700))
	var no := UI.Boton.new("", "Cancelar", Color.WHITE, Vector2(220, 84))
	no.color_icono = UI.CAFE2
	no.tam_texto = 24
	no.position = Vector2(card.size.x * 0.5 - 236, card.size.y - 112)
	no.presionado.connect(cerrar_modal)
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
		cerrar_modal()
		if hoja_tipo == "tienda":
			_armar_tarjetas())
	card.add_child(no)
	card.add_child(si)
