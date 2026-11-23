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
	var v: Dictionary = Estado.busca(Estado.cat.deco[h][slot], id)
	if v.is_empty():
		v = Estado.cat.deco[h][slot][0]
	var p: Dictionary = v.get("p", {})
	match slot:
		"pared":
			pared(n, p)
		"piso":
			piso(n, p)
		_:
			var f := "_%s_%s" % [h, slot]
			if has_method(f):
				call(f, n, p)

# ================= paredes y pisos (todas las habitaciones) =================
## Pared con patrón: liso, rayas, lunares, cuadros, estrellas, corazones, ladrillo, tablas, ondas, rombos, hojas, nubes.
func pared(n: Node3D, p: Dictionary) -> void:
	var c1 := str(p.get("c1", "#fff1dc"))
	var c2 := str(p.get("c2", "#f3d9b6"))
	_rb(n, Vector3(ANCHO, 4.4, 0.2), Vector3(0, 2.2, FONDO - 0.1), c1, 0.04)
	_rb(n, Vector3(ANCHO - 0.3, 0.22, 0.08), Vector3(0, 0.11, FONDO + 0.04), Color(c2).darkened(0.12).to_html(false), 0.03)
	var xs: Array = []
	var mesh: Mesh = BoxMesh.new()
	var z := FONDO + 0.006
	match str(p.get("patron", "liso")):
		"rayas":
			var x := -3.75
			while x < 4.0:
				xs.append(Transform3D(Basis.from_scale(Vector3(0.2, 4.2, 0.01)), Vector3(x, 2.3, z)))
				x += 0.5
		"lunares", "estrellas", "corazones", "hojas":
			var pat := str(p.patron)
			mesh = _ball
			if pat == "estrellas":
				mesh = Atuendos.extruir(_estrella(), 0.2)
			elif pat == "corazones":
				Atuendos._geos()
				mesh = Atuendos._heart
			elif pat == "hojas":
				Atuendos._geos()
				mesh = Atuendos._gota
			var fila := 0
			var y := 0.5
			while y < 4.3:
				var x := -3.9 + (0.25 if fila % 2 else 0.0)
				while x < 4.0:
					var s := 0.07 if pat == "lunares" else 0.09
					var rot := 0.0 if pat != "hojas" else (0.6 if (fila + int(x * 2.0)) % 2 else -0.6)
					xs.append(Transform3D(Basis(Vector3(0, 0, 1), rot).scaled(Vector3(s, s, 0.02)), Vector3(x, y, z)))
					x += 0.5
				y += 0.34
				fila += 1
		"cuadros":
			for i in 17:
				xs.append(Transform3D(Basis.from_scale(Vector3(0.05, 4.2, 0.01)), Vector3(-4.0 + i * 0.5, 2.3, z)))
			for i in 9:
				xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.05, 0.01)), Vector3(0, 0.45 + i * 0.5, z)))
		"ladrillo":
			for f in 14:
				xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.025, 0.01)), Vector3(0, 0.3 + f * 0.3, z)))
				var x0 := -3.9 + (0.3 if f % 2 else 0.0)
				var x := x0
				while x < 4.0:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.025, 0.3, 0.01)), Vector3(x, 0.45 + f * 0.3, z)))
					x += 0.6
		"tablas":
			for i in 27:
				xs.append(Transform3D(Basis.from_scale(Vector3(0.02, 4.2, 0.01)), Vector3(-3.9 + i * 0.3, 2.3, z)))
		"ondas":
			mesh = _ball
			for f in 6:
				for i in 64:
					var x := -4.0 + i * 0.125
					xs.append(Transform3D(Basis.from_scale(Vector3(0.05, 0.05, 0.01)), Vector3(x, 0.7 + f * 0.65 + sin(x * 3.0) * 0.12, z)))
		"rombos":
			for f in 9:
				var x := -3.9 + (0.3 if f % 2 else 0.0)
				while x < 4.0:
					xs.append(Transform3D(Basis(Vector3(0, 0, 1), PI / 4).scaled(Vector3(0.18, 0.18, 0.01)), Vector3(x, 0.5 + f * 0.45, z)))
					x += 0.6
		"nubes":
			mesh = _ball
			for f in 4:
				var x := -3.4 + (0.9 if f % 2 else 0.0)
				while x < 4.0:
					for k in 3:
						xs.append(Transform3D(Basis.from_scale(Vector3(0.16 - abs(k - 1) * 0.04, 0.1, 0.01)), Vector3(x + (k - 1) * 0.16, 0.9 + f * 0.9 + (0.04 if k == 1 else 0.0), z)))
					x += 1.8
	if xs.size() > 0:
		_multi(n, mesh, mat(c2), xs)

## Piso: tablas de madera, baldosas de ajedrez o alfombra lisa.
func piso(n: Node3D, p: Dictionary) -> void:
	var c1 := str(p.get("c1", "#d4a373"))
	var c2 := str(p.get("c2", "#b9875a"))
	_rb(n, Vector3(ANCHO, 0.2, 5.0), Vector3(0, -0.1, 0.0), c1, 0.04)
	var xs: Array = []
	match str(p.get("tipo", "tablas")):
		"tablas":
			for iz in 10:
				xs.append(Transform3D(Basis.from_scale(Vector3(ANCHO, 0.01, 0.015)), Vector3(0, 0.003, -2.25 + iz * 0.5)))
			for iz in 10:
				for k in 4:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.015, 0.01, 0.5)), Vector3(-3.0 + k * 2.0 + (iz % 2) * 1.0, 0.003, -2.0 + iz * 0.5)))
		"ajedrez":
			for ix in 16:
				for iz in 10:
					if (ix + iz) % 2 == 0:
						xs.append(Transform3D(Basis.from_scale(Vector3(0.5, 0.01, 0.5)), Vector3(-3.75 + ix * 0.5, 0.005, -2.25 + iz * 0.5)))
		_:
			pass
	if xs.size() > 0:
		_multi(n, BoxMesh.new(), mat(c2, 0.5), xs)

# ================= COCINA =================
func _cocina_nevera(n: Node3D, p: Dictionary) -> void:
	var x := -1.55
	var z := FONDO + 0.5
	var c := str(p.get("c", "#f4f6fa"))
	var r := float(p.get("r", 0.08))
	_rb(n, Vector3(0.95, 2.1, 0.8), Vector3(x, 1.05, z), c, r, Vector3.ZERO, 0.35)
	_rb(n, Vector3(0.9, 0.025, 0.04), Vector3(x, 1.45, z + 0.41), Color(c).darkened(0.12).to_html(false), 0.01)
	var cromo := "#dfe4ee"
	_rb(n, Vector3(0.05, 0.45, 0.06), Vector3(x + 0.33, 1.8, z + 0.44), cromo, 0.025, Vector3.ZERO, 0.2)
	_rb(n, Vector3(0.05, 0.6, 0.06), Vector3(x + 0.33, 0.95, z + 0.44), cromo, 0.025, Vector3.ZERO, 0.2)
	_rb(n, Vector3(0.3, 0.36, 0.02), Vector3(x - 0.12, 1.85, z + 0.41), "#ffffff", 0.01)
	_bola(n, Vector3(x - 0.12, 1.85, z + 0.43), Vector3(0.08, 0.08, 0.01), "#cf7a3e")
	_bola(n, Vector3(x + 0.12, 1.2, z + 0.42), Vector3(0.04, 0.04, 0.02), "#ffcf4a", 0.3)
	_bola(n, Vector3(x - 0.2, 1.05, z + 0.42), Vector3(0.035, 0.035, 0.02), "#6cc9b2", 0.3)

func _cocina_mesa(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(1.55, 0, -0.9)
	var c := str(p.get("c", "#c08552"))
	var osc := Color(c).darkened(0.15).to_html(false)
	match str(p.get("forma", "cuadrada")):
		"redonda":
			_cil(n, q + Vector3(0, 0.78, 0), 0.55, 0.06, c, Vector3.ZERO, 0.4)
			_cil(n, q + Vector3(0, 0.4, 0), 0.06, 0.76, osc)
			_cil(n, q + Vector3(0, 0.02, 0), 0.3, 0.04, osc)
		"hongo":
			_mi(n, _ball, mat(c, 0.6), q + Vector3(0, 0.74, 0), Vector3(0.62, 0.18, 0.55))
			_cil(n, q + Vector3(0, 0.36, 0), 0.14, 0.72, "#fff3e0")
			for i in 6:
				var a := TAU * i / 6.0
				_bola(n, q + Vector3(cos(a) * 0.38, 0.84, sin(a) * 0.32), Vector3(0.07, 0.03, 0.07), "#ffffff")
		_:
			_rb(n, Vector3(1.1, 0.08, 0.8), q + Vector3(0, 0.78, 0), c, 0.03)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_rb(n, Vector3(0.07, 0.76, 0.07), q + Vector3(sx * 0.45, 0.38, sz * 0.3), osc, 0.03)
	_cil(n, q + Vector3(0, 0.86, 0), 0.22, 0.08, "#ffffff")
	_bola(n, q + Vector3(-0.08, 0.95, 0), Vector3.ONE * 0.08, "#ff5a6e", 0.4)
	_bola(n, q + Vector3(0.08, 0.95, 0.04), Vector3.ONE * 0.075, "#ffcf4a", 0.4)
	_bola(n, q + Vector3(0.0, 0.98, -0.07), Vector3.ONE * 0.07, "#8fd16a", 0.4)

## Maceta con planta (cactus, helecho o girasol) junto a la nevera.
func _cocina_planta(n: Node3D, p: Dictionary) -> void:
	_planta(n, Vector3(-0.75, 0, FONDO + 0.45), p)

func _planta(n: Node3D, q: Vector3, p: Dictionary) -> void:
	var f := str(p.get("forma", "nada"))
	if f == "nada":
		return
	var c := str(p.get("c", "#5fae4a"))
	_cil(n, q + Vector3(0, 0.18, 0), 0.17, 0.36, "#e2865a")
	_cil(n, q + Vector3(0, 0.37, 0), 0.19, 0.05, "#c9714a")
	match f:
		"cactus":
			_mi(n, _ball, mat(c), q + Vector3(0, 0.65, 0), Vector3(0.12, 0.32, 0.12))
			for s in [-1.0, 1.0]:
				_mi(n, _ball, mat(c), q + Vector3(s * 0.13, 0.7, 0), Vector3(0.05, 0.12, 0.05))
			_bola(n, q + Vector3(0, 0.98, 0), Vector3.ONE * 0.05, "#ff8fb3")
		"helecho":
			for i in 7:
				var a := TAU * i / 7.0
				_mi(n, _ball, mat(c), q + Vector3(cos(a) * 0.12, 0.55, sin(a) * 0.12), Vector3(0.06, 0.25, 0.03), Vector3(sin(a) * 0.6, a, cos(a) * 0.6))
		"girasol":
			_cil(n, q + Vector3(0, 0.7, 0), 0.025, 0.7, "#5fae4a")
			for i in 12:
				var a := TAU * i / 12.0
				_mi(n, _ball, mat(c), q + Vector3(cos(a) * 0.12, 1.08 + sin(a) * 0.12, 0.03), Vector3(0.06, 0.03, 0.02), Vector3(0, 0, a))
			_cil(n, q + Vector3(0, 1.08, 0.04), 0.08, 0.03, "#7a4b2a", Vector3(PI / 2, 0, 0))

# ================= HABITACIÓN =================
func _habitacion_cama(n: Node3D, p: Dictionary) -> void:
	var q := cama_pos
	var c := str(p.get("c", "#ffc2d6"))
	match str(p.get("forma", "nido")):
		"nube":
			cama_alto = 0.5
			for v in [Vector3(-0.45, 0.3, 0), Vector3(0, 0.33, 0.05), Vector3(0.45, 0.3, 0), Vector3(-0.2, 0.32, -0.3), Vector3(0.25, 0.32, -0.3)]:
				_bola(n, q + v, Vector3(0.42, 0.22, 0.42), "#ffffff", 0.9)
			_bola(n, q + Vector3(0, 0.55, -0.45), Vector3(0.35, 0.14, 0.18), "#dfe9ff")
		"cohete":
			cama_alto = 0.5
			_rb(n, Vector3(1.5, 0.45, 1.0), q + Vector3(0, 0.25, 0), "#e8eef7", 0.18, Vector3.ZERO, 0.4)
			_mi(n, _cone, mat("#ff5a5f", 0.4), q + Vector3(0.95, 0.3, 0), Vector3(0.45, 0.6, 0.45), Vector3(0, 0, -PI / 2))
			for s in [-1.0, 1.0]:
				_rb(n, Vector3(0.35, 0.06, 0.45), q + Vector3(-0.75, 0.2, s * 0.45), "#ff5a5f", 0.03, Vector3(0, s * 0.3, 0))
			_cil(n, q + Vector3(0.2, 0.3, 0.51), 0.12, 0.03, "#7fd8ff", Vector3(PI / 2, 0, 0), 0.2)
			_rb(n, Vector3(1.3, 0.12, 0.85), q + Vector3(0, 0.5, 0), "#7fb8ff", 0.06)
		"concha":
			cama_alto = 0.4
			for i in 7:
				var a := -1.2 + i * 0.4
				_mi(n, _ball, mat(c), q + Vector3(sin(a) * 0.5, 0.55, -0.35 + cos(a) * 0.1), Vector3(0.14, 0.5, 0.08), Vector3(0, 0, -a * 0.8))
			_mi(n, _ball, mat(c), q + Vector3(0, 0.2, 0), Vector3(0.7, 0.2, 0.55))
			_bola(n, q + Vector3(0, 0.38, 0), Vector3(0.6, 0.06, 0.45), "#fff3f7")
			_bola(n, q + Vector3(-0.3, 0.46, -0.2), Vector3.ONE * 0.1, "#f8f4ff", 0.1)
		"hoja":
			cama_alto = 0.32
			_mi(n, _ball, mat(c), q + Vector3(0, 0.15, 0), Vector3(0.8, 0.12, 0.55))
			_rb(n, Vector3(1.4, 0.02, 0.03), q + Vector3(0, 0.28, 0), Color(c).darkened(0.25).to_html(false), 0.01)
			_cil(n, q + Vector3(0.85, 0.15, 0), 0.03, 0.3, "#8d5d32", Vector3(0, 0, PI / 2))
			_bola(n, q + Vector3(-0.4, 0.3, -0.15), Vector3(0.18, 0.08, 0.14), "#fff5e6")
		"castillo":
			cama_alto = 0.48
			_rb(n, Vector3(1.5, 0.45, 1.0), q + Vector3(0, 0.23, 0), c, 0.06)
			_rb(n, Vector3(1.35, 0.1, 0.85), q + Vector3(0, 0.48, 0), "#fff8f0", 0.05)
			for s in [-1.0, 1.0]:
				_cil(n, q + Vector3(s * 0.78, 0.6, -0.45), 0.13, 1.2, c)
				_mi(n, _cone, mat("#7a6ad0"), q + Vector3(s * 0.78, 1.35, -0.45), Vector3(0.17, 0.3, 0.17))
				_rb(n, Vector3(0.16, 0.12, 0.02), q + Vector3(s * 0.78, 0.9, -0.31), "#ffd36e", 0.02)
		_:
			cama_alto = 0.42
			_mi(n, _torus, mat("#a8743f"), q + Vector3(0, 0.25, 0), Vector3(0.75, 0.9, 0.6))
			_mi(n, _torus, mat("#8d5d32"), q + Vector3(0, 0.38, 0), Vector3(0.7, 0.6, 0.55), Vector3(0, 0.4, 0))
			_cil(n, q + Vector3(0, 0.2, 0), 0.6, 0.3, "#8d5d32")
			_bola(n, q + Vector3(0, 0.36, 0), Vector3(0.58, 0.1, 0.46), "#ffe3b8")
			_bola(n, q + Vector3(-0.35, 0.46, -0.1), Vector3(0.2, 0.1, 0.16), "#fff5e6")

func _habitacion_lampara(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(-1.45, 0.62, FONDO + 0.6)
	var c := str(p.get("c", "#ff6b6b"))
	lampara_mat = mat(c, 0.5, 0.8).duplicate()
	match str(p.get("forma", "hongo")):
		"luna":
			_cil(n, q + Vector3(0, 0.03, 0), 0.12, 0.06, "#c9c3e8")
			_cil(n, q + Vector3(0, 0.22, 0), 0.02, 0.36, "#c9c3e8")
			_mi(n, _ball, lampara_mat, q + Vector3(0, 0.55, 0), Vector3.ONE * 0.2)
		"estrella":
			_cil(n, q + Vector3(0, 0.03, 0), 0.12, 0.06, "#b48a62")
			_cil(n, q + Vector3(0, 0.25, 0), 0.02, 0.42, "#b48a62")
			_mi(n, Atuendos.extruir(_estrella(), 0.2), lampara_mat, q + Vector3(0, 0.58, 0), Vector3.ONE * 0.2)
		"lava":
			_cil(n, q + Vector3(0, 0.06, 0), 0.1, 0.12, "#4b4fa8")
			var vi := StandardMaterial3D.new()
			vi.albedo_color = Color(1, 0.85, 0.95, 0.35)
			vi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mi(n, _ball, vi, q + Vector3(0, 0.38, 0), Vector3(0.1, 0.25, 0.1))
			for i in 3:
				_mi(n, _ball, lampara_mat, q + Vector3(sin(i * 2.0) * 0.03, 0.25 + i * 0.12, 0), Vector3.ONE * (0.05 - i * 0.008))
			_cil(n, q + Vector3(0, 0.64, 0), 0.06, 0.06, "#4b4fa8")
		_:
			_cil(n, q + Vector3(0, 0.17, 0), 0.06, 0.34, "#fff1dc")
			var sombrero := _mi(n, _ball, lampara_mat, q + Vector3(0, 0.4, 0), Vector3(0.26, 0.17, 0.26))
			sombrero.position.y = q.y + 0.4
			for i in 5:
				var a := TAU * i / 5.0
				_bola(n, q + Vector3(cos(a) * 0.16, 0.48, sin(a) * 0.16 + 0.02), Vector3(0.04, 0.03, 0.04), "#ffffff")

func _habitacion_alfombra(n: Node3D, p: Dictionary) -> void:
	var c := str(p.get("c", "#ffb3c7"))
	var q := Vector3(0, 0.01, 0.1)
	match str(p.get("forma", "redonda")):
		"estrella":
			_mi(n, Atuendos.extruir(_estrella(), 0.5), mat(c), q, Vector3(1.1, 1.1, 0.02), Vector3(-PI / 2, 0, 0), false)
		"corazon":
			Atuendos._geos()
			_mi(n, Atuendos._heart, mat(c), q, Vector3(1.0, 1.0, 0.05), Vector3(-PI / 2, 0, 0), false)
		"nube":
			for v in [Vector3(-0.5, 0, 0), Vector3(0, 0, -0.1), Vector3(0.5, 0, 0), Vector3(0, 0, 0.25)]:
				_mi(n, _cyl, mat(c), q + v, Vector3(0.55, 0.02, 0.45), Vector3.ZERO, false)
		_:
			_cil(n, q, 1.05, 0.02, c)
			_cil(n, q + Vector3(0, 0.005, 0), 0.8, 0.02, Color(c).lightened(0.3).to_html(false))

# ================= PATIO =================
var cielo_mat: ShaderMaterial

func _fijo_patio(n: Node3D) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 3
	for i in 4:
		_cil(n, Vector3(-0.2 + i * 0.25, 0.012, 1.0 - i * 0.65), 0.2, 0.03, "#d9d4cc")
	for v in [Vector3(1.6, 0.25, -2.0), Vector3(2.1, 0.2, -1.7), Vector3(-2.4, 0.22, -1.4)]:
		_bola(n, v, Vector3(0.45, 0.32, 0.35), "#5fae4a")
	# casita de pájaros
	_cil(n, Vector3(1.9, 0.8, -2.25), 0.04, 1.6, "#a8743f")
	_rb(n, Vector3(0.36, 0.34, 0.3), Vector3(1.9, 1.75, -2.25), "#ffcf6a", 0.04)
	_mi(n, _cone, mat("#e2574c"), Vector3(1.9, 2.04, -2.25), Vector3(0.3, 0.24, 0.24))
	_cil(n, Vector3(1.9, 1.78, -2.09), 0.06, 0.01, "#3a2a20", Vector3(PI / 2, 0, 0))

func _patio_pasto(n: Node3D, p: Dictionary) -> void:
	var c := str(p.get("c", "#8fd16a"))
	_rb(n, Vector3(ANCHO, 0.2, 6.0), Vector3(0, -0.1, -0.5), c, 0.04)
	var cc := Color(c)
	if cc.s < 0.15 or c == "#f5dfa8":
		return   # nieve o arena: sin matas
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 3
	var flores := {"#ffffff": [], "#ffd36e": [], "#ff9fb0": [], "#b9a6ff": []}
	var keys := flores.keys()
	var nf := 90 if c == "#a5de7c" else 40
	for i in nf:
		var q := Vector3(rnd.randf_range(-3.8, 3.8), 0.03, rnd.randf_range(-2.6, 1.6))
		if absf(q.x) < 0.8 and q.z > -0.8:
			continue
		var s := rnd.randf_range(0.035, 0.06)
		flores[keys[i % keys.size()]].append(Transform3D(Basis.from_scale(Vector3(s, s * 0.6, s)), q))
	for k in flores:
		_multi(n, _ball, mat(k), flores[k])
	var mata := []
	for i in 160:
		var q := Vector3(rnd.randf_range(-3.9, 3.9), 0.0, rnd.randf_range(-2.8, 1.6))
		var b := Basis(Vector3.UP, rnd.randf() * TAU).scaled(Vector3(0.03, rnd.randf_range(0.08, 0.16), 0.03))
		mata.append(Transform3D(b, q))
	_multi(n, _cone, mat(cc.darkened(0.12).to_html(false)), mata)

func _patio_fondo(n: Node3D, p: Dictionary) -> void:
	var id := str(p.get("cielo", "dia"))
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform vec4 arriba : source_color;
uniform vec4 abajo : source_color;
uniform float estrellas = 0.0;
uniform float aurora = 0.0;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment(){
	float y = 1.0 - UV.y;
	vec3 c = mix(abajo.rgb, arriba.rgb, smoothstep(0.0, 1.0, y));
	if (aurora > 0.0) {
		float b = sin(UV.x * 9.0 + TIME * 0.4 + sin(UV.x * 3.0 + TIME * 0.2) * 2.0) * 0.06 + 0.62;
		float a = smoothstep(0.09, 0.0, abs(y - b)) * aurora;
		c += mix(vec3(0.2, 1.0, 0.6), vec3(0.7, 0.4, 1.0), UV.x) * a * 0.8;
	}
	if (estrellas > 0.0) {
		vec2 g = UV * vec2(90.0, 60.0);
		vec2 id = floor(g);
		float r = h(id);
		float d = length(fract(g) - 0.5);
		float tw = 0.6 + 0.4 * sin(TIME * (1.0 + r * 3.0) + r * 20.0);
		c += vec3(smoothstep(0.12, 0.0, d) * step(0.93, r) * tw * estrellas * smoothstep(0.2, 0.6, y));
	}
	ALBEDO = c;
}"""
	cielo_mat = ShaderMaterial.new()
	cielo_mat.shader = sh
	var cols := {"dia": ["#7cc4ff", "#e4f5ff", 0.0, 0.0], "atardecer": ["#7b5cff", "#ffb38a", 0.25, 0.0],
		"noche": ["#0d1340", "#3a3f8f", 1.0, 0.0], "galaxia": ["#1a0b3d", "#6a2c91", 1.0, 0.0],
		"aurora": ["#071a35", "#1d3a5c", 0.8, 1.0], "nublado": ["#9fb3c8", "#e3eaf2", 0.0, 0.0],
		"amanecer": ["#8fb8ff", "#ffc9a8", 0.0, 0.0], "dulce": ["#ffb8e1", "#b8f0ff", 0.0, 0.0]}
	var cc: Array = cols.get(id, cols.dia)
	cielo_mat.set_shader_parameter("arriba", Color(cc[0]))
	cielo_mat.set_shader_parameter("abajo", Color(cc[1]))
	cielo_mat.set_shader_parameter("estrellas", cc[2])
	cielo_mat.set_shader_parameter("aurora", cc[3])
	var qm := QuadMesh.new()
	qm.size = Vector2(30, 14)
	_mi(n, qm, cielo_mat, Vector3(0, 5.5, -9.0), Vector3.ONE, Vector3.ZERO, false)
	var colina := {"dia": "#79b960", "atardecer": "#8a6aa8", "noche": "#2c3a6a", "galaxia": "#3a2468", "aurora": "#1f3550",
		"nublado": "#7fa06a", "amanecer": "#8fbf72", "dulce": "#ff9fd0"}
	for q in [Vector3(-4.0, -1.2, -7.5), Vector3(1.5, -1.6, -7.8), Vector3(5.5, -1.3, -7.6)]:
		_bola(n, q, Vector3(4.0, 2.6, 1.0), str(colina.get(id, "#79b960")), 1.0)
	match id:
		"dia", "amanecer":
			var sol := Vector3(2.4, 5.2, -8.5) if id == "dia" else Vector3(-2.0, 2.6, -8.5)
			_bola(n, sol, Vector3.ONE * 0.6, "#fff2a8" if id == "dia" else "#ffd08a", 0.5, 2.0)
			for c in [Vector3(-2.5, 4.6, -8.0), Vector3(0.3, 5.6, -8.2)]:
				_nube(n, c, "#ffffff")
		"atardecer":
			_bola(n, Vector3(-1.8, 2.2, -8.5), Vector3.ONE * 0.9, "#ffcf80", 0.5, 1.6)
			for k in 3:
				_bola(n, Vector3(1.0 + k * 0.6, 4.4, -8.2), Vector3(0.6, 0.18, 0.2), "#ffb0c8", 1.0, 0.3)
		"noche", "aurora":
			_bola(n, Vector3(2.0, 5.0, -8.5), Vector3.ONE * 0.55, "#fff6d8", 0.5, 1.5)
			_bola(n, Vector3(2.25, 5.15, -8.4), Vector3.ONE * 0.5, str(cc[0]), 1.0)
		"galaxia":
			_bola(n, Vector3(-2.2, 5.3, -8.6), Vector3.ONE * 0.8, "#ff9a6b", 0.6, 0.5)
			_mi(n, _torus, mat("#ffd9a8", 0.6, 0.6), Vector3(-2.2, 5.3, -8.6), Vector3(1.3, 0.2, 1.3), Vector3(0.4, 0, 0.3), false)
			_bola(n, Vector3(2.6, 4.2, -8.6), Vector3.ONE * 0.4, "#7fd8ff", 0.6, 0.6)
			_mi(n, Atuendos.extruir(_estrella(), 0.1), mat("#fff3c4", 0.5, 3.0), Vector3(0.6, 6.0, -8.5), Vector3.ONE * 0.35, Vector3.ZERO, false)
		"nublado":
			for c in [Vector3(-3.0, 4.2, -8.0), Vector3(-0.5, 5.4, -8.2), Vector3(2.2, 4.6, -8.1), Vector3(4.0, 5.8, -8.3)]:
				_nube(n, c, "#f4f6fa")
		"dulce":
			for c in [Vector3(-2.5, 4.4, -8.0), Vector3(1.8, 5.4, -8.2)]:
				_nube(n, c, "#fff0f8")
			_mi(n, _torus, mat("#ff8fb3", 0.6, 0.4), Vector3(0.5, 2.0, -8.6), Vector3(3.5, 0.6, 3.5), Vector3(PI / 2, 0, 0), false)
			_mi(n, _torus, mat("#ffe08a", 0.6, 0.4), Vector3(0.5, 2.0, -8.55), Vector3(3.2, 0.6, 3.2), Vector3(PI / 2, 0, 0), false)
			_mi(n, _torus, mat("#a8e6ff", 0.6, 0.4), Vector3(0.5, 2.0, -8.5), Vector3(2.9, 0.6, 2.9), Vector3(PI / 2, 0, 0), false)

func _nube(n: Node3D, c: Vector3, col: String) -> void:
	for k in 4:
		_bola(n, c + Vector3(k * 0.45 - 0.7, sin(k * 1.3) * 0.12, 0), Vector3(0.55, 0.36, 0.2), col, 1.0, 0.4)

func _patio_cerca(n: Node3D, p: Dictionary) -> void:
	var z := -2.7
	var c := str(p.get("c", "#ffffff"))
	match str(p.get("forma", "estacas")):
		"troncos":
			for i in 17:
				_cil(n, Vector3(-4.0 + i * 0.5, 0.45, z), 0.09, 0.9, c)
			for y in [0.35, 0.7]:
				_cil(n, Vector3(0, y, z + 0.08), 0.05, ANCHO, Color(c).darkened(0.15).to_html(false), Vector3(0, 0, PI / 2))
		"seto":
			for i in 9:
				_bola(n, Vector3(-4.0 + i * 1.0, 0.5, z), Vector3(0.62, 0.55, 0.4), c, 0.95)
		"piedra":
			var rnd := RandomNumberGenerator.new()
			rnd.seed = 9
			for f in 3:
				for i in 14:
					var s := rnd.randf_range(0.22, 0.3)
					_mi(n, _ball, mat(Color(c).lightened(rnd.randf_range(-0.1, 0.1)).to_html(false)),
						Vector3(-3.9 + i * 0.6 + (0.3 if f % 2 else 0.0), 0.18 + f * 0.27, z), Vector3(s * 1.2, s * 0.6, 0.2))
		_:
			var xs: Array = []
			for i in 27:
				xs.append(Transform3D(Basis.from_scale(Vector3(0.14, 0.8, 0.05)), Vector3(-3.9 + i * 0.3, 0.4, z)))
			_multi(n, rbox_mesh(Vector3.ONE, 0.2), mat(c), xs, true)
			for y in [0.3, 0.62]:
				_rb(n, Vector3(ANCHO, 0.07, 0.04), Vector3(0, y, z - 0.05), Color(c).darkened(0.05).to_html(false), 0.02)

func _patio_arbol(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(-1.75, 0, -1.6)
	var c := str(p.get("c", "#5fae4a"))
	var cc := Color(c)
	match str(p.get("forma", "redondo")):
		"pino":
			_cil(n, q + Vector3(0, 0.5, 0), 0.12, 1.0, "#7a4b2a")
			for i in 4:
				_mi(n, _cone, mat(cc.darkened(i * 0.05).to_html(false)), q + Vector3(0, 1.1 + i * 0.45, 0), Vector3(0.75 - i * 0.14, 0.7, 0.75 - i * 0.14))
		"palmera":
			for i in 8:
				_cil(n, q + Vector3(sin(i * 0.15) * 0.2 * i * 0.15, 0.15 + i * 0.3, 0), 0.12 - i * 0.006, 0.3, "#b0844f", Vector3(0, 0, -i * 0.04))
			for i in 6:
				var a := TAU * i / 6.0
				_mi(n, _ball, mat(c), q + Vector3(0.35 + cos(a) * 0.45, 2.45, sin(a) * 0.45), Vector3(0.5, 0.06, 0.14), Vector3(0, -a, -0.35))
			for i in 3:
				_bola(n, q + Vector3(0.3 + (i - 1) * 0.1, 2.3, 0.08), Vector3.ONE * 0.08, "#7a4b2a")
		_:
			_cil(n, q + Vector3(0, 0.9, 0), 0.16, 1.8, "#8d5d32")
			_cil(n, q + Vector3(0.25, 1.5, 0), 0.06, 0.6, "#8d5d32", Vector3(0, 0, -0.8))
			var bolas := [Vector3(0, 2.3, 0), Vector3(-0.5, 2.0, 0.1), Vector3(0.5, 2.05, 0.05), Vector3(-0.2, 2.75, -0.1), Vector3(0.3, 2.6, 0.2)]
			for i in bolas.size():
				var col := cc.lightened(0.08 * (i % 3) - 0.04).to_html(false)
				var m := mat(col, 0.95, 0.35 if c == "#b49cff" else 0.0)
				_mi(n, _ball, m, q + bolas[i], Vector3.ONE * (0.55 - i * 0.03))
			if c == "#ffc2d6" or c == "#ff9f43":
				var rnd := RandomNumberGenerator.new()
				rnd.seed = 5
				var xs: Array = []
				for i in 25:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.035, 0.008, 0.035)), q + Vector3(rnd.randf_range(-1.2, 1.4), 0.012, rnd.randf_range(-0.6, 1.4))))
				_multi(n, _ball, mat(c), xs)
			elif c == "#b49cff":
				for i in 8:
					_bola(n, q + Vector3(sin(i * 1.7) * 0.6, 2.0 + cos(i * 2.3) * 0.5, 0.5), Vector3.ONE * 0.04, "#fff3c4", 0.5, 2.0)
			else:
				_bola(n, q + Vector3(0.35, 2.2, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)
				_bola(n, q + Vector3(-0.4, 1.9, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)

## Juegos del patio (lado derecho).
func _patio_juguete(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(1.85, 0, -0.9)
	var c := str(p.get("c", "#ff6b6b"))
	match str(p.get("forma", "nada")):
		"columpio":
			for s in [-1.0, 1.0]:
				_cil(n, q + Vector3(s * 0.55, 0.8, 0), 0.04, 1.6, "#8d5d32", Vector3(0, 0, s * 0.12))
			_cil(n, q + Vector3(0, 1.6, 0), 0.04, 1.3, "#8d5d32", Vector3(0, 0, PI / 2))
			for s in [-1.0, 1.0]:
				_cil(n, q + Vector3(s * 0.2, 1.15, 0), 0.008, 0.9, "#cfd6e2")
			_rb(n, Vector3(0.5, 0.05, 0.22), q + Vector3(0, 0.7, 0), c, 0.02)
		"tobogan":
			_rb(n, Vector3(0.4, 1.0, 0.4), q + Vector3(0.35, 0.5, -0.3), "#ffcf4a", 0.05)
			_rb(n, Vector3(0.36, 0.05, 1.3), q + Vector3(0.35, 0.55, 0.25), c, 0.02, Vector3(-0.75, 0, 0))
		"piscina":
			_cil(n, q + Vector3(0, 0.15, 0.1), 0.6, 0.3, c)
			var ag := StandardMaterial3D.new()
			ag.albedo_color = Color(0.55, 0.85, 1.0, 0.85)
			ag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ag.roughness = 0.05
			_mi(n, _cyl, ag, q + Vector3(0, 0.25, 0.1), Vector3(0.53, 0.04, 0.53), Vector3.ZERO, false)
			_mi(n, _torus, mat("#ff8fb3"), q + Vector3(0.2, 0.3, 0.2), Vector3(0.15, 0.4, 0.15))
		"casita":
			_rb(n, Vector3(0.7, 0.55, 0.6), q + Vector3(0, 0.28, -0.3), c, 0.05)
			_mi(n, _cone, mat("#7a4b2a"), q + Vector3(0, 0.72, -0.3), Vector3(0.55, 0.35, 0.45), Vector3(0, PI / 4, 0))
			_cil(n, q + Vector3(0, 0.22, 0.0), 0.14, 0.02, "#3a2a20", Vector3(PI / 2, 0, 0))
		"telescopio":
			for i in 3:
				var a := TAU * i / 3.0
				_cil(n, q + Vector3(cos(a) * 0.15, 0.35, sin(a) * 0.15), 0.02, 0.75, "#3a3d4a", Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25))
			_cil(n, q + Vector3(0, 0.85, 0), 0.08, 0.6, c, Vector3(0.9, 0, 0.3))
			_cil(n, q + Vector3(0.08, 1.05, -0.22), 0.1, 0.06, "#ffd36e", Vector3(0.9, 0, 0.3))

# ================= BAÑO =================
func _bano_banera(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(1.45, 0, -1.55)
	var c := str(p.get("c", "#ffffff"))
	var patas := str(p.get("patas", ""))
	var y0 := 0.0
	if patas != "":
		y0 = 0.15
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_bola(n, q + Vector3(sx * 0.7, 0.09, sz * 0.3), Vector3(0.1, 0.09, 0.1), patas, 0.25)
	_rb(n, Vector3(1.9, 0.75, 0.95), q + Vector3(0, y0 + 0.375, 0), c, 0.3, Vector3.ZERO, 0.25)
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.55, 0.82, 1.0, 0.85)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.05
	agua.metallic_specular = 1.0
	_mi(n, rbox_mesh(Vector3(1.7, 0.04, 0.75), 0.02), agua, q + Vector3(0, y0 + 0.72, 0), Vector3.ONE, Vector3.ZERO, false)
	for i in 6:
		_bola(n, q + Vector3(-0.6 + i * 0.25, y0 + 0.76, sin(i * 1.7) * 0.2), Vector3.ONE * (0.08 + (i % 3) * 0.03), "#ffffff", 0.9)
	_bola(n, q + Vector3(0.5, y0 + 0.82, 0.1), Vector3(0.11, 0.09, 0.13), "#ffd84a", 0.4)
	_bola(n, q + Vector3(0.5, y0 + 0.95, 0.17), Vector3.ONE * 0.065, "#ffd84a", 0.4)
	_bola(n, q + Vector3(0.5, y0 + 0.94, 0.24), Vector3(0.035, 0.015, 0.03), "#ff8c3a", 0.4)

func _bano_cortina(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(1.45, 0, -1.55)
	var c1 := str(p.get("c1", "#7fc8ff"))
	var c2 := str(p.get("c2", "#ffffff"))
	var forma := str(p.get("forma", "rayas"))
	_cil(n, q + Vector3(0, 2.55, 0.5), 0.025, 2.2, "#c9d1dc", Vector3(0, 0, PI / 2), 0.2)
	for i in 8:
		var x := q.x - 0.95 + i * 0.09
		var z := q.z + 0.5 + (0.035 if i % 2 else -0.035)
		var col := (c1 if i % 2 == 0 else c2) if forma == "rayas" else c1
		_rb(n, Vector3(0.1, 1.6, 0.04), Vector3(x, 1.75, z), col, 0.02, Vector3(0, (0.3 if i % 2 else -0.3), 0))
	if forma == "burbujas":
		for i in 6:
			_bola(n, Vector3(q.x - 0.95 + (i % 3) * 0.25, 1.4 + (i / 3) * 0.6, q.z + 0.56), Vector3.ONE * 0.05, c2, 0.2)
	elif forma == "estrellas":
		for i in 5:
			_mi(n, Atuendos.extruir(_estrella(), 0.1), mat(c2, 0.5, 0.6), Vector3(q.x - 0.9 + (i % 2) * 0.3, 1.2 + i * 0.25, q.z + 0.57), Vector3.ONE * 0.06)

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


func _fijo_bano(n: Node3D) -> void:
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

