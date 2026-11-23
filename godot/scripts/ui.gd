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
const SOMBRA := Color(0.25, 0.12, 0.05, 0.22)

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
static func caja(ci: CanvasItem, r: Rect2, col: Color, radio: float, sombra := true, brillo := true) -> void:
	if sombra:
		_sb(ci, Rect2(r.position + Vector2(0, 5), r.size), SOMBRA, radio)
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
	var f := fuente(peso)
	if centro:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		if ancho > 0 and w > ancho:
			tam = int(tam * ancho / w)
			w = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		pos.x -= w * 0.5
	ci.draw_string(f, pos + Vector2(0, tam * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, col)

static func texto_borde(ci: CanvasItem, pos: Vector2, s: String, tam: int, col: Color, borde: Color, grosor := 8, peso := 700) -> void:
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
		_:
			if id.begins_with("ropa_"):
				icono_ropa(ci, id.substr(5), c, s)
			elif id.begins_with("deco_"):
				_sb(ci, Rect2(c - Vector2(36, 36) * u, Vector2(72, 72) * u), col, 16 * u)
			elif id.begins_with("comida_"):
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
static func icono_ropa(ci: CanvasItem, id: String, c: Vector2, s: float) -> void:
	var u := s / 100.0
	match id:
		"bufanda_nova":
			_sb(ci, Rect2(c + Vector2(-40, -20) * u, Vector2(80, 26) * u), Color("#6cc9b2"), 13 * u)
			_sb(ci, Rect2(c + Vector2(10, -4) * u, Vector2(20, 46) * u), Color("#4fae98"), 8 * u)
			ci.draw_colored_polygon(estrella_pts(c + Vector2(-14, -7) * u, 10 * u), Color("#ffd36e"))
		"mono_rojo":
			_poly(ci, [c, c + Vector2(-42, -24) * u, c + Vector2(-42, 24) * u], Color("#e23b4e"))
			_poly(ci, [c, c + Vector2(42, -24) * u, c + Vector2(42, 24) * u], Color("#e23b4e"))
			ci.draw_circle(c, 11 * u, Color("#b8283a"))
		"collar_bellotas":
			ci.draw_arc(c + Vector2(0, -20) * u, 38 * u, 0.2, PI - 0.2, 20, Color("#7a4b2a"), 4 * u, true)
			for i in 5:
				var a := 0.4 + i * (PI - 0.8) / 4.0
				icono(ci, "bellota", c + Vector2(0, -20) * u + Vector2(cos(a), sin(a)) * 38 * u, 22 * u)
		"panuelo_azul":
			_poly(ci, [c + Vector2(-42, -26) * u, c + Vector2(42, -26) * u, c + Vector2(0, 36) * u], Color("#2f7de1"))
			for i in 5:
				ci.draw_circle(c + Vector2(-20 + i * 10, -14 + (i % 2) * 14) * u, 3 * u, Color.WHITE)
		"gorro_lana":
			ci.draw_circle(c + Vector2(0, 8) * u, 40 * u, Color("#e85d6f"))
			ci.draw_rect(Rect2(c + Vector2(-44, 10) * u, Vector2(88, 40) * u), Color(0, 0, 0, 0))
			_sb(ci, Rect2(c + Vector2(-46, 8) * u, Vector2(92, 22) * u), Color("#fff4ec"), 10 * u)
			ci.draw_circle(c + Vector2(0, -36) * u, 13 * u, Color("#fff4ec"))
		"gorra_nova":
			ci.draw_circle(c + Vector2(0, 6) * u, 36 * u, Color("#3d5afe"))
			_sb(ci, Rect2(c + Vector2(-4, 6) * u, Vector2(52, 14) * u), Color("#2f45c9"), 7 * u)
			ci.draw_colored_polygon(estrella_pts(c + Vector2(-6, -8) * u, 12 * u), Color("#ffd36e"))
		"sombrero_copa":
			_sb(ci, Rect2(c + Vector2(-26, -42) * u, Vector2(52, 66) * u), Color("#2b2633"), 6 * u)
			_sb(ci, Rect2(c + Vector2(-46, 20) * u, Vector2(92, 14) * u), Color("#2b2633"), 7 * u)
			ci.draw_rect(Rect2(c + Vector2(-26, 6) * u, Vector2(52, 12) * u), Color("#c0394b"))
		"corona":
			_poly(ci, [c + Vector2(-42, 30) * u, c + Vector2(-42, -26) * u, c + Vector2(-21, 0) * u, c + Vector2(0, -36) * u,
				c + Vector2(21, 0) * u, c + Vector2(42, -26) * u, c + Vector2(42, 30) * u], Color("#ffcf4a"))
			ci.draw_circle(c + Vector2(0, 14) * u, 8 * u, Color("#ff4d6d"))
			ci.draw_circle(c + Vector2(-24, 16) * u, 6 * u, Color("#4dd2ff"))
			ci.draw_circle(c + Vector2(24, 16) * u, 6 * u, Color("#7dff8a"))
		"flor":
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * 24 * u, 18 * u, Color("#ffb3c7"))
			ci.draw_circle(c, 14 * u, Color("#ffd36e"))
		"audifonos":
			ci.draw_arc(c + Vector2(0, 8) * u, 38 * u, PI, TAU, 24, Color("#7c4dff"), 9 * u, true)
			_sb(ci, Rect2(c + Vector2(-50, 0) * u, Vector2(24, 40) * u), Color("#7c4dff"), 10 * u)
			_sb(ci, Rect2(c + Vector2(26, 0) * u, Vector2(24, 40) * u), Color("#7c4dff"), 10 * u)
		"lentes_sol", "lentes_redondos":
			var lc := Color("#20202a") if id == "lentes_sol" else Color("#d4a24c")
			for sx in [-1.0, 1.0]:
				if id == "lentes_sol":
					ci.draw_circle(c + Vector2(sx * 24, 0) * u, 20 * u, lc)
				else:
					ci.draw_arc(c + Vector2(sx * 24, 0) * u, 18 * u, 0, TAU, 24, lc, 5 * u, true)
			ci.draw_line(c + Vector2(-6, -4) * u, c + Vector2(6, -4) * u, lc, 5 * u)
		"lentes_corazon":
			for sx in [-1.0, 1.0]:
				ci.draw_colored_polygon(corazon_pts(c + Vector2(sx * 24, 0) * u, 44 * u), Color("#ff4f86"))
			ci.draw_line(c + Vector2(-6, -6) * u, c + Vector2(6, -6) * u, Color("#ff8fb3"), 5 * u)
		"poleron_menta", "camiseta_estrella", "overol", "capa_real":
			var cc := {"poleron_menta": Color("#7fd8be"), "camiseta_estrella": Color("#fff3c4"), "overol": Color("#4a6fa5"), "capa_real": Color("#b3123d")}
			icono(ci, "ropa", c, s * 0.95, cc[id])
			if id == "camiseta_estrella":
				ci.draw_colored_polygon(estrella_pts(c + Vector2(0, 6) * u, 16 * u), Color("#ffb703"))
			elif id == "poleron_menta":
				_sb(ci, Rect2(c + Vector2(-18, 12) * u, Vector2(36, 16) * u), Color("#5fbfa4"), 6 * u)
			elif id == "overol":
				_sb(ci, Rect2(c + Vector2(-20, -10) * u, Vector2(40, 50) * u), Color("#3a5a8a"), 6 * u)
			elif id == "capa_real":
				ci.draw_circle(c + Vector2(0, -30) * u, 14 * u, Color("#fff8f0"))
		_:
			ci.draw_circle(c, 30 * u, Color("#cccccc"))

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
		var ir := Rect2(Vector2(12, 12), Vector2(size.x - 24, size.y * 0.55))
		UI._sb(self, ir, color, 20)
		UI.icono(self, icono, ir.get_center(), minf(ir.size.x, ir.size.y) * 0.82, color_icono)
		UI.texto(self, Vector2(size.x * 0.5, size.y * 0.68), nombre, 19, UI.CAFE, 600, true, size.x - 16)
		var py := size.y * 0.86
		if estado == "bloqueado":
			UI.icono(self, "candado", Vector2(size.x * 0.5, py), 30, UI.CAFE2)
		elif estado == "puesto":
			UI.icono(self, "check", Vector2(size.x * 0.5, py), 30, UI.MENTA)
		elif estado == "tiene":
			UI.texto(self, Vector2(size.x * 0.5, py), "Tuyo", 20, UI.MENTA, 700)
		elif precio_txt != "":
			UI._sb(self, Rect2(Vector2(14, py - 18), Vector2(size.x - 28, 36)), UI.MENTA, 18)
			UI.texto(self, Vector2(size.x * 0.5, py), precio_txt, 19, Color.WHITE, 700, true, size.x - 36)
		elif precio == 0:
			UI.texto(self, Vector2(size.x * 0.5, py), "Gratis", 20, UI.MENTA, 700)
		else:
			UI.icono(self, "bellota", Vector2(size.x * 0.5 - 26, py), 30)
			UI.texto(self, Vector2(size.x * 0.5 + 14, py), str(precio), 22, UI.CAFE, 700)
		if cantidad >= 0:
			var p := Vector2(size.x - 22, 22)
			draw_circle(p, 18, UI.LILA)
			UI.texto(self, p, str(cantidad), 18, Color.WHITE, 700)


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
					draw_colored_polygon(UI.estrella_pts(p, s * 0.5 * (1.0 - k), k * 4.0), Color(q.col, a))
				"burbuja":
					draw_arc(p, s * 0.5, 0, TAU, 24, Color(1, 1, 1, a * 0.9), 2.5, true)
					draw_circle(p, s * 0.5, Color(0.85, 0.95, 1.0, a * 0.25))
					draw_circle(p + Vector2(-s * 0.15, -s * 0.15), s * 0.1, Color(1, 1, 1, a * 0.9))
				"nota":
					UI.icono(self, "nota", p, s * 1.1, Color(q.col, a))
				"zzz":
					UI.texto_borde(self, p, "z", int(s), Color(1, 1, 1, a), Color(0.3, 0.3, 0.6, a * 0.6), 6)
				"texto":
					UI.texto_borde(self, p, q.txt, int(s), Color(q.col, a), Color(0.35, 0.18, 0.08, a), 8)
				"vuela":
					UI.icono(self, "bellota", p, s * (1.0 - 0.3 * k))
