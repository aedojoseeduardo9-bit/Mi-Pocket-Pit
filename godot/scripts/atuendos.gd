## Pocket Pip — la ropa de Pip en 3D. Cada prenda se arma con piezas y se cuelga de un hueso del esqueleto
## (cabeza, torso, brazos, cuello): así se mueve con él en todas las animaciones.
## Zonas: "cabeza", "ojos", "cuerpo", "cuello". Para una prenda nueva: añadirla en data/catalogo.json y su forma aquí.
class_name Atuendos

static var _ball: SphereMesh
static var _cyl: CylinderMesh
static var _cone: CylinderMesh
static var _torus: TorusMesh
static var _box: BoxMesh
static var _heart: ArrayMesh
static var _star: ArrayMesh

static func _geos() -> void:
	if _ball != null:
		return
	_ball = SphereMesh.new()
	_ball.radius = 1.0
	_ball.height = 2.0
	_ball.radial_segments = 28
	_ball.rings = 14
	_cyl = CylinderMesh.new()
	_cyl.top_radius = 1.0
	_cyl.bottom_radius = 1.0
	_cyl.height = 1.0
	_cyl.radial_segments = 28
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 1.0
	_cone.height = 1.0
	_cone.radial_segments = 16
	_torus = TorusMesh.new()
	_torus.inner_radius = 0.82
	_torus.outer_radius = 1.0
	_torus.rings = 40
	_torus.ring_segments = 10
	_box = BoxMesh.new()
	_box.size = Vector3.ONE
	var hp := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		# corazón paramétrico
		var x := 16.0 * pow(sin(a), 3)
		var y := 13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a)
		hp.append(Vector2(x, y) / 17.0)
	_heart = extruir(hp, 0.15)
	var sp := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0 + PI / 2.0
		var r := 0.45 if i % 2 else 1.0
		sp.append(Vector2(cos(a) * r, sin(a) * r))
	_star = extruir(sp, 0.18)

## Malla de un polígono 2D con grosor (mirando hacia +z).
static func extruir(poly: PackedVector2Array, z: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var idx := Geometry2D.triangulate_polygon(poly)
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
		idx = Geometry2D.triangulate_polygon(poly)
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

static func tela(c: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.95
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	m.rim_enabled = true
	m.rim = 0.25
	m.rim_tint = 0.5
	return m

static func metal(c: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.metallic = 0.75
	m.roughness = 0.28
	m.emission_enabled = true
	m.emission = Color(c) * 0.18
	return m

static func brillante(c: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.15
	m.metallic_specular = 0.9
	return m

static func vidrio(c: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.05
	m.metallic_specular = 1.0
	return m

static func _p(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, sc: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.scale = sc
	m.rotation = rot
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if maxf(sc.x, maxf(sc.y, sc.z)) > 0.05 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m

static func _g(parent: Node3D, nombre: String) -> Node3D:
	var g := Node3D.new()
	g.name = nombre
	parent.add_child(g)
	return g

## Viste a Pip con `puesto` = {zona: id}. Quita lo anterior.
static func vestir(pip: PipModel, puesto: Dictionary) -> void:
	_geos()
	for o in pip.get_meta("ropa", []):
		if is_instance_valid(o):
			o.queue_free()
	var piezas: Array = []
	var cuerpo := str(puesto.get("cuerpo", ""))
	var cuello := str(puesto.get("cuello", ""))
	pip.scarf.visible = cuello == "bufanda_nova"
	# con ropa en el cuerpo se esconde la pancita crema (si no, atraviesa la tela)
	for c in pip.torso.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override == pip.M.cream:
			c.visible = cuerpo == ""
	for zona in ["cabeza", "ojos", "cuerpo", "cuello"]:
		var id := str(puesto.get(zona, ""))
		if id == "" or id == "bufanda_nova":
			continue
		var ps := _armar(pip, id)
		piezas.append_array(ps)
	pip.set_meta("ropa", piezas)

static func _armar(pip: PipModel, id: String) -> Array:
	var H := pip.head
	var T := pip.torso
	var out: Array = []
	match id:
		# ---------- cabeza ----------
		"gorro_lana":
			var g := _g(H, id)
			var lana := tela("#e85d6f")
			var blanco := tela("#fff4ec")
			_p(g, _ball, lana, Vector3(0, 0.07, -0.005), Vector3(0.163, 0.115, 0.158))
			_p(g, _torus, blanco, Vector3(0, 0.07, 0), Vector3(0.162, 0.25, 0.158), Vector3(0.12, 0, 0))
			_p(g, _ball, blanco, Vector3(0, 0.19, -0.02), Vector3.ONE * 0.045)
			for i in 5:
				var a := -0.9 + i * 0.45
				_p(g, _cyl, tela("#c94456"), Vector3(sin(a) * 0.15, 0.12, cos(a) * 0.12 - 0.01), Vector3(0.006, 0.07, 0.006), Vector3(0, 0, -sin(a) * 0.5))
			out.append(g)
		"gorra_nova":
			var g := _g(H, id)
			var c := tela("#3d5afe")
			_p(g, _ball, c, Vector3(0, 0.075, -0.01), Vector3(0.158, 0.11, 0.155))
			_p(g, _cyl, c, Vector3(0, 0.085, 0.14), Vector3(0.11, 0.008, 0.09), Vector3(-0.18, 0, 0))
			_p(g, _star, metal("#ffd36e"), Vector3(0, 0.13, 0.12), Vector3.ONE * 0.03, Vector3(-0.55, 0, 0))
			_p(g, _ball, tela("#ffffff"), Vector3(0, 0.185, -0.01), Vector3.ONE * 0.014)
			g.rotation.z = -0.08
			out.append(g)
		"sombrero_copa":
			var g := _g(H, id)
			var negro := tela("#2b2633")
			_p(g, _cyl, negro, Vector3(0, 0.12, 0), Vector3(0.16, 0.012, 0.16))
			_p(g, _cyl, negro, Vector3(0, 0.2, 0), Vector3(0.1, 0.16, 0.1))
			_p(g, _cyl, tela("#c0394b"), Vector3(0, 0.145, 0), Vector3(0.102, 0.03, 0.102))
			_p(g, _ball, tela("#ffd36e"), Vector3(0.07, 0.15, 0.07), Vector3.ONE * 0.018)
			g.rotation = Vector3(-0.1, 0, 0.18)
			g.position = Vector3(-0.02, 0, 0)
			out.append(g)
		"corona":
			var g := _g(H, id)
			var oro := metal("#ffcf4a")
			_p(g, _cyl, oro, Vector3(0, 0.15, 0), Vector3(0.1, 0.045, 0.1))
			for i in 6:
				var a := TAU * i / 6.0
				_p(g, _cone, oro, Vector3(sin(a) * 0.092, 0.2, cos(a) * 0.092), Vector3(0.026, 0.06, 0.026))
				_p(g, _ball, oro, Vector3(sin(a) * 0.092, 0.235, cos(a) * 0.092), Vector3.ONE * 0.011)
			var gemas := ["#ff4d6d", "#4dd2ff", "#7dff8a"]
			for i in 3:
				var a := -0.6 + i * 0.6
				_p(g, _ball, brillante(gemas[i]), Vector3(sin(a) * 0.1, 0.15, cos(a) * 0.1), Vector3(0.016, 0.016, 0.01))
			g.rotation.z = 0.12
			out.append(g)
		"flor":
			var g := _g(H, id)
			var rosa := tela("#ffb3c7")
			for i in 5:
				var a := TAU * i / 5.0
				_p(g, _ball, rosa, Vector3(cos(a) * 0.028, sin(a) * 0.028, 0), Vector3(0.026, 0.02, 0.008), Vector3(0, 0, a))
			_p(g, _ball, tela("#ffd36e"), Vector3(0, 0, 0.006), Vector3.ONE * 0.014)
			g.position = Vector3(0.1, 0.1, 0.07)
			g.rotation = Vector3(-0.3, 0.6, 0)
			out.append(g)
		"audifonos":
			var g := _g(H, id)
			var c := tela("#7c4dff")
			var arco := _p(g, _torus, c, Vector3(0, 0.0, 0), Vector3(0.17, 0.4, 0.17), Vector3(0, 0, PI / 2))
			arco.rotation = Vector3(PI / 2, 0, 0)
			arco.rotation = Vector3(0, PI / 2, PI / 2)
			for s in [-1.0, 1.0]:
				_p(g, _cyl, c, Vector3(s * 0.16, -0.01, 0), Vector3(0.05, 0.03, 0.05), Vector3(0, 0, PI / 2))
				_p(g, _cyl, tela("#2b2633"), Vector3(s * 0.142, -0.01, 0), Vector3(0.042, 0.012, 0.042), Vector3(0, 0, PI / 2))
			out.append(g)
		# ---------- ojos ----------
		"lentes_sol":
			var g := _g(H, id)
			var marco := tela("#1e1a24")
			var luna := vidrio("#20202a")
			(luna as StandardMaterial3D).albedo_color.a = 0.88
			for s in [-1.0, 1.0]:
				_p(g, _cyl, luna, Vector3(s * 0.07, 0.025, 0.152), Vector3(0.05, 0.006, 0.045), Vector3(PI / 2, 0, 0))
				_p(g, _torus, marco, Vector3(s * 0.07, 0.025, 0.152), Vector3(0.052, 0.12, 0.047), Vector3(PI / 2, 0, 0))
				_p(g, _box, marco, Vector3(s * 0.135, 0.03, 0.08), Vector3(0.006, 0.008, 0.14), Vector3(0, s * 0.35, 0))
			_p(g, _box, marco, Vector3(0, 0.035, 0.162), Vector3(0.04, 0.008, 0.008))
			out.append(g)
		"lentes_corazon":
			var g := _g(H, id)
			var luna := vidrio("#ff4f86")
			(luna as StandardMaterial3D).albedo_color.a = 0.82
			var marco := tela("#ff8fb3")
			for s in [-1.0, 1.0]:
				_p(g, _heart, luna, Vector3(s * 0.072, 0.028, 0.155), Vector3(0.055, 0.052, 0.04))
				_p(g, _box, marco, Vector3(s * 0.135, 0.03, 0.08), Vector3(0.006, 0.008, 0.14), Vector3(0, s * 0.35, 0))
			_p(g, _box, marco, Vector3(0, 0.04, 0.16), Vector3(0.04, 0.008, 0.008))
			out.append(g)
		"lentes_redondos":
			var g := _g(H, id)
			var marco := metal("#d4a24c")
			var luna := vidrio("#e8f4ff")
			(luna as StandardMaterial3D).albedo_color.a = 0.25
			for s in [-1.0, 1.0]:
				_p(g, _torus, marco, Vector3(s * 0.07, 0.025, 0.15), Vector3(0.045, 0.1, 0.045), Vector3(PI / 2, 0, 0))
				_p(g, _cyl, luna, Vector3(s * 0.07, 0.025, 0.15), Vector3(0.042, 0.003, 0.042), Vector3(PI / 2, 0, 0))
				_p(g, _box, marco, Vector3(s * 0.135, 0.03, 0.08), Vector3(0.004, 0.005, 0.14), Vector3(0, s * 0.35, 0))
			_p(g, _box, marco, Vector3(0, 0.035, 0.158), Vector3(0.03, 0.005, 0.005))
			out.append(g)
		# ---------- cuerpo ----------
		"poleron_menta", "camiseta_estrella", "overol", "capa_real":
			out.append_array(_ropa_cuerpo(pip, id))
		# ---------- cuello ----------
		"mono_rojo":
			var g := _g(T, id)
			var rojo := tela("#e23b4e")
			for s in [-1.0, 1.0]:
				_p(g, _cone, rojo, Vector3(s * 0.03, 0, 0), Vector3(0.028, 0.045, 0.012), Vector3(0, 0, -s * PI / 2))
			_p(g, _ball, tela("#b8283a"), Vector3(0, 0, 0.004), Vector3(0.014, 0.014, 0.012))
			g.position = Vector3(0, 0.15, 0.115)
			g.rotation.x = -0.25
			out.append(g)
		"collar_bellotas":
			var g := _g(T, id)
			_p(g, _torus, tela("#7a4b2a"), Vector3.ZERO, Vector3(0.095, 0.15, 0.095), Vector3(0.2, 0, 0))
			for i in 5:
				var a := -1.0 + i * 0.5
				var b := _g(g, "b%d" % i)
				b.position = Vector3(sin(a) * 0.092, -0.012 - absf(sin(a)) * -0.01, cos(a) * 0.09)
				_p(b, _ball, brillante("#c58a4a"), Vector3(0, -0.012, 0), Vector3(0.012, 0.015, 0.012))
				_p(b, _ball, tela("#6b4226"), Vector3(0, 0.0, 0), Vector3(0.013, 0.007, 0.013))
			g.position = Vector3(0, 0.145, 0.03)
			out.append(g)
		"panuelo_azul":
			var g := _g(T, id)
			var azul := tela("#2f7de1")
			_p(g, _torus, azul, Vector3.ZERO, Vector3(0.1, 0.3, 0.1), Vector3(0.2, 0, 0))
			_p(g, _cone, azul, Vector3(0, -0.04, 0.09), Vector3(0.06, 0.07, 0.01), Vector3(PI + 0.25, 0, 0))
			for i in 4:
				_p(g, _ball, tela("#ffffff"), Vector3(-0.02 + (i % 2) * 0.03, -0.03 - (i / 2) * 0.025, 0.1), Vector3.ONE * 0.005)
			g.position = Vector3(0, 0.145, 0.03)
			out.append(g)
	return out

## Ropa que cubre el torso (y mangas en los brazos).
static func _ropa_cuerpo(pip: PipModel, id: String) -> Array:
	var T := pip.torso
	var out: Array = []
	var g := _g(T, id)
	out.append(g)
	match id:
		"poleron_menta":
			var c := tela("#7fd8be")
			var c2 := tela("#5fbfa4")
			_p(g, _ball, c, Vector3(0, 0.05, -0.01), Vector3(0.162, 0.15, 0.18))
			_p(g, _box, c2, Vector3(0, 0.0, 0.158), Vector3(0.12, 0.05, 0.02), Vector3(-0.25, 0, 0))   # bolsillo canguro
			_p(g, _ball, c2, Vector3(0, 0.15, -0.09), Vector3(0.11, 0.07, 0.07))                       # gorro caído
			for s in [-1.0, 1.0]:
				_p(g, _cyl, tela("#ffffff"), Vector3(s * 0.025, 0.1, 0.15), Vector3(0.004, 0.05, 0.004), Vector3(-0.3, 0, 0))
			_p(g, _torus, c2, Vector3(0, -0.07, -0.01), Vector3(0.14, 0.3, 0.15))                      # puño de abajo
		"camiseta_estrella":
			var c := tela("#fff3c4")
			_p(g, _ball, c, Vector3(0, 0.05, -0.01), Vector3(0.16, 0.148, 0.178))
			_p(g, _star, metal("#ffb703"), Vector3(0, 0.06, 0.162), Vector3.ONE * 0.045, Vector3(-0.15, 0, 0))
			_p(g, _torus, tela("#ffb703"), Vector3(0, 0.155, 0.02), Vector3(0.08, 0.25, 0.08), Vector3(0.2, 0, 0))
		"overol":
			var jean := tela("#4a6fa5")
			var camisa := tela("#ffe0a8")
			_p(g, _ball, camisa, Vector3(0, 0.05, -0.01), Vector3(0.158, 0.146, 0.176))
			var abajo := _p(g, _ball, jean, Vector3(0, 0.0, -0.01), Vector3(0.166, 0.12, 0.184))
			abajo.position.y = 0.0
			_p(g, _box, jean, Vector3(0, 0.07, 0.165), Vector3(0.1, 0.08, 0.02), Vector3(-0.2, 0, 0))   # peto
			for s in [-1.0, 1.0]:
				_p(g, _box, jean, Vector3(s * 0.06, 0.13, 0.1), Vector3(0.022, 0.12, 0.012), Vector3(-0.6, 0, 0))
				_p(g, _ball, metal("#ffd36e"), Vector3(s * 0.045, 0.1, 0.172), Vector3.ONE * 0.01)
		"capa_real":
			var roja := tela("#b3123d")
			roja.cull_mode = BaseMaterial3D.CULL_DISABLED
			var capa := _g(g, "capa")
			capa.position = Vector3(0, 0.15, -0.08)
			_p(capa, _ball, roja, Vector3(0, -0.12, -0.04), Vector3(0.17, 0.2, 0.05), Vector3(0.12, 0, 0))
			_p(capa, _ball, tela("#7d0b2a"), Vector3(0, -0.12, -0.025), Vector3(0.155, 0.19, 0.04), Vector3(0.12, 0, 0))
			_p(g, _torus, tela("#fff8f0"), Vector3(0, 0.15, 0.02), Vector3(0.11, 0.55, 0.11), Vector3(0.2, 0, 0))
			for i in 6:
				var a := -1.2 + i * 0.48
				_p(g, _ball, tela("#1e1a24"), Vector3(sin(a) * 0.11, 0.16, cos(a) * 0.11 + 0.02), Vector3.ONE * 0.007)
			_p(g, _ball, metal("#ffd36e"), Vector3(0, 0.15, 0.13), Vector3.ONE * 0.016)
			return out
	# mangas
	var manga := {"poleron_menta": "#7fd8be", "camiseta_estrella": "#fff3c4", "overol": "#ffe0a8"}
	for a in pip.arms:
		var m := _p(a, _ball, tela(manga[id]), Vector3(0, -0.03 if id == "poleron_menta" else -0.02, 0.01),
			Vector3(0.031, 0.05 if id == "poleron_menta" else 0.03, 0.033))
		out.append(m)
	return out
