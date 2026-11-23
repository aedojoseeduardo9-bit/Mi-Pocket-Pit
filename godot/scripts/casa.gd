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
		_h = h
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
	_h = h
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
		"acuario":
			# un acuario empotrado con peces que nadan y burbujas
			var vid := StandardMaterial3D.new()
			vid.albedo_color = Color(0.35, 0.7, 1.0, 0.9)
			vid.emission_enabled = true
			vid.emission = Color("#3a8fd6")
			vid.emission_energy_multiplier = 0.5
			_rb(n, Vector3(3.2, 1.6, 0.12), Vector3(0, 2.6, FONDO + 0.02), c2, 0.06)
			_mi(n, BoxMesh.new(), vid, Vector3(0, 2.6, FONDO + 0.09), Vector3(3.0, 1.4, 0.02), Vector3.ZERO, false)
			for i in 6:
				_bola(n, Vector3(-1.3 + i * 0.5, 1.95, FONDO + 0.1), Vector3(0.12, 0.08 + (i % 2) * 0.05, 0.02), "#4cae4c")
			var pez_c := ["#ff9f43", "#ffcf4a", "#ff6b9a", "#7fffd4"]
			for i in 4:
				var pez := Node3D.new()
				pez.position = Vector3(0, 2.25 + i * 0.22, FONDO + 0.11)
				n.add_child(pez)
				_bola(pez, Vector3.ZERO, Vector3(0.1, 0.06, 0.02), pez_c[i], 0.4)
				_mi(pez, _cone, mat(pez_c[i]), Vector3(-0.11, 0, 0), Vector3(0.05, 0.07, 0.015), Vector3(0, 0, PI / 2))
				_bola(pez, Vector3(0.05, 0.015, 0.012), Vector3.ONE * 0.012, "#1e1410")
				efecto(pez, "nadar", 0.7 + i * 0.25)
			particulas_en(n, Vector3(0.8, 2.0, FONDO + 0.12), "burbujas", 8, 0.1)
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
	_rb(n, Vector3(ANCHO, 0.2, 10.0), Vector3(0, -0.1, 2.5), c1, 0.04)
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
	if p.get("magia", false):
		# nevera mágica: borde de luz que late y destellos
		var lm := mat(c, 0.4, 0.8).duplicate()
		var marco := _mi(n, rbox_mesh(Vector3(1.0, 2.15, 0.06), 0.08), lm, Vector3(x, 1.06, z + 0.37))
		efecto(marco, "titilar", 0.6, lm)
		particulas_en(n, Vector3(x, 1.2, z + 0.5), "brillos", 14, 0.5)

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
		"dulces":
			_cil(n, q + Vector3(0, 0.78, 0), 0.55, 0.06, c, Vector3.ZERO, 0.4)
			_cil(n, q + Vector3(0, 0.4, 0), 0.06, 0.76, osc)
			# pastel con vela encendida
			_cil(n, q + Vector3(0, 0.92, 0), 0.24, 0.22, "#ffc2d6")
			_cil(n, q + Vector3(0, 1.04, 0), 0.25, 0.04, "#fff3f7")
			for i in 8:
				var a := TAU * i / 8.0
				_bola(n, q + Vector3(cos(a) * 0.2, 1.07, sin(a) * 0.2), Vector3.ONE * 0.03, "#ff4d6d", 0.3)
			_cil(n, q + Vector3(0, 1.13, 0), 0.015, 0.14, "#7fc8ff")
			var fm := mat("#ffb347", 0.5, 2.5).duplicate()
			var llama := _mi(n, _ball, fm, q + Vector3(0, 1.23, 0), Vector3(0.022, 0.045, 0.022), Vector3.ZERO, false)
			efecto(llama, "llama", 1.0, fm)
			return
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
		"girasol", "flor_magica":
			var tallo := Node3D.new()
			tallo.position = q + Vector3(0, 0.37, 0)
			n.add_child(tallo)
			_cil(tallo, Vector3(0, 0.33, 0), 0.025, 0.7, "#5fae4a")
			var magia := f == "flor_magica"
			var pm: StandardMaterial3D = mat(c, 0.6, 1.2).duplicate() if magia else mat(c)
			for i in 12:
				var a := TAU * i / 12.0
				_mi(tallo, _ball, pm, Vector3(cos(a) * 0.12, 0.71 + sin(a) * 0.12, 0.03), Vector3(0.06, 0.03, 0.02), Vector3(0, 0, a))
			_cil(tallo, Vector3(0, 0.71, 0.04), 0.08, 0.03, "#7a4b2a" if not magia else "#fff3c4", Vector3(PI / 2, 0, 0))
			efecto(tallo, "balancear", 0.6, pm if magia else null)
			if magia:
				particulas_en(n, q + Vector3(0, 1.1, 0), "luciernagas", 10, 0.3)

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
		"nube_magica":
			cama_alto = 0.55
			var g := Node3D.new()
			n.add_child(g)
			for v in [Vector3(-0.45, 0.35, 0), Vector3(0, 0.38, 0.05), Vector3(0.45, 0.35, 0), Vector3(-0.2, 0.37, -0.3), Vector3(0.25, 0.37, -0.3)]:
				_bola(g, q + v, Vector3(0.42, 0.22, 0.42), "#f4ecff", 0.9, 0.25)
			efecto(g, "flotar_suave")
			particulas_en(n, q + Vector3(0, 0.9, 0), "brillos", 18, 0.8, "#c9b8ff")
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
			efecto(_mi(n, _ball, lampara_mat, q + Vector3(0, 0.55, 0), Vector3.ONE * 0.2), "latir", 0.8)
		"estrella":
			_cil(n, q + Vector3(0, 0.03, 0), 0.12, 0.06, "#b48a62")
			_cil(n, q + Vector3(0, 0.25, 0), 0.02, 0.42, "#b48a62")
			efecto(_mi(n, Atuendos.extruir(_estrella(), 0.2), lampara_mat, q + Vector3(0, 0.58, 0), Vector3.ONE * 0.2), "girar", 0.8)
		"disco":
			_cil(n, q + Vector3(0, 0.03, 0), 0.12, 0.06, "#3a3d4a")
			_cil(n, q + Vector3(0, 0.25, 0), 0.015, 0.42, "#c9d1dc")
			var esp := StandardMaterial3D.new()
			esp.albedo_color = Color("#e8eef7")
			esp.metallic = 1.0
			esp.roughness = 0.15
			esp.emission_enabled = true
			esp.emission = Color("#b49cff")
			esp.emission_energy_multiplier = 0.4
			var bola := _mi(n, _ball, esp, q + Vector3(0, 0.6, 0), Vector3.ONE * 0.17)
			efecto(bola, "girar", 2.0, esp)
			particulas_en(n, q + Vector3(0.8, 1.6, 0.6), "brillos", 22, 1.6, "#ff8fe0")
		"lava":
			_cil(n, q + Vector3(0, 0.06, 0), 0.1, 0.12, "#4b4fa8")
			var vi := StandardMaterial3D.new()
			vi.albedo_color = Color(1, 0.85, 0.95, 0.35)
			vi.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mi(n, _ball, vi, q + Vector3(0, 0.38, 0), Vector3(0.1, 0.25, 0.1))
			for i in 3:
				efecto(_mi(n, _ball, lampara_mat, q + Vector3(sin(i * 2.0) * 0.03, 0.25 + i * 0.12, 0), Vector3.ONE * (0.05 - i * 0.008)), "flotar", 0.6 + i * 0.3)
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
		"arcoiris":
			var cols := ["#ff6b6b", "#ffb347", "#ffe066", "#7be08a", "#6fb8ff", "#b49cff"]
			for i in cols.size():
				_cil(n, q + Vector3(0, i * 0.003, 0), 1.1 - i * 0.16, 0.02, cols[i])
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
	_rb(n, Vector3(ANCHO, 0.2, 11.0), Vector3(0, -0.1, 2.0), c, 0.04)
	var cc := Color(c)
	if cc.s < 0.15:
		particulas_en(n, Vector3(0, 3.6, -0.6), "nieve", 70, 3.4)
		return   # nieve: copos cayendo, sin matas
	if c == "#f5dfa8":
		return   # arena: sin matas
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
	var cols := {"lluvia_estrellas": ["#060a2a", "#2b2266", 1.0, 0.0], "dia": ["#7cc4ff", "#e4f5ff", 0.0, 0.0], "atardecer": ["#7b5cff", "#ffb38a", 0.25, 0.0],
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
	var colina := {"lluvia_estrellas": "#1d2450", "dia": "#79b960", "atardecer": "#8a6aa8", "noche": "#2c3a6a", "galaxia": "#3a2468", "aurora": "#1f3550",
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
			particulas_en(n, Vector3(0, 0.8, -1.2), "luciernagas", 24, 3.0)
		"lluvia_estrellas":
			for i in 4:
				_fugaz(n, Vector3(4.0 + i * 1.5, 7.0 - i * 0.5, -8.4), 0.8 + i * 0.25)
			particulas_en(n, Vector3(0, 0.9, -1.2), "luciernagas", 18, 3.0, "#c9e4ff")
		"galaxia":
			_bola(n, Vector3(-2.2, 5.3, -8.6), Vector3.ONE * 0.8, "#ff9a6b", 0.6, 0.5)
			_mi(n, _torus, mat("#ffd9a8", 0.6, 0.6), Vector3(-2.2, 5.3, -8.6), Vector3(1.3, 0.2, 1.3), Vector3(0.4, 0, 0.3), false)
			_bola(n, Vector3(2.6, 4.2, -8.6), Vector3.ONE * 0.4, "#7fd8ff", 0.6, 0.6)
			_mi(n, Atuendos.extruir(_estrella(), 0.1), mat("#fff3c4", 0.5, 3.0), Vector3(0.6, 6.0, -8.5), Vector3.ONE * 0.35, Vector3.ZERO, false)
			_fugaz(n, Vector3(5.0, 6.6, -8.4), 1.0)
			_fugaz(n, Vector3(7.0, 5.8, -8.4), 0.7)
		"nublado":
			for c in [Vector3(-3.0, 4.2, -8.0), Vector3(-0.5, 5.4, -8.2), Vector3(2.2, 4.6, -8.1), Vector3(4.0, 5.8, -8.3)]:
				_nube(n, c, "#f4f6fa")
		"dulce":
			for c in [Vector3(-2.5, 4.4, -8.0), Vector3(1.8, 5.4, -8.2)]:
				_nube(n, c, "#fff0f8")
			_mi(n, _torus, mat("#ff8fb3", 0.6, 0.4), Vector3(0.5, 2.0, -8.6), Vector3(3.5, 0.6, 3.5), Vector3(PI / 2, 0, 0), false)
			_mi(n, _torus, mat("#ffe08a", 0.6, 0.4), Vector3(0.5, 2.0, -8.55), Vector3(3.2, 0.6, 3.2), Vector3(PI / 2, 0, 0), false)
			_mi(n, _torus, mat("#a8e6ff", 0.6, 0.4), Vector3(0.5, 2.0, -8.5), Vector3(2.9, 0.6, 2.9), Vector3(PI / 2, 0, 0), false)

## Estrella fugaz: una estela brillante que cruza el cielo de vez en cuando.
func _fugaz(n: Node3D, p: Vector3, vel: float) -> void:
	var g := Node3D.new()
	g.position = p
	n.add_child(g)
	_mi(g, _ball, mat("#fff8d8", 0.5, 4.0), Vector3.ZERO, Vector3(0.09, 0.09, 0.09), Vector3.ZERO, false)
	_mi(g, _cone, mat("#bfd8ff", 0.5, 2.0), Vector3(0.6, 0.2, 0), Vector3(0.06, 1.2, 0.06), Vector3(0, 0, PI / 2 + 0.32), false)
	efecto(g, "estrella_fugaz", vel)

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
				particulas_en(n, q + Vector3(0, 2.6, 0.3), "petalos", 18, 0.9, "#ffc2d6" if c == "#ffc2d6" else "#ff9f43")
				var rnd := RandomNumberGenerator.new()
				rnd.seed = 5
				var xs: Array = []
				for i in 25:
					xs.append(Transform3D(Basis.from_scale(Vector3(0.035, 0.008, 0.035)), q + Vector3(rnd.randf_range(-1.2, 1.4), 0.012, rnd.randf_range(-0.6, 1.4))))
				_multi(n, _ball, mat(c), xs)
			elif c == "#b49cff":
				particulas_en(n, q + Vector3(0, 2.2, 0.3), "brillos", 20, 0.9, "#e2d6ff")
				for i in 8:
					_bola(n, q + Vector3(sin(i * 1.7) * 0.6, 2.0 + cos(i * 2.3) * 0.5, 0.5), Vector3.ONE * 0.04, "#fff3c4", 0.5, 2.0)
			else:
				_bola(n, q + Vector3(0.35, 2.2, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)
				_bola(n, q + Vector3(-0.4, 1.9, 0.45), Vector3(0.07, 0.09, 0.07), "#c58a4a", 0.4)

## Juegos del patio (lado derecho).
func _patio_juguete(n: Node3D, p: Dictionary) -> void:
	var q := Vector3(1.4, 0, -1.25)
	var c := str(p.get("c", "#ff6b6b"))
	match str(p.get("forma", "nada")):
		"columpio":
			for s in [-1.0, 1.0]:
				_cil(n, q + Vector3(s * 0.55, 0.8, 0), 0.04, 1.6, "#8d5d32", Vector3(0, 0, s * 0.12))
			_cil(n, q + Vector3(0, 1.6, 0), 0.04, 1.3, "#8d5d32", Vector3(0, 0, PI / 2))
			var col := Node3D.new()
			col.position = q + Vector3(0, 1.6, 0)
			n.add_child(col)
			for s in [-1.0, 1.0]:
				_cil(col, Vector3(s * 0.2, -0.45, 0), 0.008, 0.9, "#cfd6e2")
			_rb(col, Vector3(0.5, 0.05, 0.22), Vector3(0, -0.9, 0), c, 0.02)
			efecto(col, "columpio", 1.0)
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
			efecto(_mi(n, _torus, mat("#ff8fb3"), q + Vector3(0.2, 0.3, 0.2), Vector3(0.15, 0.4, 0.15)), "flotar_suave")
		"fuente":
			_cil(n, q + Vector3(0, 0.15, 0.1), 0.55, 0.3, c)
			var ag := StandardMaterial3D.new()
			ag.albedo_color = Color(0.55, 0.85, 1.0, 0.85)
			ag.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			_mi(n, _cyl, ag, q + Vector3(0, 0.26, 0.1), Vector3(0.48, 0.04, 0.48), Vector3.ZERO, false)
			_cil(n, q + Vector3(0, 0.55, 0.1), 0.06, 0.6, c)
			_cil(n, q + Vector3(0, 0.85, 0.1), 0.22, 0.08, c)
			particulas_en(n, q + Vector3(0, 0.9, 0.1), "agua", 40, 0.03)
		"fogata":
			for i in 5:
				_cil(n, q + Vector3(0, 0.06, 0.1), 0.05, 0.55, "#7a4b2a", Vector3(PI / 2, TAU * i / 5.0, 0))
			for i in 7:
				var a := TAU * i / 7.0
				_bola(n, q + Vector3(cos(a) * 0.32, 0.05, sin(a) * 0.32 + 0.1), Vector3(0.09, 0.06, 0.08), "#9aa0ad")
			for k in 3:
				var fm := mat(["#ff7a2e", "#ffb347", "#ffe066"][k], 0.5, 2.5).duplicate()
				var fl := _mi(n, _cone, fm, q + Vector3((k - 1) * 0.05, 0.22 + k * 0.03, 0.1), Vector3(0.12 - k * 0.03, 0.36 - k * 0.06, 0.12 - k * 0.03), Vector3.ZERO, false)
				efecto(fl, "llama", 1.0, fm)
			particulas_en(n, q + Vector3(0, 0.4, 0.1), "chispas", 16)
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
	var pato := Node3D.new()
	pato.position = q + Vector3(0.5, y0 + 0.82, 0.1)
	n.add_child(pato)
	_bola(pato, Vector3.ZERO, Vector3(0.11, 0.09, 0.13), "#ffd84a", 0.4)
	_bola(pato, Vector3(0, 0.13, 0.07), Vector3.ONE * 0.065, "#ffd84a", 0.4)
	_bola(pato, Vector3(0, 0.12, 0.14), Vector3(0.035, 0.015, 0.03), "#ff8c3a", 0.4)
	efecto(pato, "flotar_suave")
	var jac: bool = p.get("jacuzzi", false)
	particulas_en(n, q + Vector3(0, y0 + 0.74, 0), "burbujas", 30 if jac else 10, 0.7)
	if jac:
		var lz := mat("#7fd8ff", 0.4, 1.0).duplicate()
		var luz := _mi(n, rbox_mesh(Vector3(1.6, 0.02, 0.7), 0.02), lz, q + Vector3(0, y0 + 0.705, 0), Vector3.ONE, Vector3.ZERO, false)
		efecto(luz, "titilar", 0.5, lz)

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
	elif forma == "luces":
		# guirnalda de luces que titilan a lo largo de la barra y bajando por la cortina
		var cols := ["#ff8fb3", "#ffe066", "#7fd8ff", "#b49cff", "#7be08a"]
		for i in 14:
			var lm := mat(cols[i % cols.size()], 0.4, 1.5).duplicate()
			var y := 2.5 - absf(sin(i * 0.45)) * 0.12
			var b := _mi(n, _ball, lm, Vector3(q.x - 1.0 + i * 0.15, y, q.z + 0.56), Vector3(0.028, 0.038, 0.028), Vector3.ZERO, false)
			efecto(b, "titilar", 0.6 + (i % 4) * 0.35, lm)

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
	particulas_en(n, Vector3(0.75, 1.42, FONDO + 0.45), "vapor", 10, 0.06)
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



# ================= EFECTOS (animaciones y partículas de la decoración) =================
## Cada efecto se registra con su habitación: solo se animan los de la habitación donde está Pip (ahorra batería).
var efectos: Array = []          ## {n, tipo, h, x, rot, pos, sc, mat, fase}
var particulas: Array = []       ## [CPUParticles3D, hab]
var hab_activa := "habitacion"
var t_fx := 0.0
var _h := ""                     ## habitación que se está armando
var _pmats := {}
var _pmesh := {}

func efecto(n: Node3D, tipo: String, x := 1.0, m: StandardMaterial3D = null) -> void:
	efectos.append({"n": n, "tipo": tipo, "h": _h, "x": x, "rot": n.rotation, "pos": n.position, "sc": n.scale, "mat": m,
		"fase": randf() * TAU})

func _process(dt: float) -> void:
	t_fx += dt
	var i := efectos.size() - 1
	while i >= 0:
		var e: Dictionary = efectos[i]
		if not is_instance_valid(e.n):
			efectos.remove_at(i)
			i -= 1
			continue
		if e.h == hab_activa:
			_animar(e)
		i -= 1

func _animar(e: Dictionary) -> void:
	var n: Node3D = e.n
	var t: float = t_fx + e.fase
	var x: float = e.x
	match e.tipo:
		"girar":
			n.rotation.y = (e.rot as Vector3).y + t_fx * x
		"balancear":
			n.rotation.z = (e.rot as Vector3).z + sin(t * 1.6) * 0.12 * x
		"columpio":
			n.rotation.x = (e.rot as Vector3).x + sin(t * 1.8) * 0.35 * x
		"flotar":
			n.position.y = (e.pos as Vector3).y + sin(t * 1.3 * x) * 0.05
		"flotar_suave":
			n.position.y = (e.pos as Vector3).y + sin(t * 1.1) * 0.02
			n.rotation.z = (e.rot as Vector3).z + sin(t * 0.9) * 0.06
		"latir":
			n.scale = (e.sc as Vector3) * (1.0 + sin(t * 2.0 * x) * 0.04)
		"nadar":
			var k := fposmod(t_fx * 0.12 * x + e.fase, 1.0)
			var dir := 1.0 if int(floor(t_fx * 0.12 * x + e.fase)) % 2 == 0 else -1.0
			var px := lerpf(-1.2, 1.2, k) if dir > 0 else lerpf(1.2, -1.2, k)
			n.position = (e.pos as Vector3) + Vector3(px, sin(t * 2.0) * 0.05, 0)
			n.rotation.y = 0.0 if dir > 0 else PI
		"estrella_fugaz":
			var c := fposmod(t_fx * 0.25 * x + e.fase, 1.0)
			n.visible = c < 0.25
			n.position = (e.pos as Vector3) + Vector3(-c * 18.0, -c * 6.0, 0)
		"llama":
			n.scale = (e.sc as Vector3) * Vector3(1.0 + randf() * 0.12, 0.85 + randf() * 0.35, 1.0)
	var m = e.mat
	if m != null:
		var mm := m as StandardMaterial3D
		match e.tipo:
			"llama":
				mm.emission_energy_multiplier = 1.4 + randf() * 1.0
			"titilar":
				mm.emission_energy_multiplier = 0.5 + 1.5 * (0.5 + 0.5 * sin(t * 3.0 * x))
			_:
				mm.emission_energy_multiplier = 0.7 + 0.6 * (0.5 + 0.5 * sin(t * 1.6))

## Activa solo las partículas de la habitación donde está Pip.
func activar(h: String) -> void:
	hab_activa = h
	var i := particulas.size() - 1
	while i >= 0:
		var pe = particulas[i][0]
		if not is_instance_valid(pe):
			particulas.remove_at(i)
		else:
			(pe as CPUParticles3D).emitting = particulas[i][1] == h
		i -= 1

## Material de partículas (sin luz, transparente, opcionalmente brillante); en caché.
func _pmat(c: String, brillo := 0.0) -> StandardMaterial3D:
	var k := "%s/%s" % [c, brillo]
	if _pmats.has(k):
		return _pmats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if brillo > 0.0:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = brillo
	_pmats[k] = m
	return m

func _malla_p(tipo: String) -> Mesh:
	if _pmesh.has(tipo):
		return _pmesh[tipo]
	var m: Mesh
	match tipo:
		"petalo", "copo":
			var q := QuadMesh.new()
			q.size = Vector2(0.06, 0.04) if tipo == "petalo" else Vector2(0.04, 0.04)
			m = q
		_:
			var sp := SphereMesh.new()
			sp.radius = 0.025
			sp.height = 0.05
			sp.radial_segments = 8
			sp.rings = 4
			m = sp
	_pmesh[tipo] = m
	return m

## Partículas de ambiente. tipos: petalos, nieve, burbujas, vapor, luciernagas, chispas, brillos, agua.
func particulas_en(parent: Node3D, pos: Vector3, tipo: String, cant := 24, ancho := 1.0, col := "") -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = cant
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(ancho, 0.1, ancho * 0.6)
	p.local_coords = false
	var color := Gradient.new()
	match tipo:
		"petalos":
			p.mesh = _malla_p("petalo")
			p.material_override = _pmat("#ffc2d6")
			p.lifetime = 6.0
			p.direction = Vector3(0.3, -1, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.4
			p.gravity = Vector3(0.05, -0.15, 0)
			p.angular_velocity_min = -90
			p.angular_velocity_max = 90
			p.particle_flag_align_y = false
			p.scale_amount_min = 0.7
			p.scale_amount_max = 1.2
		"nieve":
			p.mesh = _malla_p("copo")
			p.material_override = _pmat("#ffffff")
			p.lifetime = 7.0
			p.direction = Vector3(0, -1, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.35
			p.gravity = Vector3(0.03, -0.1, 0)
			p.particle_flag_rotate_y = true
		"burbujas":
			p.mesh = _malla_p("bola")
			p.material_override = _pmat("#dff6ff", 0.3)
			p.lifetime = 3.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 15.0
			p.initial_velocity_min = 0.15
			p.initial_velocity_max = 0.35
			p.gravity = Vector3(0, 0.05, 0)
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.6
		"vapor":
			p.mesh = _malla_p("bola")
			p.material_override = _pmat("#ffffff")
			p.lifetime = 2.2
			p.direction = Vector3(0, 1, 0)
			p.spread = 12.0
			p.initial_velocity_min = 0.25
			p.initial_velocity_max = 0.4
			p.gravity = Vector3.ZERO
			p.scale_amount_min = 1.5
			p.scale_amount_max = 3.0
		"luciernagas", "brillos":
			p.mesh = _malla_p("bola")
			p.material_override = _pmat("#fff3a0" if tipo == "luciernagas" else "#ffffff", 2.5)
			p.lifetime = 4.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.15
			p.gravity = Vector3.ZERO
			p.scale_amount_min = 0.3
			p.scale_amount_max = 0.7
			p.emission_box_extents = Vector3(ancho, ancho * 0.5, ancho * 0.4)
		"chispas":
			p.mesh = _malla_p("bola")
			p.material_override = _pmat("#ffb347", 3.0)
			p.lifetime = 1.2
			p.direction = Vector3(0, 1, 0)
			p.spread = 20.0
			p.initial_velocity_min = 0.5
			p.initial_velocity_max = 1.0
			p.gravity = Vector3(0, 0.2, 0)
			p.scale_amount_min = 0.2
			p.scale_amount_max = 0.5
			p.emission_box_extents = Vector3(0.12, 0.02, 0.12)
		"agua":
			p.mesh = _malla_p("bola")
			p.material_override = _pmat("#aee6ff", 0.2)
			p.lifetime = 1.0
			p.direction = Vector3(0, 1, 0)
			p.spread = 14.0
			p.initial_velocity_min = 1.6
			p.initial_velocity_max = 2.0
			p.gravity = Vector3(0, -4.5, 0)
			p.scale_amount_min = 0.4
			p.scale_amount_max = 0.8
			p.emission_box_extents = Vector3(0.03, 0.01, 0.03)
	# aparecen y se desvanecen suave
	color.set_color(0, Color(1, 1, 1, 0))
	color.add_point(0.15, Color(1, 1, 1, 0.9))
	color.add_point(0.8, Color(1, 1, 1, 0.8))
	color.set_color(color.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = color
	# el ambiente ya está "lleno" desde el primer cuadro (no espera a que caigan los primeros copos)
	if tipo in ["petalos", "nieve", "luciernagas", "brillos", "burbujas"]:
		p.preprocess = p.lifetime
	if col != "":
		p.material_override = _pmat(col, 0.0 if tipo in ["petalos", "nieve", "vapor"] else 2.0)
	p.emitting = _h == hab_activa
	parent.add_child(p)
	particulas.append([p, _h])
	return p

## Materiales de los efectos (para precalentar los sombreadores durante la carga).
func muestras() -> Array:
	return [_pmat("#ffffff"), _pmat("#fff3a0", 2.5), _pmat("#dff6ff", 0.3), mat("#ffffff", 0.5, 1.0)]

## Un emisor de cada tipo, para precalentar.
func muestras_particulas(parent: Node3D) -> void:
	var guardado := _h
	_h = "vitrina"
	hab_activa = "vitrina"
	for tp in ["petalos", "nieve", "burbujas", "vapor", "luciernagas", "chispas", "agua"]:
		particulas_en(parent, Vector3(randf_range(-0.4, 0.4), 0.6, 0), tp, 6, 0.1).emitting = true
	_h = guardado
