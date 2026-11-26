## Pocket Pip — Pip, la ardilla de Star Nova (el mismo modelo de Star Nova: "esqueleto" de pivotes y animación
## procedural), con cara expresiva (boca, dientes, rubor), zonas que se pueden tocar y todas las reacciones de
## mascota: reír, boop en la nariz, caricias, comer, bostezar, dormir, sacudirse el agua, bailar, enojarse...
## El modelo mira hacia +z con los pies en y=0 y mide ~0.55 (en la casa se escala).
class_name PipModel
extends Node3D

signal accion_terminada(nombre: String)

static var _ball: SphereMesh
static var _low: SphereMesh
static var _mid: SphereMesh     ## esfera intermedia para piezas medianas (ojos, nariz): menos triángulos
static var _cone: CylinderMesh
static var _torus: TorusMesh
static var _star: ArrayMesh

var M := {}
var body: Node3D
var torso: Node3D
var neck: Node3D
var head: Node3D
var nose: MeshInstance3D
var mouth: Node3D
var tongue: MeshInstance3D
var teeth: Array[MeshInstance3D] = []
var blush: Array[MeshInstance3D] = []
var eyes: Array[Node3D] = []
var ears: Array[Node3D] = []
var scarf: Node3D
var scarf_tails: Array[Node3D] = []
var cola: MeshInstance3D
var cola_mesh: ArrayMesh
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var tail: Array[Node3D] = []
var zonas: Array[Area3D] = []
var anim_ropa: Array = []          ## piezas de ropa animadas (Atuendos._an)
var forma := "pip"                 ## "pip" o "capibara"
var _partes_pip: Array = []
var _capi: Array = []              ## piezas de la capibara
var _pip_cara := {}
var _capi_cara := {}
var capi_mandarina: Array = []
var capi_orejas: Array = []

# estado de la animación
var t := 0.0
var phase := 0.0
var blink_t := 2.0
var ear_t := 3.0
var look_t := 4.0
var look_yaw := 0.0
var look_pitch := 0.0
var tail_swing := 0.0
var tail_vel := 0.0
var land_t := 0.0
var scarf_wave := 0.0
var fidget_t := 6.0

## acción en curso: "" (nada), "risa", "boop", "estornudo", "cola", "oreja", "pie", "comer", "bostezo",
## "rascar", "saludo", "sacudir", "enojo", "celebrar", "no", "baile_<id>"
var accion := ""
var ta := 0.0             ## tiempo dentro de la acción
var dur := 0.0
var _cola_acciones: Array = []
var durmiendo := false
var _dormir_k := 0.0
var caricia := 0.0        ## 0..1: cuánto lo están acariciando (sube al frotar, baja sola)
var _car_k := 0.0
var mirar_a = null        ## Vector3 global al que mira (el dedo), o null
var _mira_k := 0.0
var feliz := 0.5          ## 0..1 ánimo (cambia la cara en reposo)
var mojado := 0.0
var _pokes: Array = []
var corriendo := 0.0      ## velocidad al ir de una habitación a otra
var yaw_obj := 0.0
var _yaw := 0.0
var base_scale := 1.0
var pocion := ""
var pocion_t := 0.0
var _pocion_k := 0.0

const TAIL_BASE := [-1.05, -0.55, -0.15, 0.2, 0.42, 0.55, 0.6, 0.55]
const DURACION := {"risa": 1.7, "boop": 1.1, "estornudo": 1.2, "cola": 1.0, "oreja": 0.7, "pie": 1.0, "comer": 1.3,
	"bostezo": 2.0, "rascar": 1.6, "saludo": 1.6, "sacudir": 1.3, "enojo": 2.0, "celebrar": 1.4, "no": 1.0,
	"mirar_cola": 2.2, "estirarse": 1.8}

static func _geos() -> void:
	if _ball != null:
		return
	_ball = SphereMesh.new()
	_ball.radius = 1.0
	_ball.height = 2.0
	_ball.radial_segments = 28
	_ball.rings = 14
	_low = SphereMesh.new()
	_low.radius = 1.0
	_low.height = 2.0
	_low.radial_segments = 14
	_low.rings = 7
	_mid = SphereMesh.new()
	_mid.radius = 1.0
	_mid.height = 2.0
	_mid.radial_segments = 20
	_mid.rings = 10
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 1.0
	_cone.height = 1.0
	_cone.radial_segments = 16
	_cone.rings = 2
	_torus = TorusMesh.new()
	_torus.inner_radius = 0.7
	_torus.outer_radius = 1.3
	_torus.rings = 32
	_torus.ring_segments = 12
	_star = _make_star()

static func _make_star() -> ArrayMesh:
	var poly := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 + PI / 2.0
		var r := 0.45 if i % 2 else 1.0
		poly.append(Vector2(cos(a) * r, sin(a) * r))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var idx := Geometry2D.triangulate_polygon(poly)
	var z := 0.175
	for i in range(0, idx.size(), 3):
		for k in [0, 2, 1]:
			var p := poly[idx[i + k]]
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(Vector3(p.x, p.y, z))
		for k in [0, 1, 2]:
			var p := poly[idx[i + k]]
			st.set_normal(Vector3(0, 0, -1))
			st.add_vertex(Vector3(p.x, p.y, -z))
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := Vector3(b.y - a.y, a.x - b.x, 0).normalized()
		if Geometry2D.is_polygon_clockwise(poly):
			n = -n
		for v in [Vector3(a.x, a.y, z), Vector3(b.x, b.y, -z), Vector3(b.x, b.y, z), Vector3(a.x, a.y, z), Vector3(a.x, a.y, -z), Vector3(b.x, b.y, -z)]:
			st.set_normal(n)
			st.add_vertex(v)
	return st.commit()

static func pip_mat(color: String, emissive := Color.BLACK, fur := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.9
	m.metallic_specular = 0.15
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	if fur:
		# borde de luz suave: el pelaje se ve esponjoso
		m.rim_enabled = true
		m.rim = 0.45
		m.rim_tint = 0.6
	if emissive != Color.BLACK:
		m.emission_enabled = true
		m.emission = emissive
	return m

## Ojos y nariz húmedos: brillan con la luz.
static func gloss_mat(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.18
	m.metallic_specular = 0.8
	return m

func _part(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, sc: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	# optimización: Pip tiene ~80 piezas; las chicas no necesitan 800 triángulos (no se nota la diferencia)
	var tam := maxf(sc.x, maxf(sc.y, sc.z))
	if mesh == _ball and tam < 0.07:
		m.set_meta("forma_orig", "esfera")   # al exportar el modelo sigue siendo "esfera"
		mesh = _low if tam < 0.03 else _mid
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.scale = sc
	# las piezas chiquitas (ojos, mechones) no hacen sombra: ahorra trabajo y no se nota
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if maxf(sc.x, maxf(sc.y, sc.z)) > 0.045 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

func _pivot(parent: Node3D, pos: Vector3) -> Node3D:
	var g := Node3D.new()
	g.rotation_order = EULER_ORDER_XYZ
	g.position = pos
	parent.add_child(g)
	return g

func _init() -> void:
	_geos()
	name = "Pip"
	M = {
		"fur": pip_mat("#cf7a3e"), "fur2": pip_mat("#e59a5c"), "furDark": pip_mat("#a95e2c"), "cream": pip_mat("#fbe6cf"),
		"paw": pip_mat("#8c4e2a"), "eye": gloss_mat("#2a1a18"), "white": pip_mat("#ffffff", Color(0.4, 0.4, 0.4), false),
		"pink": pip_mat("#f4a7a2"), "nose": gloss_mat("#5a2f2a"), "scarf": pip_mat("#6cc9b2"), "scarf2": pip_mat("#4fae98"),
		"gold": pip_mat("#ffd36e", Color(0.48, 0.33, 0.06)), "tailTip": pip_mat("#ffe9d2"),
		"mouth": pip_mat("#5a2a2a", Color.BLACK, false), "blush": pip_mat("#ff9aa2", Color.BLACK, false),
	}
	(M.gold as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	body = _pivot(self, Vector3(0, 0.17, 0))
	torso = _pivot(body, Vector3.ZERO)
	_part(torso, _ball, M.fur, Vector3(0, 0.05, -0.01), Vector3(0.15, 0.14, 0.17))
	_part(torso, _ball, M.cream, Vector3(0, 0.04, 0.105), Vector3(0.1, 0.115, 0.08))
	_part(torso, _ball, M.cream, Vector3(0, 0.13, 0.07), Vector3(0.085, 0.07, 0.07))
	for i in 3:
		var ch := _part(torso, _cone, M.cream, Vector3((i - 1) * 0.03, 0.03, 0.17), Vector3(0.022, 0.05, 0.016))
		ch.rotation = Vector3(PI - 0.5, 0.0, (i - 1) * 0.3)
	# cabeza grande (proporción tierna)
	neck = _pivot(torso, Vector3(0, 0.17, 0.05))
	head = _pivot(neck, Vector3(0, 0.1, 0.02))
	_part(head, _ball, M.fur, Vector3.ZERO, Vector3(0.155, 0.142, 0.15))
	_part(head, _ball, M.fur2, Vector3(0, 0.07, -0.02), Vector3(0.11, 0.07, 0.11))
	for s in [-1.0, 1.0]:
		_part(head, _ball, M.cream, Vector3(s * 0.075, -0.045, 0.09), Vector3(0.07, 0.06, 0.055))
	_part(head, _ball, M.cream, Vector3(0, -0.035, 0.125), Vector3(0.06, 0.048, 0.05))
	# mechón en la frente y pelitos en las mejillas
	for i in 3:
		var tf := _part(head, _cone, M.fur2, Vector3((i - 1) * 0.022, 0.13, 0.045 - absf(i - 1) * 0.01), Vector3(0.022, 0.06, 0.018))
		tf.rotation = Vector3(0.5, 0.0, (1 - i) * 0.45)
	for s in [-1.0, 1.0]:
		for i in 2:
			var ck := _part(head, _cone, M.cream, Vector3(s * (0.128 + i * 0.012), -0.06 - i * 0.022, 0.07), Vector3(0.018, 0.045, 0.016))
			ck.rotation = Vector3(0.0, 0.0, -s * (1.9 + i * 0.25))
	nose = _part(head, _ball, M.nose, Vector3(0, -0.012, 0.172), Vector3(0.022, 0.017, 0.015))
	# boca (se abre para reír, comer y bostezar), dientes de ardilla y lengua
	mouth = _pivot(head, Vector3(0, -0.058, 0.158))
	_part(mouth, _ball, M.mouth, Vector3.ZERO, Vector3(0.024, 0.02, 0.012))
	tongue = _part(mouth, _low, M.pink, Vector3(0, -0.008, 0.004), Vector3(0.014, 0.008, 0.008))
	mouth.scale = Vector3(1.0, 0.12, 1.0)
	for s in [-1.0, 1.0]:
		var th := _part(head, _low, M.white, Vector3(s * 0.0065, -0.054, 0.171), Vector3(0.0062, 0.0095, 0.004))
		teeth.append(th)
	for s in [-1.0, 1.0]:
		var e := _pivot(head, Vector3(s * 0.07, 0.025, 0.118))
		_part(e, _ball, M.eye, Vector3.ZERO, Vector3(0.032, 0.04, 0.02))
		_part(e, _low, M.white, Vector3(s * -0.009, 0.014, 0.016), Vector3.ONE * 0.011)
		_part(e, _low, M.white, Vector3(s * 0.008, -0.01, 0.017), Vector3.ONE * 0.005)
		e.rotation.y = s * 0.28
		eyes.append(e)
		blush.append(_part(head, _ball, M.blush, Vector3(s * 0.1, -0.035, 0.105), Vector3(0.026, 0.016, 0.01)))
	for s in [-1.0, 1.0]:
		var ear := _pivot(head, Vector3(s * 0.085, 0.11, -0.01))
		ear.rotation.z = -s * 0.22
		# oreja de ardilla: hoja gruesa y redondeada, curvada hacia atrás, con el interior rosado y un mechón en la punta
		_part(ear, _oreja_malla(1.0, 0.016, 0.0), M.fur, Vector3(0, -0.005, 0), Vector3.ONE)
		_part(ear, _oreja_malla(0.62, 0.006, 0.0), M.pink, Vector3(0, 0.008, 0.012), Vector3.ONE)
		for k in 3:
			var tuft := _part(ear, _cone, M.furDark, Vector3(s * (0.004 + (k - 1) * 0.006), 0.13, -0.012), Vector3(0.012, 0.05 - absf(k - 1) * 0.012, 0.01))
			tuft.rotation = Vector3(-0.35, 0, -s * 0.25 + (k - 1) * 0.35)
		ears.append(ear)
	# bufanda con dos puntas que ondean y broche de estrella
	scarf = _pivot(torso, Vector3(0, 0.145, 0.03))
	var ring := _part(scarf, _torus, M.scarf, Vector3.ZERO, Vector3.ONE * 0.1)
	ring.rotation.x = PI / 2 + 0.2 - PI / 2   # el toro de Godot ya está acostado
	var parent: Node3D = scarf
	for i in 2:
		var tt := _pivot(parent, Vector3(0.06, -0.01, -0.07) if i == 0 else Vector3(0, -0.05, 0))
		_part(tt, _ball, M.scarf2 if i else M.scarf, Vector3(0, -0.025, 0), Vector3(0.03, 0.05, 0.012))
		scarf_tails.append(tt)
		parent = tt
	# brazos y patas
	for s in [-1.0, 1.0]:
		var a := _pivot(torso, Vector3(s * 0.112, 0.09, 0.06))
		# brazo: tubo suave que se afina hacia la muñeca + manito redonda con tres deditos
		_part(a, _brazo_malla(), M.fur, Vector3.ZERO, Vector3.ONE)
		_part(a, _ball, M.fur2, Vector3(0, -0.08, 0.022), Vector3(0.024, 0.02, 0.023))
		for k in 3:
			_part(a, _low, M.fur2, Vector3((k - 1) * 0.011, -0.094, 0.034), Vector3(0.008, 0.009, 0.009))
		arms.append(a)
	for s in [-1.0, 1.0]:
		var l := _pivot(body, Vector3(s * 0.085, -0.03, -0.04))
		_part(l, _ball, M.fur, Vector3(0, -0.02, 0), Vector3(0.055, 0.065, 0.07))
		_part(l, _ball, M.fur, Vector3(0, -0.075, 0.025), Vector3(0.03, 0.04, 0.03))
		_part(l, _ball, M.paw, Vector3(0, -0.11, 0.045), Vector3(0.035, 0.022, 0.06))
		for k in 3:
			_part(l, _low, M.paw, Vector3((k - 1) * 0.016, -0.112, 0.1), Vector3(0.011, 0.012, 0.012))
		legs.append(l)
	# cola: cadena de 8 "huesos" en forma de S; la malla es un tubo suave y esponjoso que se rehace cada cuadro
	parent = _pivot(torso, Vector3(0, 0.0, -0.14))
	for i in 8:
		var seg := _pivot(parent, Vector3.ZERO if i == 0 else Vector3(0, 0.085, -0.01))
		tail.append(seg)
		parent = seg
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.albedo_color = Color.WHITE
	cm.roughness = 0.92
	cm.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	cm.rim_enabled = true
	cm.rim = 0.55
	cm.rim_tint = 0.7
	M["cola"] = cm
	cola_mesh = ArrayMesh.new()
	cola = MeshInstance3D.new()
	cola.mesh = cola_mesh
	cola.material_override = cm
	torso.add_child(cola)
	for mi in find_children("*", "MeshInstance3D", true, false):
		_partes_pip.append(mi)
	_pip_cara = {"eyes": eyes.duplicate(), "mouth": mouth, "tongue": tongue, "teeth": teeth.duplicate(), "blush": blush.duplicate()}
	_armar_capibara()
	_nombrar()
	# el modelo editable (data/modelos/pip.json, lo arma el editor de Pip) reemplaza las piezas de arriba
	if not sin_datos:
		var d := modelo_guardado()
		if not d.is_empty():
			aplicar_modelo(d)
	_zonas()

## Zonas que se pueden tocar (el rayo del dedo las encuentra): cabeza, nariz, barriga, orejas, cola, pies y manos.
func _zonas() -> void:
	_zona("cabeza", head, Vector3(0, 0.02, 0), 0.15)
	_zona("nariz", head, Vector3(0, -0.025, 0.175), 0.045)
	_zona("barriga", torso, Vector3(0, 0.04, 0.09), 0.12)
	_zona("oreja", ears[0], Vector3(0, 0.07, 0), 0.05)
	_zona("oreja", ears[1], Vector3(0, 0.07, 0), 0.05)
	for i in [2, 4, 6]:
		_zona("cola", tail[i], Vector3(0, 0.04, 0), 0.12)
	_zona("pie", legs[0], Vector3(0, -0.1, 0.04), 0.06)
	_zona("pie", legs[1], Vector3(0, -0.1, 0.04), 0.06)

func _zona(nombre: String, parent: Node3D, pos: Vector3, r: float) -> void:
	var a := Area3D.new()
	a.collision_layer = 2
	a.collision_mask = 0
	a.monitoring = false
	a.set_meta("zona", nombre)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = r
	cs.shape = sh
	cs.position = pos
	a.add_child(cs)
	parent.add_child(a)
	zonas.append(a)

# ---------------- acciones ----------------
## Empieza una acción (si ya hay otra, la reemplaza salvo que `encolar`).
func hacer(nombre: String, encolar := false) -> void:
	if durmiendo and not nombre.begins_with("despertar"):
		return
	if encolar and accion != "":
		_cola_acciones.append(nombre)
		return
	accion = nombre
	ta = 0.0
	dur = DURACION.get(nombre, 1.0)
	if nombre.begins_with("baile_"):
		dur = 9.6
	fidget_t = 6.0 + randf() * 5.0

func ocupado() -> bool:
	return accion != ""

## Toque rápido. Si lo pinchan muchas veces seguidas, se enoja.
func toque(zona: String) -> void:
	if durmiendo:
		hacer_queja()
		return
	_pokes.append(t)
	while _pokes.size() > 0 and t - float(_pokes[0]) > 2.5:
		_pokes.pop_front()
	if _pokes.size() >= 6:
		_pokes.clear()
		hacer("enojo")
		Sfx.play("queja")
		return
	match zona:
		"barriga":
			hacer("risa")
			Sfx.play("risa", randf_range(0.95, 1.1))
		"nariz":
			hacer("boop")
			Sfx.play("boop", randf_range(0.95, 1.1))
			if randf() < 0.35:
				hacer("estornudo", true)
		"cola":
			hacer("cola")
			Sfx.play("pop", 1.2)
		"oreja":
			hacer("oreja")
			Sfx.play("tic", 0.9)
		"pie":
			hacer("pie")
			Sfx.play("risa", 1.25)
		_:
			hacer("celebrar" if randf() < 0.5 else "saludo")
			Sfx.play("feliz", randf_range(0.95, 1.08))

func hacer_queja() -> void:
	# dormido: se queja sin despertar
	land_t = 0.12
	Sfx.play("queja", 0.8, -6.0)

func dormir(on: bool) -> void:
	durmiendo = on
	accion = ""
	_cola_acciones.clear()
	if not on:
		hacer("estirarse")

func tomar_pocion(id: String, seg: float) -> void:
	pocion = id
	pocion_t = seg
	_pocion_k = 0.0
	hacer("celebrar")

## s: { speed }  — se llama cada cuadro
func animate(dt: float) -> void:
	t += dt
	# acción en curso
	if accion != "":
		ta += dt
		if ta >= dur:
			var fin := accion
			accion = ""
			if _cola_acciones.size() > 0:
				hacer(_cola_acciones.pop_front())
			accion_terminada.emit(fin)
	elif not durmiendo and corriendo < 0.1:
		fidget_t -= dt
		if fidget_t < 0.0:
			var op := ["bostezo", "rascar", "saludo", "mirar_cola", "estirarse"]
			if feliz > 0.6:
				op.append("celebrar")
			if feliz < 0.3:
				op = ["bostezo", "rascar", "bostezo"]
			hacer(op[randi() % op.size()])
	var A := accion
	var u := clampf(ta / maxf(0.001, dur), 0.0, 1.0)
	var env := sin(u * PI)                       # sube y baja durante la acción
	_dormir_k = move_toward(_dormir_k, 1.0 if durmiendo else 0.0, dt * 1.5)
	caricia = maxf(0.0, caricia - dt * 0.6)
	_car_k += (minf(1.0, caricia * 1.6) - _car_k) * minf(1.0, dt * 5.0)
	_mira_k += ((1.0 if mirar_a != null else 0.0) - _mira_k) * minf(1.0, dt * 4.0)
	mojado = maxf(0.0, mojado - dt * 0.05)

	# poción: tamaño, colores, fantasma y brillo
	if pocion != "":
		pocion_t -= dt
		_pocion_k = minf(1.0, _pocion_k + dt * 1.5) if pocion_t > 0.0 else maxf(0.0, _pocion_k - dt * 1.5)
		if pocion_t <= 0.0 and _pocion_k <= 0.0:
			pocion = ""
			_pociones_reset()
		else:
			_pociones_aplicar()
	var sc := base_scale
	if pocion == "gigante":
		sc *= lerpf(1.0, 1.45, _ease(_pocion_k))
	elif pocion == "mini":
		sc *= lerpf(1.0, 0.6, _ease(_pocion_k))
	scale = Vector3.ONE * sc

	# giro hacia donde va (correr entre habitaciones) o hacia la cámara
	_yaw = lerp_angle(_yaw, yaw_obj, minf(1.0, dt * 9.0))
	rotation.y = _yaw

	var run := corriendo > 0.3
	var run_k := minf(1.0, corriendo / 5.0)
	phase += dt * (7.0 + corriendo * 1.8) if run else 0.0
	var ph := phase

	var body_y := 0.0
	var pitch := 0.0
	var roll := 0.0
	var byaw := 0.0
	var sx := 1.0
	var sy := 1.0
	var arm_l := sin(t * 2.4) * 0.05
	var arm_r := arm_l
	var arm_lz := 0.15
	var arm_rz := -0.15
	var leg_l := 0.0
	var leg_r := 0.0
	var neck_x := sin(t * 0.9) * 0.05
	var neck_y := 0.0
	var head_z := sin(t * 0.7) * 0.06
	var ojos := 1.0                 # 1 abiertos, 0 cerrados
	var boca := 0.0                 # 0 cerrada, 1 muy abierta
	var rubor := 0.25 + feliz * 0.35
	var bizco := 0.0
	var cola_wave := 0.1
	var cola_freq := 2.2
	var cola_extra := 0.0
	var oreja_x := 0.0

	# respirar (en reposo); dormido más lento y profundo
	var br := sin(t * (1.4 if durmiendo else 2.4)) * (0.03 if durmiendo else 0.016)
	sy += br
	sx -= br * 0.5
	if run:
		body_y = absf(sin(ph)) * 0.06 * run_k
		pitch = 0.15 * run_k + sin(ph * 2.0) * 0.1 * run_k
		leg_l = sin(ph) * 1.1 * run_k
		leg_r = leg_l * 0.85
		arm_l = -sin(ph) * 1.0 * run_k
		arm_r = arm_l
		cola_wave = 0.18
		cola_freq = 9.0
		oreja_x = -0.5 * run_k

	# caricias: ojos cerrados de gusto, se inclina hacia la mano, cola contenta y ronroneo
	if _car_k > 0.01:
		ojos = lerpf(ojos, 0.08, _car_k)
		head_z += sin(t * 1.6) * 0.12 * _car_k
		neck_x += -0.12 * _car_k
		rubor += 0.4 * _car_k
		cola_wave += 0.12 * _car_k
		cola_freq += 3.0 * _car_k
		boca = maxf(boca, 0.12 * _car_k)
		oreja_x -= 0.35 * _car_k
	Sfx.set_ronroneo(_car_k if not durmiendo else 0.0)

	match A:
		"risa":
			var w := env * (1.0 - u * 0.3)
			roll = sin(ta * 28.0) * 0.12 * w
			body_y += absf(sin(ta * 14.0)) * 0.025 * w
			pitch += 0.12 * w
			arm_l = lerpf(arm_l, -0.9, w)
			arm_r = arm_l
			arm_lz = lerpf(arm_lz, -0.6, w)
			arm_rz = -arm_lz
			ojos = lerpf(ojos, 0.1, minf(1.0, w * 2.0))
			boca = maxf(boca, (0.6 + 0.4 * absf(sin(ta * 14.0))) * w)
			rubor += 0.6 * w
			cola_wave += 0.3 * w
			cola_freq = 12.0
		"boop":
			var k := sin(minf(1.0, ta / 0.25) * PI * 0.5) * (1.0 - _ease(maxf(0.0, (ta - 0.35) / 0.7)))
			neck_x += -0.35 * k
			bizco = k
			sy *= 1.0 - 0.06 * k
			ojos = lerpf(1.0, 1.25, k)
			oreja_x += 0.3 * k
		"estornudo":
			if ta < 0.6:
				var k := ta / 0.6
				neck_x += -0.4 * k
				ojos = 1.0 - 0.8 * k
				boca = 0.5 * k
				pitch -= 0.1 * k
			else:
				if ta - dt < 0.6:
					Sfx.play("estornudo", randf_range(0.95, 1.1))
				var k := 1.0 - _ease((ta - 0.6) / 0.6)
				neck_x += 0.45 * k
				pitch += 0.3 * k
				ojos = 0.1 + 0.9 * (1.0 - k)
				boca = 0.8 * k
				sy *= 1.0 - 0.12 * k
				sx *= 1.0 + 0.08 * k
		"cola":
			body_y += sin(minf(1.0, ta / 0.45) * PI) * 0.12
			neck_y = 1.3 * env
			byaw = 0.6 * env
			cola_extra = 0.6 * env
			cola_freq = 14.0
			cola_wave = 0.35
			ojos = 1.15
		"oreja":
			oreja_x += sin(ta * 50.0) * 0.4 * env
			head_z += sin(ta * 30.0) * 0.2 * env
			ojos = lerpf(1.0, 0.4, env)
		"pie":
			leg_l = -0.9 * env
			roll = -0.15 * env
			body_y += 0.02 * env
			boca = 0.6 * env
			ojos = lerpf(1.0, 0.15, env)
			arm_l = -0.8 * env
			arm_r = -0.4 * env
		"comer":
			var chomp := absf(sin(ta * 13.0))
			boca = (0.25 + 0.6 * chomp) * minf(1.0, ta * 5.0) * (1.0 - _ease(maxf(0.0, (u - 0.8) / 0.2)))
			arm_l = lerpf(arm_l, -1.7, env)
			arm_r = arm_l
			arm_lz = lerpf(arm_lz, -0.5, env)
			arm_rz = -arm_lz
			neck_x += 0.12 * env + chomp * 0.04 * env
			ojos = lerpf(1.0, 0.35, env)
			rubor += 0.3 * env
			if int(ta * 13.0 / PI) != int((ta - dt) * 13.0 / PI) and u < 0.8:
				Sfx.play("mordisco", randf_range(0.9, 1.2), -4.0)
		"bostezo":
			boca = _ease(env) * 1.0
			ojos = 1.0 - _ease(env) * 0.92
			neck_x += -0.35 * env
			arm_l = lerpf(arm_l, -2.6, env)
			arm_r = arm_l
			arm_lz = 0.4 * env + 0.15
			arm_rz = -arm_lz
			sy *= 1.0 + 0.06 * env
			if ta - dt <= 0.0:
				Sfx.play("bostezo", randf_range(0.9, 1.05), -3.0)
		"estirarse":
			arm_l = lerpf(arm_l, -2.8, env)
			arm_r = arm_l
			sy *= 1.0 + 0.1 * env
			sx *= 1.0 - 0.05 * env
			ojos = 1.0 - env * 0.9
			boca = 0.5 * env
		"rascar":
			arm_r = lerpf(arm_r, -2.9, minf(1.0, env * 2.0))
			arm_rz = lerpf(arm_rz, 0.4, minf(1.0, env * 2.0)) + sin(ta * 40.0) * 0.12 * env
			head_z += -0.25 * env
			ojos = lerpf(1.0, 0.3, env)
			leg_r = -0.2 * env
		"saludo":
			arm_r = lerpf(arm_r, -2.7, minf(1.0, env * 2.2))
			arm_rz = -0.3 - sin(ta * 12.0) * 0.45 * minf(1.0, env * 2.2)
			head_z += 0.12 * env
			boca = 0.35 * env
			rubor += 0.2 * env
		"mirar_cola":
			neck_y = 1.4 * env
			byaw = 0.9 * env
			cola_wave = 0.3
			cola_freq = 5.0
			ojos = 1.1
		"sacudir":
			byaw = sin(ta * 34.0) * 0.6 * env
			head_z += sin(ta * 34.0 + 1.0) * 0.3 * env
			ojos = lerpf(1.0, 0.1, env)
			cola_extra = sin(ta * 34.0) * 0.5 * env
			if ta - dt <= 0.0:
				Sfx.play("dash", 1.3, -6.0)
		"enojo":
			arm_l = lerpf(arm_l, -1.2, env)
			arm_r = arm_l
			arm_lz = lerpf(arm_lz, -1.1, env)
			arm_rz = -arm_lz
			ojos = lerpf(1.0, 0.45, env)
			neck_x += 0.12 * env
			byaw = 0.35 * env
			neck_y = -0.6 * env
			rubor += 0.5 * env
			leg_l = absf(sin(ta * 9.0)) * -0.35 * env
		"celebrar":
			body_y += sin(minf(1.0, ta / 0.6) * PI) * 0.16
			if ta > 0.6:
				body_y += sin(minf(1.0, (ta - 0.6) / 0.5) * PI) * 0.08
			arm_l = lerpf(arm_l, -2.6, minf(1.0, env * 2.0))
			arm_r = arm_l
			arm_lz = 0.6 * env
			arm_rz = -arm_lz
			boca = 0.55 * env
			ojos = lerpf(1.0, 0.12, env)
			cola_wave = 0.3
			cola_freq = 10.0
		"no":
			neck_y = sin(ta * 16.0) * 0.5 * env
			ojos = 0.6
			boca = 0.05
		_:
			if A.begins_with("baile_"):
				var r := _baile(A.substr(6), ta)
				body_y += r.y; pitch += r.p; roll += r.r; byaw += r.yaw
				arm_l = r.al; arm_r = r.ar; arm_lz = r.alz; arm_rz = r.arz
				leg_l = r.ll; leg_r = r.lr
				neck_x += r.nx; head_z += r.hz
				boca = r.boca; ojos = r.ojos
				cola_wave = 0.3; cola_freq = 8.0

	# ánimo en reposo: triste = orejas y cabeza gachas
	if A == "" and _car_k < 0.1 and not run:
		var triste := clampf((0.35 - feliz) / 0.35, 0.0, 1.0)
		oreja_x += 0.5 * triste
		neck_x += 0.1 * triste
		ojos = minf(ojos, 1.0 - 0.35 * triste)
		cola_wave *= 1.0 - 0.6 * triste

	# dormido: sentado mirando al frente, cabeza ladeada, ojos cerrados y la cola de cobija
	if _dormir_k > 0.0:
		var k := _ease(_dormir_k)
		pitch = lerpf(pitch, 0.12, k)
		body_y = lerpf(body_y, -0.03, k)
		neck_x = lerpf(neck_x, 0.28, k)
		head_z = lerpf(head_z, 0.38 + sin(t * 0.7) * 0.03, k)
		ojos = lerpf(ojos, 0.0, k)
		boca = lerpf(boca, 0.05, k)
		arm_l = lerpf(arm_l, -0.5, k)
		arm_r = arm_l
		arm_lz = lerpf(arm_lz, -0.45, k)
		arm_rz = -arm_lz
		leg_l = lerpf(leg_l, -0.6, k)
		leg_r = leg_l
		cola_extra = lerpf(cola_extra, 0.3, k)
		cola_wave *= 1.0 - 0.8 * k
		oreja_x = lerpf(oreja_x, 0.35, k)
		rubor += 0.15 * k

	if land_t > 0:
		land_t -= dt
		var k: float = maxf(0.0, land_t) * 1.8
		sy *= 1.0 - k
		sx *= 1.0 + k * 0.8
		body_y -= k * 0.1

	body.position.y = 0.17 + body_y
	body.scale = Vector3(sx, sy, sx)
	body.rotation = Vector3(pitch, byaw, roll)
	legs[0].rotation.x = leg_l
	legs[1].rotation.x = leg_r
	arms[0].rotation.x = arm_l
	arms[1].rotation.x = arm_r
	arms[0].rotation.z = arm_lz
	arms[1].rotation.z = arm_rz

	# cabeza: mira alrededor en reposo o sigue al dedo
	look_t -= dt
	if look_t < 0:
		look_t = 2.0 + randf() * 3.0
		look_yaw = (randf() - 0.5) * 0.9
		look_pitch = (randf() - 0.5) * 0.25
		if randf() < 0.4:
			look_yaw = 0.0   # mira a la cámara (al jugador)
			look_pitch = 0.0
	var ly := look_yaw
	var lp := look_pitch
	if mirar_a != null and is_inside_tree():
		var loc := head.global_transform.affine_inverse() * (mirar_a as Vector3)
		ly = clampf(atan2(loc.x, maxf(0.05, loc.z)), -0.9, 0.9)
		lp = clampf(-atan2(loc.y, maxf(0.05, loc.z)), -0.5, 0.5)
	if run or A != "" or _dormir_k > 0.5:
		ly = 0.0
		lp = 0.0
	neck.rotation.y += ((ly + neck_y) - neck.rotation.y) * minf(1.0, dt * (6.0 if A != "" else 3.5))
	neck.rotation.x += ((-pitch * 0.7 + neck_x + lp) - neck.rotation.x) * minf(1.0, dt * 8.0)
	head.rotation.z += (head_z - head.rotation.z) * minf(1.0, dt * 10.0)

	# parpadeo
	blink_t -= dt
	if blink_t < 0:
		blink_t = 2.2 + randf() * 3.5
	if blink_t < 0.1:
		ojos = minf(ojos, 0.1)
	for i in eyes.size():
		var e := eyes[i]
		e.scale.y += (clampf(ojos, 0.1, 1.3) - e.scale.y) * minf(1.0, dt * 25.0)
		var sgn := -1.0 if i == 0 else 1.0
		e.rotation.y = sgn * 0.28 - sgn * bizco * 0.5
	# boca, dientes y rubor
	mouth.scale.y += (lerpf(0.12, 1.2, clampf(boca, 0.0, 1.0)) - mouth.scale.y) * minf(1.0, dt * 22.0)
	tongue.visible = boca > 0.3
	var bm := M.blush as StandardMaterial3D
	bm.albedo_color = Color("#ff9aa2").lerp(Color("#ff6f86"), clampf(rubor - 0.3, 0.0, 1.0))
	for b in blush:
		b.scale = Vector3(0.026, 0.016, 0.01) * (0.8 + clampf(rubor, 0.0, 1.2) * 0.35)

	# orejas: temblor de vez en cuando
	ear_t -= dt
	var twitch := sin(t * 60.0) * 0.25 if ear_t < 0.15 else 0.0
	if ear_t < 0:
		ear_t = 2.0 + randf() * 4.0
	for i in ears.size():
		ears[i].rotation.x = oreja_x + (twitch if i == 1 else 0.0)

	# cola: forma de S + ola + resorte
	var target := clampf(-wrapf(yaw_obj - _yaw, -PI, PI) * 0.8, -0.7, 0.7)
	tail_vel += ((target - tail_swing) * 60.0 - tail_vel * 9.0) * dt
	tail_swing += tail_vel * dt
	for i in tail.size():
		var base: float = TAIL_BASE[i]
		var streamline := -0.25 * run_k * (1.0 if i < 3 else 0.5) if run else 0.0
		tail[i].rotation.x = base + streamline + sin(t * cola_freq - i * 0.7) * cola_wave * (0.4 + i * 0.12)
		tail[i].rotation.z = tail_swing * (0.3 + i * 0.12) + sin(t * 1.3 - i * 0.5) * 0.05 + cola_extra * (0.2 + i * 0.1)

	# bufanda que ondea
	scarf_wave += dt * (6.0 + corriendo * 3.0)
	scarf_tails[0].rotation.x = 0.6 + corriendo * 0.12 + sin(scarf_wave) * 0.15
	scarf_tails[1].rotation.x = 0.3 + sin(scarf_wave - 1.0) * 0.25
	_cola_tubo()
	_animar_ropa()

## Bailes: devuelve la pose para el tiempo tt (a 120 pulsos por minuto: un pulso = 0.5 s).
func _baile(id: String, tt: float) -> Dictionary:
	var b := tt * TAU          # una vuelta por segundo = 2 pulsos
	var k := minf(1.0, tt * 3.0) * minf(1.0, (dur - tt) * 3.0)
	var r := {"y": 0.0, "p": 0.0, "r": 0.0, "yaw": 0.0, "al": 0.0, "ar": 0.0, "alz": 0.15, "arz": -0.15,
		"ll": 0.0, "lr": 0.0, "nx": 0.0, "hz": 0.0, "boca": 0.3, "ojos": 1.0}
	match id:
		"saltitos":
			r.y = absf(sin(b)) * 0.09 * k
			r.r = sin(b * 0.5) * 0.15 * k
			r.al = (-2.4 + sin(b) * 0.4) * k
			r.ar = (-2.4 - sin(b) * 0.4) * k
			r.alz = 0.5 * k
			r.arz = -0.5 * k
			r.hz = sin(b * 0.5) * 0.25 * k
			r.ll = sin(b) * 0.4 * k
			r.lr = -r.ll
			r.boca = 0.5 + 0.3 * absf(sin(b))
			r.ojos = 0.2 if fmod(tt, 2.0) < 1.0 else 1.0
		"robot":
			var step := floorf(tt * 4.0)
			var pose := int(step) % 4
			r.al = [-1.6, 0.0, -1.6, -3.0][pose] * k
			r.ar = [0.0, -1.6, -3.0, -1.6][pose] * k
			r.alz = [0.2, 0.2, 1.3, 0.2][pose] * k
			r.arz = [-1.3, -0.2, -0.2, -0.2][pose] * -k * -1.0
			r.yaw = [0.4, -0.4, 0.0, 0.0][pose] * k
			r.nx = [0.0, 0.0, 0.15, -0.2][pose] * k
			r.y = 0.03 * float(pose % 2) * k
			r.boca = 0.2
			r.ojos = 1.15
		"trompo":
			r.yaw = tt * TAU * 1.5 * k if tt < dur - 0.6 else 0.0
			r.y = 0.05 + absf(sin(b * 2.0)) * 0.03 * k
			r.al = -2.0 * k
			r.ar = -2.0 * k
			r.alz = 1.4 * k
			r.arz = -1.4 * k
			r.ll = -0.5 * k
			r.boca = 0.6
			r.ojos = 0.15
		"aplausos":
			var c := absf(sin(b))
			r.al = -1.3 * k
			r.ar = -1.3 * k
			r.alz = lerpf(-0.2, -0.9, c) * k
			r.arz = -r.alz
			r.y = absf(sin(b * 0.5)) * 0.05 * k
			r.r = sin(b * 0.5) * 0.12 * k
			r.boca = 0.6 * c
			r.ojos = 0.3 + 0.7 * (1.0 - c)
			if int(tt * 2.0) != int((tt - get_process_delta_time()) * 2.0):
				Sfx.play("pop", 1.6, -6.0)
	return r

static func _ease(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)

# ---------------- pociones ----------------
var _colores_base := {}

func _pociones_aplicar() -> void:
	if _colores_base.is_empty():
		for k in M:
			_colores_base[k] = (M[k] as StandardMaterial3D).albedo_color
	var k := _pocion_k
	match pocion:
		"arcoiris":
			for key in ["fur", "fur2", "furDark", "tailTip"]:
				var c := Color.from_hsv(fmod(t * 0.25 + key.length() * 0.07, 1.0), 0.55, 0.95)
				(M[key] as StandardMaterial3D).albedo_color = (_colores_base[key] as Color).lerp(c, k)
		"fantasma":
			for key in M:
				var m := M[key] as StandardMaterial3D
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if k > 0.01 else BaseMaterial3D.TRANSPARENCY_DISABLED
				var c := m.albedo_color
				c.a = 1.0 - 0.55 * k - 0.1 * sin(t * 3.0) * k
				m.albedo_color = c
		"brillo":
			for key in ["fur", "fur2", "furDark", "cream", "tailTip"]:
				var m := M[key] as StandardMaterial3D
				m.emission_enabled = true
				m.emission = Color("#ffcf6a") * (0.35 + 0.15 * sin(t * 4.0)) * k
	pass

func _pociones_reset() -> void:
	for key in _colores_base:
		var m := M[key] as StandardMaterial3D
		m.albedo_color = _colores_base[key]
		m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		if key != "gold" and key != "white":
			m.emission_enabled = false
	_colores_base.clear()

# ---------------- cola: tubo suave ----------------
const COLA_ANILLOS := 26
const COLA_LADOS := 12

## Rehace la malla de la cola siguiendo los huesos: curva suave (Catmull-Rom), grosor que crece hacia el medio,
## borde ondulado (pelaje), lados más claros y punta crema.
## Optimización: lo que no cambia de un cuadro a otro (triángulos, colores, senos y radios de cada anillo) se
## calcula una vez; la forma se rehace hasta 40 veces por segundo (antes, todo en cada cuadro).
var _cola_idx := PackedInt32Array()
var _cola_cs := PackedColorArray()
var _cola_clave := ""
var _cola_dir: Array = []          ## [cos, sin, ondita] de cada vértice del anillo
var _cola_r := PackedFloat32Array()
var _cola_r_grosor := -1.0
var _cola_t := 0.0

func _cola_tubo() -> void:
	if not cola.visible:
		return
	if t - _cola_t < 0.025 and _cola_t > 0.0 and t >= _cola_t:
		return
	_cola_t = t
	if _cola_idx.is_empty():
		for k in COLA_ANILLOS - 1:
			for l in COLA_LADOS:
				var a := k * COLA_LADOS + l
				var b := k * COLA_LADOS + (l + 1) % COLA_LADOS
				_cola_idx.append_array([a, b, a + COLA_LADOS, b, b + COLA_LADOS, a + COLA_LADOS])
		for k in COLA_ANILLOS:
			var u := float(k) / (COLA_ANILLOS - 1)
			for l in COLA_LADOS:
				var a := TAU * l / COLA_LADOS
				_cola_dir.append([cos(a), sin(a), 1.0 + 0.09 * sin(a * 5.0 + u * 23.0)])
	if _cola_r_grosor != cola_grosor:
		_cola_r_grosor = cola_grosor
		_cola_r.resize(COLA_ANILLOS)
		for k in COLA_ANILLOS:
			var u := float(k) / (COLA_ANILLOS - 1)
			var r := cola_grosor * 0.03 + cola_grosor * 0.078 * pow(sin(PI * minf(1.0, u * 1.12) * 0.5), 0.7) * (1.0 - 0.35 * u)
			if u > 0.86:
				r *= sqrt(maxf(0.0, 1.0 - (u - 0.86) / 0.14))
			_cola_r[k] = r
	var fur: Color = (M.fur as StandardMaterial3D).albedo_color
	var fur2: Color = (M.fur2 as StandardMaterial3D).albedo_color
	var tip: Color = (M.tailTip as StandardMaterial3D).albedo_color
	var clave := "%s|%s|%s|%s" % [fur, fur2, tip, cola_punta]
	if clave != _cola_clave:
		_cola_clave = clave
		_cola_cs = PackedColorArray()
		for k in COLA_ANILLOS:
			var u := float(k) / (COLA_ANILLOS - 1)
			for l in COLA_LADOS:
				var c := fur.lerp(fur2, 0.35 + 0.35 * absf(float(_cola_dir[k * COLA_LADOS + l][0])))
				if u > cola_punta:
					c = c.lerp(tip, clampf((u - cola_punta) / 0.16, 0.0, 1.0))
				_cola_cs.append(c)
	var inv := torso.global_transform.affine_inverse()
	var pts: Array[Vector3] = [Vector3(0, 0.03, -0.1)]
	for i in tail.size():
		pts.append(inv * (tail[i].global_transform * Vector3(0, 0.05, 0)))
	pts.append(inv * (tail[tail.size() - 1].global_transform * Vector3(0, 0.15, -0.01)))
	var n := pts.size()
	var cen: Array[Vector3] = []
	for k in COLA_ANILLOS:
		var f := float(k) / (COLA_ANILLOS - 1) * (n - 1)
		var j := mini(int(f), n - 2)
		var u := f - j
		var p0 := pts[maxi(0, j - 1)]
		var p1 := pts[j]
		var p2 := pts[j + 1]
		var p3 := pts[mini(n - 1, j + 2)]
		var u2 := u * u
		var u3 := u2 * u
		cen.append(0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3))
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	vs.resize(COLA_ANILLOS * COLA_LADOS)
	ns.resize(COLA_ANILLOS * COLA_LADOS)
	var ref := Vector3.RIGHT
	var q := 0
	for k in COLA_ANILLOS:
		var tg := (cen[mini(k + 1, COLA_ANILLOS - 1)] - cen[maxi(k - 1, 0)]).normalized()
		var b1 := (ref - tg * ref.dot(tg)).normalized()
		ref = b1
		var b2 := tg.cross(b1)
		var r: float = _cola_r[k]
		for l in COLA_LADOS:
			var dd: Array = _cola_dir[q]
			var dir: Vector3 = b1 * float(dd[0]) + b2 * float(dd[1])
			vs[q] = cen[k] + dir * (r * float(dd[2]))
			ns[q] = dir
			q += 1
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_COLOR] = _cola_cs
	arr[Mesh.ARRAY_INDEX] = _cola_idx
	cola_mesh.clear_surfaces()
	cola_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

# ---------------- ropa animada ----------------
func _animar_ropa() -> void:
	for a in anim_ropa:
		var n: Node3D = a.n
		if not is_instance_valid(n):
			continue
		var x: float = a.x
		match a.tipo:
			"girar":
				n.rotation.y = t * x
			"flotar":
				n.position.y = (a.pos as Vector3).y + sin(t * 2.0) * 0.012
				n.rotation.y = t * 0.8
			"balancear":
				n.rotation.z = (a.rot as Vector3).z + sin(t * 3.2) * 0.22 * x - body.rotation.z * 1.5
			"aletear":
				n.rotation.y = (a.rot as Vector3).y + sin(t * 9.0 * absf(x)) * 0.45 * signf(x)
			"ondear":
				n.rotation.x = (a.rot as Vector3).x + (0.06 + sin(t * 2.4) * 0.09) * x + corriendo * 0.08
			"gelatina":
				var w := sin(t * 5.0 * x)
				n.scale = (a.sc as Vector3) * Vector3(1.0 + w * 0.05, 1.0 - w * 0.05, 1.0 + sin(t * 5.0 * x + 1.0) * 0.04)
			"llama":
				n.scale = (a.sc as Vector3) * Vector3(1.0, 0.7 + randf() * 0.6, 1.0)
		var m = a.mat
		if m != null:
			var mm := m as StandardMaterial3D
			match a.tipo:
				"parpadear":
					mm.emission_energy_multiplier = 0.3 + 1.4 * (0.5 + 0.5 * sin(t * 5.0 + x * 2.0))
				"brillar":
					mm.emission_energy_multiplier = 0.4 + 0.8 * (0.5 + 0.5 * sin(t * 2.2 + x * 1.7))
				"llama":
					mm.emission_energy_multiplier = 1.0 + randf() * 1.2
				"flotar":
					mm.emission_energy_multiplier = 1.0 + 0.4 * sin(t * 3.0)
				"balancear":
					mm.emission_energy_multiplier = 0.5 + 1.0 * (0.5 + 0.5 * sin(t * 4.0))

# ---------------- capibara ----------------
## La capibara usa el mismo esqueleto: así ríe, come, baila y duerme igual que Pip.
func _armar_capibara() -> void:
	var cafe := pip_mat("#a0703f")
	var cafe2 := pip_mat("#b8875a")
	var osc := pip_mat("#6e4a2a")
	var hocico := pip_mat("#8a5a33")
	var neg := gloss_mat("#1e1410")
	var bl := pip_mat("#ffffff", Color(0.4, 0.4, 0.4), false)
	M["capi"] = cafe
	M["capi2"] = cafe2
	M["capiOscuro"] = osc
	M["capiHocico"] = hocico
	M["capiOjo"] = neg
	M["capiBlanco"] = bl
	var L: Array = []
	L.append(_part(torso, _ball, cafe, Vector3(0, 0.04, -0.02), Vector3(0.175, 0.165, 0.19)))
	L.append(_part(torso, _ball, cafe2, Vector3(0, 0.03, 0.08), Vector3(0.12, 0.12, 0.1)))
	L.append(_part(head, _ball, cafe, Vector3(0, 0.0, 0.03), Vector3(0.15, 0.13, 0.17)))
	L.append(_part(head, _ball, hocico, Vector3(0, -0.035, 0.15), Vector3(0.115, 0.095, 0.09)))
	L.append(_part(head, _ball, cafe, Vector3(0, 0.03, 0.12), Vector3(0.12, 0.08, 0.1)))
	for sx in [-1.0, 1.0]:
		L.append(_part(head, _ball, neg, Vector3(sx * 0.03, -0.012, 0.232), Vector3(0.013, 0.008, 0.006)))
		var oc := _part(head, _ball, osc, Vector3(sx * 0.1, 0.115, -0.03), Vector3(0.035, 0.03, 0.016))
		capi_orejas.append(oc)
		L.append(oc)
	# ojos chiquitos y altos (tranquilos, como las capibaras)
	var ce: Array[Node3D] = []
	for sx in [-1.0, 1.0]:
		var e := _pivot(head, Vector3(sx * 0.085, 0.055, 0.13))
		L.append(_part(e, _ball, neg, Vector3.ZERO, Vector3(0.019, 0.022, 0.013)))
		L.append(_part(e, _low, bl, Vector3(sx * -0.005, 0.008, 0.01), Vector3.ONE * 0.006))
		e.rotation.y = sx * 0.4
		ce.append(e)
	var bo := _pivot(head, Vector3(0, -0.09, 0.2))
	L.append(_part(bo, _ball, M.mouth, Vector3.ZERO, Vector3(0.026, 0.018, 0.01)))
	var len := _part(bo, _low, M.pink, Vector3(0, -0.006, 0.004), Vector3(0.014, 0.008, 0.008))
	L.append(len)
	bo.scale = Vector3(1.0, 0.12, 1.0)
	var dts: Array[MeshInstance3D] = []
	for sx in [-1.0, 1.0]:
		var th := _part(head, _low, bl, Vector3(sx * 0.008, -0.078, 0.213), Vector3(0.007, 0.011, 0.004))
		L.append(th)
		dts.append(th)
	var rub: Array[MeshInstance3D] = []
	for sx in [-1.0, 1.0]:
		var b := _part(head, _ball, M.blush, Vector3(sx * 0.11, -0.03, 0.12), Vector3(0.026, 0.016, 0.01))
		L.append(b)
		rub.append(b)
	# la mandarina en la cabeza
	M["mandarina"] = pip_mat("#ff9f2e", Color(0.15, 0.06, 0.0), false)
	M["hoja"] = pip_mat("#4cae4c", Color.BLACK, false)
	capi_mandarina = [_part(head, _ball, M.mandarina, Vector3(0, 0.15, 0.0), Vector3(0.05, 0.045, 0.05)),
		_part(head, _ball, M.hoja, Vector3(0.015, 0.2, 0.0), Vector3(0.025, 0.006, 0.014))]
	L.append_array(capi_mandarina)
	for a in arms:
		L.append(_part(a, _ball, osc, Vector3(0, -0.05, 0.01), Vector3(0.034, 0.045, 0.038)))
	for l in legs:
		L.append(_part(l, _ball, cafe, Vector3(0, -0.02, 0), Vector3(0.06, 0.065, 0.075)))
		L.append(_part(l, _ball, osc, Vector3(0, -0.11, 0.04), Vector3(0.04, 0.022, 0.055)))
	for mi in L:
		(mi as MeshInstance3D).visible = false
	_capi = L
	_capi_cara = {"eyes": ce, "mouth": bo, "tongue": len, "teeth": dts, "blush": rub}

func set_forma(f: String) -> void:
	if f == forma:
		return
	forma = f
	var capi := f == "capibara"
	for mi in _partes_pip:
		if is_instance_valid(mi):
			(mi as Node3D).visible = not capi
	for mi in _capi:
		(mi as Node3D).visible = capi
	cola.visible = not capi
	scarf.visible = not capi
	for e in ears:
		e.visible = not capi
	var cara: Dictionary = _capi_cara if capi else _pip_cara
	eyes.assign(cara.eyes)
	mouth = cara.mouth
	tongue = cara.tongue
	teeth.assign(cara.teeth)
	blush.assign(cara.blush)

# ---------------- mallas suaves (brazos y orejas) ----------------
## Tubo suave a lo largo de unos puntos, con un radio por punto (sección elíptica rx·rz). Se arma una vez.
static func loft(pts: Array, rx: Array, rz: Array, lados := 14) -> ArrayMesh:
	var n := pts.size()
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var idx := PackedInt32Array()
	var ref := Vector3.RIGHT
	for k in n:
		var p: Vector3 = pts[k]
		var tg := ((pts[mini(k + 1, n - 1)] as Vector3) - (pts[maxi(k - 1, 0)] as Vector3)).normalized()
		var b1 := (ref - tg * ref.dot(tg)).normalized()
		ref = b1
		var b2 := tg.cross(b1)
		for l in lados:
			var a := TAU * l / lados
			var ca := cos(a)
			var sa := sin(a)
			vs.append(p + b1 * ca * float(rx[k]) + b2 * sa * float(rz[k]))
			ns.append((b1 * ca * float(rz[k]) + b2 * sa * float(rx[k])).normalized())
	for k in n - 1:
		for l in lados:
			var a := k * lados + l
			var b := k * lados + (l + 1) % lados
			idx.append_array([a, b, a + lados, b, b + lados, a + lados])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m

static var _mallas := {}

## Brazo: del hombro a la muñeca, un poco curvado hacia adelante (en el espacio del hueso del brazo).
static func _brazo_malla() -> ArrayMesh:
	if _mallas.has("brazo"):
		return _mallas.brazo
	var pts: Array = []
	var rx: Array = []
	var rz: Array = []
	var n := 9
	for k in n:
		var u := float(k) / (n - 1)
		pts.append(Vector3(0, 0.012 - u * 0.088, 0.004 + u * u * 0.02))
		var r := 0.027 - 0.008 * u
		if k == 0 or k == n - 1:
			r *= 0.55   # extremos redondeados
		rx.append(r)
		rz.append(r * 1.06)
	_mallas.brazo = loft(pts, rx, rz)
	return _mallas.brazo

## Oreja: hoja redondeada que termina en punta, curvada hacia atrás. `k` = tamaño, `grosor` en la base.
static func _oreja_malla(k: float, grosor: float, _x: float) -> ArrayMesh:
	var key := "oreja%s/%s" % [k, grosor]
	if _mallas.has(key):
		return _mallas[key]
	var pts: Array = []
	var rx: Array = []
	var rz: Array = []
	var n := 14
	for i in n:
		var u := float(i) / (n - 1)
		pts.append(Vector3(0, u * 0.14 * k, -0.016 * sin(u * PI) * k - 0.012 * u * u * k))
		var w := 0.05 * k * pow(sin(PI * clampf(0.1 + u * 0.9, 0.0, 1.0)), 0.75) * (1.0 - 0.45 * u)
		if i == 0:
			w *= 0.85
		rx.append(maxf(0.0005, w))
		rz.append(maxf(0.0005, grosor * (1.0 - 0.7 * u) + 0.004 * k))
	_mallas[key] = loft(pts, rx, rz, 16)
	return _mallas[key]


# ================= modelo editable (editor de Pip) =================
## Los huesos tienen nombre; las piezas (formas, colores, posiciones) pueden venir de data/modelos/pip.json, que
## arma el editor de Pip. Las animaciones usan los huesos, así que todo lo editado se sigue moviendo igual.
static var sin_datos := false          ## true al exportar el modelo "de fábrica" (tools/exportar_modelo.gd)
static var _guardado = null
var huesos := {}                        ## nombre -> Node3D
var cola_grosor := 1.0
var cola_punta := 0.72

static func modelo_guardado() -> Dictionary:
	if _guardado == null:
		_guardado = {}
		var ruta := "res://data/modelos/pip.json"
		if FileAccess.file_exists(ruta):
			var d = JSON.parse_string(FileAccess.open(ruta, FileAccess.READ).get_as_text())
			if d is Dictionary:
				_guardado = d
	return _guardado

func _nombrar() -> void:
	var n := {"cuerpo": body, "torso": torso, "cuello": neck, "cabeza": head, "boca": mouth, "bufanda": scarf,
		"capi_boca": _capi_cara.mouth}
	for i in 2:
		n["ojo_%d" % i] = _pip_cara.eyes[i]
		n["oreja_%d" % i] = ears[i]
		n["brazo_%d" % i] = arms[i]
		n["pierna_%d" % i] = legs[i]
		n["bufanda_punta_%d" % i] = scarf_tails[i]
		n["capi_ojo_%d" % i] = _capi_cara.eyes[i]
	n["cola_raiz"] = tail[0].get_parent()
	for i in tail.size():
		n["cola_%d" % i] = tail[i]
	for k in n:
		(n[k] as Node3D).name = k
	huesos = n
	# papeles especiales de algunas piezas (las animaciones los buscan)
	for x in teeth:
		x.set_meta("rol", "diente")
	for x in blush:
		x.set_meta("rol", "rubor")
	tongue.set_meta("rol", "lengua")
	nose.set_meta("rol", "nariz")
	for x in _capi_cara.teeth:
		x.set_meta("rol", "diente")
	for x in _capi_cara.blush:
		x.set_meta("rol", "rubor")
	(_capi_cara.tongue as Node).set_meta("rol", "lengua")
	for x in capi_mandarina:
		x.set_meta("rol", "mandarina")
	for x in capi_orejas:
		x.set_meta("rol", "oreja")
	for x in _capi:
		x.set_meta("capi", true)

func _nombre_malla(m: Mesh) -> String:
	if m == _ball: return "esfera"
	if m == _low: return "esfera_baja"
	if m == _cone: return "cono"
	if m == _torus: return "toro"
	if m == _star: return "estrella"
	for k in _mallas:
		if _mallas[k] == m:
			return str(k)
	return "esfera"

static var _cil: CylinderMesh
static var _caja: BoxMesh

func _malla(nombre: String) -> Mesh:
	match nombre:
		"esfera": return _ball
		"esfera_baja": return _low
		"cono": return _cone
		"toro": return _torus
		"estrella": return _star
		"cilindro":
			if _cil == null:
				_cil = CylinderMesh.new()
				_cil.top_radius = 1.0
				_cil.bottom_radius = 1.0
				_cil.height = 1.0
				_cil.radial_segments = 24
			return _cil
		"caja":
			if _caja == null:
				_caja = BoxMesh.new()
				_caja.size = Vector3.ONE
			return _caja
		"brazo": return _brazo_malla()
	if nombre.begins_with("oreja"):
		var p := nombre.substr(5).split("/")
		return _oreja_malla(float(p[0]), float(p[1]) if p.size() > 1 else 0.016, 0.0)
	return _ball

static func _v3(a) -> Array:
	var v: Vector3 = a
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]

static func _hex(c: Color) -> String:
	return "#" + c.to_html(false)

## El modelo actual como datos (lo que lee el editor).
func exportar() -> Dictionary:
	var claves := {}
	for k in M:
		claves[M[k]] = k
	var mats := {}
	for k in M:
		var m := M[k] as StandardMaterial3D
		if k == "cola":
			continue
		mats[k] = {"color": _hex(m.albedo_color), "emision": _hex(m.emission) if m.emission_enabled else "",
			"tipo": "brillo" if m.roughness < 0.5 else ("pelo" if m.rim_enabled else "plano")}
	var hs := {}
	for k in huesos:
		var h := huesos[k] as Node3D
		var padre := str(h.get_parent().name) if h.get_parent() != self else ""
		hs[k] = {"padre": padre, "pos": _v3(h.position), "rot": _v3(h.rotation), "esc": _v3(h.scale)}
	var partes: Array = []
	var mallas := {}
	var i := 0
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m == cola or m.get_parent() is Area3D:
			continue
		var forma := str(m.get_meta("forma_orig", _nombre_malla(m.mesh)))
		if forma == "brazo" or forma.begins_with("oreja"):
			if not mallas.has(forma):
				var arr := m.mesh.surface_get_arrays(0)
				var vv: Array = []
				for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					vv.append_array(_v3(v))
				mallas[forma] = {"v": vv, "i": Array(arr[Mesh.ARRAY_INDEX] as PackedInt32Array)}
		i += 1
		partes.append({"id": "p%d" % i, "hueso": str(m.get_parent().name), "forma": forma, "mat": str(claves.get(m.material_override, "fur")),
			"pos": _v3(m.position), "rot": _v3(m.rotation), "esc": _v3(m.scale), "rol": str(m.get_meta("rol", "")),
			"capi": bool(m.get_meta("capi", false))})
	return {"version": 1, "materiales": mats, "huesos": hs, "partes": partes, "mallas": mallas,
		"cola": {"grosor": cola_grosor, "punta": cola_punta}}

## Arma las piezas desde los datos del editor (reemplaza las de fábrica).
func aplicar_modelo(d: Dictionary) -> void:
	for k in d.get("materiales", {}):
		var md: Dictionary = d.materiales[k]
		var em := Color(str(md.emision)) if str(md.get("emision", "")) != "" else Color.BLACK
		if not M.has(k):
			M[k] = gloss_mat(str(md.color)) if md.tipo == "brillo" else pip_mat(str(md.color), em, md.tipo == "pelo")
		else:
			var m := M[k] as StandardMaterial3D
			m.albedo_color = Color(str(md.color))
			if em != Color.BLACK:
				m.emission_enabled = true
				m.emission = em
	for k in d.get("huesos", {}):
		if huesos.has(k):
			var hd: Dictionary = d.huesos[k]
			(huesos[k] as Node3D).position = Vector3(hd.pos[0], hd.pos[1], hd.pos[2])
			if k.begins_with("oreja") or k.begins_with("ojo") or k.begins_with("capi_ojo") or k.begins_with("bufanda"):
				(huesos[k] as Node3D).rotation = Vector3(hd.rot[0], hd.rot[1], hd.rot[2])
	var c: Dictionary = d.get("cola", {})
	cola_grosor = float(c.get("grosor", 1.0))
	cola_punta = float(c.get("punta", 0.72))
	for mi in _partes_pip + _capi:
		if is_instance_valid(mi) and mi != cola:
			(mi as Node).free()
	_partes_pip = [cola]
	_capi = []
	teeth.clear()
	blush.clear()
	capi_mandarina.clear()
	capi_orejas.clear()
	var cara_p := {"teeth": [], "blush": [], "tongue": null}
	var cara_c := {"teeth": [], "blush": [], "tongue": null}
	for pd in d.get("partes", []):
		var padre: Node3D = huesos.get(str(pd.hueso), torso)
		var mi := _part(padre, _malla(str(pd.forma)), M.get(str(pd.mat), M.fur), Vector3(pd.pos[0], pd.pos[1], pd.pos[2]),
			Vector3(pd.esc[0], pd.esc[1], pd.esc[2]))
		mi.rotation = Vector3(pd.rot[0], pd.rot[1], pd.rot[2])
		var capi: bool = pd.get("capi", false)
		var cara: Dictionary = cara_c if capi else cara_p
		if str(pd.get("rol", "")) != "":
			mi.set_meta("rol", str(pd.rol))
		if capi:
			mi.set_meta("capi", true)
		match str(pd.get("rol", "")):
			"diente": cara.teeth.append(mi)
			"rubor": cara.blush.append(mi)
			"lengua": cara.tongue = mi
			"nariz": nose = mi
			"mandarina": capi_mandarina.append(mi)
			"oreja": capi_orejas.append(mi)
		if capi:
			mi.visible = false
			_capi.append(mi)
		else:
			_partes_pip.append(mi)
	tongue = cara_p.tongue if cara_p.tongue else MeshInstance3D.new()
	teeth.assign(cara_p.teeth)
	blush.assign(cara_p.blush)
	_pip_cara = {"eyes": _pip_cara.eyes, "mouth": _pip_cara.mouth, "tongue": tongue, "teeth": teeth.duplicate(), "blush": blush.duplicate()}
	var ct: Array[MeshInstance3D] = []
	ct.assign(cara_c.teeth)
	var cb: Array[MeshInstance3D] = []
	cb.assign(cara_c.blush)
	_capi_cara = {"eyes": _capi_cara.eyes, "mouth": _capi_cara.mouth, "tongue": cara_c.tongue if cara_c.tongue else MeshInstance3D.new(),
		"teeth": ct, "blush": cb}
