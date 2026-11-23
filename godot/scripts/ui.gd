## Pocket Pip — piezas de la interfaz: colores, tipografía, íconos dibujados a mano (sin imágenes), botones con
## rebote, tarjetas de la tienda/armario y la capa de efectos (corazones, estrellas, burbujas, bellotas que vuelan).
class_name UI

const CREMA := Color("#fff8f0")
const CAFE := Color("#5b3a29")
const CAFE2 := Color("#8a5a3c")
const NARANJO := Color("#ff9f43")
const MENTA := Color("#5cc9a7")
const ROSA := Color("#ff7aa2")
const ORO := Color("#ffc93c")
const LILA := Color("#8b7cf6")
const AZUL := Color("#4aa8ff")
const ROJO := Color("#ff5a5f")
const SOMBRA := Color(0.25, 0.12, 0.05, 0.13)

static var _fuentes := {}

static func fuente(peso := 500) -> Font:
	if _fuentes.has(peso):
		return _fuentes[peso]
	var base: Font = load("res://fonts/Fredoka.ttf")
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
	_fuentes[peso] = f
	return f

## Rectángulo redondeado relleno (con sombra opcional y brillo arriba).
static func caja(ci: CanvasItem, r: Rect2, col: Color, radio: float, sombra := true, brillo := false) -> void:
	if sombra:
		_sb(ci, Rect2(r.position + Vector2(0, 3), r.size), SOMBRA, radio)
	_sb(ci, r, col, radio)
	if brillo:
		var h := Rect2(r.position + Vector2(r.size.x * 0.08, r.size.y * 0.06), Vector2(r.size.x * 0.84, r.size.y * 0.3))
		_sb(ci, h, Color(1, 1, 1, 0.22), minf(radio, h.size.y * 0.5))

static var _sbox: StyleBoxFlat

static func _sb(ci: CanvasItem, r: Rect2, col: Color, radio: float) -> void:
	if _sbox == null:
		_sbox = StyleBoxFlat.new()
		_sbox.anti_aliasing = true
		_sbox.anti_aliasing_size = 1.2
	_sbox.bg_color = col
	_sbox.set_corner_radius_all(int(minf(radio, minf(r.size.x, r.size.y) * 0.5)))
	_sbox.corner_detail = 10
	ci.draw_style_box(_sbox, r)

static func texto(ci: CanvasItem, pos: Vector2, s: String, tam: int, col: Color, peso := 600, centro := true, ancho := -1.0) -> void:
	s = L.t(s)
	var f := fuente(peso)
	if centro:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		if ancho > 0 and w > ancho:
			tam = int(tam * ancho / w)
			w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		pos.x -= w * 0.5
	ci.draw_string(f, pos + Vector2(0, tam * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

static func texto_borde(ci: CanvasItem, pos: Vector2, s: String, tam: int, col: Color, borde: Color, grosor := 8, peso := 700) -> void:
	s = L.t(s)
	var f := fuente(peso)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var p := pos + Vector2(-w * 0.5, tam * 0.35)
	ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, grosor, borde)
	ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

# ================= íconos =================
static func _poly(ci: CanvasItem, pts: Array, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array(pts), col)

static func corazon_pts(c: Vector2, s: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var x := 16.0 * pow(sin(a), 3)
		var y := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
		p.append(c + Vector2(x, -y) * s / 34.0)
	return p

static func estrella_pts(c: Vector2, r: float, rot := 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 - PI / 2.0 + rot
		var rr := r * (0.46 if i % 2 else 1.0)
		p.append(c + Vector2(cos(a), sin(a)) * rr)
	return p

## Dibuja el ícono `id` centrado en c, en una caja de lado s.
static func icono(ci: CanvasItem, id: String, c: Vector2, s: float, col := Color.WHITE) -> void:
	var u := s / 100.0
	match id:
		"bellota":
			ci.draw_circle(c + Vector2(0, 8) * u, 30 * u, Color("#d08a3c"))
			_poly(ci, [c + Vector2(-30, 8) * u, c + Vector2(30, 8) * u, c + Vector2(0, 46) * u], Color("#d08a3c"))
			ci.draw_circle(c + Vector2(-9, 4) * u, 9 * u, Color(1, 1, 1, 0.35))
			_sb(ci, Rect2(c + Vector2(-36, -24) * u, Vector2(72, 26) * u), Color("#7a4b2a"), 13 * u)
			_sb(ci, Rect2(c + Vector2(-4, -38) * u, Vector2(8, 16) * u), Color("#7a4b2a"), 4 * u)
			for i in 4:
				ci.draw_line(c + Vector2(-26 + i * 17, -21) * u, c + Vector2(-20 + i * 17, -2) * u, Color("#5b3720"), 3 * u)
			ci.draw_circle(c + Vector2(10, -14) * u, 5 * u, Color(1, 0.9, 0.6, 0.4))
		"corazon":
			ci.draw_colored_polygon(corazon_pts(c + Vector2(0, 4) * u, 80 * u), col)
		"estrella":
			ci.draw_colored_polygon(estrella_pts(c, 44 * u), col)
		"ropa":
			_poly(ci, [c + Vector2(-20, -36) * u, c + Vector2(-44, -24) * u, c + Vector2(-50, 0) * u, c + Vector2(-32, 6) * u,
				c + Vector2(-30, 40) * u, c + Vector2(30, 40) * u, c + Vector2(32, 6) * u, c + Vector2(50, 0) * u,
				c + Vector2(44, -24) * u, c + Vector2(20, -36) * u, c + Vector2(0, -24) * u], col)
			ci.draw_circle(c + Vector2(0, -32) * u, 12 * u, col)
		"tienda":
			_sb(ci, Rect2(c + Vector2(-38, -14) * u, Vector2(76, 58) * u), col, 12 * u)
			ci.draw_arc(c + Vector2(0, -14) * u, 20 * u, PI, TAU, 16, col, 8 * u, true)
			ci.draw_circle(c + Vector2(0, 14) * u, 9 * u, Color(0, 0, 0, 0.15))
		"pincel":
			ci.draw_line(c + Vector2(26, -36) * u, c + Vector2(-6, 6) * u, col, 12 * u, true)
			ci.draw_circle(c + Vector2(26, -36) * u, 6 * u, col)
			_poly(ci, [c + Vector2(-2, 2) * u, c + Vector2(-14, -6) * u, c + Vector2(-38, 36) * u, c + Vector2(-8, 18) * u], col)
		"pocion":
			ci.draw_circle(c + Vector2(0, 14) * u, 30 * u, col)
			_sb(ci, Rect2(c + Vector2(-11, -38) * u, Vector2(22, 30) * u), col, 6 * u)
			_sb(ci, Rect2(c + Vector2(-15, -44) * u, Vector2(30, 10) * u), Color(col, 0.7), 4 * u)
			ci.draw_circle(c + Vector2(-10, 6) * u, 7 * u, Color(1, 1, 1, 0.45))
		"nota":
			ci.draw_circle(c + Vector2(-16, 26) * u, 15 * u, col)
			ci.draw_circle(c + Vector2(24, 18) * u, 15 * u, col)
			ci.draw_line(c + Vector2(-3, 26) * u, c + Vector2(-3, -34) * u, col, 8 * u)
			ci.draw_line(c + Vector2(37, 18) * u, c + Vector2(37, -42) * u, col, 8 * u)
			_poly(ci, [c + Vector2(-7, -34) * u, c + Vector2(41, -44) * u, c + Vector2(41, -28) * u, c + Vector2(-7, -18) * u], col)
		"regalo":
			_sb(ci, Rect2(c + Vector2(-36, -8) * u, Vector2(72, 48) * u), col, 8 * u)
			_sb(ci, Rect2(c + Vector2(-42, -22) * u, Vector2(84, 18) * u), col.lightened(0.15), 6 * u)
			ci.draw_rect(Rect2(c + Vector2(-7, -22) * u, Vector2(14, 62) * u), Color("#ff5a5f"))
			ci.draw_circle(c + Vector2(-14, -30) * u, 12 * u, Color("#ff5a5f"))
			ci.draw_circle(c + Vector2(14, -30) * u, 12 * u, Color("#ff5a5f"))
		"cocina":
			ci.draw_arc(c + Vector2(0, 0) * u, 36 * u, 0, TAU, 32, col, 8 * u, true)
			ci.draw_line(c + Vector2(-50, -30) * u, c + Vector2(-50, 40) * u, col, 7 * u)
			ci.draw_line(c + Vector2(50, -30) * u, c + Vector2(50, 40) * u, col, 7 * u)
			ci.draw_circle(c + Vector2(50, -30) * u, 8 * u, col)
		"habitacion":
			# luna
			_luna(ci, c, 40 * u, col)
		"patio":
			ci.draw_circle(c, 24 * u, col)
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * 33 * u, c + Vector2(cos(a), sin(a)) * 46 * u, col, 8 * u, true)
		"bano":
			_gota(ci, c + Vector2(0, 4) * u, 40 * u, col)
		"hambre":
			ci.draw_circle(c + Vector2(-12, 8) * u, 30 * u, col)
			ci.draw_circle(c + Vector2(12, 8) * u, 30 * u, col)
			ci.draw_line(c + Vector2(0, -18) * u, c + Vector2(6, -42) * u, Color("#7a4b2a"), 7 * u)
			_poly(ci, [c + Vector2(6, -32) * u, c + Vector2(30, -44) * u, c + Vector2(18, -24) * u], Color("#5cc96a"))
		"energia":
			_poly(ci, [c + Vector2(8, -46) * u, c + Vector2(-26, 6) * u, c + Vector2(-2, 6) * u, c + Vector2(-10, 46) * u,
				c + Vector2(26, -8) * u, c + Vector2(2, -8) * u], col)
		"diversion":
			ci.draw_circle(c, 40 * u, col)
			ci.draw_arc(c + Vector2(0, 2) * u, 22 * u, 0.3, PI - 0.3, 16, Color(0, 0, 0, 0.45), 7 * u, true)
			ci.draw_circle(c + Vector2(-14, -12) * u, 6 * u, Color(0, 0, 0, 0.45))
			ci.draw_circle(c + Vector2(14, -12) * u, 6 * u, Color(0, 0, 0, 0.45))
		"higiene":
			ci.draw_circle(c + Vector2(-12, 10) * u, 26 * u, col)
			ci.draw_circle(c + Vector2(20, -16) * u, 16 * u, col)
			ci.draw_circle(c + Vector2(24, 26) * u, 10 * u, col)
			ci.draw_circle(c + Vector2(-20, 2) * u, 7 * u, Color(1, 1, 1, 0.5))
		"foco":
			ci.draw_circle(c + Vector2(0, -8) * u, 30 * u, col)
			_sb(ci, Rect2(c + Vector2(-15, 18) * u, Vector2(30, 24) * u), col.darkened(0.25), 6 * u)
		"ducha":
			_sb(ci, Rect2(c + Vector2(-34, -40) * u, Vector2(68, 20) * u), col, 10 * u)
			for i in 5:
				ci.draw_line(c + Vector2(-24 + i * 12, -12) * u, c + Vector2(-28 + i * 14, 40) * u, Color(col, 0.8), 6 * u, true)
		"jabon":
			_sb(ci, Rect2(c + Vector2(-40, -10) * u, Vector2(80, 44) * u), col, 16 * u)
			ci.draw_circle(c + Vector2(-16, -26) * u, 14 * u, Color(1, 1, 1, 0.8))
			ci.draw_circle(c + Vector2(12, -34) * u, 10 * u, Color(1, 1, 1, 0.8))
		"pelota":
			ci.draw_circle(c, 40 * u, col)
			ci.draw_arc(c, 40 * u, -0.6, 0.6, 12, Color("#ff5a5f"), 10 * u, true)
			ci.draw_arc(c, 40 * u, PI - 0.6, PI + 0.6, 12, Color("#4aa8ff"), 10 * u, true)
			ci.draw_circle(c + Vector2(-12, -14) * u, 8 * u, Color(1, 1, 1, 0.6))
		"cerrar":
			ci.draw_line(c + Vector2(-24, -24) * u, c + Vector2(24, 24) * u, col, 12 * u, true)
			ci.draw_line(c + Vector2(24, -24) * u, c + Vector2(-24, 24) * u, col, 12 * u, true)
		"mas":
			ci.draw_line(c + Vector2(0, -28) * u, c + Vector2(0, 28) * u, col, 12 * u, true)
			ci.draw_line(c + Vector2(-28, 0) * u, c + Vector2(28, 0) * u, col, 12 * u, true)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-28, 2) * u, c + Vector2(-8, 22) * u, c + Vector2(30, -22) * u]), col, 12 * u, true)
		"candado":
			ci.draw_arc(c + Vector2(0, -8) * u, 20 * u, PI, TAU, 16, col, 9 * u, true)
			ci.draw_line(c + Vector2(-20, -8) * u, c + Vector2(-20, 4) * u, col, 9 * u)
			ci.draw_line(c + Vector2(20, -8) * u, c + Vector2(20, 4) * u, col, 9 * u)
			_sb(ci, Rect2(c + Vector2(-30, 0) * u, Vector2(60, 42) * u), col, 8 * u)
		"altavoz":
			_poly(ci, [c + Vector2(-38, -14) * u, c + Vector2(-18, -14) * u, c + Vector2(6, -36) * u, c + Vector2(6, 36) * u,
				c + Vector2(-18, 14) * u, c + Vector2(-38, 14) * u], col)
			ci.draw_arc(c + Vector2(6, 0) * u, 22 * u, -0.8, 0.8, 10, col, 7 * u, true)
			ci.draw_arc(c + Vector2(6, 0) * u, 38 * u, -0.8, 0.8, 12, col, 7 * u, true)
		"flecha_izq":
			ci.draw_polyline(PackedVector2Array([c + Vector2(16, -30) * u, c + Vector2(-16, 0) * u, c + Vector2(16, 30) * u]), col, 13 * u, true)
		"flecha_der":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-16, -30) * u, c + Vector2(16, 0) * u, c + Vector2(-16, 30) * u]), col, 13 * u, true)
		"zzz":
			texto(ci, c, "Zz", int(60 * u), col, 700)
		"juegos":
			_sb(ci, Rect2(c + Vector2(-48, -26) * u, Vector2(96, 56) * u), col, 26 * u)
			ci.draw_line(c + Vector2(-30, 2) * u, c + Vector2(-10, 2) * u, Color(0, 0, 0, 0.35), 7 * u)
			ci.draw_line(c + Vector2(-20, -8) * u, c + Vector2(-20, 12) * u, Color(0, 0, 0, 0.35), 7 * u)
			ci.draw_circle(c + Vector2(18, -4) * u, 6 * u, Color(0, 0, 0, 0.35))
			ci.draw_circle(c + Vector2(30, 8) * u, 6 * u, Color(0, 0, 0, 0.35))
		"menu":
			for i in 3:
				ci.draw_circle(c + Vector2(-28 + i * 28, 0) * u, 10 * u, col)
		"engranaje":
			for i in 8:
				var a := TAU * i / 8.0
				_sb(ci, Rect2(c + Vector2(cos(a), sin(a)) * 34 * u - Vector2(9, 9) * u, Vector2(18, 18) * u), col, 4 * u)
			ci.draw_circle(c, 32 * u, col)
			ci.draw_circle(c, 13 * u, Color(0, 0, 0, 0.3))
		"capibara":
			_sb(ci, Rect2(c + Vector2(-40, -30) * u, Vector2(80, 66) * u), Color("#a0703f"), 30 * u)
			_sb(ci, Rect2(c + Vector2(-26, 0) * u, Vector2(52, 36) * u), Color("#8a5a33"), 18 * u)
			ci.draw_circle(c + Vector2(-22, -30) * u, 9 * u, Color("#6e4a2a"))
			ci.draw_circle(c + Vector2(22, -30) * u, 9 * u, Color("#6e4a2a"))
			ci.draw_circle(c + Vector2(-16, -10) * u, 5 * u, Color("#1e1410"))
			ci.draw_circle(c + Vector2(16, -10) * u, 5 * u, Color("#1e1410"))
			ci.draw_circle(c + Vector2(0, -44) * u, 13 * u, Color("#ff9f2e"))
			ci.draw_circle(c + Vector2(6, -56) * u, 5 * u, Color("#4cae4c"))
		"salto":
			for j in 3:
				ci.draw_circle(c + Vector2((j - 1) * 24, 26) * u, 18 * u, col)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-20, -10) * u, c + Vector2(0, -38) * u, c + Vector2(20, -10) * u]), Color("#ff9f43"), 10 * u, true)
		"memoria":
			_sb(ci, Rect2(c + Vector2(-44, -34) * u, Vector2(50, 68) * u), Color("#ff9f43"), 10 * u)
			_sb(ci, Rect2(c + Vector2(-6, -26) * u, Vector2(50, 68) * u), col, 10 * u)
			ci.draw_colored_polygon(corazon_pts(c + Vector2(19, 8) * u, 34 * u), ROSA)
		"cohete":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -46) * u, c + Vector2(18, -10) * u, c + Vector2(18, 26) * u,
				c + Vector2(-18, 26) * u, c + Vector2(-18, -10) * u]), Color("#e8eef7"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -46) * u, c + Vector2(14, -18) * u, c + Vector2(-14, -18) * u]), Color("#ff5a5f"))
			ci.draw_circle(c + Vector2(0, 0) * u, 9 * u, Color("#7fd8ff"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, 26) * u, c + Vector2(0, 50) * u, c + Vector2(12, 26) * u]), Color("#ffb347"))
		"luna":
			_luna(ci, c, 40 * u, col)
		_:
			if id.begins_with("comida_"):
				icono_comida(ci, id.substr(7), c, s)
			else:
				ci.draw_circle(c, 30 * u, col)

static func _luna(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var a := _circle(c, r, 40)
	var b := _circle(c + Vector2(r * 0.45, -r * 0.35), r * 0.85, 40)
	var res := Geometry2D.clip_polygons(a, b)
	for p in res:
		ci.draw_colored_polygon(p, col)

static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var an := TAU * i / n
		p.append(c + Vector2(cos(an), sin(an)) * r)
	return p

static func _gota(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var p := PackedVector2Array()
	for i in 30:
		var a := PI * i / 29.0
		p.append(c + Vector2(cos(a) * r * 0.8, sin(a) * r * 0.8 + r * 0.25))
	p.append(c + Vector2(0, -r * 1.05))
	ci.draw_colored_polygon(p, col)

## Mini dibujos de la ropa (para las tarjetas del armario).
static func icono_ropa(ci: CanvasItem, forma: String, c: Vector2, s: float, cs: Array = []) -> void:
	var u := s / 100.0
	var c0 := Color(str(cs[0])) if cs.size() > 0 else Color("#cccccc")
	var c1 := Color(str(cs[1])) if cs.size() > 1 else Color.WHITE
	var c2 := Color(str(cs[2])) if cs.size() > 2 else Color("#2b2633")
	var def: Dictionary = {}
	for r in Estado.cat.ropa:
		if r.forma == forma:
			def = r
			break
	var zona := str(def.get("zona", ""))
	match forma:
		"bufanda", "panuelo":
			_sb(ci, Rect2(c + Vector2(-40, -20) * u, Vector2(80, 26) * u), c0, 13 * u)
			_poly(ci, [c + Vector2(4, -4) * u, c + Vector2(30, -4) * u, c + Vector2(18, 40) * u], c0.darkened(0.1))
			ci.draw_circle(c + Vector2(-14, -7) * u, 5 * u, c1)
		"mono", "corbata":
			if forma == "mono":
				_poly(ci, [c, c + Vector2(-42, -24) * u, c + Vector2(-42, 24) * u], c0)
				_poly(ci, [c, c + Vector2(42, -24) * u, c + Vector2(42, 24) * u], c0)
				ci.draw_circle(c, 11 * u, c0.darkened(0.2))
			else:
				_poly(ci, [c + Vector2(-10, -36) * u, c + Vector2(10, -36) * u, c + Vector2(18, 26) * u, c + Vector2(0, 44) * u, c + Vector2(-18, 26) * u], c0)
		"collar_bellotas", "collar_perlas", "cascabel", "medalla":
			ci.draw_arc(c + Vector2(0, -24) * u, 38 * u, 0.2, PI - 0.2, 20, c1 if forma != "collar_perlas" else c0, 5 * u, true)
			if forma == "collar_bellotas":
				for i in 5:
					var a := 0.4 + i * (PI - 0.8) / 4.0
					icono(ci, "bellota", c + Vector2(0, -24) * u + Vector2(cos(a), sin(a)) * 38 * u, 22 * u)
			elif forma == "collar_perlas":
				for i in 9:
					var a := 0.3 + i * (PI - 0.6) / 8.0
					ci.draw_circle(c + Vector2(0, -24) * u + Vector2(cos(a), sin(a)) * 38 * u, 6 * u, c0)
			else:
				ci.draw_circle(c + Vector2(0, 22) * u, 18 * u, c1 if forma == "cascabel" else c0)
				if forma == "medalla":
					ci.draw_colored_polygon(estrella_pts(c + Vector2(0, 22) * u, 12 * u), Color("#fff3c4"))
		"corona", "tiara":
			_poly(ci, [c + Vector2(-42, 30) * u, c + Vector2(-42, -26) * u, c + Vector2(-21, 0) * u, c + Vector2(0, -36) * u,
				c + Vector2(21, 0) * u, c + Vector2(42, -26) * u, c + Vector2(42, 30) * u], c0)
			ci.draw_circle(c + Vector2(0, 14) * u, 8 * u, Color("#ff4d6d"))
		"flor", "corona_flores":
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * 24 * u, 18 * u, c0)
			ci.draw_circle(c, 14 * u, c1 if forma == "flor" else Color("#ffcf4a"))
		"audifonos":
			ci.draw_arc(c + Vector2(0, 8) * u, 38 * u, PI, TAU, 24, c0, 9 * u, true)
			_sb(ci, Rect2(c + Vector2(-50, 0) * u, Vector2(24, 40) * u), c0, 10 * u)
			_sb(ci, Rect2(c + Vector2(26, 0) * u, Vector2(24, 40) * u), c0, 10 * u)
		"sombrero_copa":
			_sb(ci, Rect2(c + Vector2(-26, -42) * u, Vector2(52, 66) * u), c0, 6 * u)
			_sb(ci, Rect2(c + Vector2(-46, 20) * u, Vector2(92, 14) * u), c0, 7 * u)
			ci.draw_rect(Rect2(c + Vector2(-26, 6) * u, Vector2(52, 12) * u), c1)
		"mago", "bruja", "gorro_navidad":
			_poly(ci, [c + Vector2(0, -46) * u, c + Vector2(30, 22) * u, c + Vector2(-30, 22) * u], c0)
			_sb(ci, Rect2(c + Vector2(-46, 18) * u, Vector2(92, 16) * u), c0 if forma != "gorro_navidad" else c1, 8 * u)
			if forma == "gorro_navidad":
				ci.draw_circle(c + Vector2(0, -44) * u, 10 * u, c1)
			else:
				ci.draw_colored_polygon(estrella_pts(c + Vector2(0, -4) * u, 10 * u), c1)
		"vaquero":
			_sb(ci, Rect2(c + Vector2(-50, 12) * u, Vector2(100, 16) * u), c0, 8 * u)
			_sb(ci, Rect2(c + Vector2(-26, -24) * u, Vector2(52, 44) * u), c0, 16 * u)
			ci.draw_rect(Rect2(c + Vector2(-26, 4) * u, Vector2(52, 8) * u), c1)
		"chef":
			_sb(ci, Rect2(c + Vector2(-26, 0) * u, Vector2(52, 30) * u), c0, 6 * u)
			for i in 3:
				ci.draw_circle(c + Vector2(-22 + i * 22, -14) * u, 22 * u, c0)
		"pirata":
			_poly(ci, [c + Vector2(-48, 16) * u, c + Vector2(0, -30) * u, c + Vector2(48, 16) * u], c0)
			ci.draw_circle(c + Vector2(0, 0) * u, 9 * u, c1)
		"casco_astronauta":
			ci.draw_circle(c, 42 * u, Color(0.8, 0.92, 1.0, 0.8))
			ci.draw_arc(c, 42 * u, 0, TAU, 32, c0, 6 * u, true)
		"cuernos":
			for sx in [-1.0, 1.0]:
				_poly(ci, [c + Vector2(sx * 10, 30) * u, c + Vector2(sx * 40, 30) * u, c + Vector2(sx * 36, -40) * u], c0)
		"aureola":
			ci.draw_arc(c, 36 * u, 0, TAU, 32, c0, 10 * u, true)
		"antenas":
			for sx in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(sx * 10, 36) * u, c + Vector2(sx * 30, -20) * u, c0, 6 * u)
				ci.draw_circle(c + Vector2(sx * 30, -24) * u, 12 * u, c1)
		"orejas_conejo":
			for sx in [-1.0, 1.0]:
				_sb(ci, Rect2(c + Vector2(sx * 22 - 13, -44) * u, Vector2(26, 80) * u), c0, 13 * u)
				_sb(ci, Rect2(c + Vector2(sx * 22 - 7, -36) * u, Vector2(14, 60) * u), c1, 7 * u)
		"cuerno_unicornio":
			_poly(ci, [c + Vector2(-16, 36) * u, c + Vector2(16, 36) * u, c + Vector2(0, -44) * u], Color("#fff3f8"))
			for i in 3:
				ci.draw_line(c + Vector2(-12 + i * 2, 20 - i * 20) * u, c + Vector2(12 - i * 2, 12 - i * 20) * u, c0, 4 * u)
		"boina":
			_sb(ci, Rect2(c + Vector2(-46, -12) * u, Vector2(92, 36) * u), c0, 18 * u)
			ci.draw_line(c + Vector2(10, -12) * u, c + Vector2(14, -26) * u, c0, 5 * u)
		"vikingo":
			ci.draw_circle(c + Vector2(0, 10) * u, 34 * u, c0)
			for sx in [-1.0, 1.0]:
				_poly(ci, [c + Vector2(sx * 30, 0) * u, c + Vector2(sx * 52, -40) * u, c + Vector2(sx * 40, 10) * u], c1)
		"lentes_sol", "lentes_redondos", "gafas_buceo", "lentes_corazon", "lentes_estrella":
			for sx in [-1.0, 1.0]:
				var q := c + Vector2(sx * 24, 0) * u
				match forma:
					"lentes_corazon":
						ci.draw_colored_polygon(corazon_pts(q, 44 * u), c0)
					"lentes_estrella":
						ci.draw_colored_polygon(estrella_pts(q, 22 * u), c0)
					"lentes_redondos":
						ci.draw_arc(q, 18 * u, 0, TAU, 24, c0, 5 * u, true)
					_:
						ci.draw_circle(q, 20 * u, c0 if forma == "lentes_sol" else c1)
			ci.draw_line(c + Vector2(-6, -4) * u, c + Vector2(6, -4) * u, c0, 5 * u)
		"monoculo":
			ci.draw_arc(c, 24 * u, 0, TAU, 24, c0, 6 * u, true)
			ci.draw_line(c + Vector2(20, 14) * u, c + Vector2(30, 44) * u, c0, 3 * u)
		"visor":
			_sb(ci, Rect2(c + Vector2(-48, -14) * u, Vector2(96, 28) * u), c1, 14 * u)
		"parche":
			ci.draw_line(c + Vector2(-46, -20) * u, c + Vector2(46, 10) * u, c0, 4 * u)
			ci.draw_circle(c + Vector2(12, 0) * u, 20 * u, c0)
		"alas_hada", "alas_angel", "alas_mariposa", "alas_murcielago":
			for sx in [-1.0, 1.0]:
				var q := c + Vector2(sx * 24, -6) * u
				var pts := PackedVector2Array()
				for i in 20:
					var a := TAU * i / 20.0
					pts.append(q + Vector2(cos(a) * 22 * sx + sx * 6, sin(a) * 34) * u)
				ci.draw_colored_polygon(pts, Color(c0, 0.75 if forma == "alas_hada" else 1.0))
		"mochila", "jetpack", "caparazon":
			_sb(ci, Rect2(c + Vector2(-32, -34) * u, Vector2(64, 72) * u), c0, 18 * u)
			_sb(ci, Rect2(c + Vector2(-22, 4) * u, Vector2(44, 26) * u), c1, 10 * u)
			if forma == "jetpack":
				_poly(ci, [c + Vector2(-14, 40) * u, c + Vector2(0, 58) * u, c + Vector2(14, 40) * u], Color("#ffb347"))
		_:
			if zona == "cuerpo" or forma == "capa":
				icono(ci, "ropa", c, s * 0.95, c0)
				ci.draw_circle(c + Vector2(0, 6) * u, 9 * u, c1)
			elif zona == "traje":
				# Pip con el traje puesto
				ci.draw_circle(c + Vector2(0, 26) * u, 30 * u, c0)
				ci.draw_circle(c + Vector2(0, -14) * u, 32 * u, c0)
				ci.draw_circle(c + Vector2(0, -10) * u, 20 * u, Color("#cf7a3e") if forma not in ["robot", "slime", "astronauta"] else c1.lerp(c0, 0.3))
				for sx in [-1.0, 1.0]:
					ci.draw_circle(c + Vector2(sx * 8, -14) * u, 4 * u, Color("#2a1a18"))
				ci.draw_circle(c + Vector2(0, 26) * u, 12 * u, c1)
			else:
				# gorros y gorras
				ci.draw_circle(c + Vector2(0, 8) * u, 38 * u, c0)
				ci.draw_rect(Rect2(c + Vector2(-44, 12) * u, Vector2(88, 40) * u), Color(0, 0, 0, 0))
				_sb(ci, Rect2(c + Vector2(-44, 8) * u, Vector2(88, 20) * u), c1, 10 * u)
				if forma == "helice":
					ci.draw_line(c + Vector2(-30, -40) * u, c + Vector2(30, -40) * u, c1, 6 * u)

## Miniatura de una decoración: la pared con su patrón, el piso, o el mueble en su color.
static func icono_deco(ci: CanvasItem, slot: String, r: Rect2, c1: Color, cs: Array) -> void:
	var c2 := Color(str(cs[0])) if cs.size() > 0 and str(cs[0]).begins_with("#") else Color.WHITE
	var pat := str(cs[1]) if cs.size() > 1 else ""
	var c := r.get_center()
	var u := minf(r.size.x, r.size.y) / 100.0
	match slot:
		"pared", "piso":
			_sb(ci, r, c1, 20)
			match pat:
				"rayas", "tablas":
					var x := r.position.x + 14
					while x < r.end.x - 10:
						ci.draw_rect(Rect2(Vector2(x, r.position.y + 6), Vector2(8 if pat == "rayas" else 2, r.size.y - 12)), c2)
						x += 22
				"lunares", "nubes", "ondas":
					for i in 9:
						ci.draw_circle(r.position + Vector2(18 + (i % 3) * r.size.x * 0.33, 18 + (i / 3) * r.size.y * 0.33), 6, c2)
				"estrellas":
					for i in 6:
						ci.draw_colored_polygon(estrella_pts(r.position + Vector2(20 + (i % 3) * r.size.x * 0.33, 24 + (i / 3) * r.size.y * 0.45), 9), c2)
				"corazones":
					for i in 6:
						ci.draw_colored_polygon(corazon_pts(r.position + Vector2(20 + (i % 3) * r.size.x * 0.33, 24 + (i / 3) * r.size.y * 0.45), 18), c2)
				"cuadros", "ladrillo", "ajedrez", "rombos":
					var tam := r.size.x / 5.0
					for ix in 5:
						for iy in int(r.size.y / tam):
							if (ix + iy) % 2 == 0:
								ci.draw_rect(Rect2(r.position + Vector2(ix * tam, iy * tam), Vector2(tam, tam)).intersection(r.grow(-4)), c2)
				"hojas":
					for i in 6:
						ci.draw_circle(r.position + Vector2(20 + (i % 3) * r.size.x * 0.33, 24 + (i / 3) * r.size.y * 0.45), 8, c2)
		"fondo":
			var cols := {"dia": ["#7cc4ff", "#e4f5ff"], "atardecer": ["#7b5cff", "#ffb38a"], "noche": ["#0d1340", "#3a3f8f"],
				"galaxia": ["#1a0b3d", "#6a2c91"], "aurora": ["#071a35", "#2ad59a"], "nublado": ["#9fb3c8", "#e3eaf2"],
				"amanecer": ["#8fb8ff", "#ffc9a8"], "dulce": ["#ffb8e1", "#b8f0ff"]}
			var cc: Array = cols.get(pat, cols.dia)
			var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
			ci.draw_polygon(pts, PackedColorArray([Color(cc[0]), Color(cc[0]), Color(cc[1]), Color(cc[1])]))
		_:
			_sb(ci, r, Color(c1, 0.25), 20)
			var ic: String = {"cama": "habitacion", "lampara": "foco", "alfombra": "estrella", "cerca": "menu", "arbol": "patio",
				"pasto": "patio", "juguete": "pelota", "banera": "bano", "cortina": "ducha", "nevera": "cocina", "mesa": "cocina",
				"planta": "patio"}.get(slot, "pincel")
			icono(ci, ic, c, 70 * u, c1.darkened(0.15) if c1.v > 0.9 else c1)

static func icono_comida(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var u := s / 100.0
	match id:
		"bellota":
			icono(ci, "bellota", c, s)
		"fresa":
			_poly(ci, [c + Vector2(-34, -14) * u, c + Vector2(34, -14) * u, c + Vector2(0, 42) * u], Color("#ff5a6e"))
			ci.draw_circle(c + Vector2(-17, -12) * u, 17 * u, Color("#ff5a6e"))
			ci.draw_circle(c + Vector2(17, -12) * u, 17 * u, Color("#ff5a6e"))
			for v in [Vector2(-12, 0), Vector2(10, 4), Vector2(0, 18), Vector2(-4, -10), Vector2(14, -14)]:
				ci.draw_circle(c + v * u, 2.5 * u, Color("#ffe08a"))
			_poly(ci, [c + Vector2(-20, -24) * u, c + Vector2(0, -38) * u, c + Vector2(20, -24) * u, c + Vector2(0, -18) * u], Color("#5cc96a"))
		"galleta":
			ci.draw_circle(c, 40 * u, Color("#e2a95f"))
			for v in [Vector2(-14, -12), Vector2(12, -18), Vector2(16, 10), Vector2(-10, 16), Vector2(2, 0)]:
				ci.draw_circle(c + v * u, 6 * u, Color("#6b3f22"))
		"nuez":
			ci.draw_circle(c, 36 * u, Color("#a8743f"))
			ci.draw_line(c + Vector2(0, -34) * u, c + Vector2(0, 34) * u, Color("#7a4b2a"), 5 * u)
			ci.draw_arc(c + Vector2(-14, 0) * u, 14 * u, -1.2, 1.2, 10, Color("#7a4b2a"), 4 * u)
			ci.draw_arc(c + Vector2(14, 0) * u, 14 * u, PI - 1.2, PI + 1.2, 10, Color("#7a4b2a"), 4 * u)
		"pastel":
			_sb(ci, Rect2(c + Vector2(-40, -6) * u, Vector2(80, 44) * u), Color("#ffc2d6"), 10 * u)
			_sb(ci, Rect2(c + Vector2(-40, -14) * u, Vector2(80, 18) * u), Color("#fff3f7"), 9 * u)
			ci.draw_circle(c + Vector2(0, -26) * u, 10 * u, Color("#ff4d6d"))
		"helado":
			_poly(ci, [c + Vector2(-24, 0) * u, c + Vector2(24, 0) * u, c + Vector2(0, 46) * u], Color("#e2a95f"))
			ci.draw_circle(c + Vector2(0, -14) * u, 26 * u, Color("#bff0e4"))
			ci.draw_circle(c + Vector2(0, -36) * u, 18 * u, Color("#ffc2d6"))
		_:
			ci.draw_circle(c, 30 * u, Color("#cccccc"))


# ================= botón con rebote =================
class Boton extends Control:
	signal presionado
	var icono := ""
	var texto := ""
	var color := UI.CREMA
	var color_icono := UI.CAFE
	var radio := 999.0
	var tam_texto := 22
	var insignia := ""            ## texto de la burbujita roja (vacío = sin burbuja)
	var activo := true
	var seleccionado := false
	var _apretado := false
	var _tw: Tween
	var sonido := "select"
	var sin_fondo := false

	func _init(ic := "", tx := "", col := UI.CREMA, sz := Vector2(96, 96)) -> void:
		icono = ic
		texto = tx
		color = col
		custom_minimum_size = sz
		size = sz
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(func(): pivot_offset = size * 0.5)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_apretado = true
				_anim(0.88, 0.08, Tween.TRANS_QUAD)
				accept_event()
			elif _apretado:
				_apretado = false
				_anim(1.0, 0.45, Tween.TRANS_ELASTIC)
				if Rect2(Vector2.ZERO, size).has_point(e.position):
					if sonido != "":
						Sfx.play(sonido, randf_range(0.97, 1.05), -4.0)
					presionado.emit()
				accept_event()

	func _anim(s: float, d: float, tr: Tween.TransitionType) -> void:
		if _tw:
			_tw.kill()
		_tw = create_tween()
		_tw.tween_property(self, "scale", Vector2.ONE * s, d).set_trans(tr).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var c := color if activo else color.lerp(Color(0.8, 0.8, 0.8), 0.6)
		if not sin_fondo:
			UI.caja(self, r, c, minf(radio, size.y * 0.5))
		if seleccionado:
			draw_style_box(_borde(), r.grow(3))
		var has_t := texto != ""
		var horiz := size.x > size.y * 1.8
		var isz := minf(size.x, size.y) * (0.5 if has_t and not horiz else 0.62)
		if icono != "":
			var ic := Vector2(size.x * 0.5, size.y * (0.4 if has_t and not horiz else 0.5))
			if has_t and horiz:
				ic = Vector2(size.y * 0.55, size.y * 0.5)
			UI.icono(self, icono, ic, isz, color_icono)
		if has_t:
			if horiz and icono != "":
				UI.texto(self, Vector2(size.y + (size.x - size.y) * 0.5 - 6, size.y * 0.5), texto, tam_texto, color_icono, 600, true, size.x - size.y - 10)
			elif icono != "":
				UI.texto(self, Vector2(size.x * 0.5, size.y * 0.82), texto, tam_texto, color_icono, 600, true, size.x - 8)
			else:
				UI.texto(self, size * 0.5, texto, tam_texto, color_icono, 600, true, size.x - 16)
		if insignia != "":
			var p := Vector2(size.x - 10, 10)
			draw_circle(p, 15, UI.ROJO)
			UI.texto(self, p, insignia, 18, Color.WHITE, 700)

	static var _sbb: StyleBoxFlat
	func _borde() -> StyleBoxFlat:
		if _sbb == null:
			_sbb = StyleBoxFlat.new()
			_sbb.draw_center = false
			_sbb.set_border_width_all(5)
			_sbb.border_color = UI.NARANJO
			_sbb.anti_aliasing = true
		_sbb.set_corner_radius_all(int(minf(radio, size.y * 0.5)) + 3)
		return _sbb


# ================= tarjeta (armario, tienda, decoración) =================
class Tarjeta extends Control:
	signal elegida
	var icono := ""
	var nombre := ""
	var precio := 0
	var precio_txt := ""          ## para los paquetes con dinero real
	var estado := ""              ## "", "tiene", "puesto", "bloqueado"
	var cantidad := -1
	var color := Color.WHITE
	var color_icono := UI.CAFE
	var colores: Array = []       ## colores de la prenda o decoración (para su miniatura)
	var etiqueta := ""            ## texto en lugar del precio ("Gratis", "Récord: 120")
	var cinta := ""               ## cinta de esquina ("¡Oferta!", "Más popular")
	var animada := false          ## la prenda tiene animación (chispita en la esquina)
	var _p := Vector2.ZERO
	var _apretado := false
	var _tw: Tween

	func _init(sz := Vector2(150, 190)) -> void:
		custom_minimum_size = sz
		size = sz
		mouse_filter = Control.MOUSE_FILTER_PASS
		resized.connect(func(): pivot_offset = size * 0.5)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_apretado = true
				_p = e.position
				_anim(0.92, 0.08, Tween.TRANS_QUAD)
			elif _apretado:
				_apretado = false
				_anim(1.0, 0.45, Tween.TRANS_ELASTIC)
				if e.position.distance_to(_p) < 24 and Rect2(Vector2.ZERO, size).has_point(e.position):
					Sfx.play("select", randf_range(0.97, 1.05), -4.0)
					elegida.emit()
		elif e is InputEventMouseMotion and _apretado and e.position.distance_to(_p) > 24:
			_apretado = false
			_anim(1.0, 0.3, Tween.TRANS_BACK)

	func _anim(s: float, d: float, tr: Tween.TransitionType) -> void:
		if _tw:
			_tw.kill()
		_tw = create_tween()
		_tw.tween_property(self, "scale", Vector2.ONE * s, d).set_trans(tr).set_ease(Tween.EASE_OUT)

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var fondo := Color("#ffffff") if estado != "puesto" else Color("#fff1d6")
		UI.caja(self, r, fondo, 26, true, false)
		if estado == "puesto":
			var sb := StyleBoxFlat.new()
			sb.draw_center = false
			sb.set_border_width_all(5)
			sb.border_color = UI.NARANJO
			sb.set_corner_radius_all(26)
			sb.anti_aliasing = true
			draw_style_box(sb, r)
		var doble := precio_txt != "" and etiqueta != ""
		var ir := Rect2(Vector2(12, 12), Vector2(size.x - 24, size.y * (0.46 if doble else 0.55)))
		UI._sb(self, ir, color, 20)
		var isz := minf(ir.size.x, ir.size.y) * 0.82
		if icono.begins_with("ropa_"):
			UI.icono_ropa(self, icono.substr(5), ir.get_center(), isz, colores)
		elif icono.begins_with("deco_"):
			UI.icono_deco(self, icono.substr(5), ir, color, colores)
		else:
			UI.icono(self, icono, ir.get_center(), isz, color_icono)
		if animada:
			draw_colored_polygon(UI.estrella_pts(ir.position + Vector2(ir.size.x - 18, 18), 12), UI.ORO)
		UI.texto(self, Vector2(size.x * 0.5, size.y * (0.6 if doble else 0.68)), nombre, 22 if doble else 19, UI.CAFE, 700 if doble else 600, true, size.x - 16)
		var py := size.y * (0.72 if doble else 0.86)
		if estado == "bloqueado":
			UI.icono(self, "candado", Vector2(size.x * 0.5, py), 30, UI.CAFE2)
		elif estado == "puesto":
			UI.icono(self, "check", Vector2(size.x * 0.5, py), 30, UI.MENTA)
		elif etiqueta != "":
			UI.texto(self, Vector2(size.x * 0.5, py), etiqueta, 19, UI.MENTA.darkened(0.15), 700, true, size.x - 16)
		elif estado == "tiene":
			UI.texto(self, Vector2(size.x * 0.5, py), "Tuyo", 20, UI.MENTA, 700)
		elif precio_txt != "":
			UI._sb(self, Rect2(Vector2(14, py - 20), Vector2(size.x - 28, 40)), UI.MENTA, 20)
			UI.texto(self, Vector2(size.x * 0.5, py), precio_txt, 22, Color.WHITE, 700, true, size.x - 36)
		elif precio == 0:
			UI.texto(self, Vector2(size.x * 0.5, py), "Gratis", 20, UI.MENTA, 700)
		else:
			UI.icono(self, "bellota", Vector2(size.x * 0.5 - 26, py), 30)
			UI.texto(self, Vector2(size.x * 0.5 + 14, py), str(precio), 22, UI.CAFE, 700)
		if precio_txt != "" and etiqueta != "":
			UI._sb(self, Rect2(Vector2(14, size.y - 50), Vector2(size.x - 28, 40)), UI.MENTA, 20)
			UI.texto(self, Vector2(size.x * 0.5, size.y - 30), precio_txt, 22, Color.WHITE, 700, true, size.x - 36)
		if cantidad >= 0:
			var p := Vector2(size.x - 22, 22)
			draw_circle(p, 18, UI.LILA)
			UI.texto(self, p, str(cantidad), 18, Color.WHITE, 700)
		if cinta != "":
			var w := UI.fuente(700).get_string_size(L.t(cinta), HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 28
			UI._sb(self, Rect2(Vector2(-4, 6), Vector2(w, 34)), UI.ROJO, 17)
			UI.texto(self, Vector2(-4 + w * 0.5, 23), cinta, 18, Color.WHITE, 700)


# ================= efectos 2D (encima del juego) =================
class Fx extends Control:
	var parts: Array = []          ## {tipo, p, v, vida, max, s, rot, col, txt, dest}
	signal llego(tipo: String)

	func _init() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func emitir(tipo: String, p: Vector2, n := 1, col := Color.WHITE, txt := "") -> void:
		for i in n:
			var q := {"tipo": tipo, "p": p + Vector2(randf_range(-20, 20), randf_range(-10, 10)), "vida": 0.0, "max": 1.3,
				"s": randf_range(26, 40), "rot": randf_range(-0.4, 0.4), "col": col, "txt": txt, "v": Vector2(randf_range(-60, 60), randf_range(-180, -110))}
			match tipo:
				"burbuja":
					q.v = Vector2(randf_range(-50, 50), randf_range(-140, -60))
					q.s = randf_range(16, 40)
					q.max = randf_range(1.2, 2.2)
				"chispa":
					var a := randf() * TAU
					q.v = Vector2(cos(a), sin(a)) * randf_range(120, 380)
					q.s = randf_range(14, 26)
					q.max = randf_range(0.5, 0.9)
				"texto":
					q.v = Vector2(0, -90)
					q.max = 1.2
					q.s = 34
				"zzz":
					q.v = Vector2(randf_range(20, 50), -60)
					q.max = 2.4
					q.s = randf_range(28, 44)
				"nota":
					q.v = Vector2(randf_range(-80, 80), randf_range(-150, -90))
					q.max = 1.8
			parts.append(q)

	## Bellotas que vuelan desde p hasta dest (el contador).
	func volar(p: Vector2, dest: Vector2, n: int) -> void:
		for i in n:
			var a := randf() * TAU
			parts.append({"tipo": "vuela", "p": p, "v": Vector2(cos(a), sin(a)) * randf_range(150, 420), "vida": -i * 0.04,
				"max": 1.1, "s": 40.0, "rot": 0.0, "col": Color.WHITE, "txt": "", "dest": dest})

	func _process(dt: float) -> void:
		if parts.is_empty():
			return
		var i := parts.size() - 1
		while i >= 0:
			var q: Dictionary = parts[i]
			q.vida += dt
			if q.vida >= q.max:
				if q.tipo == "vuela":
					llego.emit("vuela")
				parts.remove_at(i)
				i -= 1
				continue
			if q.vida >= 0.0:
				match q.tipo:
					"vuela":
						var k: float = q.vida / q.max
						if k < 0.35:
							q.v *= 0.9
							q.p += q.v * dt
						else:
							var kk := (k - 0.35) / 0.65
							q.p = q.p.lerp(q.dest, minf(1.0, kk * kk * 0.6 + dt * 8.0 * kk))
					"chispa":
						q.v *= 0.92
						q.p += q.v * dt
					"burbuja":
						q.p += q.v * dt
						q.p.x += sin(q.vida * 5.0 + q.s) * 0.6
					_:
						q.v.y += 40.0 * dt
						q.p += q.v * dt
						q.p.x += sin(q.vida * 4.0) * 0.8
			i -= 1
		queue_redraw()

	func _draw() -> void:
		for q in parts:
			if q.vida < 0.0:
				continue
			var k: float = q.vida / q.max
			var a := clampf(minf(k * 6.0, (1.0 - k) * 3.0), 0.0, 1.0)
			var s: float = q.s * (0.6 + 0.4 * minf(1.0, k * 5.0))
			var p: Vector2 = q.p
			match q.tipo:
				"corazon":
					draw_colored_polygon(UI.corazon_pts(p, s), Color(UI.ROSA, a))
					draw_circle(p + Vector2(-s * 0.18, -s * 0.12), s * 0.09, Color(1, 1, 1, a * 0.6))
				"estrella":
					draw_colored_polygon(UI.estrella_pts(p, s * 0.5, q.rot + k * 2.0), Color(UI.ORO, a))
				"chispa":
					if (1.0 - k) * s > 2.0:
						draw_colored_polygon(UI.estrella_pts(p, s * 0.5 * (1.0 - k), k * 4.0), Color(q.col, a))
				"burbuja":
					draw_arc(p, s * 0.5, 0, TAU, 24, Color(1, 1, 1, a * 0.9), 2.5, true)
					draw_circle(p, s * 0.5, Color(0.85, 0.95, 1.0, a * 0.25))
					draw_circle(p + Vector2(-s * 0.15, -s * 0.15), s * 0.1, Color(1, 1, 1, a * 0.9))
				"nota":
					UI.icono(self, "nota", p, s * 1.1, Color(q.col, a))
				"zzz":
					# tamaño de letra fijo y escalado con la transformación (cambiar el tamaño cada cuadro traba el juego)
					draw_set_transform(p, 0.0, Vector2.ONE * s / 40.0)
					UI.texto_borde(self, Vector2.ZERO, "z", 40, Color(1, 1, 1, a), Color(0.3, 0.3, 0.6, a * 0.6), 6)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"texto":
					draw_set_transform(p, 0.0, Vector2.ONE * s / 34.0)
					UI.texto_borde(self, Vector2.ZERO, q.txt, 34, Color(q.col, a), Color(0.35, 0.18, 0.08, a), 8)
					draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				"vuela":
					UI.icono(self, "bellota", p, s * (1.0 - 0.3 * k))


## Pip dibujado en 2D (minijuegos): cabeza redonda con orejas, ojos brillantes y cachetes.
static func pip2d(ci: CanvasItem, p: Vector2, r: float, feliz := true) -> void:
	var fur := Color("#cf7a3e")
	if Estado.capibara_activa():
		fur = Color("#a0703f")
	for s in [-1.0, 1.0]:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(s * r * 0.35, -r * 0.6), p + Vector2(s * r * 0.85, -r * 1.35), p + Vector2(s * r * 0.95, -r * 0.35)]), fur)
	ci.draw_circle(p + Vector2(0, r * 0.08), r * 1.02, Color(0, 0, 0, 0.12))
	ci.draw_circle(p, r, fur)
	ci.draw_circle(p + Vector2(0, r * 0.35), r * 0.55, Color("#fbe6cf"))
	for s in [-1.0, 1.0]:
		if feliz:
			ci.draw_circle(p + Vector2(s * r * 0.38, -r * 0.08), r * 0.17, Color("#2a1a18"))
			ci.draw_circle(p + Vector2(s * r * 0.38 - r * 0.05, -r * 0.14), r * 0.06, Color.WHITE)
		else:
			ci.draw_arc(p + Vector2(s * r * 0.38, -r * 0.05), r * 0.14, PI + 0.3, TAU - 0.3, 8, Color("#2a1a18"), r * 0.07)
		ci.draw_circle(p + Vector2(s * r * 0.62, r * 0.25), r * 0.13, Color(1, 0.6, 0.65, 0.7))
	ci.draw_circle(p + Vector2(0, r * 0.18), r * 0.1, Color("#5a2f2a"))
	ci.draw_arc(p + Vector2(0, r * 0.3), r * 0.15, 0.4, PI - 0.4, 8, Color("#5a2f2a"), r * 0.05)
