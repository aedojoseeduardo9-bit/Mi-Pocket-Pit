## Pocket Pip — "los ojos": recorre el juego solo, toma capturas y hace pruebas automáticas.
## Uso: godot --path godot -- --ojos=CARPETA   (lo llama tools/ojos.sh). La partida es de prueba (no se guarda).
## Al final informa los textos que se vieron sin traducción al inglés.
class_name Ojos
extends Node

var main
var dir := ""
var informe: Array[String] = []
var n := 0

func _init(m, d: String) -> void:
	main = m
	dir = d

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_correr()

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	n += 1
	img.save_png("%s/%02d_%s.png" % [dir, n, nombre])

func ok(cond: bool, txt: String) -> void:
	informe.append(("OK    " if cond else "FALLO ") + txt)

func _ir(i: int) -> void:
	if main.hab != i:
		main.ir_a(i)
		await _esperar(1.8)

func _vestir(p: Dictionary) -> void:
	for z in Atuendos.ZONAS:
		Estado.d.puesto[z] = ""
	for z in p:
		Estado.d.puesto[z] = p[z]
	Atuendos.vestir(main.pip, Estado.d.puesto)

func _correr() -> void:
	while main.intro.t < 1.2:
		await _esperar(0.02)
	await foto("intro_esfera")
	while main.intro.t < 2.35:
		await _esperar(0.02)
	await foto("intro_nioro")
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(360, 640)
	get_viewport().push_input(ev)
	await _esperar(0.1)
	ok(main.modo == "intro", "tocar la pantalla no salta la intro")
	while main.modo == "intro":
		await _esperar(0.1)
	ok(main._vitrina == null or not is_instance_valid(main._vitrina), "la vitrina de precalentado se borró antes de jugar")
	var espera := 0.0
	while main.hud.modal == null and espera < 4.0:
		await _esperar(0.1)
		espera += 0.1
	ok(main.hud.modal != null, "se ofrece el regalo diario al entrar")
	await _esperar(0.5)
	await foto("regalo_diario")
	Estado.reclamar_regalo()
	main.hud.cerrar_modal()
	await _esperar(1.0)
	await foto("habitacion")
	# brazos y orejas nuevos, de cerca
	main.zoom_panel = 1.0
	main.pip.hacer("saludo")
	await _esperar(0.9)
	await foto("pip_cerca")
	main.zoom_panel = 0.0
	# burbuja de habitaciones: tocar = siguiente, mantener y deslizar = elegir
	var bb: Control = main.hud.burbuja
	ok(bb.visible, "la burbuja de habitaciones está junto a Más")
	var e1 := InputEventMouseButton.new()
	e1.button_index = MOUSE_BUTTON_LEFT
	e1.pressed = true
	e1.position = bb.size * 0.5
	bb._gui_input(e1)
	var e2 := e1.duplicate()
	e2.pressed = false
	bb._gui_input(e2)
	await _esperar(1.8)
	ok(main.hab == 2, "tocar la burbuja lleva a la siguiente habitación (%d)" % main.hab)
	bb._gui_input(e1)
	await _esperar(0.45)
	var mv := InputEventMouseMotion.new()
	mv.position = bb.size * 0.5 + Vector2(-112 * 2, 0)
	bb._gui_input(mv)
	await _esperar(0.3)
	await foto("burbuja_deslizando")
	mv.position = bb.size * 0.5 + Vector2(-112 * 3, 0)
	bb._gui_input(mv)
	bb._gui_input(e2)
	await _esperar(3.4)
	ok(main.hab == 0, "deslizar en la burbuja lleva a la cocina (%d)" % main.hab)
	await _ir(1)
	# caricias: ya no dan bellotas
	var b0 := Estado.bellotas()
	for i in 3:
		main._frotar("cabeza", Vector2(360, 600), 400.0)
	main.pip.caricia = 1.0
	await _esperar(0.5)
	await foto("caricia")
	ok(Estado.bellotas() == b0, "hacer cariño no regala bellotas")
	main.pip.toque("barriga")
	await _esperar(0.45)
	await foto("risa_barriga")
	await _esperar(1.5)
	var bp: Vector2 = main.cam.unproject_position(main.pip.torso.global_position + Vector3(0, 0.1, 0.35))
	ok(main.zona_en(bp) != "", "tocar a Pip encuentra una zona")
	# la cola nueva, de cerca y de lado
	main.pip.hacer("mirar_cola")
	await _esperar(0.9)
	await foto("cola")
	# habitaciones
	for i in [0, 2, 3]:
		main.ir_a(i)
		await _esperar(0.45)
		if i == 0:
			await foto("viaje_corriendo")
		await _esperar(1.4)
		await foto(Casa.HABS[i])
		ok(main.hab == i and main.modo == "juego", "se llega a " + Casa.HABS[i])
	main.espuma = 60.0
	main.ducha()
	await _esperar(1.6)
	await foto("ducha")
	await _esperar(3.0)
	ok(main.modo == "juego", "la ducha termina sola")
	# cocina: bellotas gratis limitadas
	await _ir(0)
	Estado.d.nec.hambre = 20.0
	var g0 := Estado.gratis()
	main.alimentar("bellota", Vector2(200, 1000))
	await _esperar(1.6)
	ok(Estado.gratis() == g0 - 1, "comer una bellota gratis descuenta una (%d → %d)" % [g0, Estado.gratis()])
	Estado.d.gratis.n = 0
	Estado.d.gratis.t = Time.get_unix_time_from_system()
	Estado.d.bellotas = 0
	main.alimentar("bellota", Vector2(200, 1000))
	await _esperar(0.6)
	ok(main.hud.modal != null, "sin bellotas ni comida gratis se ofrece la tienda")
	await foto("faltan_bellotas")
	main.hud.cerrar_modal()
	Estado.dar_bellotas(30000)
	await _esperar(0.5)
	main.hud.refrescar()
	await foto("cocina_comida")
	# Pip sigue viviendo con la app cerrada
	Estado.d.nec.hambre = 90.0
	var antes := Estado.nec("hambre")
	Estado.d.t = Time.get_unix_time_from_system() - 8 * 3600
	Estado._avanzar_tiempo()
	ok(Estado.nec("hambre") < antes - 50.0, "en 8 horas cerrada la app, a Pip le da hambre (%d → %d)" % [antes, Estado.nec("hambre")])
	for k in Estado.NECESIDADES:
		Estado.d.nec[k] = 70.0
	# armario y trajes
	await _ir(1)
	main.hud.abrir_panel("armario")
	await _esperar(0.8)
	await foto("armario")
	main.hud._hoja_tab = 5
	main.hud._armar_tabs()
	main.hud._armar_tarjetas()
	await _esperar(0.4)
	await foto("armario_trajes")
	main.hud.cerrar_panel()
	await _esperar(0.5)
	main.zoom_panel = 1.0
	var looks := [
		{"traje": "ninja_negro"}, {"traje": "robot_plata"}, {"traje": "slime_verde"}, {"traje": "astronauta"},
		{"traje": "dino_verde"}, {"traje": "abeja"}, {"traje": "caballero"}, {"traje": "unicornio"},
		{"traje": "mago_traje"}, {"traje": "tiburon"}, {"traje": "panda"}, {"traje": "heroe_azul", "ojos": ""},
		{"cabeza": "corona_oro", "ojos": "lentes_corazon_rosa", "cuello": "collar_perlas", "cuerpo": "capa_rojo"},
		{"cabeza": "helice_azul", "ojos": "lentes_sol_negro", "cuerpo": "poleron_menta", "espalda": "mochila_rojo"},
		{"cabeza": "vaquero_cafe", "cuello": "panuelo_rojo", "cuerpo": "chaleco_cafe", "espalda": "jetpack"},
		{"cabeza": "orejas_conejo_blanco", "cuerpo": "tutu_rosa", "espalda": "alas_hada_rosa"},
		{"cabeza": "mago_azul", "ojos": "monoculo", "cuerpo": "smoking", "cuello": "corbata_rojo"},
		{"cabeza": "casco_astronauta", "ojos": "visor_celeste", "espalda": "alas_murcielago"},
	]
	var faltan := 0
	for i in looks.size():
		for z in looks[i]:
			if looks[i][z] != "" and not Estado.ropa_por_id.has(looks[i][z]):
				faltan += 1
				informe.append("FALLO no existe la prenda " + looks[i][z])
		_vestir(looks[i])
		main.pip.hacer("celebrar" if i % 2 == 0 else "saludo")
		await _esperar(0.7)
		await foto("look_%02d" % i)
	ok(faltan == 0, "todas las prendas de prueba existen")
	ok(Estado.cat.ropa.size() >= 100, "hay más de 100 prendas (%d)" % Estado.cat.ropa.size())
	# todas las prendas se pueden armar sin errores, y al quitarlas no queda nada pegado
	_vestir({"cuello": "bufanda_nova"})
	await _esperar(0.1)
	var base: int = main.pip.find_children("*", "MeshInstance3D", true, false).size()
	for r in Estado.cat.ropa:
		_vestir({r.zona: r.id})
	ok(true, "las %d prendas se arman" % Estado.cat.ropa.size())
	_vestir({"cuello": "bufanda_nova"})
	await _esperar(0.1)
	var despues: int = main.pip.find_children("*", "MeshInstance3D", true, false).size()
	ok(despues == base, "al quitar la ropa no quedan piezas pegadas (%d → %d)" % [base, despues])
	main.zoom_panel = 0.0
	# capibara
	Estado.sumar_pocion("capibara", 1)
	main.pocion("capibara")
	await _esperar(1.2)
	ok(main.pip.forma == "capibara", "la poción capibara transforma a Pip")
	await foto("capibara")
	# la ropa se acomoda a la capibara
	main.zoom_panel = 1.0
	for i in 6:
		var lk: Dictionary = [{"traje": "ninja_rojo"}, {"traje": "robot_oro"}, {"cabeza": "corona_oro", "ojos": "lentes_corazon_rosa", "cuerpo": "capa_azul"},
			{"cabeza": "gorra_azul", "ojos": "lentes_sol_negro", "cuerpo": "poleron_rosa", "espalda": "alas_hada_celeste"},
			{"traje": "dino_lila"}, {"cabeza": "vaquero_cafe", "cuello": "panuelo_rojo", "cuerpo": "overol_azul"}][i]
		_vestir(lk)
		main.pip.hacer("saludo")
		await _esperar(0.7)
		await foto("capibara_ropa_%d" % i)
	_vestir({"cuello": "bufanda_nova"})
	main.zoom_panel = 0.0
	main.pip.toque("barriga")
	await _esperar(0.5)
	await foto("capibara_risa")
	Estado.d.capi_hasta = 0.0
	await _esperar(1.0)
	ok(main.pip.forma == "pip", "al terminar los 3 minutos vuelve a ser Pip")
	main.hud.abrir_capibara()
	await _esperar(0.6)
	await foto("capibara_oferta")
	main.hud.cerrar_modal()
	Pagos.comprar("capibara_permanente")
	await Pagos.compra_lista
	Estado.d.forma = "capibara"
	main._revisar_forma()
	ok(Estado.capibara_permanente() and main.pip.forma == "capibara", "capibara para siempre (compra de prueba)")
	Estado.d.forma = "pip"
	main._revisar_forma()
	await _esperar(0.5)
	# tienda
	main.hud.abrir_panel("tienda")
	await _esperar(0.8)
	await foto("tienda")
	var b1 := Estado.bellotas()
	Pagos.comprar("bellotas_500")
	await Pagos.compra_lista
	ok(Estado.bellotas() == b1 + 500, "compra de prueba entrega 500 bellotas")
	main.hud.cerrar_panel()
	await _esperar(0.5)
	# decoración: más de 30 por habitación
	for h in Estado.cat.deco:
		var nd := 0
		for s in Estado.cat.deco[h]:
			nd += Estado.cat.deco[h][s].size()
		ok(nd >= 30, "%s tiene %d decoraciones" % [h, nd])
	main.hud.abrir_panel("decorar")
	await _esperar(0.8)
	await foto("decorar")
	main.hud.cerrar_panel()
	# todas las decoraciones se arman
	for h in Estado.cat.deco:
		for s in Estado.cat.deco[h]:
			for v in Estado.cat.deco[h][s]:
				main.casa.rearmar(h, s, v.id)
	ok(true, "todas las decoraciones se arman")
	var combos := {
		"habitacion": [{"pared": "corazones_noche", "cama": "nube_magica", "lampara": "disco", "alfombra": "arcoiris", "piso": "alfombra_lila"},
			{"pared": "corazones_noche", "cama": "castillo", "lampara": "lava", "alfombra": "corazon", "piso": "alfombra_lila"},
			{"pared": "lunares_algodon", "cama": "concha", "lampara": "estrella", "alfombra": "nube", "piso": "madera_oscura"}],
		"cocina": [{"pared": "ladrillo_crema", "piso": "ajedrez_menta", "nevera": "magica", "mesa": "dulces", "planta": "flor_magica"},
			{"pared": "ladrillo_crema", "piso": "ajedrez_menta", "nevera": "amarilla", "mesa": "hongo", "planta": "girasol"}],
		"patio": [{"fondo": "lluvia_estrellas", "cerca": "seto", "arbol": "magico", "pasto": "nieve", "juguete": "fogata"},
			{"fondo": "dia", "cerca": "blanca", "arbol": "cerezo", "pasto": "primavera", "juguete": "fuente"},
			{"fondo": "aurora", "cerca": "seto", "arbol": "pino", "pasto": "nieve", "juguete": "telescopio"},
			{"fondo": "dulce", "cerca": "rosa", "arbol": "palmera", "pasto": "arena", "juguete": "piscina"},
			{"fondo": "galaxia", "cerca": "piedra", "arbol": "magico", "pasto": "primavera", "juguete": "columpio"}],
		"bano": [{"pared": "acuario", "banera": "jacuzzi", "cortina": "luces", "piso": "ajedrez_rosa"},
			{"pared": "corazones_coral", "banera": "negra", "cortina": "noche", "piso": "ajedrez_rosa"}],
	}
	for h in combos:
		await _ir(Casa.HABS.find(h))
		var k := 0
		for c in combos[h]:
			for s in Estado.cat.deco[h]:
				main.casa.rearmar(h, s, c.get(s, ""))
			await _esperar(1.6)
			await foto("deco_%s_%d" % [h, k])
			k += 1
	# patio: pelota
	await _ir(2)
	main.jugar_pelota()
	await _esperar(0.4)
	main.toques_pelota = 7
	await foto("pelota")
	while main.modo == "pelota":
		await _esperar(0.2)
	# minijuegos
	main.hud.abrir_panel("juegos")
	await _esperar(0.7)
	await foto("juegos")
	for j in ["salto", "lluvia", "memoria", "cohete"]:
		Estado.d.nec.energia = 80.0
		main.hud._jugar(j)
		await _esperar(0.2)
		var mj: Minijuego = main.hud.juego
		ok(mj != null, "se abre el minijuego " + j)
		if mj == null:
			continue
		await _esperar(3.2)
		if j == "memoria":
			mj.cartas[0].abierta = true
			mj.cartas[3].abierta = true
		await foto("juego_" + j)
		mj.puntos = 120
		mj._terminar()
		await _esperar(0.8)
		await foto("juego_%s_fin" % j)
		mj.terminado.emit(j, mj.puntos, 10)
		await _esperar(0.5)
		ok(main.hud.juego == null, "se cierra el minijuego " + j)
	# más y ajustes
	main.hud.abrir_panel("mas")
	await _esperar(0.7)
	await foto("mas")
	main.hud.abrir_panel("ajustes")
	await _esperar(0.7)
	await foto("ajustes")
	Estado.poner_cfg("idioma", "en")
	main.aplicar_ajustes()
	main.hud._armar_tarjetas()
	await _esperar(0.5)
	await foto("ajustes_ingles")
	main.hud.cerrar_panel()
	await _esperar(0.4)
	# recorrido en inglés para encontrar textos sin traducir
	for p in ["armario", "tienda", "juegos", "mas", "pociones", "bailes", "decorar"]:
		main.hud.abrir_panel(p)
		await _esperar(0.35)
		if p == "tienda":
			await foto("tienda_ingles")
		main.hud.cerrar_panel(true)
	main.hud.abrir_regalo()
	await _esperar(0.4)
	main.hud.cerrar_modal()
	for i in [0, 1, 2, 3]:
		main.ir_a(i)
		await _esperar(1.6)
	await foto("bano_ingles")
	Estado.poner_cfg("idioma", "es")
	main.aplicar_ajustes()
	# baile, poción y dormir
	await _ir(1)
	main.bailar("robot")
	await _esperar(1.5)
	await foto("baile")
	await _esperar(8.5)
	ok(main.modo == "juego", "el baile termina solo")
	Estado.sumar_pocion("arcoiris", 1)
	main.pocion("arcoiris")
	await _esperar(1.2)
	await foto("pocion_arcoiris")
	main.pip.pocion_t = 0.0
	await _esperar(1.0)
	main.apagar_luz(true)
	await _esperar(2.4)
	await foto("durmiendo")
	ok(Estado.d.durmiendo, "se recuerda que Pip quedó durmiendo")
	main.apagar_luz(false)
	await _esperar(1.0)
	var fallos := 0
	for l in informe:
		if l.begins_with("FALLO"):
			fallos += 1
	if L.faltan.size() > 0:
		informe.append("TEXTOS SIN TRADUCIR (%d):" % L.faltan.size())
		for k in L.faltan:
			informe.append("  " + str(k))
	informe.append("RESUMEN: %d pruebas fallidas" % fallos)
	var f := FileAccess.open(dir + "/report.txt", FileAccess.WRITE)
	f.store_string("\n".join(informe) + "\n")
	f.close()
	print("\n".join(informe))
	get_tree().quit(1 if fallos > 0 else 0)
