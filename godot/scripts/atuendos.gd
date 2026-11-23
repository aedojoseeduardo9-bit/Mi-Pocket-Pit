## Pocket Pip — la ropa de Pip en 3D. Cada prenda del catálogo tiene una "forma" y colores (`c`); aquí se arma
## con piezas colgadas de los huesos (cabeza, torso, brazos, piernas), así se mueve con Pip en todas sus animaciones.
## Zonas: cabeza, ojos, cuello, cuerpo, espalda y traje (el traje cubre cuerpo y cabeza).
## Animaciones de la ropa (las mueve PipModel._animar_ropa): girar, flotar, balancear, aletear, ondear,
## parpadear, brillar, gelatina, llama.
## Medidas de referencia (Pip sin escalar): cabeza radio ~0.15 con centro en el hueso de la cabeza; ojos en
## (±0.07, 0.025, 0.118); torso: esfera (0.15, 0.14, 0.17) con centro en (0, 0.05, -0.01).
class_name Atuendos

const ZONAS := ["cabeza", "ojos", "cuello", "cuerpo", "espalda", "traje"]

static var _ball: SphereMesh
static var _cyl: CylinderMesh
static var _cone: CylinderMesh
static var _torus: TorusMesh
static var _box: BoxMesh
static var _heart: ArrayMesh
static var _star: ArrayMesh
static var _gota: ArrayMesh
static var _ala: ArrayMesh
static var _ala_bat: ArrayMesh
static var _mats := {}

static func _geos() -> void:
	if _ball != null:
		return
	_ball = SphereMesh.new()
	_ball.radius = 1.0
	_ball.height = 2.0
	_ball.radial_segments = 24
	_ball.rings = 12
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 1.0
	_cyl.bottom_radius = 1.0
	_cyl.height = 1.0
	_cyl.radial_segments = 24
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 1.0
	_cone.height = 1.0
	_cone.radial_segments = 16
	_torus = TorusMesh.new()
	_torus.inner_radius = 0.82
	_torus.outer_radius = 1.0
	_torus.rings = 32
	_torus.ring_segments = 10
	_box = BoxMesh.new()
	_box.size = Vector3.ONE
	var hp := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var x := 16.0 * pow(sin(a), 3)
		var y := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
		hp.append(Vector2(x, y) / 17.0)
	_heart = extruir(hp, 0.15)
	_star = extruir(estrella(), 0.18)
	var gp := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		gp.append(Vector2(sin(a) * 0.55 * (1.0 - 0.4 * cos(a)), -cos(a)))
	_gota = extruir(gp, 0.2)
	# ala redondeada (hada/ángel/mariposa) y ala de murciélago con picos
	var ap := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		ap.append(Vector2(0.5 + cos(a) * 0.5, sin(a) * 0.32 + sin(a * 2.0) * 0.06))
	_ala = extruir(ap, 0.04)
	_ala_bat = extruir(PackedVector2Array([Vector2(0, 0.1), Vector2(0.35, 0.4), Vector2(1.0, 0.35), Vector2(0.85, 0.05),
		Vector2(0.7, 0.15), Vector2(0.55, -0.05), Vector2(0.4, 0.1), Vector2(0.25, -0.1), Vector2(0, -0.05)]), 0.04)

static func estrella() -> PackedVector2Array:
	var sp := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 + PI / 2.0
		var r := 0.45 if i % 2 else 1.0
		sp.append(Vector2(cos(a) * r, sin(a) * r))
	return sp

## Malla de un polígono 2D con grosor (mirando hacia +z).
static func extruir(poly: PackedVector2Array, z: float) -> ArrayMesh:
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	var idx := Geometry2D.triangulate_polygon(poly)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
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
		for v in [Vector3(a.x, a.y, z), Vector3(b.x, b.y, -z), Vector3(b.x, b.y, z), Vector3(a.x, a.y, z), Vector3(a.x, a.y, -z), Vector3(b.x, b.y, -z)]:
			st.set_normal(n)
			st.add_vertex(v)
	return st.commit()

# ---------------- materiales (en caché: pocos sombreadores distintos = menos tirones) ----------------
static func tela(c: String) -> StandardMaterial3D:
	var k := "t" + c
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.95
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.5
	_mats[k] = m
	return m

static func metal(c: String) -> StandardMaterial3D:
	var k := "m" + c
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.metallic = 0.7
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = Color(c) * 0.15
	_mats[k] = m
	return m

static func brillante(c: String) -> StandardMaterial3D:
	var k := "b" + c
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.15
	m.metallic_specular = 0.9
	_mats[k] = m
	return m

static func vidrio(c: String, a: float) -> StandardMaterial3D:
	var k := "v%s%s" % [c, a]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	var cc := Color(c)
	cc.a = a
	m.albedo_color = cc
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic_specular = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[k] = m
	return m

## Material que brilla (luces de robot, visor): uno propio por prenda porque su brillo se anima.
static func luz(c: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.emission_enabled = true
	m.emission = Color(c)
	m.emission_energy_multiplier = 1.2
	return m

## Todos los tipos de material que usa la ropa (para precalentar los sombreadores durante la intro).
static func muestras() -> Array:
	return [tela("#ffffff"), metal("#ffcf4a"), brillante("#ff4d6d"), vidrio("#e8f4ff", 0.3), luz("#7fc8ff")]

static func _p(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, sc: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.scale = sc
	m.rotation = rot
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if maxf(sc.x, maxf(sc.y, sc.z)) > 0.06 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

static func _g(parent: Node3D, nombre: String, pos := Vector3.ZERO, rot := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.name = nombre
	g.position = pos
	g.rotation = rot
	parent.add_child(g)
	return g

## Registra una pieza animada (PipModel la mueve cada cuadro).
static func _an(pip: PipModel, n: Node3D, tipo: String, extra = 1.0, mat: StandardMaterial3D = null) -> void:
	pip.anim_ropa.append({"n": n, "tipo": tipo, "x": extra, "rot": n.rotation, "pos": n.position, "sc": n.scale, "mat": mat})

# ---------------- vestir ----------------
## Viste a Pip con `puesto` = {zona: id}. Quita lo anterior.
static func vestir(pip: PipModel, puesto: Dictionary) -> void:
	_geos()
	for o in pip.get_meta("ropa", []):
		if is_instance_valid(o):
			o.queue_free()
	pip.anim_ropa.clear()
	var piezas: Array = []
	var traje := str(puesto.get("traje", ""))
	var cuerpo := "" if traje != "" else str(puesto.get("cuerpo", ""))
	var cuello := str(puesto.get("cuello", ""))
	var def_cuello: Dictionary = Estado.ropa_por_id.get(cuello, {})
	pip.scarf.visible = traje == "" and str(def_cuello.get("forma", "")) == "bufanda" and cuello == "bufanda_nova"
	# la pancita crema se esconde bajo la ropa (si no, atraviesa la tela)
	for c in pip.torso.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override == pip.M.cream:
			c.visible = cuerpo == "" and traje == ""
	var orejas := true
	for zona in ZONAS:
		var id := str(puesto.get(zona, ""))
		if id == "" or id == "bufanda_nova":
			continue
		if traje != "" and (zona == "cuerpo" or zona == "cabeza"):
			continue
		var def: Dictionary = Estado.ropa_por_id.get(id, {})
		if def.is_empty():
			continue
		var res := _armar(pip, str(def.forma), def.c, str(def.get("anim", "")))
		piezas.append_array(res)
		if str(def.forma) in ["robot", "astronauta", "caballero", "casco_astronauta"]:
			orejas = false
	for e in pip.ears:
		e.visible = orejas and pip.forma == "pip"
	if pip.forma != "pip":
		pip.scarf.visible = false
		for o in piezas:
			(o as Node3D).visible = false
	pip.set_meta("ropa", piezas)

static func _c(cs: Array, i: int, def := "#ffffff") -> String:
	return str(cs[i]) if i < cs.size() else def

static func _armar(pip: PipModel, forma: String, cs: Array, anim: String) -> Array:
	var H := pip.head
	var T := pip.torso
	var c0 := _c(cs, 0)
	var c1 := _c(cs, 1, "#ffffff")
	var c2 := _c(cs, 2, "#2b2633")
	var g := _g(T if forma in CUERPO_TORSO else H, forma)
	var out: Array = [g]
	match forma:
		# ================= CUELLO =================
		"bufanda":
			g.position = Vector3(0, 0.145, 0.03)
			_p(g, _torus, tela(c0), Vector3.ZERO, Vector3(0.1, 0.32, 0.1), Vector3(0.2, 0, 0))
			var punta := _g(g, "punta", Vector3(0.06, -0.01, 0.07))
			_p(punta, _ball, tela(c0), Vector3(0, -0.03, 0), Vector3(0.03, 0.055, 0.012))
			_p(punta, _box, tela(c1), Vector3(0, -0.06, 0.0), Vector3(0.05, 0.008, 0.026))
			_an(pip, punta, "ondear", 0.5)
		"mono":
			g.position = Vector3(0, 0.15, 0.115)
			g.rotation.x = -0.25
			for s in [-1.0, 1.0]:
				_p(g, _cone, tela(c0), Vector3(s * 0.03, 0, 0), Vector3(0.028, 0.045, 0.012), Vector3(0, 0, -s * PI / 2))
			_p(g, _ball, tela(c0), Vector3(0, 0, 0.004), Vector3(0.014, 0.014, 0.012))
		"collar_bellotas":
			g.position = Vector3(0, 0.145, 0.03)
			_p(g, _torus, tela(c1), Vector3.ZERO, Vector3(0.095, 0.15, 0.095), Vector3(0.2, 0, 0))
			for i in 5:
				var a := -1.0 + i * 0.5
				var b := _g(g, "b%d" % i, Vector3(sin(a) * 0.092, -0.015, cos(a) * 0.09))
				_p(b, _ball, brillante("#c58a4a"), Vector3(0, -0.012, 0), Vector3(0.012, 0.015, 0.012))
				_p(b, _ball, tela("#6b4226"), Vector3.ZERO, Vector3(0.013, 0.007, 0.013))
		"panuelo":
			g.position = Vector3(0, 0.145, 0.03)
			_p(g, _torus, tela(c0), Vector3.ZERO, Vector3(0.1, 0.3, 0.1), Vector3(0.2, 0, 0))
			_p(g, _cone, tela(c0), Vector3(0, -0.04, 0.09), Vector3(0.06, 0.07, 0.01), Vector3(PI + 0.25, 0, 0))
			for i in 4:
				_p(g, _ball, tela(c1), Vector3(-0.02 + (i % 2) * 0.03, -0.03 - (i / 2) * 0.025, 0.1), Vector3.ONE * 0.005)
		"corbata":
			g.position = Vector3(0, 0.14, 0.1)
			g.rotation.x = -0.35
			_p(g, _ball, tela(c0), Vector3(0, 0, 0.01), Vector3(0.016, 0.014, 0.01))
			_p(g, _gota, tela(c0), Vector3(0, -0.05, 0.012), Vector3(0.035, 0.045, 0.04), Vector3(0, 0, PI))
			_p(g, _torus, tela(c1), Vector3(0, 0.01, -0.07), Vector3(0.1, 0.25, 0.1), Vector3(0.3, 0, 0))
		"collar_perlas":
			g.position = Vector3(0, 0.14, 0.03)
			for i in 11:
				var a := -1.5 + i * 0.3
				_p(g, _ball, brillante(c0), Vector3(sin(a) * 0.098, -absf(sin(a * 0.5)) * 0.02, cos(a) * 0.095), Vector3.ONE * 0.011)
		"cascabel":
			g.position = Vector3(0, 0.145, 0.03)
			_p(g, _torus, tela(c0), Vector3.ZERO, Vector3(0.096, 0.25, 0.096), Vector3(0.2, 0, 0))
			var b := _g(g, "campana", Vector3(0, -0.015, 0.1))
			_p(b, _ball, metal(c1), Vector3(0, -0.02, 0), Vector3.ONE * 0.024)
			_p(b, _box, tela("#5a3a1a"), Vector3(0, -0.026, 0.02), Vector3(0.025, 0.004, 0.004))
			_an(pip, b, "balancear", 0.6)
		"medalla":
			g.position = Vector3(0, 0.14, 0.03)
			_p(g, _torus, tela(c1), Vector3.ZERO, Vector3(0.096, 0.2, 0.096), Vector3(0.35, 0, 0))
			var m := _g(g, "medalla", Vector3(0, -0.06, 0.12))
			_p(m, _cyl, metal(c0), Vector3.ZERO, Vector3(0.03, 0.006, 0.03), Vector3(PI / 2 - 0.3, 0, 0))
			_p(m, _star, metal("#fff3c4"), Vector3(0, 0.002, 0.006), Vector3.ONE * 0.016, Vector3(-0.3, 0, 0))
			_an(pip, m, "balancear", 0.35)

		# ================= CABEZA =================
		"gorro_lana":
			_p(g, _ball, tela(c0), Vector3(0, 0.07, -0.005), Vector3(0.163, 0.115, 0.158))
			_p(g, _torus, tela(c1), Vector3(0, 0.07, 0), Vector3(0.162, 0.25, 0.158), Vector3(0.12, 0, 0))
			var pom := _g(g, "pompon", Vector3(0, 0.19, -0.02))
			_p(pom, _ball, tela(c1), Vector3.ZERO, Vector3.ONE * 0.045)
			_an(pip, pom, "balancear", 0.25)
		"gorra":
			_p(g, _ball, tela(c0), Vector3(0, 0.075, -0.01), Vector3(0.158, 0.11, 0.155))
			_p(g, _cyl, tela(c0), Vector3(0, 0.085, 0.14), Vector3(0.11, 0.008, 0.09), Vector3(-0.18, 0, 0))
			_p(g, _star, metal("#ffd36e"), Vector3(0, 0.13, 0.12), Vector3.ONE * 0.028, Vector3(-0.55, 0, 0))
			_p(g, _ball, tela(c1), Vector3(0, 0.185, -0.01), Vector3.ONE * 0.014)
			g.rotation.z = -0.08
		"sombrero_copa":
			_p(g, _cyl, tela(c0), Vector3(0, 0.12, 0), Vector3(0.16, 0.012, 0.16))
			_p(g, _cyl, tela(c0), Vector3(0, 0.2, 0), Vector3(0.1, 0.16, 0.1))
			_p(g, _cyl, tela(c1), Vector3(0, 0.145, 0), Vector3(0.102, 0.03, 0.102))
			g.rotation = Vector3(-0.1, 0, 0.18)
			g.position = Vector3(-0.02, 0, 0)
		"corona":
			var oro := metal(c0)
			_p(g, _cyl, oro, Vector3(0, 0.15, 0), Vector3(0.1, 0.045, 0.1))
			for i in 6:
				var a := TAU * i / 6.0
				_p(g, _cone, oro, Vector3(sin(a) * 0.092, 0.2, cos(a) * 0.092), Vector3(0.026, 0.06, 0.026))
				_p(g, _ball, oro, Vector3(sin(a) * 0.092, 0.235, cos(a) * 0.092), Vector3.ONE * 0.011)
			var gemas := ["#ff4d6d", "#4dd2ff", "#7dff8a"]
			for i in 3:
				var a := -0.6 + i * 0.6
				var gm := luz(gemas[i])
				_p(g, _ball, gm, Vector3(sin(a) * 0.1, 0.15, cos(a) * 0.1), Vector3(0.016, 0.016, 0.01))
				_an(pip, g, "brillar", i, gm)
			g.rotation.z = 0.12
		"flor":
			for i in 5:
				var a := TAU * i / 5.0
				_p(g, _ball, tela(c0), Vector3(cos(a) * 0.028, sin(a) * 0.028, 0), Vector3(0.026, 0.02, 0.008), Vector3(0, 0, a))
			_p(g, _ball, tela(c1), Vector3(0, 0, 0.006), Vector3.ONE * 0.014)
			g.position = Vector3(0.1, 0.1, 0.07)
			g.rotation = Vector3(-0.3, 0.6, 0)
		"audifonos":
			var arco := _p(g, _torus, tela(c0), Vector3.ZERO, Vector3(0.168, 0.35, 0.168))
			arco.rotation = Vector3(0, PI / 2, PI / 2)
			for s in [-1.0, 1.0]:
				_p(g, _cyl, tela(c0), Vector3(s * 0.158, -0.01, 0), Vector3(0.05, 0.03, 0.05), Vector3(0, 0, PI / 2))
				_p(g, _cyl, tela(c1), Vector3(s * 0.14, -0.01, 0), Vector3(0.042, 0.012, 0.042), Vector3(0, 0, PI / 2))
		"vaquero":
			_p(g, _cyl, tela(c0), Vector3(0, 0.12, 0), Vector3(0.21, 0.012, 0.18))
			_p(g, _ball, tela(c0), Vector3(0, 0.17, 0), Vector3(0.11, 0.07, 0.1))
			_p(g, _torus, tela(c1), Vector3(0, 0.145, 0), Vector3(0.105, 0.2, 0.095))
			for s in [-1.0, 1.0]:
				_p(g, _ball, tela(c0), Vector3(s * 0.19, 0.14, 0), Vector3(0.04, 0.025, 0.12))
		"chef":
			_p(g, _cyl, tela(c0), Vector3(0, 0.15, 0), Vector3(0.11, 0.06, 0.11))
			for i in 5:
				var a := TAU * i / 5.0
				_p(g, _ball, tela(c0), Vector3(cos(a) * 0.06, 0.24, sin(a) * 0.06), Vector3.ONE * 0.065)
			_p(g, _ball, tela(c0), Vector3(0, 0.27, 0), Vector3.ONE * 0.07)
		"pirata":
			_p(g, _ball, tela(c0), Vector3(0, 0.13, 0), Vector3(0.2, 0.07, 0.12))
			_p(g, _cone, tela(c0), Vector3(0, 0.19, 0.0), Vector3(0.18, 0.06, 0.07), Vector3(0, 0, 0))
			# calavera blanca
			_p(g, _ball, tela(c1), Vector3(0, 0.15, 0.115), Vector3(0.022, 0.02, 0.008))
			for s in [-1.0, 1.0]:
				_p(g, _box, tela(c1), Vector3(0, 0.125, 0.115), Vector3(0.05, 0.007, 0.005), Vector3(0, 0, s * 0.6))
		"mago", "bruja":
			_p(g, _cyl, tela(c0), Vector3(0, 0.12, 0), Vector3(0.19 if forma == "bruja" else 0.16, 0.01, 0.19 if forma == "bruja" else 0.16))
			var punta := _g(g, "punta", Vector3(0, 0.13, 0))
			_p(punta, _cone, tela(c0), Vector3(0, 0.12, 0), Vector3(0.1, 0.24, 0.1))
			_p(punta, _torus, tela(c1), Vector3(0, 0.02, 0), Vector3(0.1, 0.25, 0.1))
			if forma == "mago":
				for i in 3:
					var sm := luz("#fff3c4")
					_p(punta, _star, sm, Vector3(sin(i * 2.1) * 0.06, 0.06 + i * 0.05, cos(i * 2.1) * 0.06 + 0.02), Vector3.ONE * 0.016)
					_an(pip, punta, "brillar", i, sm)
			punta.rotation.z = 0.15
			_an(pip, punta, "balancear", 0.12)
		"casco_astronauta":
			_p(g, _ball, vidrio("#cfeaff", 0.22), Vector3(0, 0.02, 0.01), Vector3(0.21, 0.2, 0.2))
			_p(g, _torus, metal(c0), Vector3(0, -0.15, 0), Vector3(0.16, 0.5, 0.16))
			var ant := _g(g, "antena", Vector3(0.12, 0.17, -0.04))
			_p(ant, _cyl, metal("#cfd6e2"), Vector3(0, 0.03, 0), Vector3(0.005, 0.06, 0.005))
			var lm := luz("#ff5a5f")
			_p(ant, _ball, lm, Vector3(0, 0.065, 0), Vector3.ONE * 0.012)
			_an(pip, ant, "parpadear", 1.0, lm)
		"corona_flores":
			for i in 9:
				var a := TAU * i / 9.0
				var f := _g(g, "f%d" % i, Vector3(sin(a) * 0.12, 0.11, cos(a) * 0.115))
				_p(f, _ball, tela(c0 if i % 2 == 0 else "#ffffff"), Vector3.ZERO, Vector3.ONE * 0.022)
				_p(f, _ball, tela(_c(cs, 2, "#ffcf4a")), Vector3(0, 0.01, 0), Vector3.ONE * 0.009)
			_p(g, _torus, tela(c1), Vector3(0, 0.1, 0), Vector3(0.12, 0.15, 0.115))
		"cuernos":
			for s in [-1.0, 1.0]:
				_p(g, _cone, brillante(c0), Vector3(s * 0.065, 0.15, 0.03), Vector3(0.022, 0.07, 0.022), Vector3(0.2, 0, -s * 0.35))
		"aureola":
			var au := _g(g, "aureola", Vector3(0, 0.27, 0))
			var am := luz(c0)
			_p(au, _torus, am, Vector3.ZERO, Vector3(0.11, 0.3, 0.11))
			_an(pip, au, "flotar", 1.0, am)
		"antenas":
			for s in [-1.0, 1.0]:
				var a := _g(g, "ant", Vector3(s * 0.05, 0.13, 0.02), Vector3(0, 0, -s * 0.3))
				_p(a, _cyl, tela(c0), Vector3(0, 0.05, 0), Vector3(0.006, 0.1, 0.006))
				_p(a, _ball, tela(c1), Vector3(0, 0.105, 0), Vector3.ONE * 0.022)
				_an(pip, a, "balancear", 0.35 * s)
			_p(g, _torus, tela(c0), Vector3(0, 0.1, 0), Vector3(0.13, 0.12, 0.125))
		"helice":
			_p(g, _ball, tela(c0), Vector3(0, 0.075, -0.01), Vector3(0.158, 0.11, 0.155))
			for i in 4:
				_p(g, _ball, tela(c1 if i % 2 else _c(cs, 2, "#ffcf4a")), Vector3(0, 0.077, -0.01), Vector3(0.159, 0.111, 0.156), Vector3(0, i * PI / 2, 0)).scale.x = 0.04
			_p(g, _cyl, tela("#2b2633"), Vector3(0, 0.2, -0.01), Vector3(0.008, 0.03, 0.008))
			var h := _g(g, "helice", Vector3(0, 0.218, -0.01))
			for i in 2:
				_p(h, _ball, tela(c1), Vector3(0, 0, 0), Vector3(0.11, 0.006, 0.022), Vector3(0, i * PI, 0)).position.x = 0.0
			_p(h, _ball, tela(c1), Vector3.ZERO, Vector3(0.022, 0.006, 0.11))
			_an(pip, h, "girar", 14.0)
		"gorro_navidad":
			_p(g, _torus, tela(c1), Vector3(0, 0.08, 0), Vector3(0.16, 0.35, 0.155), Vector3(0.1, 0, 0))
			var p := _g(g, "punta", Vector3(0, 0.1, -0.01))
			_p(p, _cone, tela(c0), Vector3(0.0, 0.08, 0), Vector3(0.14, 0.17, 0.14))
			_p(p, _ball, tela(c1), Vector3(0.0, 0.17, 0), Vector3.ONE * 0.03)
			p.rotation = Vector3(-0.4, 0, 0.5)
			_an(pip, p, "balancear", 0.15)
		"orejas_conejo":
			_p(g, _torus, tela(c0), Vector3(0, 0.1, 0), Vector3(0.14, 0.15, 0.13), Vector3(0.1, 0, 0))
			for s in [-1.0, 1.0]:
				var o := _g(g, "oreja", Vector3(s * 0.05, 0.13, 0.0), Vector3(0, 0, -s * 0.2))
				_p(o, _ball, tela(c0), Vector3(0, 0.1, 0), Vector3(0.03, 0.1, 0.018))
				_p(o, _ball, tela(c1), Vector3(0, 0.1, 0.008), Vector3(0.018, 0.075, 0.012))
				_an(pip, o, "balancear", 0.2 * s)
		"cuerno_unicornio":
			var cm := luz("#fff3f8")
			cm.emission_energy_multiplier = 0.3
			var u := _g(g, "cuerno", Vector3(0, 0.15, 0.06), Vector3(0.45, 0, 0))
			_p(u, _cone, cm, Vector3(0, 0.05, 0), Vector3(0.025, 0.11, 0.025))
			for i in 4:
				_p(u, _torus, tela(c0), Vector3(0, 0.01 + i * 0.022, 0), Vector3(0.022 - i * 0.004, 0.2, 0.022 - i * 0.004))
			_an(pip, u, "brillar", 0.0, cm)
		"boina":
			_p(g, _ball, tela(c0), Vector3(0.02, 0.11, 0), Vector3(0.17, 0.06, 0.16), Vector3(0, 0, 0.2))
			_p(g, _cyl, tela(c0), Vector3(0.06, 0.17, 0), Vector3(0.006, 0.02, 0.006))
		"casco_bombero":
			_p(g, _ball, brillante(c0), Vector3(0, 0.08, -0.01), Vector3(0.165, 0.12, 0.16))
			_p(g, _cyl, brillante(c0), Vector3(0, 0.07, -0.02), Vector3(0.2, 0.01, 0.21), Vector3(-0.1, 0, 0))
			_p(g, _cyl, metal(c1), Vector3(0, 0.15, 0.12), Vector3(0.04, 0.008, 0.04), Vector3(PI / 2 - 0.5, 0, 0))
		"tiara":
			var tm := metal(c0)
			_p(g, _torus, tm, Vector3(0, 0.11, 0.01), Vector3(0.12, 0.15, 0.115), Vector3(0.3, 0, 0))
			var gm := luz(c1)
			_p(g, _gota, gm, Vector3(0, 0.17, 0.11), Vector3(0.025, 0.035, 0.03), Vector3(0.3, 0, PI))
			_an(pip, g, "brillar", 0.0, gm)
		"vikingo":
			_p(g, _ball, metal(c0), Vector3(0, 0.075, -0.01), Vector3(0.165, 0.12, 0.16))
			_p(g, _torus, metal("#b08a4a"), Vector3(0, 0.07, 0), Vector3(0.166, 0.3, 0.16))
			for s in [-1.0, 1.0]:
				var cu := _g(g, "cuerno", Vector3(s * 0.14, 0.1, 0), Vector3(0, 0, -s * 0.9))
				_p(cu, _cone, brillante(c1), Vector3(0, 0.05, 0), Vector3(0.028, 0.1, 0.028))

		# ================= OJOS =================
		"lentes_sol", "lentes_redondos", "gafas_buceo":
			var marco := tela(c0) if forma != "lentes_redondos" else metal(c0)
			var luna := vidrio("#20202a", 0.88) if forma == "lentes_sol" else vidrio("#e8f4ff", 0.25)
			if forma == "gafas_buceo":
				luna = vidrio(c1, 0.35)
			var r := 0.05 if forma != "lentes_redondos" else 0.045
			for s in [-1.0, 1.0]:
				_p(g, _cyl, luna, Vector3(s * 0.07, 0.025, 0.152), Vector3(r, 0.006, r * 0.9), Vector3(PI / 2, 0, 0))
				_p(g, _torus, marco, Vector3(s * 0.07, 0.025, 0.152), Vector3(r + 0.004, 0.14, r * 0.9 + 0.004), Vector3(PI / 2, 0, 0))
				if forma != "gafas_buceo":
					_p(g, _box, marco, Vector3(s * 0.135, 0.03, 0.08), Vector3(0.006, 0.008, 0.14), Vector3(0, s * 0.35, 0))
			_p(g, _box, marco, Vector3(0, 0.035, 0.162), Vector3(0.04, 0.008, 0.008))
			if forma == "gafas_buceo":
				_p(g, _torus, tela("#2b2633"), Vector3(0, 0.03, 0), Vector3(0.158, 0.1, 0.152), Vector3(0, 0, 0))
		"lentes_corazon", "lentes_estrella":
			var luna := vidrio(c0, 0.82)
			for s in [-1.0, 1.0]:
				if forma == "lentes_corazon":
					_p(g, _heart, luna, Vector3(s * 0.072, 0.028, 0.155), Vector3(0.055, 0.052, 0.04))
				else:
					_p(g, _star, luna, Vector3(s * 0.072, 0.028, 0.155), Vector3(0.06, 0.06, 0.04))
				_p(g, _box, tela(c0), Vector3(s * 0.135, 0.03, 0.08), Vector3(0.006, 0.008, 0.14), Vector3(0, s * 0.35, 0))
			_p(g, _box, tela(c0), Vector3(0, 0.04, 0.16), Vector3(0.04, 0.008, 0.008))
		"monoculo":
			_p(g, _torus, metal(c0), Vector3(0.07, 0.025, 0.152), Vector3(0.042, 0.12, 0.042), Vector3(PI / 2, 0, 0))
			_p(g, _cyl, vidrio("#e8f4ff", 0.3), Vector3(0.07, 0.025, 0.152), Vector3(0.04, 0.003, 0.04), Vector3(PI / 2, 0, 0))
			_p(g, _cyl, metal(c0), Vector3(0.1, -0.04, 0.14), Vector3(0.002, 0.12, 0.002), Vector3(0.2, 0, 0.3))
		"visor":
			var vm := luz(c1 if c1 != "#ffffff" else "#7fc8ff")
			vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			vm.albedo_color.a = 0.75
			var vi := _p(g, _ball, vm, Vector3(0, 0.03, 0.06), Vector3(0.16, 0.04, 0.115))
			vi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_p(g, _torus, tela(c0), Vector3(0, 0.03, 0), Vector3(0.158, 0.25, 0.152))
			_an(pip, g, "parpadear", 0.5, vm)
		"parche":
			_p(g, _ball, tela(c0), Vector3(0.07, 0.03, 0.14), Vector3(0.04, 0.04, 0.012))
			_p(g, _torus, tela(c0), Vector3(0, 0.05, 0), Vector3(0.157, 0.04, 0.152), Vector3(0, 0, -0.35))

		# ================= CUERPO =================
		"poleron", "polera_estrella", "sueter", "futbol", "impermeable", "hawaiana", "chaleco", "smoking", "overol", "tutu":
			out.append_array(_ropa_cuerpo(pip, g, forma, c0, c1, c2))
		"capa":
			var tc := tela(c0)
			tc.cull_mode = BaseMaterial3D.CULL_DISABLED
			var capa := _g(g, "capa", Vector3(0, 0.15, -0.08))
			_p(capa, _ball, tc, Vector3(0, -0.12, -0.05), Vector3(0.17, 0.2, 0.04), Vector3(0.12, 0, 0))
			_p(capa, _ball, tela(c1), Vector3(0, 0.0, 0.02), Vector3(0.11, 0.035, 0.11))
			_p(g, _ball, metal("#ffd36e"), Vector3(0, 0.15, 0.13), Vector3.ONE * 0.016)
			_an(pip, capa, "ondear", 1.0)

		# ================= ESPALDA =================
		"alas_hada", "alas_angel", "alas_mariposa", "alas_murcielago":
			var mat: Material
			if forma == "alas_hada":
				mat = vidrio(c0, 0.55)
			elif forma == "alas_angel":
				mat = tela(c0)
			elif forma == "alas_mariposa":
				mat = tela(c0)
			else:
				mat = tela(c0)
			var malla := _ala_bat if forma == "alas_murcielago" else _ala
			var tam := 0.2 if forma != "alas_angel" else 0.24
			for s in [-1.0, 1.0]:
				var w := _g(g, "ala", Vector3(s * 0.04, 0.12, -0.15), Vector3(0, s * 0.5, 0))
				var m := _p(w, malla, mat, Vector3.ZERO, Vector3(tam * s, tam, tam))
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if forma == "alas_mariposa":
					_p(w, _ball, tela(c1), Vector3(s * tam * 0.6, 0.0, 0.0), Vector3(0.03, 0.03, 0.012))
					_p(w, _ball, tela("#fff3c4"), Vector3(s * tam * 0.35, 0.03, 0.0), Vector3(0.015, 0.015, 0.012))
				if forma == "alas_hada":
					_p(w, malla, vidrio(c0, 0.5), Vector3(0, -0.06, 0), Vector3(tam * 0.65 * s, tam * 0.55, tam), Vector3(0, 0, -s * 0.6))
				_an(pip, w, "aletear", s)
		"mochila":
			_p(g, _ball, tela(c0), Vector3(0, 0.06, -0.19), Vector3(0.1, 0.11, 0.06))
			_p(g, _ball, tela(c1), Vector3(0, 0.02, -0.235), Vector3(0.07, 0.05, 0.03))
			for s in [-1.0, 1.0]:
				_p(g, _torus, tela(c1), Vector3(s * 0.07, 0.09, -0.05), Vector3(0.12, 0.12, 0.12), Vector3(0, PI / 2, 0.2 * s))
		"jetpack":
			for s in [-1.0, 1.0]:
				_p(g, _cyl, metal(c0), Vector3(s * 0.045, 0.06, -0.2), Vector3(0.04, 0.16, 0.04))
				_p(g, _cone, metal(c1), Vector3(s * 0.045, 0.17, -0.2), Vector3(0.04, 0.05, 0.04))
				var f := _g(g, "fuego", Vector3(s * 0.045, -0.03, -0.2))
				var fm := luz("#ffb347")
				_p(f, _cone, fm, Vector3(0, -0.04, 0), Vector3(0.03, 0.08, 0.03), Vector3(PI, 0, 0))
				_an(pip, f, "llama", 1.0, fm)
			_p(g, _box, metal("#7a8090"), Vector3(0, 0.06, -0.18), Vector3(0.05, 0.12, 0.04))
		"caparazon":
			_p(g, _ball, brillante(c0), Vector3(0, 0.05, -0.17), Vector3(0.15, 0.15, 0.08))
			for i in 5:
				var a := TAU * i / 5.0
				_p(g, _cyl, tela(c1), Vector3(cos(a) * 0.07, 0.05 + sin(a) * 0.07, -0.245), Vector3(0.03, 0.004, 0.03), Vector3(PI / 2, 0, 0))

		# ================= TRAJES =================
		_:
			if forma in TRAJES:
				out.append_array(_traje(pip, g, forma, c0, c1, c2, anim))
	return out

const CUERPO_TORSO := ["bufanda", "mono", "collar_bellotas", "panuelo", "corbata", "collar_perlas", "cascabel", "medalla",
	"poleron", "polera_estrella", "sueter", "futbol", "impermeable", "hawaiana", "chaleco", "smoking", "overol", "tutu", "capa",
	"alas_hada", "alas_angel", "alas_mariposa", "alas_murcielago", "mochila", "jetpack", "caparazon",
	"ninja", "robot", "slime", "astronauta", "dino", "abeja", "caballero", "mago_traje", "pinguino", "rana", "unicornio",
	"vampiro", "payaso", "heroe", "momia", "calabaza", "panda", "tiburon"]
const TRAJES := ["ninja", "robot", "slime", "astronauta", "dino", "abeja", "caballero", "mago_traje", "pinguino", "rana",
	"unicornio", "vampiro", "payaso", "heroe", "momia", "calabaza", "panda", "tiburon"]

## Capa sobre el torso (un poco más grande que el cuerpo).
static func _tronco(g: Node3D, mat: Material, extra := 0.008) -> MeshInstance3D:
	return _p(g, _ball, mat, Vector3(0, 0.05, -0.01), Vector3(0.15 + extra, 0.14 + extra, 0.17 + extra))

static func _mangas(pip: PipModel, mat: Material, largo := 1.0) -> Array:
	var out: Array = []
	for a in pip.arms:
		out.append(_p(a, _ball, mat, Vector3(0, -0.03 * largo, 0.01), Vector3(0.031, 0.048 * largo, 0.033)))
	return out

static func _piernas(pip: PipModel, mat: Material) -> Array:
	var out: Array = []
	for l in pip.legs:
		out.append(_p(l, _ball, mat, Vector3(0, -0.02, 0), Vector3(0.059, 0.069, 0.074)))
	return out

static func _capucha(hg: Node3D, mat: Material, extra := 0.008) -> MeshInstance3D:
	return _p(hg, _ball, mat, Vector3(0, 0.0, -0.005), Vector3(0.155 + extra, 0.142 + extra, 0.15 + extra))

static func _ropa_cuerpo(pip: PipModel, g: Node3D, forma: String, c0: String, c1: String, c2: String) -> Array:
	var out: Array = []
	match forma:
		"poleron":
			var c := tela(c0)
			_tronco(g, c)
			var osc := tela(Color(c0).darkened(0.15).to_html(false))
			_p(g, _box, osc, Vector3(0, 0.0, 0.158), Vector3(0.12, 0.05, 0.02), Vector3(-0.25, 0, 0))
			_p(g, _ball, osc, Vector3(0, 0.15, -0.09), Vector3(0.11, 0.07, 0.07))
			for s in [-1.0, 1.0]:
				_p(g, _cyl, tela("#ffffff"), Vector3(s * 0.025, 0.1, 0.15), Vector3(0.004, 0.05, 0.004), Vector3(-0.3, 0, 0))
			out.append_array(_mangas(pip, c))
		"polera_estrella":
			_tronco(g, tela(c0))
			_p(g, _star, metal(c1), Vector3(0, 0.06, 0.162), Vector3.ONE * 0.045, Vector3(-0.15, 0, 0))
			_p(g, _torus, tela(c1), Vector3(0, 0.155, 0.02), Vector3(0.08, 0.25, 0.08), Vector3(0.2, 0, 0))
			out.append_array(_mangas(pip, tela(c0), 0.6))
		"sueter", "futbol":
			_tronco(g, tela(c0))
			for i in 3:
				var y := -0.03 + i * 0.06
				_p(g, _torus, tela(c1), Vector3(0, y, -0.01), Vector3(0.152 - absf(y - 0.05) * 0.3, 0.12, 0.172 - absf(y - 0.05) * 0.3))
			if forma == "futbol":
				_p(g, _box, tela(c1), Vector3(0, 0.06, 0.168), Vector3(0.03, 0.05, 0.005), Vector3(-0.1, 0, 0))
			out.append_array(_mangas(pip, tela(c0), 1.0 if forma == "sueter" else 0.6))
		"impermeable":
			var c := brillante(c0)
			_tronco(g, c, 0.012)
			for i in 3:
				_p(g, _ball, tela(c1), Vector3(0, 0.12 - i * 0.05, 0.172 - i * 0.002), Vector3.ONE * 0.01)
			_p(g, _ball, c, Vector3(0, 0.16, -0.1), Vector3(0.12, 0.08, 0.08))
			out.append_array(_mangas(pip, c))
		"hawaiana":
			_tronco(g, tela(c0))
			var rnd := RandomNumberGenerator.new()
			rnd.seed = 4
			for i in 10:
				var a := rnd.randf_range(-1.2, 1.2)
				var y := rnd.randf_range(-0.05, 0.15)
				_p(g, _ball, tela(c1 if i % 2 else c2), Vector3(sin(a) * 0.158, y, cos(a) * 0.17 - 0.01), Vector3(0.02, 0.02, 0.006), Vector3(0, a, 0))
			out.append_array(_mangas(pip, tela(c0), 0.6))
		"chaleco":
			_tronco(g, tela(c1), 0.005)
			for s in [-1.0, 1.0]:
				_p(g, _ball, tela(c0), Vector3(s * 0.06, 0.04, 0.02), Vector3(0.1, 0.15, 0.16), Vector3(0, s * 0.25, 0))
			for i in 2:
				_p(g, _ball, metal("#ffd36e"), Vector3(0.03, 0.08 - i * 0.05, 0.165), Vector3.ONE * 0.008)
		"smoking":
			_tronco(g, tela(c1), 0.005)
			for s in [-1.0, 1.0]:
				_p(g, _ball, tela(c0), Vector3(s * 0.065, 0.04, 0.01), Vector3(0.1, 0.15, 0.165), Vector3(0, s * 0.3, 0))
			for s in [-1.0, 1.0]:
				_p(g, _cone, tela(c2), Vector3(s * 0.025, 0.15, 0.13), Vector3(0.022, 0.035, 0.01), Vector3(0, 0, -s * PI / 2))
			_p(g, _ball, tela(c2), Vector3(0, 0.15, 0.134), Vector3.ONE * 0.01)
			out.append_array(_mangas(pip, tela(c0)))
		"overol":
			_tronco(g, tela(c1), 0.004)
			var jean := tela(c0)
			_p(g, _ball, jean, Vector3(0, 0.0, -0.01), Vector3(0.166, 0.12, 0.184))
			_p(g, _box, jean, Vector3(0, 0.07, 0.165), Vector3(0.1, 0.08, 0.02), Vector3(-0.2, 0, 0))
			for s in [-1.0, 1.0]:
				_p(g, _box, jean, Vector3(s * 0.06, 0.13, 0.1), Vector3(0.022, 0.12, 0.012), Vector3(-0.6, 0, 0))
				_p(g, _ball, metal("#ffd36e"), Vector3(s * 0.045, 0.1, 0.172), Vector3.ONE * 0.01)
			out.append_array(_piernas(pip, jean))
		"tutu":
			_tronco(g, tela(c0), 0.004)
			var falda := tela(c0)
			falda.cull_mode = BaseMaterial3D.CULL_DISABLED
			for i in 3:
				_p(g, _cone, tela(c0 if i % 2 == 0 else c1), Vector3(0, -0.02 - i * 0.012, -0.01), Vector3(0.24 - i * 0.02, 0.07, 0.25 - i * 0.02), Vector3(PI, 0, 0)).scale.y = -0.07
	return out

## Trajes completos: cubren torso, brazos, piernas y la cabeza (capucha o casco).
static func _traje(pip: PipModel, g: Node3D, forma: String, c0: String, c1: String, c2: String, anim: String) -> Array:
	var out: Array = []
	var H := pip.head
	var hg := _g(H, forma + "_cabeza")
	out.append(hg)
	match forma:
		"ninja":
			var c := tela(c0)
			_tronco(g, c)
			out.append_array(_mangas(pip, c))
			out.append_array(_piernas(pip, c))
			_capucha(hg, c)
			# rendija de los ojos: la capucha se abre al frente (franja de piel) + cinta
			_p(hg, _ball, pip.M.fur, Vector3(0, 0.025, 0.11), Vector3(0.12, 0.045, 0.06))
			_p(hg, _torus, tela("#e23b4e" if c0 != "#e85d6f" else "#2b2633"), Vector3(0, 0.07, -0.005), Vector3(0.162, 0.2, 0.157), Vector3(0.15, 0, 0))
			var cinta := _g(hg, "cinta", Vector3(0, 0.07, -0.15))
			for s in [-1.0, 1.0]:
				_p(cinta, _ball, tela("#e23b4e" if c0 != "#e85d6f" else "#2b2633"), Vector3(s * 0.02, -0.04, -0.03), Vector3(0.012, 0.05, 0.006), Vector3(0.6, 0, s * 0.3))
			_an(pip, cinta, "ondear", 1.5)
			_p(g, _torus, tela(c1), Vector3(0, 0.0, -0.01), Vector3(0.155, 0.2, 0.175))
		"robot":
			var m := metal(c0)
			_tronco(g, m, 0.012)
			out.append_array(_mangas(pip, m))
			out.append_array(_piernas(pip, m))
			var casco := _p(hg, rbox(Vector3(0.33, 0.29, 0.31), 0.07), m, Vector3(0, 0.0, 0.0), Vector3.ONE)
			casco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			# pantalla con ojos de luz
			_p(hg, rbox(Vector3(0.24, 0.13, 0.02), 0.03), tela("#1e2230"), Vector3(0, 0.0, 0.155), Vector3.ONE)
			var om := luz(c1)
			for s in [-1.0, 1.0]:
				_p(hg, _ball, om, Vector3(s * 0.055, 0.01, 0.167), Vector3(0.025, 0.025, 0.006))
			_an(pip, hg, "parpadear", 0.0, om)
			var ant := _g(hg, "antena", Vector3(0, 0.16, 0))
			_p(ant, _cyl, metal("#cfd6e2"), Vector3(0, 0.04, 0), Vector3(0.006, 0.08, 0.006))
			var lm := luz(c2 if c2 != "#2b2633" else "#ff5a5f")
			_p(ant, _ball, lm, Vector3(0, 0.09, 0), Vector3.ONE * 0.02)
			_an(pip, ant, "balancear", 0.3, lm)
			for s in [-1.0, 1.0]:
				_p(hg, _cyl, metal("#9aa0ad"), Vector3(s * 0.17, 0, 0), Vector3(0.04, 0.02, 0.04), Vector3(0, 0, PI / 2))
			# panel del pecho con luces
			_p(g, rbox(Vector3(0.12, 0.09, 0.02), 0.02), tela("#1e2230"), Vector3(0, 0.07, 0.17), Vector3.ONE, Vector3(-0.15, 0, 0))
			for i in 3:
				var bm := luz(["#ff5a5f", "#ffcf4a", "#4cc38a"][i])
				_p(g, _ball, bm, Vector3(-0.03 + i * 0.03, 0.07, 0.182), Vector3.ONE * 0.01)
				_an(pip, g, "parpadear", i * 0.7, bm)
		"slime":
			var sm := vidrio(c0, 0.55)
			sm.emission_enabled = true
			sm.emission = Color(c0) * 0.25
			var blob := _g(g, "blob")
			_p(blob, _ball, sm, Vector3(0, 0.03, 0.0), Vector3(0.2, 0.2, 0.21))
			for i in 4:
				var a := -0.9 + i * 0.6
				_p(blob, _ball, sm, Vector3(sin(a) * 0.17, -0.13, cos(a) * 0.12), Vector3(0.05, 0.04, 0.05))
			_an(pip, blob, "gelatina", 1.0)
			var hb := _g(hg, "blob_cabeza")
			_p(hb, _ball, sm, Vector3(0, 0.03, 0), Vector3(0.2, 0.19, 0.2))
			_p(hb, _ball, vidrio("#ffffff", 0.7), Vector3(-0.08, 0.13, 0.08), Vector3(0.03, 0.02, 0.02))
			_an(pip, hb, "gelatina", 1.3)
		"astronauta":
			var tr := tela(c0)
			_tronco(g, tr, 0.014)
			out.append_array(_mangas(pip, tr))
			out.append_array(_piernas(pip, tr))
			_p(g, rbox(Vector3(0.1, 0.07, 0.02), 0.02), tela("#d9dde6"), Vector3(0, 0.07, 0.175), Vector3.ONE, Vector3(-0.15, 0, 0))
			_p(g, _ball, luz("#ff5a5f"), Vector3(-0.025, 0.08, 0.186), Vector3.ONE * 0.008)
			_p(g, _ball, luz("#4cc38a"), Vector3(0.0, 0.08, 0.186), Vector3.ONE * 0.008)
			_p(g, _box, tela(c1), Vector3(0.09, 0.12, 0.13), Vector3(0.04, 0.02, 0.01), Vector3(-0.2, 0.5, 0))
			_p(g, rbox(Vector3(0.18, 0.2, 0.08), 0.04), tela("#d9dde6"), Vector3(0, 0.06, -0.2), Vector3.ONE)
			_p(hg, _ball, vidrio(c2 if c2 != "#2b2633" else "#cfeaff", 0.22), Vector3(0, 0.02, 0.01), Vector3(0.215, 0.205, 0.205))
			_p(hg, _torus, tela(c0), Vector3(0, -0.15, 0), Vector3(0.17, 0.6, 0.17))
		"dino":
			var c := tela(c0)
			_tronco(g, c)
			out.append_array(_mangas(pip, c))
			out.append_array(_piernas(pip, c))
			_p(g, _ball, tela(c1), Vector3(0, 0.03, 0.1), Vector3(0.1, 0.11, 0.08))
			_capucha(hg, c, 0.012)
			_p(hg, _ball, pip.M.fur, Vector3(0, 0.0, 0.1), Vector3(0.12, 0.1, 0.07))
			# dientes de la capucha
			for i in 6:
				_p(hg, _cone, tela("#ffffff"), Vector3(-0.08 + i * 0.032, 0.09, 0.115), Vector3(0.01, 0.022, 0.01), Vector3(PI, 0, 0))
			var esp := _g(g, "espinas")
			for i in 6:
				var y := 0.32 - i * 0.07
				var par: Node3D = hg if i < 2 else esp
				var pos := Vector3(0, 0.15 - i * 0.07, -0.05 - i * 0.03) if i < 2 else Vector3(0, 0.27 - i * 0.07, -0.17)
				_p(par, _cone, tela(c1), pos, Vector3(0.03, 0.05, 0.018), Vector3(-0.5, 0, 0))
				y = y
			_an(pip, esp, "balancear", 0.1)
		"abeja":
			_tronco(g, tela(c0), 0.008)
			for i in 3:
				var y := -0.04 + i * 0.065
				_p(g, _torus, tela(c1), Vector3(0, y, -0.01), Vector3(0.154 - absf(y - 0.05) * 0.35, 0.2, 0.174 - absf(y - 0.05) * 0.35))
			for s in [-1.0, 1.0]:
				var w := _g(g, "ala", Vector3(s * 0.04, 0.12, -0.15), Vector3(0, s * 0.5, 0))
				_p(w, _ala, vidrio("#e8f4ff", 0.55), Vector3.ZERO, Vector3(0.16 * s, 0.16, 0.16))
				_an(pip, w, "aletear", s * 1.6)
			_p(g, _cone, tela(c1), Vector3(0, -0.05, -0.19), Vector3(0.02, 0.05, 0.02), Vector3(-1.9, 0, 0))
			_p(hg, _torus, tela(c1), Vector3(0, 0.1, 0), Vector3(0.13, 0.12, 0.125))
			for s in [-1.0, 1.0]:
				var a := _g(hg, "ant", Vector3(s * 0.05, 0.13, 0.02), Vector3(0, 0, -s * 0.3))
				_p(a, _cyl, tela(c1), Vector3(0, 0.05, 0), Vector3(0.006, 0.1, 0.006))
				_p(a, _ball, tela(c1), Vector3(0, 0.105, 0), Vector3.ONE * 0.02)
				_an(pip, a, "balancear", 0.4 * s)
		"caballero":
			var m := metal(c0)
			_tronco(g, m, 0.012)
			out.append_array(_mangas(pip, m))
			out.append_array(_piernas(pip, m))
			_p(g, _box, tela(c1), Vector3(0, 0.05, 0.175), Vector3(0.05, 0.1, 0.01))
			_p(hg, _ball, m, Vector3(0, 0.0, -0.005), Vector3(0.17, 0.16, 0.165))
			for i in 4:
				_p(hg, _box, tela("#1e2230"), Vector3(0, 0.0 + i * 0.022 - 0.03, 0.162), Vector3(0.13, 0.008, 0.01))
			var pl := _g(hg, "pluma", Vector3(0, 0.16, -0.03))
			_p(pl, _ball, tela(c1), Vector3(0, 0.05, -0.03), Vector3(0.025, 0.08, 0.04), Vector3(-0.5, 0, 0))
			_an(pip, pl, "balancear", 0.2)
			var capa := _g(g, "capa", Vector3(0, 0.15, -0.09))
			var cr := tela(c1)
			_p(capa, _ball, cr, Vector3(0, -0.12, -0.05), Vector3(0.16, 0.19, 0.035), Vector3(0.12, 0, 0))
			_an(pip, capa, "ondear", 1.0)
		"mago_traje":
			var c := tela(c0)
			_tronco(g, c, 0.01)
			out.append_array(_mangas(pip, c))
			_p(g, _cone, c, Vector3(0, -0.04, -0.01), Vector3(0.2, 0.18, 0.21))
			var sm := luz(c1)
			for i in 5:
				var a := -1.0 + i * 0.5
				_p(g, _star, sm, Vector3(sin(a) * 0.17, -0.02 + (i % 2) * 0.08, cos(a) * 0.17), Vector3.ONE * 0.018, Vector3(0, a, 0))
			_an(pip, g, "brillar", 0.0, sm)
			_p(hg, _cyl, c, Vector3(0, 0.12, 0), Vector3(0.17, 0.01, 0.17))
			var punta := _g(hg, "punta", Vector3(0, 0.13, 0))
			_p(punta, _cone, c, Vector3(0, 0.13, 0), Vector3(0.11, 0.26, 0.11))
			punta.rotation.z = 0.2
			_an(pip, punta, "balancear", 0.12)
			# barba
			_p(hg, _gota, tela("#f6f2ee"), Vector3(0, -0.11, 0.12), Vector3(0.07, 0.09, 0.05), Vector3(0, 0, PI))
		"pinguino":
			var n := tela(c0)
			_tronco(g, n, 0.01)
			_p(g, _ball, tela(c1), Vector3(0, 0.03, 0.1), Vector3(0.11, 0.13, 0.09))
			for a in pip.arms:
				out.append(_p(a, _ball, n, Vector3(0, -0.05, 0.0), Vector3(0.025, 0.08, 0.045)))
			out.append_array(_piernas(pip, tela(c2)))
			_capucha(hg, n, 0.01)
			_p(hg, _ball, pip.M.fur, Vector3(0, -0.01, 0.1), Vector3(0.12, 0.11, 0.07))
			_p(hg, _cone, tela(c2), Vector3(0, 0.12, 0.13), Vector3(0.03, 0.05, 0.02), Vector3(PI / 2 + 0.6, 0, 0))
		"rana":
			var v := tela(c0)
			_tronco(g, v)
			out.append_array(_mangas(pip, v))
			out.append_array(_piernas(pip, v))
			_p(g, _ball, tela(c1), Vector3(0, 0.03, 0.1), Vector3(0.1, 0.11, 0.08))
			_capucha(hg, v, 0.01)
			_p(hg, _ball, pip.M.fur, Vector3(0, -0.01, 0.1), Vector3(0.12, 0.1, 0.07))
			for s in [-1.0, 1.0]:
				_p(hg, _ball, v, Vector3(s * 0.07, 0.15, 0.04), Vector3.ONE * 0.05)
				_p(hg, _ball, tela("#ffffff"), Vector3(s * 0.07, 0.16, 0.08), Vector3.ONE * 0.03)
				_p(hg, _ball, tela("#2b2633"), Vector3(s * 0.07, 0.165, 0.105), Vector3.ONE * 0.015)
		"unicornio":
			var c := tela(c0)
			_tronco(g, c)
			out.append_array(_mangas(pip, c))
			out.append_array(_piernas(pip, c))
			_capucha(hg, c, 0.01)
			_p(hg, _ball, pip.M.fur, Vector3(0, -0.01, 0.1), Vector3(0.12, 0.1, 0.07))
			var cm := luz(c2)
			cm.emission_energy_multiplier = 0.5
			var u := _g(hg, "cuerno", Vector3(0, 0.15, 0.07), Vector3(0.4, 0, 0))
			_p(u, _cone, cm, Vector3(0, 0.06, 0), Vector3(0.03, 0.13, 0.03))
			_an(pip, u, "brillar", 0.0, cm)
			var crin := ["#ff8fb3", "#c77dff", "#7fc8ff", "#ffcf4a"]
			for i in 4:
				_p(hg, _ball, tela(crin[i]), Vector3(0, 0.12 - i * 0.05, -0.12 - i * 0.02), Vector3(0.04, 0.04, 0.05))
		"vampiro":
			_tronco(g, tela(c0), 0.008)
			out.append_array(_mangas(pip, tela(c0)))
			_p(g, _box, tela("#ffffff"), Vector3(0, 0.1, 0.165), Vector3(0.05, 0.08, 0.01), Vector3(-0.2, 0, 0))
			var tc := tela(c1)
			tc.cull_mode = BaseMaterial3D.CULL_DISABLED
			var capa := _g(g, "capa", Vector3(0, 0.16, -0.08))
			_p(capa, _ball, tc, Vector3(0, -0.12, -0.05), Vector3(0.19, 0.21, 0.04), Vector3(0.12, 0, 0))
			_p(capa, _ball, tela(c0), Vector3(0, -0.12, -0.065), Vector3(0.195, 0.215, 0.035), Vector3(0.12, 0, 0))
			for s in [-1.0, 1.0]:
				_p(g, _cone, tela(c0), Vector3(s * 0.09, 0.2, -0.04), Vector3(0.06, 0.1, 0.02), Vector3(0, 0, -s * 0.4))
			_an(pip, capa, "ondear", 1.3)
			for s in [-1.0, 1.0]:
				_p(hg, _cone, tela("#ffffff"), Vector3(s * 0.012, -0.068, 0.165), Vector3(0.005, 0.012, 0.005), Vector3(PI, 0, 0))
		"payaso":
			_tronco(g, tela(c0), 0.01)
			out.append_array(_mangas(pip, tela(c1)))
			out.append_array(_piernas(pip, tela(c2)))
			for i in 3:
				_p(g, _ball, tela(["#ffffff", c1, c2][i]), Vector3(0, 0.12 - i * 0.05, 0.175), Vector3.ONE * 0.016)
			_p(g, _torus, tela("#ffffff"), Vector3(0, 0.15, 0.02), Vector3(0.12, 0.8, 0.12), Vector3(0.2, 0, 0))
			var nariz := brillante("#ff2e3f")
			_p(hg, _ball, nariz, Vector3(0, -0.01, 0.18), Vector3.ONE * 0.03)
			for s in [-1.0, 1.0]:
				_p(hg, _ball, tela(c1 if s > 0 else c2), Vector3(s * 0.1, 0.1, -0.02), Vector3(0.07, 0.07, 0.07))
			_p(hg, _cone, tela(c2), Vector3(0, 0.18, 0), Vector3(0.05, 0.1, 0.05))
		"heroe":
			var c := tela(c0)
			_tronco(g, c, 0.006)
			out.append_array(_mangas(pip, c))
			out.append_array(_piernas(pip, tela(c1)))
			_p(g, _star, metal(c1), Vector3(0, 0.06, 0.17), Vector3.ONE * 0.05, Vector3(-0.15, 0, 0))
			_p(g, _torus, tela(c1), Vector3(0, -0.02, -0.01), Vector3(0.155, 0.15, 0.175))
			var tc := tela("#e23b4e" if c0 != "#e85d6f" else "#3d6dfe")
			tc.cull_mode = BaseMaterial3D.CULL_DISABLED
			var capa := _g(g, "capa", Vector3(0, 0.15, -0.08))
			_p(capa, _ball, tc, Vector3(0, -0.13, -0.05), Vector3(0.17, 0.22, 0.035), Vector3(0.12, 0, 0))
			_an(pip, capa, "ondear", 1.5)
			# antifaz
			_p(hg, _ball, tela(c0), Vector3(0, 0.03, 0.11), Vector3(0.135, 0.04, 0.06))
		"momia":
			var v := tela(c0)
			_tronco(g, v, 0.006)
			for i in 6:
				var y := -0.06 + i * 0.04
				_p(g, _torus, tela("#e9e2d2"), Vector3(0, y, -0.01), Vector3(0.156 - absf(y - 0.05) * 0.4, 0.15, 0.176 - absf(y - 0.05) * 0.4), Vector3(0.1 * (i % 2 - 0.5), 0, 0.15 * (i % 2 - 0.5)))
			out.append_array(_mangas(pip, v))
			out.append_array(_piernas(pip, v))
			for i in 3:
				_p(hg, _torus, v, Vector3(0, 0.07 - i * 0.07, -0.005), Vector3(0.16, 0.15, 0.155), Vector3(0.2 * (i - 1), 0, 0.15 * (1 - i)))
			var cinta := _g(hg, "cinta", Vector3(0.1, 0.1, -0.08))
			_p(cinta, _box, v, Vector3(0, -0.04, 0), Vector3(0.02, 0.08, 0.004), Vector3(0.3, 0, 0.4))
			_an(pip, cinta, "ondear", 1.2)
		"calabaza":
			var na := brillante(c0)
			for i in 6:
				var a := TAU * i / 6.0
				_p(g, _ball, na, Vector3(sin(a) * 0.06, 0.04, cos(a) * 0.06 - 0.01), Vector3(0.12, 0.15, 0.12))
			for s in [-1.0, 1.0]:
				_p(g, _cone, tela("#2b2633"), Vector3(s * 0.05, 0.08, 0.17), Vector3(0.02, 0.025, 0.01), Vector3(PI / 2, 0, 0))
			_p(g, _box, tela("#2b2633"), Vector3(0, 0.0, 0.178), Vector3(0.08, 0.015, 0.01))
			_p(hg, _cyl, tela(c1), Vector3(0, 0.15, 0), Vector3(0.015, 0.05, 0.015), Vector3(0, 0, 0.3))
			_p(hg, _ball, tela(c1), Vector3(0.04, 0.17, 0), Vector3(0.04, 0.01, 0.025), Vector3(0, 0, 0.5))
		"panda":
			var b := tela(c0)
			var n := tela(c1)
			_tronco(g, b)
			out.append_array(_mangas(pip, n))
			out.append_array(_piernas(pip, n))
			_capucha(hg, b, 0.01)
			_p(hg, _ball, pip.M.fur, Vector3(0, -0.01, 0.1), Vector3(0.12, 0.1, 0.07))
			for s in [-1.0, 1.0]:
				_p(hg, _ball, n, Vector3(s * 0.11, 0.13, 0.0), Vector3.ONE * 0.045)
				_p(hg, _ball, n, Vector3(s * 0.065, 0.03, 0.155), Vector3(0.03, 0.035, 0.01), Vector3(0, 0, s * 0.4))
		"tiburon":
			var gr := tela(c0)
			_tronco(g, gr)
			_p(g, _ball, tela(c1), Vector3(0, 0.03, 0.1), Vector3(0.1, 0.12, 0.08))
			out.append_array(_mangas(pip, gr))
			out.append_array(_piernas(pip, gr))
			_capucha(hg, gr, 0.014)
			_p(hg, _ball, pip.M.fur, Vector3(0, -0.04, 0.11), Vector3(0.11, 0.08, 0.06))
			for i in 7:
				_p(hg, _cone, tela("#ffffff"), Vector3(-0.09 + i * 0.03, 0.035, 0.14), Vector3(0.011, 0.025, 0.011), Vector3(PI, 0, 0))
			var aleta := _g(hg, "aleta", Vector3(0, 0.15, -0.02))
			_p(aleta, _cone, gr, Vector3(0, 0.05, -0.02), Vector3(0.05, 0.1, 0.015), Vector3(-0.4, 0, 0))
			_an(pip, aleta, "balancear", 0.1)
	return out

static var _rb := {}

## Caja de bordes redondeados (para cascos y paneles).
static func rbox(s: Vector3, r: float) -> ArrayMesh:
	var key := "%s/%s" % [s, r]
	if _rb.has(key):
		return _rb[key]
	r = minf(r, minf(s.x, minf(s.y, s.z)) * 0.5 - 0.001)
	var bm := BoxMesh.new()
	bm.size = s
	bm.subdivide_width = 6
	bm.subdivide_height = 6
	bm.subdivide_depth = 6
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
	_rb[key] = m
	return m
