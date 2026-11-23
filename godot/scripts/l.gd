## Pocket Pip — idiomas. Los textos se escriben en español en el código; L.t(texto) los traduce al idioma
## elegido (data/en.json tiene las traducciones al inglés). UI.texto ya llama a L.t solo.
## Los textos con números se traducen con su plantilla: L.f("¡Nivel %d!", [n]).
class_name L

static var idioma := "es"
static var _en := {}
static var _hechos := {}         ## textos que ya salieron traducidos (no se vuelven a buscar)
static var faltan := {}          ## textos sin traducir que se vieron (los "ojos" los informan)

static func cambiar(i: String) -> void:
	idioma = i
	if _en.is_empty():
		var f := FileAccess.open("res://data/en.json", FileAccess.READ)
		if f:
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_en = d
				for k in _en:
					_hechos[str(_en[k])] = true

static func t(s: String) -> String:
	if idioma == "es" or s == "":
		return s
	if _en.has(s):
		return str(_en[s])
	if _hechos.has(s):
		return s
	if s.replace(",", "").replace(".", "").is_valid_int():
		return s
	if s.length() > 1 and not s.begins_with("+") and not s.begins_with("$"):
		faltan[s] = true
	return s

static func f(plantilla: String, args: Array) -> String:
	var r: String = t(plantilla) % args
	if idioma != "es":
		_hechos[r] = true
	return r

## Marca textos que ya vienen traducidos (nombres del catálogo en inglés).
static func registrar(s: String) -> void:
	_hechos[s] = true
