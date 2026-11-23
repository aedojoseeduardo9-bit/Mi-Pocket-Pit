## Pocket Pip — la casa de Pip: 4 habitaciones en fila (cocina, habitación, patio, baño), como una casa de
## muñecas vista de frente. Cada habitación tiene "ranuras" de decoración (pared, piso, cama, cortina, fondo...)
## que se rearman al cambiar el estilo (Estado.deco). Piezas con bordes redondeados para que se vea suave.
class_name Casa
extends Node3D

const HABS := ["cocina", "habitacion", "patio", "bano"]
const NOMBRES := {"cocina": "Cocina", "habitacion": "Habitación", "patio": "Patio", "bano": "Baño"}
const ANCHO := 8.0
const FONDO := -2.5

var nodos := {}           ## hab -> Node3D
var ranuras := {}         ## "hab/slot" -> Node3D
var luces := {}           ## hab -> OmniLight3D principal
var lampara: OmniLight3D
var lampara_mat: StandardMaterial3D
var ventana_mat: StandardMaterial3D
var ducha: Node3D
var gotas: CPUParticles3D
var cama_pos := Vector3(1.15, 0.0, -1.2)
var cama_alto := 0.45
var _mats := {}
var _rbox := {}
var _ball: SphereMesh
var _cyl: CylinderMesh
var _cone: CylinderMesh
var _torus: TorusMesh

func _init() -> void:
	name = "Casa"
	_ball = SphereMesh.new()
	_ball.radius = 1.0
	_ball.height = 2.0
	_ball.radial_segments = 24
	_ball.rings = 12
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 1.0
	_cyl.bottom_radius = 1.0
	_cyl.height = 1.0
	_cyl.radial_segments = 28
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 1.0
	_cone.height = 1.0
	_cone.radial_segments = 20
	_torus = TorusMesh.new()
	_torus.inner_radius = 0.75
	_torus.outer_radius = 1.0
	_torus.rings = 36
	_torus.ring_segments = 12

func construir() -> void:
	for i in HABS.size():
		var h: String = HABS[i]
		var n := Node3D.new()
		n.name = h
		n.position.x = i * ANCHO
		add_child(n)
		nodos[h] = n
		var luz := OmniLight3D.new()
		luz.position = Vector3(0.4, 3.0, 0.8)
		luz.omni_range = 7.5
		luz.light_energy = 0.22
		luz.light_color = Color("#ffe8cc")
		n.add_child(luz)
		luces[h] = luz
		call("_fijo_" + h, n)
		for slot in Estado.cat.deco[h]:
			rearmar(h, slot)
	# columnas entre habitaciones (al pasar de una a otra se ve la casa de muñecas)
	for i in HABS.size() + 1:
		var x := -ANCHO / 2.0 + i * ANCHO
		var exterior := i == 2 or i == 3   # a los lados del patio: setos
		var col := "#7cbf6a" if exterior else "#f3e6d8"
		_rb(self, Vector3(0.36, 4.4, 0.9), Vector3(x, 2.2, FONDO + 0.35), col, 0.12)

func centro(i: int) -> float:
	return i * ANCHO

# ---------------- utilidades ----------------
func mat(c: String, rough := 0.85, emis := 0.0) -> StandardMaterial3D:
	var k := "%s/%s/%s" % [c, rough, emis]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = rough
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = emis
	_mats[k] = m
	return m

## Caja de bordes redondeados (malla en caché por tamaño y radio).
func rbox_mesh(s: Vector3, r: float) -> ArrayMesh:
	var key := "%s/%s" % [s, r]
	if _rbox.has(key):
		return _rbox[key]
	r = minf(r, minf(s.x, minf(s.y, s.z)) * 0.5 - 0.001)
	var bm := BoxMesh.new()
	bm.size = s
	bm.subdivide_width = 7
	bm.subdivide_height = 7
	bm.subdivide_depth = 7
	var arr := bm.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var inner := s * 0.5 - Vector3.ONE * r
	for i in vs.size():
		var v := vs[i]
		var c := Vector3(clampf(v.x, -inner.x, inner.x), clampf(v.y, -inner.y, inner.y), clampf(v.z, -inner.z, inner.z))
		var d := v - c
		var n := d.normalized() if d.length() > 0.00001 else ns[i]
		vs[i] = c + n * r
		ns[i] = n
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_TANGENT] = null
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_rbox[key] = m
	return m

func _mi(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, sc := Vector3.ONE, rot := Vector3.ZERO, sombra := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = sc
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _rb(parent: Node3D, s: Vector3, pos: Vector3, c: String, r := 0.06, rot := Vector3.ZERO, rough := 0.85) -> MeshInstance3D:
	return _mi(parent, rbox_mesh(s, r), mat(c, rough), pos, Vector3.ONE, rot)

func _bola(parent: Node3D, pos: Vector3, sc: Vector3, c: String, rough := 0.85, emis := 0.0) -> MeshInstance3D:
	return _mi(parent, _ball, mat(c, rough, emis), pos, sc)

func _cil(parent: Node3D, pos: Vector3, r: float, h: float, c: String, rot := Vector3.ZERO, rough := 0.85) -> MeshInstance3D:
	return _mi(parent, _cyl, mat(c, rough), pos, Vector3(r, h, r), rot)

## Muchas copias de una misma malla (lunares, baldosas, estrellas): una sola llamada de dibujo.
func _multi(parent: Node3D, mesh: Mesh, m: Material, xforms: Array, sombra := false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _slot(h: String, slot: String) -> Node3D:
	var k := h + "/" + slot
	if ranuras.has(k) and is_instance_valid(ranuras[k]):
		ranuras[k].free()
	var n := Node3D.new()
	n.name = slot
	nodos[h].add_child(n)
	ranuras[k] = n
	return n

## Vuelve a armar una ranura con el estilo guardado (o `prueba` para probarlo sin comprarlo).
func rearmar(h: String, slot: String, prueba := "") -> void:
	var n := _slot(h, slot)
	var id := prueba if prueba != "" else Estado.deco(h, slot)
	var f := "_%s_%s" % [h, slot]
	if has_method(f):
		call(f, n, id)

func _pared(n: Node3D, c: String, zocalo: String) -> void:
	_rb(n, Vector3(ANCHO, 4.4, 0.2), Vector3(0, 2.2, FONDO - 0.1), c, 0.04)
	_rb(n, Vector3(ANCHO - 0.3, 0.22, 0.08), Vector3(0, 0.11, FONDO + 0.04), zocalo, 0.03)

func _piso(n: Node3D, c: String) -> void:
	_rb(n, Vector3(ANCHO, 0.2, 5.0), Vector3(0, -0.1, 0.0), c, 0.04)

func _rayas(n: Node3D, c: String, cada: float, ancho: float) -> void:
	var xs: Array = []
	var x := -ANCHO / 2.0 + cada * 0.5
	while x < ANCHO / 2.0:
		xs.append(Transform3D(Basis.from_scale(Vector3(ancho, 4.2, 0.02)), Vector3(x, 2.3, FONDO + 0.005)))
		x += cada
	var bm := BoxMesh.new()
	_multi(n, bm, mat(c), xs)

func _lunares(n: Node3D, c: String, r: float, paso: float, y0 := 0.4) -> void:
	var xs: Array = []
	var fila := 0
	var y := y0
	while y < 4.3:
		var x := -ANCHO / 2.0 + (paso * 0.5 if fila % 2 else 0.0)
		while x < ANCHO / 2.0:
			xs.append(Transform3D(Basis.from_scale(Vector3(r, r, 0.01)), Vector3(x, y, FONDO + 0.01)))
			x += paso
		y += paso * 0.6
		fila += 1
	_multi(n, _ball, mat(c), xs)

func _ventana(n: Node3D, pos: Vector3, w: float, h: float, marco: String, cielo: StandardMaterial3D) -> void:
	_rb(n, Vector3(w + 0.16, h + 0.16, 0.1), pos + Vector3(0, 0, 0.0), marco, 0.05)
	_mi(n, BoxMesh.new(), cielo, pos + Vector3(0, 0, 0.04), Vector3(w, h, 0.02), Vector3.ZERO, false)
	_rb(n, Vector3(0.05, h, 0.05), pos + Vector3(0, 0, 0.07), marco, 0.02)
	_rb(n, Vector3(w, 0.05, 0.05), pos + Vector3(0, 0, 0.07), marco, 0.02)
	_rb(n, Vector3(w + 0.35, 0.08, 0.22), pos + Vector3(0, -h / 2.0 - 0.1, 0.1), marco, 0.03)

# ================= COCINA =================
func _fijo_cocina(n: Node3D) -> void:
	# mesón con cocinilla, horno y repisas
	_rb(n, Vector3(2.3, 1.0, 0.75), Vector3(0.35, 0.5, FONDO + 0.4), "#f7f2ea", 0.06)
	_rb(n, Vector3(2.4, 0.08, 0.82), Vector3(0.35, 1.03, FONDO + 0.42), "#9a7a5c", 0.03)
	for i in 3:
		_rb(n, Vector3(0.66, 0.78, 0.04), Vector3(-0.38 + i * 0.73, 0.5, FONDO + 0.78), "#efe6da", 0.04)
		_cil(n, Vector3(-0.38 + i * 0.73 + 0.22, 0.72, FONDO + 0.82), 0.018, 0.12, "#c9a46a", Vector3(PI / 2, 0, 0), 0.3)
	for i in 2:
		_cil(n, Vector3(0.75 + i * 0.42, 1.08, FONDO + 0.45), 0.15, 0.025, "#3a3a44")
	# olla roja con tapa
	_cil(n, Vector3(0.75, 1.22, FONDO + 0.45), 0.17, 0.24, "#e2574c", Vector3.ZERO, 0.35)
	_cil(n, Vector3(0.75, 1.35, FONDO + 0.45), 0.18, 0.03, "#c94236", Vector3.ZERO, 0.35)
	_bola(n, Vector3(0.75, 1.39, FONDO + 0.45), Vector3.ONE * 0.035, "#2f2f37")
	# repisa con frascos
	_rb(n, Vector3(1.5, 0.06, 0.3), Vector3(0.4, 2.35, FONDO + 0.16), "#9a7a5c", 0.02)
	var frascos := ["#ffcf6a", "#ff8f8f", "#9fe0b8", "#a9c7ff"]
	for i in 4:
		_cil(n, Vector3(-0.1 + i * 0.33, 2.52, FONDO + 0.16), 0.09, 0.28, frascos[i], Vector3.ZERO, 0.2)
		_cil(n, Vector3(-0.1 + i * 0.33, 2.68, FONDO + 0.16), 0.095, 0.05, "#f2efe9")
	# ventana con cortinas
	ventana_mat = mat("#bfe7ff", 0.5, 0.6)
	_ventana(n, Vector3(0.45, 3.2, FONDO + 0.05), 1.3, 0.85, "#ffffff", ventana_mat)
	for s in [-1.0, 1.0]:
		_rb(n, Vector3(0.32, 1.0, 0.06), Vector3(0.45 + s * 0.78, 3.25, FONDO + 0.15), "#ff9fb0", 0.03)
	# sartenes colgadas
	for i in 2:
		_cil(n, Vector3(-1.75 + i * 0.32, 2.75, FONDO + 0.1), 0.14 - i * 0.03, 0.03, "#3a3a44", Vector3(PI / 2, 0, 0), 0.4)

func _cocina_pared(n: Node3D, id: String) -> void:
	match id:
		"menta":
			_pared(n, "#cdeee2", "#9fd6c2")
			_rayas(n, "#bfe6d8", 0.5, 0.18)
		"cerezo":
			_pared(n, "#ffe1e8", "#f6b6c6")
			_lunares(n, "#ffc7d4", 0.06, 0.45)
		_:
			_pared(n, "#fff1dc", "#e8cfae")
			# azulejos detrás del mesón
			var xs: Array = []
			for ix in 11:
				for iy in 4:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.2, 0.2, 0.02)), Vector3(-0.75 + ix * 0.22, 1.2 + iy * 0.22, FONDO + 0.01)))
			_multi(n, BoxMesh.new(), mat("#d8eef7", 0.3), xs)

func _cocina_piso(n: Node3D, id: String) -> void:
	if id == "ajedrez":
		_piso(n, "#f4f1ec")
		var xs: Array = []
		for ix in 16:
			for iz in 10:
				if (ix + iz) % 2 == 0:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.01, 0.5)), Vector3(-3.75 + ix * 0.5, 0.005, -2.25 + iz * 0.5)))
		_multi(n, BoxMesh.new(), mat("#3c3f58", 0.4), xs)
	else:
		_piso(n, "#d4a373")
		var xs: Array = []
		for iz in 10:
			xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.01, 0.015)), Vector3(0, 0.003, -2.25 + iz * 0.5)))
		_multi(n, BoxMesh.new(), mat("#b9875a"), xs)

func _cocina_nevera(n: Node3D, id: String) -> void:
	var x := -1.55
	var z := FONDO + 0.5
	var c := "#ffb3c1" if id == "retro" else "#f4f6fa"
	var r := 0.18 if id == "retro" else 0.08
	_rb(n, Vector3(0.95, 2.1, 0.8), Vector3(x, 1.05, z), c, r, Vector3.ZERO, 0.35)
	_rb(n, Vector3(0.9, 0.025, 0.04), Vector3(x, 1.45, z + 0.41), "#d9dbe3" if id != "retro" else "#e88ea0", 0.01)
	var cromo := "#dfe4ee" if id == "retro" else "#b8bec9"
	_rb(n, Vector3(0.05, 0.45, 0.06), Vector3(x + 0.33, 1.8, z + 0.44), cromo, 0.025, Vector3.ZERO, 0.2)
	_rb(n, Vector3(0.05, 0.6, 0.06), Vector3(x + 0.33, 0.95, z + 0.44), cromo, 0.025, Vector3.ZERO, 0.2)
	# imanes y un dibujo de Pip
	_rb(n, Vector3(0.3, 0.36, 0.02), Vector3(x - 0.12, 1.85, z + 0.41), "#ffffff", 0.01)
	_bola(n, Vector3(x - 0.12, 1.85, z + 0.43), Vector3(0.08, 0.08, 0.01), "#cf7a3e")
	_bola(n, Vector3(x + 0.12, 1.2, z + 0.42), Vector3(0.04, 0.04, 0.02), "#ffcf4a", 0.3)
	_bola(n, Vector3(x - 0.2, 1.05, z + 0.42), Vector3(0.035, 0.035, 0.02), "#6cc9b2", 0.3)

func _cocina_mesa(n: Node3D, id: String) -> void:
	var p := Vector3(1.55, 0, -0.9)
	if id == "azul":
		_cil(n, p + Vector3(0, 0.78, 0), 0.55, 0.06, "#7fb8ff", Vector3.ZERO, 0.4)
		_cil(n, p + Vector3(0, 0.4, 0), 0.06, 0.76, "#5a8fd6")
		_cil(n, p + Vector3(0, 0.02, 0), 0.3, 0.04, "#5a8fd6")
	else:
		_rb(n, Vector3(1.1, 0.08, 0.8), p + Vector3(0, 0.78, 0), "#c08552", 0.03)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_rb(n, Vector3(0.07, 0.76, 0.07), p + Vector3(sx * 0.45, 0.38, sz * 0.3), "#a86e3f", 0.03)
	# frutero
	_cil(n, p + Vector3(0, 0.86, 0), 0.22, 0.08, "#ffffff")
	_bola(n, p + Vector3(-0.08, 0.95, 0), Vector3.ONE * 0.08, "#ff5a6e", 0.4)
	_bola(n, p + Vector3(0.08, 0.95, 0.04), Vector3.ONE * 0.075, "#ffcf4a", 0.4)
	_bola(n, p + Vector3(0.0, 0.98, -0.07), Vector3.ONE * 0.07, "#8fd16a", 0.4)

# ================= HABITACIÓN =================
func _fijo_habitacion(n: Node3D) -> void:
	# ventana con la luna o el sol
	ventana_mat = mat("#bfe2ff", 0.5, 0.5)
	var vm := StandardMaterial3D.new()
	vm.albedo_color = Color("#bfe2ff")
	vm.emission_enabled = true
	vm.emission = Color("#9fc8ff")
	vm.emission_energy_multiplier = 0.6
	set_meta("ventana_habitacion", vm)
	_ventana(n, Vector3(-0.2, 2.75, FONDO + 0.05), 1.2, 1.0, "#fff8f0", vm)
	_bola(n, Vector3(0.05, 2.95, FONDO + 0.08), Vector3(0.14, 0.14, 0.01), "#fff6c9", 0.5, 1.2)
	# velador
	_rb(n, Vector3(0.6, 0.62, 0.5), Vector3(-1.45, 0.31, FONDO + 0.6), "#d9b48f", 0.06)
	_rb(n, Vector3(0.5, 0.03, 0.04), Vector3(-1.45, 0.42, FONDO + 0.86), "#b48a62", 0.01)
	# repisa con libros y el cuadro de Nova
	_rb(n, Vector3(1.0, 0.05, 0.25), Vector3(1.55, 2.3, FONDO + 0.13), "#b48a62", 0.02)
	var libros := ["#ff8fa3", "#7fb8ff", "#ffcf6a", "#9fe0b8", "#c3a6ff"]
	for i in 5:
		_rb(n, Vector3(0.1, 0.32 - (i % 2) * 0.06, 0.2), Vector3(1.2 + i * 0.13, 2.49 - (i % 2) * 0.03, FONDO + 0.13), libros[i], 0.02)
	_rb(n, Vector3(0.62, 0.5, 0.04), Vector3(1.55, 3.2, FONDO + 0.03), "#fff8f0", 0.03)
	_rb(n, Vector3(0.52, 0.4, 0.02), Vector3(1.55, 3.2, FONDO + 0.06), "#2b2d5c", 0.01)
	_mi(n, Atuendos.extruir(_estrella(), 0.1), mat("#ffd36e", 0.4, 1.0), Vector3(1.55, 3.2, FONDO + 0.08), Vector3.ONE * 0.12)

static func _estrella() -> PackedVector2Array:
	var sp := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 + PI / 2.0
		var r := 0.45 if i % 2 else 1.0
		sp.append(Vector2(cos(a) * r, sin(a) * r))
	return sp

func _habitacion_pared(n: Node3D, id: String) -> void:
	match id:
		"noche":
			_pared(n, "#2f3170", "#23255a")
			var xs: Array = []
			var rnd := RandomNumberGenerator.new()
			rnd.seed = 7
			for i in 70:
				var s := rnd.randf_range(0.015, 0.04)
				xs.append(Transform3D(Basis.from_scale(Vector3(s, s, 0.005)), Vector3(rnd.randf_range(-3.9, 3.9), rnd.randf_range(0.5, 4.3), FONDO + 0.01)))
			_multi(n, _ball, mat("#fff3c4", 0.5, 1.5), xs)
		"durazno":
			_pared(n, "#ffdcc8", "#f2b796")
			_rayas(n, "#ffd0b8", 0.6, 0.25)
		_:
			_pared(n, "#e6dcff", "#c8b8f0")
			_lunares(n, "#d9ccff", 0.05, 0.5)
	_piso(n, "#c9a27c")

func _habitacion_cama(n: Node3D, id: String) -> void:
	var p := cama_pos
	match id:
		"nube":
			cama_alto = 0.5
			var nubes := [Vector3(-0.45, 0.3, 0), Vector3(0, 0.33, 0.05), Vector3(0.45, 0.3, 0), Vector3(-0.2, 0.32, -0.3), Vector3(0.25, 0.32, -0.3)]
			for v in nubes:
				_bola(n, p + v, Vector3(0.42, 0.22, 0.42), "#ffffff", 0.9)
			_bola(n, p + Vector3(0, 0.55, -0.45), Vector3(0.35, 0.14, 0.18), "#dfe9ff")
		"cohete":
			cama_alto = 0.5
			_rb(n, Vector3(1.5, 0.45, 1.0), p + Vector3(0, 0.25, 0), "#e8eef7", 0.18, Vector3.ZERO, 0.4)
			_mi(n, _cone, mat("#ff5a5f", 0.4), p + Vector3(0.95, 0.3, 0), Vector3(0.45, 0.6, 0.45), Vector3(0, 0, -PI / 2))
			for s in [-1.0, 1.0]:
				_rb(n, Vector3(0.35, 0.06, 0.45), p + Vector3(-0.75, 0.2, s * 0.45), "#ff5a5f", 0.03, Vector3(0, s * 0.3, 0))
			_cil(n, p + Vector3(0.2, 0.3, 0.51), 0.12, 0.03, "#7fd8ff", Vector3(PI / 2, 0, 0), 0.2)
			_rb(n, Vector3(1.3, 0.12, 0.85), p + Vector3(0, 0.5, 0), "#7fb8ff", 0.06)
		_:
			cama_alto = 0.42
			# nido: anillo de ramitas con un cojín
			_mi(n, _torus, mat("#a8743f"), p + Vector3(0, 0.25, 0), Vector3(0.75, 0.9, 0.6))
			_mi(n, _torus, mat("#8d5d32"), p + Vector3(0, 0.38, 0), Vector3(0.7, 0.6, 0.55), Vector3(0, 0.4, 0))
			_cil(n, p + Vector3(0, 0.2, 0), 0.6, 0.3, "#8d5d32")
			_bola(n, p + Vector3(0, 0.36, 0), Vector3(0.58, 0.1, 0.46), "#ffe3b8")
			_bola(n, p + Vector3(-0.35, 0.46, -0.1), Vector3(0.2, 0.1, 0.16), "#fff5e6")

func _habitacion_lampara(n: Node3D, id: String) -> void:
	var p := Vector3(-1.45, 0.62, FONDO + 0.6)
	var luz := OmniLight3D.new()
	luz.omni_range = 4.0
	luz.light_energy = 0.35
	luz.shadow_enabled = false
	n.add_child(luz)
	lampara = luz
	if id == "luna":
		luz.light_color = Color("#cfe0ff")
		luz.position = p + Vector3(0, 0.55, 0.2)
		_cil(n, p + Vector3(0, 0.03, 0), 0.12, 0.06, "#c9c3e8")
		_cil(n, p + Vector3(0, 0.22, 0), 0.02, 0.36, "#c9c3e8")
		lampara_mat = mat("#e9f0ff", 0.5, 1.2).duplicate()
		_mi(n, _ball, lampara_mat, p + Vector3(0, 0.55, 0), Vector3.ONE * 0.2)
	else:
		luz.light_color = Color("#ffd9a8")
		luz.position = p + Vector3(0, 0.5, 0.2)
		_cil(n, p + Vector3(0, 0.17, 0), 0.06, 0.34, "#fff1dc")
		lampara_mat = mat("#ff6b6b", 0.6, 0.6).duplicate()
		var sombrero := _mi(n, _ball, lampara_mat, p + Vector3(0, 0.38, 0), Vector3(0.26, 0.17, 0.26))
		sombrero.position.y = p.y + 0.4
		for i in 5:
			var a := TAU * i / 5.0
			_bola(n, p + Vector3(cos(a) * 0.16, 0.48, sin(a) * 0.16 + 0.02), Vector3(0.04, 0.03, 0.04), "#ffffff")

func _habitacion_alfombra(n: Node3D, id: String) -> void:
	if id == "estrella":
		var m := _mi(n, Atuendos.extruir(_estrella(), 0.5), mat("#ffd36e"), Vector3(0, 0.01, 0.1), Vector3(1.1, 1.1, 0.02), Vector3(-PI / 2, 0, 0), false)
		m.rotation = Vector3(-PI / 2, 0, 0)
	else:
		_cil(n, Vector3(0, 0.01, 0.1), 1.05, 0.02, "#ffb3c7")
		_cil(n, Vector3(0, 0.015, 0.1), 0.8, 0.02, "#ffd1de")

# ================= PATIO =================
var cielo_mat: ShaderMaterial

func _fijo_patio(n: Node3D) -> void:
	# pasto
	_rb(n, Vector3(ANCHO, 0.2, 6.0), Vector3(0, -0.1, -0.5), "#8fd16a", 0.04)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 3
	var flores := {"#ffffff": [], "#ffd36e": [], "#ff9fb0": [], "#b9a6ff": []}
	var keys := flores.keys()
	for i in 90:
		var p := Vector3(rnd.randf_range(-3.8, 3.8), 0.03, rnd.randf_range(-2.6, 1.6))
		if absf(p.x) < 0.8 and p.z > -0.8:
			continue
		var s := rnd.randf_range(0.035, 0.06)
		flores[keys[i % keys.size()]].append(Transform3D(Basis.from_scale(Vector3(s, s * 0.6, s)), p))
	for c in flores:
		_multi(n, _ball, mat(c), flores[c])
	var mata := []
	for i in 160:
		var p := Vector3(rnd.randf_range(-3.9, 3.9), 0.0, rnd.randf_range(-2.8, 1.6))
		var b := Basis(Vector3.UP, rnd.randf() * TAU).scaled(Vector3(0.03, rnd.randf_range(0.08, 0.16), 0.03))
		mata.append(Transform3D(b, p))
	_multi(n, _cone, mat("#74bd55"), mata)
	# piedras del camino y arbustos
	for i in 4:
		_cil(n, Vector3(-0.2 + i * 0.25, 0.01, 1.0 - i * 0.65), 0.2, 0.03, "#d9d4cc")
	for v in [Vector3(1.6, 0.25, -2.0), Vector3(2.1, 0.2, -1.7), Vector3(-2.4, 0.22, -1.4)]:
		_bola(n, v, Vector3(0.45, 0.32, 0.35), "#5fae4a")
	# casita de pájaros
	_cil(n, Vector3(1.9, 0.8, -2.25), 0.04, 1.6, "#a8743f")
	_rb(n, Vector3(0.36, 0.34, 0.3), Vector3(1.9, 1.75, -2.25), "#ffcf6a", 0.04)
	_mi(n, _cone, mat("#e2574c"), Vector3(1.9, 2.04, -2.25), Vector3(0.3, 0.24, 0.24))
	_cil(n, Vector3(1.9, 1.78, -2.09), 0.06, 0.01, "#3a2a20", Vector3(PI / 2, 0, 0))

func _patio_fondo(n: Node3D, id: String) -> void:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 arriba : source_color;
uniform vec4 abajo : source_color;
uniform float estrellas = 0.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment(){
	vec3 c = mix(abajo.rgb, arriba.rgb, smoothstep(0.0, 1.0, UV.y * -1.0 + 1.0));
	if (estrellas > 0.0) {
		vec2 g = UV * vec2(90.0, 60.0);
		vec2 id = floor(g);
		float r = h(id);
		float d = length(fract(g) - 0.5);
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + r * 3.0) + r * 20.0);
		c += vec3(smoothstep(0.12, 0.0, d) * step(0.93, r) * tw * estrellas * (1.0 - UV.y * -1.0 * 0.0));
	}
	ALBEDO = c;
}"""
	cielo_mat = ShaderMaterial.new()
	cielo_mat.shader = sh
	var cols := {"dia": ["#7cc4ff", "#e4f5ff", 0.0], "atardecer": ["#7b5cff", "#ffb38a", 0.25],
		"noche": ["#0d1340", "#3a3f8f", 1.0], "galaxia": ["#1a0b3d", "#6a2c91", 1.0]}
	var cc: Array = cols.get(id, cols.dia)
	cielo_mat.set_shader_parameter("arriba", Color(cc[0]))
	cielo_mat.set_shader_parameter("abajo", Color(cc[1]))
	cielo_mat.set_shader_parameter("estrellas", cc[2])
	var q := QuadMesh.new()
	q.size = Vector2(30, 14)
	_mi(n, q, cielo_mat, Vector3(0, 5.5, -9.0), Vector3.ONE, Vector3.ZERO, false)
	# colinas a lo lejos
	var colina := "#79b960" if id == "dia" else ("#8a6aa8" if id == "atardecer" else "#2c3a6a")
	if id == "galaxia":
		colina = "#3a2468"
	for v in [Vector3(-4.0, -1.2, -7.5), Vector3(1.5, -1.6, -7.8), Vector3(5.5, -1.3, -7.6)]:
		_bola(n, v, Vector3(4.0, 2.6, 1.0), colina, 1.0)
	match id:
		"dia":
			_bola(n, Vector3(2.4, 5.2, -8.5), Vector3.ONE * 0.6, "#fff2a8", 0.5, 2.0)
			for c in [Vector3(-2.5, 4.6, -8.0), Vector3(0.3, 5.6, -8.2)]:
				for k in 4:
					_bola(n, c + Vector3(k * 0.45 - 0.7, sin(k * 1.3) * 0.12, 0), Vector3(0.55, 0.36, 0.2), "#ffffff", 1.0, 0.4)
		"atardecer":
			_bola(n, Vector3(-1.8, 2.2, -8.5), Vector3.ONE * 0.9, "#ffcf80", 0.5, 1.6)
			for k in 3:
				_bola(n, Vector3(1.0 + k * 0.6, 4.4, -8.2), Vector3(0.6, 0.18, 0.2), "#ffb0c8", 1.0, 0.3)
		"noche":
			_bola(n, Vector3(2.0, 5.0, -8.5), Vector3.ONE * 0.55, "#fff6d8", 0.5, 1.5)
			_bola(n, Vector3(2.25, 5.15, -8.4), Vector3.ONE * 0.5, "#0d1340", 1.0)
		"galaxia":
			_bola(n, Vector3(-2.2, 5.3, -8.6), Vector3.ONE * 0.8, "#ff9a6b", 0.6, 0.5)
			_mi(n, _torus, mat("#ffd9a8", 0.6, 0.6), Vector3(-2.2, 5.3, -8.6), Vector3(1.3, 0.2, 1.3), Vector3(0.4, 0, 0.3), false)
			_bola(n, Vector3(2.6, 4.2, -8.6), Vector3.ONE * 0.4, "#7fd8ff", 0.6, 0.6)
			_mi(n, Atuendos.extruir(_estrella(), 0.1), mat("#fff3c4", 0.5, 3.0), Vector3(0.6, 6.0, -8.5), Vector3.ONE * 0.35, Vector3.ZERO, false)

func _patio_cerca(n: Node3D, id: String) -> void:
	var z := -2.7
	if id == "madera":
		for i in 17:
			_cil(n, Vector3(-4.0 + i * 0.5, 0.45, z), 0.09, 0.9, "#a8743f", Vector3(0, 0, 0))
		for y in [0.35, 0.7]:
			_cil(n, Vector3(0, y, z + 0.08), 0.05, ANCHO, "#8d5d32", Vector3(0, 0, PI / 2))
	else:
		var xs: Array = []
		for i in 27:
			xs.append(Transform3D(Basis.from_scale(Vector3(0.14, 0.8, 0.05)), Vector3(-3.9 + i * 0.3, 0.4, z)))
		_multi(n, rbox_mesh(Vector3.ONE, 0.2), mat("#ffffff"), xs, true)
		for y in [0.3, 0.62]:
			_rb(n, Vector3(ANCHO, 0.07, 0.04), Vector3(0, y, z - 0.05), "#f1ede6", 0.02)

func _patio_arbol(n: Node3D, id: String) -> void:
	var p := Vector3(-1.75, 0, -1.6)
	_cil(n, p + Vector3(0, 0.9, 0), 0.16, 1.8, "#8d5d32")
	_cil(n, p + Vector3(0.25, 1.5, 0), 0.06, 0.6, "#8d5d32", Vector3(0, 0, -0.8))
	var hojas := ["#ffc2d6", "#ffadc8", "#ffd6e3"] if id == "cerezo" else ["#5fae4a", "#6fc157", "#4f9a3e"]
	var bolas := [Vector3(0, 2.3, 0), Vector3(-0.5, 2.0, 0.1), Vector3(0.5, 2.05, 0.05), Vector3(-0.2, 2.75, -0.1), Vector3(0.3, 2.6, 0.2)]
	for i in bolas.size():
		_bola(n, p + bolas[i], Vector3.ONE * (0.55 - i * 0.03), hojas[i % 3], 0.95)
	if id == "cerezo":
		var rnd := RandomNumberGenerator.new()
		rnd.seed = 5
		var xs: Array = []
		for i in 25:
			xs.append(Transform3D(Basis.from_scale(Vector3(0.035, 0.008, 0.035)), p + Vector3(rnd.randf_range(-1.2, 1.4), 0.01, rnd.randf_range(-0.6, 1.4))))
		_multi(n, _ball, mat("#ffadc8"), xs)
	else:
		_bola(n, p + Vector3(0.35, 2.2, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)
		_bola(n, p + Vector3(-0.4, 1.9, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)

# ================= BAÑO =================
func _fijo_bano(n: Node3D) -> void:
	_piso(n, "#f4f7fb")
	var xs: Array = []
	for ix in 16:
		xs.append(Transform3D(Basis.from_scale(Vector3(0.012, 0.01, 5.0)), Vector3(-3.75 + ix * 0.5, 0.003, 0)))
	for iz in 10:
		xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.01, 0.012)), Vector3(0, 0.003, -2.25 + iz * 0.5)))
	_multi(n, BoxMesh.new(), mat("#d6dee8"), xs)
	# lavamanos y espejo
	var p := Vector3(-1.55, 0, FONDO + 0.45)
	_rb(n, Vector3(0.9, 0.9, 0.6), p + Vector3(0, 0.45, 0), "#ffffff", 0.1, Vector3.ZERO, 0.3)
	_cil(n, p + Vector3(0, 0.92, 0.05), 0.3, 0.06, "#e8eef7", Vector3.ZERO, 0.2)
	_cil(n, p + Vector3(0, 1.05, -0.2), 0.03, 0.22, "#c9d1dc", Vector3.ZERO, 0.15)
	_cil(n, p + Vector3(0, 1.14, -0.1), 0.025, 0.2, "#c9d1dc", Vector3(PI / 2, 0, 0), 0.15)
	_rb(n, Vector3(0.8, 1.0, 0.06), p + Vector3(0, 1.95, -0.22), "#ffffff", 0.08)
	var espejo := StandardMaterial3D.new()
	espejo.albedo_color = Color("#cfe6f5")
	espejo.metallic = 0.9
	espejo.roughness = 0.05
	_mi(n, rbox_mesh(Vector3(0.68, 0.88, 0.02), 0.05), espejo, p + Vector3(0, 1.95, -0.18))
	# toalla y patito
	_rb(n, Vector3(0.06, 0.06, 0.6), Vector3(-0.55, 1.7, FONDO + 0.12), "#c9d1dc", 0.02, Vector3(0, PI / 2, 0))
	_rb(n, Vector3(0.5, 0.75, 0.05), Vector3(-0.55, 1.35, FONDO + 0.16), "#ff9fb0", 0.04)
	# la ducha (baja cuando se usa)
	ducha = Node3D.new()
	ducha.position = Vector3(0, 4.6, 0.25)
	n.add_child(ducha)
	_cil(ducha, Vector3(0, 0.6, 0), 0.03, 1.2, "#c9d1dc", Vector3.ZERO, 0.2)
	_cil(ducha, Vector3(0, 0, 0), 0.2, 0.08, "#dfe6ee", Vector3.ZERO, 0.2)
	gotas = CPUParticles3D.new()
	gotas.emitting = false
	gotas.amount = 140
	gotas.lifetime = 0.9
	gotas.position = Vector3(0, -0.05, 0)
	gotas.direction = Vector3(0, -1, 0)
	gotas.spread = 12.0
	gotas.initial_velocity_min = 3.0
	gotas.initial_velocity_max = 4.0
	gotas.gravity = Vector3(0, -6, 0)
	gotas.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	gotas.emission_sphere_radius = 0.15
	gotas.scale_amount_min = 0.6
	gotas.scale_amount_max = 1.0
	var gm := SphereMesh.new()
	gm.radius = 0.02
	gm.height = 0.08
	gm.radial_segments = 6
	gm.rings = 3
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.7, 0.88, 1.0, 0.7)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.material = gmat
	gotas.mesh = gm
	ducha.add_child(gotas)

func _bano_pared(n: Node3D, id: String) -> void:
	if id == "coral":
		_pared(n, "#ffd1c4", "#f4a38f")
		_rayas(n, "#ffc3b3", 0.8, 0.3)
	else:
		_pared(n, "#dff3fb", "#b6dcea")
		var xs: Array = []
		for ix in 17:
			xs.append(Transform3D(Basis.from_scale(Vector3(0.015, 2.0, 0.01)), Vector3(-4.0 + ix * 0.5, 1.0, FONDO + 0.01)))
		for iy in 5:
			xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.015, 0.01)), Vector3(0, 0.25 + iy * 0.45, FONDO + 0.01)))
		_multi(n, BoxMesh.new(), mat("#bfe1ee"), xs)

func _bano_banera(n: Node3D, id: String) -> void:
	var p := Vector3(1.45, 0, -1.55)
	var c := "#ffffff"
	if id == "dorada":
		c = "#fff4f6"
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_bola(n, p + Vector3(sx * 0.7, 0.09, sz * 0.3), Vector3(0.1, 0.09, 0.1), "#ffcf4a", 0.25)
	var y0 := 0.15 if id == "dorada" else 0.0
	_rb(n, Vector3(1.9, 0.75, 0.95), p + Vector3(0, y0 + 0.375, 0), c, 0.3, Vector3.ZERO, 0.25)
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.55, 0.82, 1.0, 0.85)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.05
	agua.metallic_specular = 1.0
	_mi(n, rbox_mesh(Vector3(1.7, 0.04, 0.75), 0.02), agua, p + Vector3(0, y0 + 0.72, 0), Vector3.ONE, Vector3.ZERO, false)
	# espuma y patito
	for i in 6:
		_bola(n, p + Vector3(-0.6 + i * 0.25, y0 + 0.76, sin(i * 1.7) * 0.2), Vector3.ONE * (0.08 + (i % 3) * 0.03), "#ffffff", 0.9)
	_bola(n, p + Vector3(0.5, y0 + 0.82, 0.1), Vector3(0.11, 0.09, 0.13), "#ffd84a", 0.4)
	_bola(n, p + Vector3(0.5, y0 + 0.95, 0.17), Vector3.ONE * 0.065, "#ffd84a", 0.4)
	_bola(n, p + Vector3(0.5, y0 + 0.94, 0.24), Vector3(0.035, 0.015, 0.03), "#ff8c3a", 0.4)

func _bano_cortina(n: Node3D, id: String) -> void:
	var p := Vector3(1.45, 0, -1.55)
	_cil(n, p + Vector3(0, 2.55, 0.5), 0.025, 2.2, "#c9d1dc", Vector3(0, 0, PI / 2), 0.2)
	var cols := {"rayas": ["#7fc8ff", "#ffffff"], "burbujas": ["#b8f0ff", "#ffffff"], "estrellas": ["#4b4fa8", "#ffd36e"]}
	var cc: Array = cols.get(id, cols.rayas)
	# pliegues: la cortina está recogida hacia la izquierda (se ve la bañera)
	for i in 8:
		var x := p.x - 0.95 + i * 0.09
		var z := p.z + 0.5 + (0.035 if i % 2 else -0.035)
		var col: String = cc[i % 2] if id == "rayas" else cc[0]
		_rb(n, Vector3(0.1, 1.6, 0.04), Vector3(x, 1.75, z), col, 0.02, Vector3(0, (0.3 if i % 2 else -0.3), 0))
	if id == "burbujas":
		for i in 6:
			_bola(n, Vector3(p.x - 0.95 + (i % 3) * 0.25, 1.4 + (i / 3) * 0.6, p.z + 0.56), Vector3.ONE * 0.05, "#ffffff", 0.2)
	elif id == "estrellas":
		for i in 5:
			_mi(n, Atuendos.extruir(_estrella(), 0.1), mat("#ffd36e", 0.5, 0.6), Vector3(p.x - 0.9 + (i % 2) * 0.3, 1.2 + i * 0.25, p.z + 0.57), Vector3.ONE * 0.06)
