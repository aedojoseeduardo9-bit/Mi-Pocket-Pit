## Pocket Pip — la partida (autoload "Estado"): bellotas, nivel, necesidades de Pip, lo que tiene, lo que
## lleva puesto y cómo está decorada cada habitación. Se guarda sola en user://partida.json.
## También carga el catálogo (data/catalogo.json) en `cat`.
extends Node

signal cambio                   ## cualquier cambio de la partida (la interfaz se refresca)
signal bellotas_cambio(antes: int, ahora: int)
signal subio_nivel(nivel: int)

const RUTA := "user://partida.json"
const NECESIDADES := ["hambre", "energia", "diversion", "higiene"]
## cuánto baja cada necesidad por hora (con la app cerrada también)
const BAJA_HORA := {"hambre": 7.0, "energia": 4.0, "diversion": 6.0, "higiene": 3.5}

var cat := {}                   ## catálogo
var ropa_por_id := {}
var d := {}                     ## la partida
var prueba := false             ## partida de prueba (los "ojos"): no se guarda
var _sucio := false
var _t_guardar := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f := FileAccess.open("res://data/catalogo.json", FileAccess.READ)
	cat = JSON.parse_string(f.get_as_text())
	for r in cat.ropa:
		ropa_por_id[r.id] = r
	prueba = OS.get_cmdline_user_args().has("--prueba") or OS.get_cmdline_user_args().has("--ojos")
	cargar()

func nueva() -> Dictionary:
	var deco := {}
	var tengo := ["bufanda_nova", "baile_saltitos", "comida_bellota"]
	for hab in cat.deco:
		deco[hab] = {}
		for slot in cat.deco[hab]:
			var v0: String = cat.deco[hab][slot][0].id
			deco[hab][slot] = v0
			tengo.append("deco_%s_%s_%s" % [hab, slot, v0])
	return {
		"v": 1, "bellotas": 250, "xp": 0, "nivel": 1,
		"nec": {"hambre": 70.0, "energia": 85.0, "diversion": 60.0, "higiene": 75.0},
		"t": Time.get_unix_time_from_system(),
		"tengo": tengo,
		"puesto": {"cabeza": "", "ojos": "", "cuerpo": "", "cuello": "bufanda_nova"},
		"deco": deco,
		"pociones": {},
		"comida": {"bellota": 5, "fresa": 2},
		"diario": {"ultimo": "", "racha": 0},
		"habitacion": 1,
		"musica": true, "sonido": true,
	}

func cargar() -> void:
	d = nueva()
	if prueba or not FileAccess.file_exists(RUTA):
		return
	var f := FileAccess.open(RUTA, FileAccess.READ)
	var g = JSON.parse_string(f.get_as_text())
	if g is Dictionary:
		# mezcla: así las claves nuevas de versiones futuras quedan con su valor inicial
		for k in g:
			if d.has(k) and d[k] is Dictionary and g[k] is Dictionary:
				for k2 in g[k]:
					d[k][k2] = g[k][k2]
			else:
				d[k] = g[k]
	_avanzar_tiempo()

## La app estuvo cerrada: las necesidades bajan según el tiempo que pasó (nunca bajo 5).
func _avanzar_tiempo() -> void:
	var ahora := Time.get_unix_time_from_system()
	var horas := clampf((ahora - float(d.get("t", ahora))) / 3600.0, 0.0, 72.0)
	for n in NECESIDADES:
		d.nec[n] = maxf(minf(float(d.nec[n]), 5.0), float(d.nec[n]) - BAJA_HORA[n] * horas)
	d.t = ahora

func guardar() -> void:
	_sucio = false
	if prueba:
		return
	d.t = Time.get_unix_time_from_system()
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

func marcar() -> void:
	_sucio = true
	cambio.emit()

func _process(dt: float) -> void:
	# las necesidades bajan despacio mientras se juega
	for n in NECESIDADES:
		d.nec[n] = maxf(0.0, float(d.nec[n]) - BAJA_HORA[n] / 3600.0 * dt)
	_t_guardar += dt
	if _t_guardar > 20.0:
		_t_guardar = 0.0
		guardar()
	elif _sucio and _t_guardar > 2.0:
		guardar()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		guardar()

# ---------------- bellotas y nivel ----------------
func bellotas() -> int:
	return int(d.bellotas)

func dar_bellotas(n: int) -> void:
	var a := bellotas()
	d.bellotas = a + n
	bellotas_cambio.emit(a, a + n)
	marcar()

func gastar(n: int) -> bool:
	if bellotas() < n:
		return false
	var a := bellotas()
	d.bellotas = a - n
	bellotas_cambio.emit(a, a - n)
	marcar()
	return true

func xp_para(nivel: int) -> int:
	return 60 + (nivel - 1) * 45

func dar_xp(n: int) -> void:
	d.xp = int(d.xp) + n
	while int(d.xp) >= xp_para(int(d.nivel)):
		d.xp = int(d.xp) - xp_para(int(d.nivel))
		d.nivel = int(d.nivel) + 1
		dar_bellotas(50 + int(d.nivel) * 10)
		subio_nivel.emit(int(d.nivel))
	marcar()

func nivel() -> int:
	return int(d.nivel)

func avance_nivel() -> float:
	return float(d.xp) / float(xp_para(int(d.nivel)))

# ---------------- necesidades ----------------
func nec(n: String) -> float:
	return float(d.nec[n])

func subir(n: String, cuanto: float) -> void:
	d.nec[n] = clampf(float(d.nec[n]) + cuanto, 0.0, 100.0)
	marcar()

## Ánimo general 0..100 (el promedio, pero lo más bajo pesa más).
func animo() -> float:
	var s := 0.0
	var m := 100.0
	for n in NECESIDADES:
		s += nec(n)
		m = minf(m, nec(n))
	return s / 4.0 * 0.6 + m * 0.4

# ---------------- cosas ----------------
func tiene(clave: String) -> bool:
	return d.tengo.has(clave)

func agregar(clave: String) -> void:
	if not tiene(clave):
		d.tengo.append(clave)
		marcar()

func puesto(zona: String) -> String:
	return str(d.puesto.get(zona, ""))

func poner(zona: String, id: String) -> void:
	d.puesto[zona] = id
	marcar()

func deco(hab: String, slot: String) -> String:
	return str(d.deco[hab][slot])

func poner_deco(hab: String, slot: String, id: String) -> void:
	d.deco[hab][slot] = id
	marcar()

func pociones(id: String) -> int:
	return int(d.pociones.get(id, 0))

func sumar_pocion(id: String, n: int) -> void:
	d.pociones[id] = pociones(id) + n
	marcar()

func comida(id: String) -> int:
	if id == "bellota":
		return 999   # las bellotas comunes son gratis e infinitas
	return int(d.comida.get(id, 0))

func sumar_comida(id: String, n: int) -> void:
	d.comida[id] = int(d.comida.get(id, 0)) + n
	marcar()

func busca(lista: Array, id: String) -> Dictionary:
	for x in lista:
		if x.id == id:
			return x
	return {}

# ---------------- regalo diario ----------------
func hoy() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t.year, t.month, t.day]

func regalo_disponible() -> bool:
	return str(d.diario.ultimo) != hoy()

## Día de la racha que toca hoy (0..6). Si pasó más de un día sin entrar, la racha vuelve a empezar.
func dia_regalo() -> int:
	var ult := str(d.diario.ultimo)
	if ult == "":
		return 0
	var a := Time.get_unix_time_from_datetime_string(ult + "T12:00:00")
	var b := Time.get_unix_time_from_datetime_string(hoy() + "T12:00:00")
	var dias := int(round((b - a) / 86400.0))
	if dias == 1:
		return (int(d.diario.racha) + 1) % 7
	if dias <= 0:
		return int(d.diario.racha)
	return 0

func reclamar_regalo() -> int:
	if not regalo_disponible():
		return 0
	var dia := dia_regalo()
	var n: int = int(cat.regalo_diario[dia])
	d.diario.racha = dia
	d.diario.ultimo = hoy()
	dar_bellotas(n)
	return n
