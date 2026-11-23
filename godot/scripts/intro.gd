## Pocket Pip — animación de inicio del estudio "nioro" (la misma de Color Flow, portada desde Intro.kt):
## cielo estrellado, aparece la esfera de cristal azul con la luna, un arco de luz recorre el logo de izquierda a
## derecha dejando chispas y descubriendo "nioro", destello con sonido, "sparks of life" y fundido a negro.
## NO se puede saltar (lo pidió el dueño): se come todos los toques y dura LEN segundos.
## Se dibuja en unidades de diseño: 1080 de ancho y `vh` de alto.
class_name IntroNioro
extends Control

signal terminada

const LEN := 3.7
const SWEEP_A := 0.9
const SWEEP_B := 2.0

var t := 0.0
var _rnd := RandomNumberGenerator.new()
var _stars: Array = []
var _sparks: Array = []          ## [x, y, vx, vy, vida, max, r]
var _chimed := false
var _done := false
var _bold: SystemFont
var _thin: SystemFont
var _glow_tex: GradientTexture2D
var _bg_tex: GradientTexture2D
var _moon: PackedVector2Array
var _moon_cols: PackedColorArray
var _txt: Control                ## "nioro" con recorte (se descubre con el arco)
var _fondo: ColorRect
var _top: Control                ## estela, chispas, destello y fundido (encima del texto)

# medidas
var gVh := -1.0
var gCy := 0.0
var gR := 128.0
var gTs := 216
var gOx := 0.0
var gTx := 0.0
var gEcx := 540.0
var gEcy := 0.0
var gRx := 0.0
var gRy := 265.0
var headX := 0.0
var headY := 0.0
var endX := 0.0
var endY := 0.0

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_rnd.seed = 11
	for i in 150:
		_stars.append([_rnd.randf(), _rnd.randf(), 0.8 + _rnd.randf() * 2.4, _rnd.randf() * 6.28, 0.5 + _rnd.randf() * 1.6])
	_bold = SystemFont.new()
	_bold.font_names = PackedStringArray(["sans-serif", "Roboto", "DejaVu Sans"])
	_bold.font_weight = 700
	_thin = SystemFont.new()
	_thin.font_names = PackedStringArray(["sans-serif-light", "Roboto Light", "sans-serif", "DejaVu Sans"])
	_thin.font_weight = 300
	# brillo radial (blanco → transparente); se tiñe con modulate
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.45))
	_glow_tex = _radial(g)
	var gb := Gradient.new()
	gb.set_color(0, Color("#1C2A7C"))
	gb.add_point(0.45, Color("#0C1546"))
	gb.set_color(gb.get_point_count() - 1, Color("#050817"))
	_bg_tex = _radial(gb)
	# luna creciente de radio ~100 centrada en 0,0
	var a := _circle(Vector2(-5, 6), 60.0, 72)
	var b := _circle(Vector2(19, -18), 54.0, 72)
	var res := Geometry2D.clip_polygons(a, b)
	_moon = res[0] if res.size() > 0 else a
	_moon_cols = PackedColorArray()
	var c0 := Color("#F4F6FF")
	var c1 := Color("#AEBBFF")
	for p in _moon:
		var u := clampf(((p.x + 60.0) + (p.y + 60.0)) / 240.0, 0.0, 1.0)
		_moon_cols.append(c0.lerp(c1, u))
	# fondo con su propio sombreador: degradado radial sin bandas (con un poco de ruido)
	var fondo := ColorRect.new()
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fondo.show_behind_parent = true
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2 centro = vec2(0.5, 0.46);
uniform float radio = 0.72;
uniform float aspecto = 0.5625;
void fragment() {
	vec2 p = UV - centro;
	p.x *= aspecto;
	float d = length(p) / radio;
	vec3 c0 = vec3(0.110, 0.165, 0.486);
	vec3 c1 = vec3(0.047, 0.082, 0.275);
	vec3 c2 = vec3(0.020, 0.031, 0.090);
	vec3 c = d < 0.45 ? mix(c0, c1, d / 0.45) : mix(c1, c2, clamp((d - 0.45) / 0.55, 0.0, 1.0));
	float n = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(c + (n - 0.5) / 255.0 * 1.5, 1.0);
}"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	fondo.material = sm
	add_child(fondo)
	_fondo = fondo
	_txt = Control.new()
	_txt.clip_contents = true
	_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_txt)
	_txt.draw.connect(_draw_text)
	_top = Control.new()
	_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_top.draw.connect(_draw_top)

static func _radial(g: Gradient) -> GradientTexture2D:
	var t2 := GradientTexture2D.new()
	t2.gradient = g
	t2.fill = GradientTexture2D.FILL_RADIAL
	t2.fill_from = Vector2(0.5, 0.5)
	t2.fill_to = Vector2(1.0, 0.5)
	t2.width = 256
	t2.height = 256
	return t2

static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var an := TAU * i / n
		p.append(c + Vector2(cos(an), sin(an)) * r)
	return p

func _gui_input(e: InputEvent) -> void:
	accept_event()   # no se puede saltar

func _k() -> float:
	return size.x / 1080.0

func _vh() -> float:
	return size.y / maxf(0.001, _k())

func prepare(vh: float) -> void:
	if vh == gVh:
		return
	gVh = vh
	gCy = vh * 0.46
	var tw := _bold.get_string_size("nioro", HORIZONTAL_ALIGNMENT_LEFT, -1, gTs).x
	var gap := 50.0
	var gw := 2.0 * gR + gap + tw
	var sx := 540.0 - gw / 2.0
	gOx = sx + gR
	gTx = sx + 2.0 * gR + gap
	gEcx = 540.0
	gEcy = gCy + 80.0
	gRx = gw * 0.62
	gRy = 265.0
	endX = arcX(1.0)
	endY = arcY(1.0)

func arcX(u: float) -> float: return gEcx + gRx * cos(deg_to_rad(200.0 + 140.0 * u))
func arcY(u: float) -> float: return gEcy + gRy * sin(deg_to_rad(200.0 + 140.0 * u))
func sweepU() -> float: return easeInOut((t - SWEEP_A) / (SWEEP_B - SWEEP_A))

static func easeOut(x: float) -> float:
	var u := 1.0 - clampf(x, 0.0, 1.0)
	return 1.0 - u * u * u
static func easeInOut(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return 4.0 * u * u * u if u < 0.5 else 1.0 - pow(-2.0 * u + 2.0, 3.0) / 2.0
static func backOut(x: float) -> float:
	var u := clampf(x, 0.0, 1.0) - 1.0
	var k := 1.7
	return 1.0 + (k + 1.0) * u * u * u + k * u * u

func _process(dt: float) -> void:
	if _done:
		return
	dt = minf(dt, 0.05)   # si el teléfono se traba al arrancar, la animación no da saltos
	t += dt
	var i := _sparks.size() - 1
	while i >= 0:
		var s: Array = _sparks[i]
		s[4] -= dt
		if s[4] <= 0.0:
			_sparks.remove_at(i)
		else:
			s[3] += 40.0 * dt
			s[2] *= 0.985
			s[0] += s[2] * dt
			s[1] += s[3] * dt
		i -= 1
	if gVh > 0.0:
		var u := sweepU()
		headX = arcX(u)
		headY = arcY(u)
	if t >= SWEEP_A and t <= SWEEP_B and gVh > 0.0:
		for k in 3:
			var l := 0.45 + _rnd.randf() * 0.5
			_sparks.append([headX, headY, (_rnd.randf() - 0.5) * 220.0, (_rnd.randf() - 0.3) * 160.0, l, l, 2.5 + _rnd.randf() * 4.0])
	if not _chimed and t >= SWEEP_B and gVh > 0.0:
		_chimed = true
		for k in 46:
			var an := _rnd.randf() * TAU
			var sp := 160.0 + _rnd.randf() * 420.0
			var l := 0.5 + _rnd.randf() * 0.6
			_sparks.append([endX, endY, cos(an) * sp, sin(an) * sp, l, l, 2.5 + _rnd.randf() * 5.0])
		Sfx.play("sfx_nioro")
	queue_redraw()
	_txt.queue_redraw()
	_top.queue_redraw()
	if t >= LEN:
		_done = true
		terminada.emit()

func _glow(ci: CanvasItem, x: float, y: float, r: float, col: Color, a: int) -> void:
	var c := col
	c.a = clampf(a / 255.0, 0.0, 1.0)
	ci.draw_texture_rect(_glow_tex, Rect2(x - r, y - r, r * 2.0, r * 2.0), false, c)

## círculo con sombreado de esfera: degradado radial que nace en el punto de luz (hx, hy) y llega hasta rk·r
func _shaded_circle(x: float, y: float, r: float, hx: float, hy: float, rk: float, cols: Array, stops: Array) -> void:
	var hp := Vector2(x + hx * r, y + hy * r)
	var rings := 7
	var segs := 64
	var rr := rk * r
	var pts := PackedVector2Array()
	var cs := PackedColorArray()
	for ri in rings:
		var f0 := float(ri) / rings
		var f1 := float(ri + 1) / rings
		for si in segs:
			var a0 := TAU * si / segs
			var a1 := TAU * (si + 1) / segs
			var e0 := Vector2(x, y) + Vector2(cos(a0), sin(a0)) * r
			var e1 := Vector2(x, y) + Vector2(cos(a1), sin(a1)) * r
			var q := [hp.lerp(e0, f0), hp.lerp(e1, f0), hp.lerp(e1, f1), hp.lerp(e0, f1)]
			var quad := PackedVector2Array(q)
			var qc := PackedColorArray()
			for v in q:
				qc.append(_grad(cols, stops, (v as Vector2).distance_to(hp) / rr))
			draw_polygon(quad, qc)

static func _grad(cols: Array, stops: Array, u: float) -> Color:
	u = clampf(u, 0.0, 1.0)
	for i in range(1, stops.size()):
		if u <= stops[i]:
			var k: float = (u - stops[i - 1]) / maxf(0.0001, stops[i] - stops[i - 1])
			return (cols[i - 1] as Color).lerp(cols[i], k)
	return cols[cols.size() - 1]

func _draw() -> void:
	var k := _k()
	var vh := _vh()
	prepare(vh)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var cx := 540.0
	var cy := gCy
	# fondo: azul noche con un halo al centro
	# (el degradado del fondo lo pinta _fondo, detrás)
	(_fondo.material as ShaderMaterial).set_shader_parameter("aspecto", size.x / maxf(1.0, size.y))
	(_fondo.material as ShaderMaterial).set_shader_parameter("radio", 0.72)
	# estrellas que titilan y suben despacio
	for s in _stars:
		var y := fposmod(s[1] * vh - t * 10.0 * s[4], vh)
		var a := clampf((130.0 + 110.0 * sin(t * s[4] * 2.2 + s[3])) / 255.0, 0.0, 1.0)
		draw_circle(Vector2(s[0] * 1080.0, y), s[2], Color(0.84, 0.87, 1.0, a))
	# esfera de cristal con la luna
	var r := gR
	var ox := gOx
	var logoA := easeOut((t - 0.25) / 0.45)
	var pulse := maxf(0.0, 1.0 - absf(t - 2.15) / 0.45)
	var s := 0.72 + 0.28 * backOut((t - 0.25) / 0.65)
	if logoA > 0.0:
		var la := logoA
		_glow(self, ox, cy, r * 2.5 * s, Color("#3F5FFF"), int((70 + 110 * pulse) * la))
		var cols := [Color("#7A95FF"), Color("#2B3FC4"), Color("#0A1352")]
		for i in cols.size():
			cols[i] = Color(cols[i], la)
		_shaded_circle(ox, cy, r * s, -0.38, -0.48, 1.6, cols, [0.0, 0.45, 1.0])
		# brillo de vidrio arriba
		draw_arc(Vector2(ox, cy), r * s * 0.8, deg_to_rad(212.0), deg_to_rad(282.0), 24, Color(1, 1, 1, 80.0 / 255.0 * la), r * s * 0.11, true)
		# luna y su puntito
		draw_set_transform(Vector2(ox, cy) * k, deg_to_rad(-8.0 + 8.0 * easeOut((t - 0.3) / 0.8)), Vector2.ONE * k * r * s / 100.0)
		var mc := PackedColorArray()
		for c in _moon_cols:
			mc.append(Color(c, la))
		draw_polygon(_moon, mc)
		draw_circle(Vector2(43, 31), 7.0, Color(Color("#E9EDFF"), la))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
		# borde de luz
		draw_arc(Vector2(ox, cy), r * s, 0.0, TAU, 96, Color(Color("#B9C3FF"), 170.0 / 255.0 * la), 3.5, true)
	# el texto vive en _txt (recortado): se ajusta su ancho a lo que ya descubrió el arco
	var revealX := 2000.0 if t >= SWEEP_B else (-1.0 if t < SWEEP_A else headX + 30.0)
	var tx := gTx
	_txt.position = Vector2(tx - 60.0, 0.0) * k
	_txt.size = Vector2(maxf(0.0, revealX - (tx - 60.0)), vh) * k

func _draw_text() -> void:
	var k := _k()
	var vh := _vh()
	var tx := gTx
	var ts := gTs
	var cy := gCy
	var ty := cy + ts * 0.275
	var pulse := maxf(0.0, 1.0 - absf(t - 2.15) / 0.45)
	var black := _black()
	var fa := 1.0 - black
	_txt.draw_set_transform(Vector2(-(tx - 60.0) * k, 0.0), 0.0, Vector2(k, k))
	if t >= SWEEP_A:
		# resplandor azul (en Android era una sombra difusa)
		var gc := Color("#6F8CFF")
		for i in 4:
			var w := (18.0 + 26.0 * pulse) * (1.0 - i * 0.22) * 1.4
			var a := (150.0 + 100.0 * pulse) / 255.0 * 0.12 * (1.0 + i * 0.5) * fa
			_txt.draw_string_outline(_bold, Vector2(tx, ty), "nioro", HORIZONTAL_ALIGNMENT_LEFT, -1, ts, int(w), Color(gc, a))
		_txt.draw_string(_bold, Vector2(tx, ty), "nioro", HORIZONTAL_ALIGNMENT_LEFT, -1, ts, Color(Color("#EEF1FF"), fa))
	var sa := easeOut((t - 2.1) / 0.5)
	if sa > 0.0:
		_txt.draw_string(_thin, Vector2(tx + 6.0, cy + ts * 0.79 + 14.0 * (1.0 - sa)), "sparks of life", HORIZONTAL_ALIGNMENT_LEFT, -1, 64,
			Color(Color("#A3B4FF"), sa * fa))

func _black() -> float:
	return maxf(1.0 - easeOut(t / 0.5), easeOut((t - (LEN - 0.5)) / 0.5))

func _draw_top() -> void:
	var k := _k()
	var vh := _vh()
	_top.draw_set_transform(Vector2.ZERO, 0.0, Vector2(k, k))
	var u := sweepU()
	# la estela del arco
	var fade := 1.0 - easeOut((t - SWEEP_B) / 0.7)
	if t >= SWEEP_A and fade > 0.0:
		var u1 := u
		var u0 := maxf(0.0, u - 0.65) if t < SWEEP_B else minf(1.0, u1 - 0.65 + 0.65 * easeOut((t - SWEEP_B) / 0.7))
		var n := 56
		var p := Vector2(arcX(u0), arcY(u0))
		for i in range(1, n + 1):
			var f := float(i) / n
			var uu := u0 + (u1 - u0) * f
			var q := Vector2(arcX(uu), arcY(uu))
			var a := pow(f, 1.6) * fade
			_line(p, q, 10.0 + 46.0 * f, Color(Color("#5C7CFF"), 55.0 / 255.0 * a))
			_line(p, q, 4.0 + 18.0 * f, Color(Color("#9DB3FF"), 110.0 / 255.0 * a))
			_line(p, q, 2.0 + 8.0 * f, Color(Color("#F7F9FF"), 245.0 / 255.0 * a))
			p = q
		if t < SWEEP_B:
			_glow(_top, headX, headY, 200.0, Color("#6F8DFF"), 130)
			_glow(_top, headX, headY, 80.0, Color.WHITE, 240)
	# destello al final del arco
	if t >= SWEEP_B and t < SWEEP_B + 0.8:
		var kk := (t - SWEEP_B) / 0.8
		_glow(_top, endX, endY, 90.0 + 260.0 * kk, Color("#8FA6FF"), int(220 * (1.0 - kk)))
		_glow(_top, endX, endY, 40.0 + 60.0 * kk, Color.WHITE, int(255 * (1.0 - kk)))
	# chispas
	for sp in _sparks:
		var a: float = sp[4] / sp[5]
		_glow(_top, sp[0], sp[1], sp[6] * 4.0, Color("#7F9BFF"), int(120 * a))
		_top.draw_circle(Vector2(sp[0], sp[1]), sp[6] * (0.4 + 0.6 * a), Color(1, 1, 1, 240.0 / 255.0 * a))
	# entrada desde negro y salida a negro
	var black := _black()
	if black > 0.003:
		_top.draw_rect(Rect2(-10, -10, 1100, vh + 20), Color(0, 0, 0, black))

func _line(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	_top.draw_line(a, b, c, w, true)
	_top.draw_circle(b, w * 0.5, c)
