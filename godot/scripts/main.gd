## Pocket Pip — núcleo: arma el mundo (luz, cámara, casa, Pip), muestra la intro "nioro" (no se salta),
## maneja los toques sobre Pip (toques, caricias, mirar el dedo), el paso entre habitaciones y las actividades:
## comer (cocina), dormir (habitación), pelota (patio), jabón y ducha (baño), bailes y pociones.
extends Node

const ESCALA_PIP := 2.3

var mundo: Node3D
var cam: Camera3D
var sol: DirectionalLight3D
var env: Environment
var casa: Casa
var pip: PipModel
var hud: Hud
var fx: UI.Fx
var capa_ui: CanvasLayer
var intro: IntroNioro
var negro: ColorRect

var hab := 1                  ## habitación actual (0 cocina, 1 habitación, 2 patio, 3 baño)
var modo := "intro"           ## intro, juego, viaje, panel, pelota, baile, dormir, ducha
var cam_pos := Vector3.ZERO
var cam_mira := Vector3.ZERO
var cam_pos_obj := Vector3.ZERO
var cam_mira_obj := Vector3.ZERO
var zoom_panel := 0.0         ## 0..1: acerca la cámara a Pip cuando hay un panel abierto
var _zoom_k := 0.0
var foco_deco := ""           ## ranura de decoración que mira la cámara ("" = Pip)
var _foco_k := 0.0
var luz_apagada := false
var _noche_k := 0.0

# toque
var _toque := false
var _t0 := 0.0
var _p0 := Vector2.ZERO
var _p_ult := Vector2.ZERO
var _zona := ""
var _arrastre := 0.0
var _car_acum := 0.0
var _t_corazon := 0.0
var _t_forma := 0.0
var listo := false
var _vitrina: Node3D

# actividades
var jabon := false
var espuma := 0.0
var _ducha_t := 0.0
var _zzz_t := 0.0
var pelota: MeshInstance3D
var _pel_v := Vector2.ZERO
var _pel_p := Vector2.ZERO
var toques_pelota := 0
var _baile_t := 0.0
var _nota_t := 0.0
var _musica_hab := ""
var tiempo := 0.0

func _ready() -> void:
	get_viewport().physics_object_picking = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--exportar-modelo="):
			_exportar_modelo(a.substr(18))
			return
	# 1) primero la pantalla negra de la intro (el arranque pesado ocurre detrás, sin que se note)
	var capa_intro := CanvasLayer.new()
	capa_intro.layer = 50
	add_child(capa_intro)
	negro = ColorRect.new()
	negro.color = Color.BLACK
	negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_intro.add_child(negro)
	intro = IntroNioro.new()
	capa_intro.add_child(intro)
	intro.terminada.connect(_fin_intro)
	await get_tree().process_frame
	await get_tree().process_frame
	# 2) se arma todo con la pantalla en negro
	_armar_mundo()
	capa_ui = CanvasLayer.new()
	add_child(capa_ui)
	fx = UI.Fx.new()
	hud = Hud.new(self)
	capa_ui.add_child(hud)
	capa_ui.add_child(fx)
	hud.visible = false
	Estado.subio_nivel.connect(_subio_nivel)
	Estado.cambio.connect(_revisar_forma)
	Pagos.compra_lista.connect(_compra_lista)
	aplicar_ajustes()
	# 3) se preparan los sombreadores (todavía en negro) y recién entonces corre la intro, sin el 3D detrás:
	#    así la animación nioro va fluida
	await _precalentar()
	casa.activar(Casa.HABS[hab])
	get_viewport().disable_3d = true
	listo = true
	intro.listo = true
	if OS.get_cmdline_user_args().has("--sin-intro"):
		intro.t = IntroNioro.LEN - 0.01
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ojos="):
			var o := Ojos.new(self, a.substr(7))
			add_child(o)

func _armar_mundo() -> void:
	mundo = Node3D.new()
	mundo.name = "Mundo"
	add_child(mundo)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#2a1f2e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff1e6")
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	we.environment = env
	mundo.add_child(we)
	sol = DirectionalLight3D.new()
	sol.rotation = Vector3(deg_to_rad(-52), deg_to_rad(-28), 0)
	sol.light_energy = 0.42
	sol.light_color = Color("#fff4e2")
	sol.shadow_enabled = true
	# sombras: rango corto (la casa mide ~8 m) para que cada píxel de sombra sea chico y el borde no se vea dentado;
	# sesgo un poco mayor para que las superficies curvas no se sombreen a sí mismas en rayas
	sol.shadow_blur = 1.5
	sol.shadow_bias = 0.06
	sol.shadow_normal_bias = 2.6
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sol.directional_shadow_max_distance = 8.5
	sol.directional_shadow_fade_start = 0.9
	mundo.add_child(sol)
	casa = Casa.new()
	mundo.add_child(casa)
	casa.construir()
	pip = PipModel.new()
	pip.base_scale = ESCALA_PIP
	mundo.add_child(pip)
	Atuendos.vestir(pip, Estado.d.puesto)
	hab = clampi(int(Estado.d.get("habitacion", 1)), 0, 3)
	pip.position = Vector3(casa.centro(hab), 0, 0)
	pip.accion_terminada.connect(_accion_terminada)
	# pelota del patio
	pelota = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	pelota.mesh = sm
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("#ff6b6b")
	pm.roughness = 0.35
	pelota.material_override = pm
	pelota.visible = false
	mundo.add_child(pelota)
	cam = Camera3D.new()
	cam.fov = 50.0
	cam.near = 0.1
	cam.far = 60.0
	mundo.add_child(cam)
	_objetivo_camara()
	cam_pos = cam_pos_obj
	cam_mira = cam_mira_obj
	cam.position = cam_pos
	cam.look_at(cam_mira)

func _fin_intro() -> void:
	get_viewport().disable_3d = false
	modo = "juego"
	hud.visible = true
	hud.refrescar()
	_musica()
	var tw := create_tween()
	tw.tween_property(negro, "color:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	intro.queue_free()
	await get_tree().create_timer(0.9).timeout
	if Estado.d.get("durmiendo", false) and hab == 1:
		apagar_luz(true)
	else:
		Estado.d.durmiendo = false
		pip.hacer("saludo")
		Sfx.play("feliz")
	if Estado.reembolso > 0:
		hud.toast(L.f("Te devolvimos %d bellotas de decoraciones que cambiaron", [Estado.reembolso]), UI.MENTA)
		fx.volar(hud.size * 0.5, hud.pos_bellotas(), 12)
		Estado.reembolso = 0
		Estado.guardar()
	if Estado.regalo_disponible():
		await get_tree().create_timer(0.6).timeout
		hud.abrir_regalo()

# ---------------- cámara ----------------
func _objetivo_camara() -> void:
	var x := pip.position.x if modo == "viaje" else casa.centro(hab)
	var base := Vector3(x, 1.6, 5.2)
	var mira := Vector3(x, 1.02, 0.0)
	# con un panel abierto (armario) Pip queda entero arriba del panel
	var cerca := Vector3(pip.position.x, 1.15, 5.3)
	var mira_cerca := Vector3(pip.position.x, 0.05, 0.0)
	if modo == "dormir":
		base = Vector3(x + 0.75, 1.75, 3.9)
		mira = Vector3(x + 1.0, 0.85, -1.0)
	elif modo == "pelota":
		base = Vector3(x, 1.7, 5.2)
		mira = Vector3(x, 1.35, 0.0)
	cam_pos_obj = base.lerp(cerca, _zoom_k)
	cam_mira_obj = mira.lerp(mira_cerca, _zoom_k)
	if foco_deco == "_pip_atras":
		cam_pos_obj = pip.position + Vector3(-1.5, 1.15, -1.5)
		cam_mira_obj = pip.position + Vector3(0, 0.75, 0)
	elif foco_deco == "_pip":
		# primer plano de Pip (fotos de la galería de ropa)
		cam_pos_obj = pip.position + Vector3(0.45, 1.25, 3.1)
		cam_mira_obj = pip.position + Vector3(0, 0.85, 0)
	elif foco_deco != "" and modo != "viaje":
		# decorando: encuadra el objeto arriba de la pantalla (el panel tapa la mitad de abajo)
		var f: Dictionary = casa.foco(Casa.HABS[hab], foco_deco)
		var c: Vector3 = f.c + Vector3(casa.centro(hab), 0, 0)
		var d: float = f.d
		cam_pos_obj = c + Vector3(0, d * 0.3, d)
		cam_mira_obj = c - Vector3(0, d * 0.24, 0)

func _process(dt: float) -> void:
	if not listo or (hud and hud.juego != null):
		return   # cargando, o con un minijuego abierto (el 3D no se dibuja)
	tiempo += dt
	_zoom_k = move_toward(_zoom_k, zoom_panel, dt * 2.5)
	var zk := _zoom_k * _zoom_k * (3.0 - 2.0 * _zoom_k)
	_objetivo_camara()
	var k := minf(1.0, dt * 5.0)
	cam_pos = cam_pos.lerp(cam_pos_obj, k)
	cam_mira = cam_mira.lerp(cam_mira_obj, k)
	# pequeña "respiración" de la cámara: la escena nunca se ve congelada
	var vaiven := Vector3(sin(tiempo * 0.35) * 0.03, sin(tiempo * 0.5) * 0.02, 0.0) * (1.0 - zk)
	cam.position = cam_pos + vaiven
	cam.look_at(cam_mira)
	pip.feliz = Estado.animo() / 100.0
	pip.animate(dt)
	_noche_k = move_toward(_noche_k, 1.0 if luz_apagada else 0.0, dt * 1.6)
	_aplicar_noche()
	match modo:
		"dormir":
			Estado.subir("energia", dt * 1.4)
			_zzz_t -= dt
			if _zzz_t < 0.0:
				_zzz_t = 1.3
				fx.emitir("zzz", _pantalla(pip.head.global_position) + Vector2(30, -40))
		"pelota":
			_pelota(dt)
		"baile":
			_baile_t += dt
			_nota_t -= dt
			if _nota_t < 0.0:
				_nota_t = 0.45
				var cols := [UI.ROSA, UI.LILA, UI.AZUL, UI.MENTA, UI.ORO]
				fx.emitir("nota", _pantalla(pip.global_position + Vector3(randf_range(-0.6, 0.6), 1.4, 0)), 1, cols[randi() % cols.size()])
		"ducha":
			_ducha_t += dt
			if _ducha_t > 4.0:
				_fin_ducha()
	if casa.ducha:
		var y := 2.35 if modo == "ducha" else 4.6
		casa.ducha.position.y = lerpf(casa.ducha.position.y, y, minf(1.0, dt * 4.0))
	_t_forma -= dt
	if _t_forma < 0.0:
		_t_forma = 0.5
		_revisar_forma()

## Luz de cada habitación: sol, luz ambiente, exposición y tono. La habitación (cuarto de Pip) es más tibia y
## suave: con la luz de la cocina se veía lavada y encandilaba. El baño, todo blanco, también baja un poco.
const LUZ := [
	{"sol": 0.42, "amb": 0.38, "exp": 0.95, "tono": "#fff1e6"},   # cocina
	{"sol": 0.33, "amb": 0.29, "exp": 0.84, "tono": "#ffe6d6"},   # habitación
	{"sol": 0.46, "amb": 0.40, "exp": 0.95, "tono": "#fff4e8"},   # patio
	{"sol": 0.37, "amb": 0.32, "exp": 0.87, "tono": "#f4f2ff"},   # baño
]
var _luz_x := -1.0
var _noche_aplicada := -1.0

func _aplicar_noche() -> void:
	var k := _noche_k
	# mezcla la luz de las habitaciones según dónde mira la cámara (al viajar cambia suave)
	if casa.lampara_mat:
		casa.lampara_mat.emission_energy_multiplier = lerpf(0.6, 0.05, k)
	var fx_ := clampf(cam_pos.x / Casa.ANCHO, 0.0, 3.0)
	if absf(fx_ - _luz_x) < 0.002 and k == _noche_aplicada:
		return   # nada cambió: no se toca el ambiente (cada cambio cuesta en el teléfono)
	_luz_x = fx_
	_noche_aplicada = k
	var a: Dictionary = LUZ[int(floorf(fx_))]
	var b: Dictionary = LUZ[mini(3, int(floorf(fx_)) + 1)]
	var u: float = fx_ - floorf(fx_)
	var base_sol := lerpf(float(a.sol), float(b.sol), u)
	var base_amb := lerpf(float(a.amb), float(b.amb), u)
	env.tonemap_exposure = lerpf(float(a.exp), float(b.exp), u)
	sol.light_energy = lerpf(base_sol, 0.06, k)
	env.ambient_light_energy = lerpf(base_amb, 0.16, k)
	env.ambient_light_color = Color(str(a.tono)).lerp(Color(str(b.tono)), u).lerp(Color("#6b78c9"), k)
	var vm = casa.get_meta("ventana_habitacion", null)
	if vm:
		(vm as StandardMaterial3D).emission = Color("#9fc8ff").lerp(Color("#1a2266"), k)
		(vm as StandardMaterial3D).emission_energy_multiplier = lerpf(0.22, 0.6, k)

func _pantalla(p: Vector3) -> Vector2:
	# de 3D a coordenadas de la interfaz (el lienzo está escalado)
	return _a_ui(cam.unproject_position(p))

func _a_ui(sp: Vector2) -> Vector2:
	return hud.get_global_transform_with_canvas().affine_inverse() * sp

func pip_en_pantalla() -> Vector2:
	return _pantalla(pip.global_position + Vector3(0, 0.3 * pip.scale.y, 0))

func boca_en_pantalla() -> Vector2:
	return _pantalla(pip.mouth.global_position)

# ---------------- habitaciones ----------------
var _pendiente := -1

func ir_a(i: int) -> void:
	if modo == "viaje":
		_pendiente = i    # al llegar sigue hacia la habitación señalada (burbuja deslizada)
		return
	if i == hab or modo == "intro":
		return
	if modo == "dormir":
		apagar_luz(false)
	if modo in ["pelota", "baile", "ducha"]:
		_terminar_actividad()
	var desde := hab
	hab = i
	Estado.d.habitacion = i
	modo = "viaje"
	casa.mostrar_camino(desde, i)
	Sfx.play("swipe", 1.0, -3.0)
	pip.dormir(false)
	pip.accion = ""
	pip.yaw_obj = PI / 2.0 if i > desde else -PI / 2.0
	pip.corriendo = 6.0
	hud.cambio_habitacion()
	var x := casa.centro(i)
	var dist := absf(x - pip.position.x)
	var tw := create_tween()
	tw.tween_property(pip, "position:x", x, clampf(0.55 + dist * 0.07, 0.6, 1.4)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	pip.corriendo = 0.0
	pip.yaw_obj = 0.0
	pip.land_t = 0.15
	casa.activar(Casa.HABS[hab])
	if _pendiente >= 0 and _pendiente != hab:
		var sig := _pendiente
		_pendiente = -1
		modo = "juego"
		ir_a(sig)
		return
	_pendiente = -1
	modo = "juego"
	_musica()
	hud.refrescar()
	await get_tree().create_timer(0.35).timeout
	if modo == "juego" and not pip.ocupado():
		pip.hacer("saludo" if randf() < 0.5 else "celebrar")

func _musica() -> void:
	var m := "musica_dia_0"
	if hab == 1:
		m = "musica_cuento_0"
	if modo == "dormir":
		m = "musica_noche_0"
	Sfx.musica(m)

# ---------------- toques sobre Pip ----------------
func _unhandled_input(e: InputEvent) -> void:
	if modo == "intro":
		return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_toque = true
			_t0 = tiempo
			_p0 = e.position
			_p_ult = e.position
			_arrastre = 0.0
			_zona = zona_en(e.position)
			_mirar(e.position)
			if modo == "pelota":
				_golpe_pelota(e.position)
		elif _toque:
			_toque = false
			pip.mirar_a = null
			var corto := tiempo - _t0 < 0.35 and _arrastre < 18.0
			var dx: float = e.position.x - _p0.x
			if _zona == "" and absf(dx) > 140.0 and absf(dx) > absf(e.position.y - _p0.y) * 1.5 and modo in ["juego", "dormir"]:
				ir_a(clampi(hab + (-1 if dx > 0 else 1), 0, 3))
			elif corto and _zona != "" and modo in ["juego", "dormir", "ducha"]:
				_tocar(_zona, e.position)
	elif e is InputEventMouseMotion and _toque:
		var d: float = e.position.distance_to(_p_ult)
		_arrastre += d
		_p_ult = e.position
		_mirar(e.position)
		var z := zona_en(e.position)
		if z != "" and _arrastre > 18.0:
			_frotar(z, e.position, d)

func zona_en(p: Vector2) -> String:
	var desde := cam.project_ray_origin(p)
	var hacia := desde + cam.project_ray_normal(p) * 30.0
	var q := PhysicsRayQueryParameters3D.create(desde, hacia, 2)
	q.collide_with_areas = true
	q.collide_with_bodies = false
	var r := mundo.get_world_3d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return ""
	return str((r.collider as Node).get_meta("zona", ""))

func _mirar(p: Vector2) -> void:
	if modo in ["viaje", "baile", "dormir"]:
		return
	var o := cam.project_ray_origin(p)
	var n := cam.project_ray_normal(p)
	var plano := Plane(Vector3(0, 0, 1), 0.9)
	var hit = plano.intersects_ray(o, n)
	if hit != null:
		pip.mirar_a = hit

func _tocar(zona: String, p: Vector2) -> void:
	if modo == "dormir":
		pip.hacer_queja()
		fx.emitir("zzz", p)
		return
	pip.toque(zona)
	if pip.accion == "enojo":
		Estado.subir("diversion", -3)
		hud.toast("¡Pip se enojó! Mejor hazle cariño", UI.ROJO)
		return
	fx.emitir("estrella" if zona != "barriga" else "corazon", p, 3)
	Estado.subir("diversion", 1.5)
	Estado.dar_xp(1)

func _frotar(zona: String, p: Vector2, d: float) -> void:
	if modo == "ducha" or (hab == 3 and jabon):
		# jabón: espuma donde se frota
		espuma = minf(100.0, espuma + d * 0.06)
		if randf() < 0.35:
			fx.emitir("burbuja", p, 1)
			if randf() < 0.3:
				Sfx.play("burbuja", randf_range(0.8, 1.4), -10.0)
		return
	if modo != "juego" or zona in ["pie", "nariz"]:
		return
	if pip.accion == "enojo":
		pip.accion = ""
	pip.caricia = minf(1.0, pip.caricia + d * 0.0035)
	_car_acum += d
	_t_corazon -= d
	if _t_corazon < 0.0:
		_t_corazon = 90.0
		fx.emitir("corazon", p + Vector2(0, -30), 1)
	if _car_acum > 900.0:
		_car_acum = 0.0
		Estado.subir("diversion", 3.0)
		Estado.dar_xp(1)

func _accion_terminada(nombre: String) -> void:
	if nombre == "enojo":
		pip.hacer("no")

# ---------------- cocina ----------------
func alimentar(id: String, desde: Vector2) -> void:
	if modo != "juego" or hab != 0:
		return
	var c: Dictionary = Estado.busca(Estado.cat.comida, id)
	if Estado.nec("hambre") >= 97.0:
		pip.hacer("no")
		Sfx.play("queja", 1.1, -4.0)
		hud.toast("Pip está lleno", UI.NARANJO)
		return
	if Estado.comida(id) <= 0:
		if not hud.pagar(int(c.precio)):
			return
	elif id == "bellota":
		Estado.usar_gratis()
	else:
		Estado.sumar_comida(id, -1)
	var boca := boca_en_pantalla()
	pip.mirar_a = pip.mouth.global_position + Vector3(0, 0.3, 1.0)
	hud.volar_icono("comida_" + id, desde, boca, 0.55, func():
		pip.mirar_a = null
		pip.hacer("comer")
		Estado.subir("hambre", float(c.llena))
		Estado.dar_xp(3)
		fx.emitir("corazon", boca + Vector2(0, -40), 2)
		hud.refrescar()
		if c.has("efecto"):
			_efecto_comida(str(c.efecto)))

## Comidas exóticas (regalos de nivel): cada una le hace algo a Pip.
func _efecto_comida(ef: String) -> void:
	await get_tree().create_timer(0.75).timeout
	match ef:
		"fuego":
			pip.hacer("sacudir")
			hud.toast("¡Pica, pica! ¡Pip echa fuego!", Color("#ff4d3a"))
			Sfx.play("dash", 0.8)
			for i in 14:
				fx.emitir("chispa", boca_en_pantalla() + Vector2(0, 16), 5, Color("#ff7a2a") if i % 2 else Color("#ffcf4a"))
				await get_tree().create_timer(0.1).timeout
		"frio":
			pip.hacer("sacudir")
			hud.toast("¡Brrr! Helado de estrellas", Color("#7fd8ff"))
			for i in 10:
				fx.emitir("burbuja", pip_en_pantalla() + Vector2(randf_range(-120, 120), -160), 3, Color("#e8f6ff"))
				await get_tree().create_timer(0.15).timeout
		_:
			# brillo, gigante, fantasma, arcoiris o mini: como una poción corta
			pip.tomar_pocion(ef, 20.0)
			Sfx.play("crystal")
			fx.emitir("estrella", pip_en_pantalla() + Vector2(0, -120), 8)

# ---------------- habitación: dormir ----------------
func apagar_luz(on: bool) -> void:
	if on == luz_apagada:
		return
	luz_apagada = on
	Estado.d.durmiendo = on
	Estado.marcar()
	Sfx.play("tic", 0.7)
	if on:
		modo = "dormir"
		pip.yaw_obj = 0.0
		var cama := Vector3(casa.centro(1), 0, 0) + casa.cama_pos + Vector3(0, casa.cama_alto, 0.15)
		var tw := create_tween()
		pip.corriendo = 3.0
		tw.tween_property(pip, "position", cama, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished
		pip.corriendo = 0.0
		if luz_apagada:
			pip.dormir(true)
	else:
		pip.dormir(false)
		if modo == "dormir":
			modo = "juego"
		var tw := create_tween()
		tw.tween_interval(0.6)
		tw.tween_property(pip, "position", Vector3(casa.centro(hab), 0, 0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		Estado.dar_xp(4)
	_musica()
	hud.refrescar()

# ---------------- baño ----------------
func usar_jabon() -> void:
	jabon = not jabon
	if jabon:
		hud.toast("Frota a Pip para hacer espuma", UI.AZUL)
	hud.refrescar()

func ducha() -> void:
	if modo != "juego" or hab != 3:
		return
	modo = "ducha"
	jabon = false
	_ducha_t = 0.0
	casa.gotas.emitting = true
	Sfx.set_agua(true)
	pip.hacer("bostezo")
	hud.refrescar()

func _fin_ducha() -> void:
	casa.gotas.emitting = false
	Sfx.set_agua(false)
	modo = "juego"
	var gana := 18.0 + espuma * 0.45
	Estado.subir("higiene", gana)
	Estado.dar_xp(4)
	pip.mojado = 1.0
	pip.hacer("sacudir")
	pip.hacer("celebrar", true)
	espuma = 0.0
	var p := pip_en_pantalla()
	fx.emitir("chispa", p + Vector2(0, -120), 16, Color("#bfe9ff"))
	fx.emitir("estrella", p + Vector2(0, -160), 4)
	hud.refrescar()

# ---------------- patio: pelota ----------------
func jugar_pelota() -> void:
	if modo != "juego" or hab != 2:
		return
	modo = "pelota"
	toques_pelota = 0
	_pel_p = Vector2(0.0, 2.6)
	_pel_v = Vector2(randf_range(-0.4, 0.4), 0.0)
	pelota.visible = true
	hud.refrescar()

func _pelota(dt: float) -> void:
	_pel_v.y -= 5.2 * dt
	_pel_p += _pel_v * dt
	if absf(_pel_p.x) > 0.95:
		_pel_p.x = signf(_pel_p.x) * 0.95
		_pel_v.x = -_pel_v.x * 0.8
	pelota.position = Vector3(casa.centro(2) + _pel_p.x, _pel_p.y, 0.8)
	pelota.rotation.z -= _pel_v.x * dt * 4.0
	pip.mirar_a = pelota.global_position
	if _pel_p.y < 0.16:
		_fin_pelota()

func _golpe_pelota(p: Vector2) -> void:
	var sp := cam.unproject_position(pelota.global_position)
	var borde := cam.unproject_position(pelota.global_position + Vector3(0.16, 0, 0))
	var r := absf(borde.x - sp.x)
	var real_p := p
	if real_p.distance_to(sp) < r * 2.4 + 30.0:
		toques_pelota += 1
		_pel_v.y = 4.6 + randf() * 0.4
		_pel_v.x = clampf((sp.x - real_p.x) / maxf(1.0, r) * 0.5 + randf_range(-0.3, 0.3), -1.4, 1.4)
		Sfx.play("pop", 0.9 + minf(0.6, toques_pelota * 0.03))
		fx.emitir("chispa", _a_ui(sp), 6, UI.ORO)
		if toques_pelota % 5 == 0:
			fx.emitir("texto", _a_ui(sp) + Vector2(0, -60), 1, UI.ORO, "¡%d!" % toques_pelota)
			pip.hacer("celebrar")
		hud.refrescar()

func _fin_pelota() -> void:
	modo = "juego"
	pelota.visible = false
	pip.mirar_a = null
	var premio := toques_pelota
	if premio > 0:
		Estado.subir("diversion", minf(30.0, 4.0 + premio * 1.5))
		Estado.dar_xp(2 + premio / 2)
		Estado.dar_bellotas(premio)
		fx.volar(pip_en_pantalla(), hud.pos_bellotas(), mini(premio, 12))
		hud.toast("¡%d toques! +%d bellotas" % [premio, premio], UI.MENTA)
		pip.hacer("celebrar")
	else:
		pip.hacer("no")
	hud.refrescar()

# ---------------- bailes y pociones ----------------
func bailar(id: String) -> void:
	if modo not in ["juego"]:
		return
	var b: Dictionary = Estado.busca(Estado.cat.bailes, id)
	modo = "baile"
	_baile_t = 0.0
	Sfx.musica(str(b.get("musica", "musica_dia_0")))
	pip.mirar_a = null
	pip.hacer("baile_" + id)
	hud.refrescar()

func _terminar_actividad() -> void:
	match modo:
		"pelota":
			pelota.visible = false
		"ducha":
			casa.gotas.emitting = false
			Sfx.set_agua(false)
		"baile":
			pip.accion = ""
	modo = "juego"

func pocion(id: String) -> void:
	var p: Dictionary = Estado.busca(Estado.cat.pociones, id)
	if Estado.pociones(id) <= 0:
		return
	Estado.sumar_pocion(id, -1)
	if id == "capibara":
		Estado.d.capi_hasta = Time.get_unix_time_from_system() + float(p.segundos)
		Estado.marcar()
		_revisar_forma()
		return
	pip.tomar_pocion(id, float(p.segundos))
	Sfx.play("crystal")
	var c := pip_en_pantalla()
	fx.emitir("chispa", c + Vector2(0, -100), 22, Color(str(p.color)))
	Estado.dar_xp(2)

func _subio_nivel(n: int) -> void:
	hud.toast(L.f("¡Nivel %d! +%d bellotas", [n, 20 + n * 5]), UI.ORO)
	Sfx.play("level")
	pip.hacer("celebrar", true)
	fx.emitir("estrella", pip_en_pantalla() + Vector2(0, -150), 10)
	hud.avisar_nivel(n)

func _compra_lista(id: String, n: int) -> void:
	Sfx.play("chest")
	if n > 0:
		fx.volar(hud.size * 0.5, hud.pos_bellotas(), 16)
		hud.toast(L.f("+%d bellotas (compra de prueba)", [n]), UI.MENTA)
	if id == "capibara_permanente":
		hud.toast("¡La capibara es tuya para siempre!", UI.MENTA)
		_revisar_forma()
	pip.hacer("celebrar")

## Llamado cada cuadro por Pip al terminar un baile (ver _process).
func _physics_process(_dt: float) -> void:
	if not listo:
		return
	if modo == "baile" and pip.accion == "":
		modo = "juego"
		Estado.subir("diversion", 12.0)
		Estado.dar_xp(5)
		_musica()
		hud.refrescar()

# ---------------- ajustes ----------------
func aplicar_ajustes() -> void:
	var q := int(Estado.cfg("calidad"))
	sol.shadow_enabled = q >= 1
	sol.shadow_blur = 1.5
	env.glow_enabled = q >= 1
	get_viewport().msaa_3d = Viewport.MSAA_4X if q >= 2 else (Viewport.MSAA_2X if q == 1 else Viewport.MSAA_DISABLED)
	get_viewport().scaling_3d_scale = 1.0 if q >= 1 else 0.75
	Engine.max_fps = 60 if q >= 1 else 30
	RenderingServer.directional_shadow_atlas_set_size(4096 if q >= 2 else 2048, true)
	var idioma := str(Estado.cfg("idioma"))
	if idioma != L.idioma:
		L.cambiar(idioma)
		if hud:
			hud.cambio_habitacion()
			hud.queue_redraw()

func vibrar(ms := 18) -> void:
	if Estado.cfg("vibrar"):
		Input.vibrate_handheld(ms)

# ---------------- capibara ----------------
func _revisar_forma() -> void:
	var quiere := "capibara" if Estado.capibara_activa() else "pip"
	if quiere == pip.forma:
		return
	pip.set_forma(quiere)
	Atuendos.vestir(pip, Estado.d.puesto)
	Sfx.play("crystal", 0.8)
	fx.emitir("chispa", pip_en_pantalla() + Vector2(0, -60), 28, Color("#ffd9a8"))
	fx.emitir("estrella", pip_en_pantalla() + Vector2(0, -90), 6)
	pip.hacer("celebrar")
	if quiere == "capibara":
		hud.toast("¡Pip es una capibara!", Color("#b07a45"))

# ---------------- sin tirones ----------------
## Durante la intro (que tapa la pantalla) se dibuja una vez cada tipo de material, la ropa animada, la capibara
## y las partículas: así el teléfono prepara sus sombreadores antes de jugar y no se traba la primera vez.
func _precalentar() -> void:
	_vitrina = Node3D.new()
	_vitrina.position = Vector3(casa.centro(hab), 0.2, 1.6)
	mundo.add_child(_vitrina)
	var mats: Array = Atuendos.muestras()
	mats.append_array([casa.mat("#ffffff", 0.5, 1.0), casa.mat("#ffffff"), pip.M.fur, pip.M.eye, pip.M["cola"]])
	var esfera := SphereMesh.new()
	esfera.radius = 0.05
	esfera.height = 0.1
	for i in mats.size():
		var m := MeshInstance3D.new()
		m.mesh = esfera
		m.material_override = mats[i]
		m.position = Vector3(-0.6 + i * 0.1, 0.5, 0)
		_vitrina.add_child(m)
	# un Pip de muestra con un traje, alas y casco (sombras y transparencias incluidas)
	var muestra := PipModel.new()
	muestra.scale = Vector3.ONE * 0.8
	_vitrina.add_child(muestra)
	Atuendos.vestir(muestra, {"traje": "slime_verde", "espalda": "alas_hada_celeste", "ojos": "visor_celeste"})
	var capi := PipModel.new()
	capi.scale = Vector3.ONE * 0.8
	capi.position.x = 0.5
	_vitrina.add_child(capi)
	capi.set_forma("capibara")
	if casa.cielo_mat:
		var q := MeshInstance3D.new()
		q.mesh = QuadMesh.new()
		q.material_override = casa.cielo_mat
		q.position = Vector3(0.6, 0.8, 0)
		q.scale = Vector3.ONE * 0.2
		_vitrina.add_child(q)
	for m in casa.muestras():
		var e := MeshInstance3D.new()
		e.mesh = esfera
		e.material_override = m
		e.position = Vector3(randf_range(-0.6, 0.6), 0.9, 0)
		_vitrina.add_child(e)
	casa.muestras_particulas(_vitrina)
	casa.gotas.emitting = true
	pelota.visible = true
	for i in 6:
		await RenderingServer.frame_post_draw
	casa.gotas.emitting = false
	pelota.visible = false
	_vitrina.queue_free()

## Exporta el modelo "de fábrica" de Pip y la capibara (para el editor de Pip):
## godot --headless --path godot -- --exportar-modelo=<archivo.json>
func _exportar_modelo(ruta: String) -> void:
	PipModel.sin_datos = not ruta.ends_with("_cargado.json")
	var m := PipModel.new()
	for i in m.tail.size():
		m.tail[i].rotation.x = PipModel.TAIL_BASE[i]
	var f := FileAccess.open(ruta, FileAccess.WRITE)
	f.store_string(JSON.stringify(m.exportar()))
	f.close()
	print("modelo exportado: ", ruta)
	m.free()
	get_tree().quit()
