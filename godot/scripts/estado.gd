## Pocket Pip — la partida (autoload "Estado"): bellotas, nivel, necesidades de Pip, lo que tiene, lo que
## lleva puesto, cómo está decorada cada habitación y los ajustes. Se guarda sola en user://partida.json.
## Pip "sigue viviendo" con la app cerrada: al volver, sus necesidades bajaron según el tiempo que pasó
## (y si quedó durmiendo con la luz apagada, recuperó energía).
## También carga el catálogo (data/catalogo.json) en `cat`.
extends Node

signal cambio                   ## cambió algo importante (compras, ropa, decoración): la interfaz se refresca
signal bellotas_cambio(antes: int, ahora: int)
signal subio_nivel(nivel: int)

const RUTA := "user://partida.json"
const NECESIDADES := ["hambre", "energia", "diversion", "higiene"]
## cuánto baja cada necesidad por hora (también con la app cerrada): en ~8 horas Pip ya pide atención
const BAJA_HORA := {"hambre": 11.0, "energia": 7.0, "diversion": 9.0, "higiene": 6.0}
const SUBE_DURMIENDO := 22.0   ## energía por hora si quedó dormido

var cat := {}
var ropa_por_id := {}
var d := {}
var prueba := false
var _sucio := false
var _t_guardar := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var f := FileAccess.open("res://data/catalogo.json", FileAccess.READ)
	cat = JSON.parse_string(f.get_as_text())
	for r in cat.ropa:
		ropa_por_id[r.id] = r
	for lista in [cat.ropa, cat.pociones, cat.bailes, cat.comida, cat.juegos, cat.paquetes, cat.especiales]:
		for x in lista:
			L.registrar(str(x.get("en", "")))
	for hab in cat.deco:
		for slot in cat.deco[hab]:
			for x in cat.deco[hab][slot]:
				L.registrar(str(x.get("en", "")))
	prueba = OS.get_cmdline_user_args().has("--prueba") or _tiene_arg("--ojos")
	cargar()
	L.cambiar(str(d.cfg.idioma))

func _tiene_arg(pre: String) -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(pre):
			return true
	return false

func nueva() -> Dictionary:
	var deco := {}
	var tengo := ["bufanda_nova", "baile_saltitos"]
	for hab in cat.deco:
		deco[hab] = {}
		for slot in cat.deco[hab]:
			var v0: String = cat.deco[hab][slot][0].id
			deco[hab][slot] = v0
			tengo.append("deco_%s_%s_%s" % [hab, slot, v0])
	var idioma := "en" if not OS.get_locale_language().begins_with("es") and not prueba else "es"
	return {
		"v": 2, "bellotas": 150, "xp": 0, "nivel": 1,
		"nec": {"hambre": 65.0, "energia": 80.0, "diversion": 55.0, "higiene": 70.0},
		"t": Time.get_unix_time_from_system(),
		"durmiendo": false,
		"tengo": tengo,
		"puesto": {"cabeza": "", "ojos": "", "cuello": "bufanda_nova", "cuerpo": "", "espalda": "", "traje": ""},
		"deco": deco,
		"pociones": {},
		"comida": {"fresa": 2},
		"gratis": {"n": int(cat.bellotas_gratis.max), "t": Time.get_unix_time_from_system()},
		"diario": {"ultimo": "", "racha": 0},
		"habitacion": 1,
		"compras": {},          ## compras de una sola vez (pack de bienvenida, capibara para siempre)
		"forma": "pip",
		"capi_hasta": 0.0,      ## hora (unix) en que termina la capibara de 3 minutos
		"records": {},
		"cfg": {"musica": 0.7, "efectos": 1.0, "calidad": 1, "idioma": idioma, "vibrar": true},
	}

func cargar() -> void:
	d = nueva()
	if prueba or not FileAccess.file_exists(RUTA):
		return
	var f := FileAccess.open(RUTA, FileAccess.READ)
	var g = JSON.parse_string(f.get_as_text())
	if g is Dictionary:
		_mezclar(d, g)
	_limpiar()
	_avanzar_tiempo()

## Mezcla lo guardado sobre los valores nuevos (así las claves de versiones nuevas quedan con su valor inicial).
func _mezclar(a: Dictionary, b: Dictionary) -> void:
	for k in b:
		if a.has(k) and a[k] is Dictionary and b[k] is Dictionary:
			_mezclar(a[k], b[k])
		else:
			a[k] = b[k]

## Quita lo que ya no existe en el catálogo (ropa o decoración de versiones viejas).
func _limpiar() -> void:
	for z in d.puesto:
		var id := str(d.puesto[z])
		if id != "" and not ropa_por_id.has(id):
			d.puesto[z] = "bufanda_nova" if z == "cuello" else ""
	for hab in cat.deco:
		for slot in cat.deco[hab]:
			if busca(cat.deco[hab][slot], str(d.deco[hab].get(slot, ""))).is_empty():
				d.deco[hab][slot] = cat.deco[hab][slot][0].id
			agregar("deco_%s_%s_%s" % [hab, slot, cat.deco[hab][slot][0].id], false)

## La app estuvo cerrada: Pip siguió su día.
func _avanzar_tiempo() -> void:
	var ahora := Time.get_unix_time_from_system()
	var horas := clampf((ahora - float(d.get("t", ahora))) / 3600.0, 0.0, 96.0)
	for n in NECESIDADES:
		var baja: float = BAJA_HORA[n] * horas
		if n == "energia" and d.get("durmiendo", false):
			baja = -SUBE_DURMIENDO * horas
		d.nec[n] = clampf(float(d.nec[n]) - baja, 0.0, 100.0)
	d.t = ahora

func guardar() -> void:
	_sucio = false
	_t_guardar = 0.0
	if prueba:
		return
	d.t = Time.get_unix_time_from_system()
	var f := FileAccess.open(RUTA, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))

## Algo importante cambió: se avisa a la interfaz y se guarda pronto.
func marcar() -> void:
	_sucio = true
	cambio.emit()

func _process(dt: float) -> void:
	for n in NECESIDADES:
		var baja: float = BAJA_HORA[n] / 3600.0 * dt
		d.nec[n] = maxf(0.0, float(d.nec[n]) - baja)
	_t_guardar += dt
	if (_sucio and _t_guardar > 4.0) or _t_guardar > 30.0:
		guardar()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		guardar()
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if not prueba:
			_avanzar_tiempo()

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
	return 60 + (nivel - 1) * 50

func dar_xp(n: int) -> void:
	d.xp = int(d.xp) + n
	while int(d.xp) >= xp_para(int(d.nivel)):
		d.xp = int(d.xp) - xp_para(int(d.nivel))
		d.nivel = int(d.nivel) + 1
		dar_bellotas(20 + int(d.nivel) * 5)
		subio_nivel.emit(int(d.nivel))
	_sucio = true

func nivel() -> int:
	return int(d.nivel)

func avance_nivel() -> float:
	return float(d.xp) / float(xp_para(int(d.nivel)))

# ---------------- necesidades ----------------
func nec(n: String) -> float:
	return float(d.nec[n])

## Sube/baja una necesidad (no avisa a la interfaz: la barra se mira sola cada cuadro).
func subir(n: String, cuanto: float) -> void:
	d.nec[n] = clampf(float(d.nec[n]) + cuanto, 0.0, 100.0)
	_sucio = true

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

func agregar(clave: String, avisar := true) -> void:
	if not tiene(clave):
		d.tengo.append(clave)
		if avisar:
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

## Bellotas comunes para comer: hay un máximo gratis que se recarga de a una cada 30 minutos.
func gratis() -> int:
	var g: Dictionary = d.gratis
	var mx := int(cat.bellotas_gratis.max)
	var paso := float(cat.bellotas_gratis.minutos) * 60.0
	var ahora := Time.get_unix_time_from_system()
	if int(g.n) < mx:
		var ganadas := int((ahora - float(g.t)) / paso)
		if ganadas > 0:
			g.n = mini(mx, int(g.n) + ganadas)
			g.t = float(g.t) + ganadas * paso
	if int(g.n) >= mx:
		g.t = ahora
	return int(g.n)

## Segundos que faltan para la próxima bellota gratis.
func gratis_falta() -> int:
	var paso := float(cat.bellotas_gratis.minutos) * 60.0
	return int(paso - (Time.get_unix_time_from_system() - float(d.gratis.t)))

func usar_gratis() -> void:
	gratis()
	if int(d.gratis.n) >= int(cat.bellotas_gratis.max):
		d.gratis.t = Time.get_unix_time_from_system()
	d.gratis.n = int(d.gratis.n) - 1
	_sucio = true

func comida(id: String) -> int:
	if id == "bellota":
		return gratis()
	return int(d.comida.get(id, 0))

func sumar_comida(id: String, n: int) -> void:
	d.comida[id] = int(d.comida.get(id, 0)) + n
	_sucio = true

func busca(lista: Array, id: String) -> Dictionary:
	for x in lista:
		if x.id == id:
			return x
	return {}

func nombre(x: Dictionary) -> String:
	return str(x.get("en", x.get("nombre", ""))) if L.idioma == "en" else str(x.get("nombre", ""))

# ---------------- capibara ----------------
func capibara_permanente() -> bool:
	return d.compras.get("capibara_permanente", false)

func capibara_activa() -> bool:
	return capibara_permanente() and str(d.forma) == "capibara" or float(d.capi_hasta) > Time.get_unix_time_from_system()

# ---------------- regalo diario ----------------
func hoy() -> String:
	var t := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [t.year, t.month, t.day]

func regalo_disponible() -> bool:
	return str(d.diario.ultimo) != hoy()

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

func cfg(k: String):
	return d.cfg.get(k)

func poner_cfg(k: String, v) -> void:
	d.cfg[k] = v
	marcar()
