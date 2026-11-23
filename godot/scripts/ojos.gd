## Pocket Pip — "los ojos": recorre el juego solo, toma capturas y hace pruebas automáticas.
## Uso: godot --path godot -- --ojos=CARPETA   (lo llama tools/ojos.sh). La partida es de prueba (no se guarda).
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
	var f := "%s/%02d_%s.png" % [dir, n, nombre]
	img.save_png(f)
	informe.append("captura %s" % f.get_file())

func ok(cond: bool, txt: String) -> void:
	informe.append(("OK    " if cond else "FALLO ") + txt)

func _correr() -> void:
	# la intro avanza a su ritmo (en un PC lento va más despacio): se espera por su reloj
	while main.intro.t < 1.2:
		await _esperar(0.02)
	await foto("intro_esfera")
	while main.intro.t < 2.35:
		await _esperar(0.02)
	await foto("intro_nioro")
	ok(main.modo == "intro", "la intro sigue durante su tiempo (no se salta)")
	# un toque durante la intro no la salta
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = Vector2(360, 640)
	get_viewport().push_input(ev)
	await _esperar(0.1)
	ok(main.modo == "intro", "tocar la pantalla no salta la intro")
	while main.modo == "intro":
		await _esperar(0.1)
	var espera := 0.0
	while main.hud.modal == null and espera < 4.0:
		await _esperar(0.1)
		espera += 0.1
	ok(main.hud.modal != null, "se ofrece el regalo diario al entrar")
	await _esperar(0.5)
	await foto("regalo_diario")
	var antes: int = Estado.bellotas()
	Estado.reclamar_regalo()
	main.hud.cerrar_modal()
	ok(Estado.bellotas() > antes, "el regalo diario da bellotas")
	await _esperar(1.2)
	await foto("habitacion")
	# caricias y toques
	main.pip.caricia = 1.0
	await _esperar(0.5)
	await foto("caricia")
	main.pip.toque("barriga")
	await _esperar(0.45)
	await foto("risa_barriga")
	await _esperar(1.5)
	main.pip.toque("nariz")
	await _esperar(0.3)
	await foto("boop_nariz")
	await _esperar(1.5)
	# zona tocable: el rayo encuentra la barriga de Pip
	var bp: Vector2 = main.cam.unproject_position(main.pip.torso.global_position + Vector3(0, 0.1, 0.35))
	var z: String = main.zona_en(bp)
	ok(z != "", "tocar a Pip encuentra una zona (%s)" % z)
	# habitaciones
	for i in [0, 2, 3]:
		main.ir_a(i)
		await _esperar(0.45)
		if i == 0:
			await foto("viaje_corriendo")
		await _esperar(1.4)
		await foto(Casa.HABS[i])
		ok(main.hab == i and main.modo == "juego", "se llega a " + Casa.HABS[i])
	# baño: ducha
	main.espuma = 60.0
	main.ducha()
	await _esperar(1.6)
	await foto("ducha")
	await _esperar(3.0)
	ok(main.modo == "juego", "la ducha termina sola")
	# patio: pelota
	main.ir_a(2)
	await _esperar(1.8)
	main.jugar_pelota()
	await _esperar(0.4)
	main.toques_pelota = 7
	await foto("pelota")
	while main.modo == "pelota":
		await _esperar(0.2)
	ok(true, "el juego de la pelota termina")
	# cocina: comer
	main.ir_a(0)
	await _esperar(1.8)
	Estado.d.nec.hambre = 40.0
	main.alimentar("fresa", Vector2(200, 1000))
	await _esperar(0.75)
	await foto("comiendo")
	await _esperar(1.2)
	ok(Estado.nec("hambre") > 45.0, "comer sube el hambre")
	# armario
	main.ir_a(1)
	await _esperar(1.8)
	Estado.dar_bellotas(2000)
	main.hud.abrir_panel("armario")
	await _esperar(0.8)
	await foto("armario")
	main.hud._probar_ropa("cabeza", "corona")
	main.hud._probar_ropa("ojos", "lentes_corazon")
	await _esperar(0.9)
	await foto("armario_probando")
	main.hud._hoja_tab = 2
	main.hud._probar_ropa("cuerpo", "poleron_menta")
	main.hud._probar_ropa("cuello", "mono_rojo")
	await _esperar(0.9)
	await foto("armario_poleron")
	main.hud.cerrar_panel()
	ok(Estado.puesto("cabeza") == "", "al cerrar el armario se quita lo que no se compró")
	await _esperar(0.6)
	# vestido completo (comprado)
	for id in ["gorra_nova", "lentes_sol", "camiseta_estrella", "panuelo_azul"]:
		Estado.agregar(id)
		Estado.poner(Estado.ropa_por_id[id].zona, id)
	Atuendos.vestir(main.pip, Estado.d.puesto)
	await _esperar(0.8)
	await foto("vestido")
	# tienda
	main.hud.abrir_panel("tienda")
	await _esperar(0.8)
	await foto("tienda")
	main.hud._confirmar_compra("bellotas_500")
	await _esperar(0.6)
	await foto("tienda_confirmar")
	antes = Estado.bellotas()
	Pagos.comprar("bellotas_500")
	await Pagos.compra_lista
	ok(Estado.bellotas() == antes + 500, "compra de prueba entrega 500 bellotas")
	main.hud.cerrar_modal()
	main.hud.cerrar_panel()
	await _esperar(0.6)
	# decorar
	main.hud.abrir_panel("decorar")
	await _esperar(0.6)
	main.hud._hoja_tab = 1
	main.hud._probar_deco("habitacion", "cama", "cohete")
	await _esperar(0.6)
	await foto("decorar_cama")
	main.hud.cerrar_panel()
	await _esperar(0.5)
	for slot_id in [["pared", "noche"], ["cama", "nube"], ["lampara", "luna"], ["alfombra", "estrella"]]:
		main.casa.rearmar("habitacion", slot_id[0], slot_id[1])
	await _esperar(0.4)
	await foto("habitacion_decorada")
	# pociones
	Estado.sumar_pocion("gigante", 1)
	main.pocion("gigante")
	await _esperar(1.4)
	await foto("pocion_gigante")
	main.pip.pocion_t = 0.0
	await _esperar(1.0)
	Estado.sumar_pocion("arcoiris", 1)
	main.pocion("arcoiris")
	await _esperar(1.4)
	await foto("pocion_arcoiris")
	main.pip.pocion_t = 0.0
	await _esperar(1.2)
	# baile
	main.bailar("saltitos")
	await _esperar(1.7)
	await foto("baile")
	await _esperar(8.5)
	ok(main.modo == "juego", "el baile termina solo")
	# dormir
	main.apagar_luz(true)
	await _esperar(2.4)
	await foto("durmiendo")
	main.apagar_luz(false)
	await _esperar(1.5)
	# patio con fondos
	main.ir_a(2)
	await _esperar(1.8)
	main.casa.rearmar("patio", "fondo", "galaxia")
	main.casa.rearmar("patio", "arbol", "cerezo")
	await _esperar(0.3)
	await foto("patio_galaxia")
	main.casa.rearmar("patio", "fondo", "atardecer")
	main.casa.rearmar("patio", "cerca", "madera")
	await _esperar(0.3)
	await foto("patio_atardecer")
	main.ir_a(3)
	await _esperar(1.8)
	main.casa.rearmar("bano", "cortina", "estrellas")
	main.casa.rearmar("bano", "banera", "dorada")
	main.casa.rearmar("bano", "pared", "coral")
	await _esperar(0.3)
	await foto("bano_decorado")
	main.ir_a(0)
	await _esperar(1.8)
	main.casa.rearmar("cocina", "pared", "cerezo")
	main.casa.rearmar("cocina", "piso", "ajedrez")
	main.casa.rearmar("cocina", "nevera", "retro")
	main.casa.rearmar("cocina", "mesa", "azul")
	await _esperar(0.3)
	await foto("cocina_decorada")
	var fallos := 0
	for l in informe:
		if l.begins_with("FALLO"):
			fallos += 1
	informe.append("RESUMEN: %d pruebas fallidas" % fallos)
	var f := FileAccess.open(dir + "/report.txt", FileAccess.WRITE)
	f.store_string("\n".join(informe) + "\n")
	f.close()
	print("\n".join(informe))
	get_tree().quit(1 if fallos > 0 else 0)
