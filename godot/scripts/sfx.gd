## Pocket Pip — sonidos y música (autoload "Sfx").
## Sonidos de archivo en audio/ (sfx_*.ogg / .wav) y sonidos "de Pip" sintetizados al arrancar
## (risita, boop, estornudo, mordisco, ronroneo, burbuja, pop, agua). Música con fundido: Sfx.musica("musica_dia_0").
extends Node

var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _m_a: AudioStreamPlayer
var _m_b: AudioStreamPlayer
var _cancion := ""
var _fade := 1.0
var _vol_m := 0.8
var agua: AudioStreamPlayer
var ronroneo: AudioStreamPlayer
const RATE := 22050

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_m_a = AudioStreamPlayer.new()
	_m_b = AudioStreamPlayer.new()
	for m in [_m_a, _m_b]:
		m.volume_db = -80.0
		add_child(m)
	_sintetizar()
	agua = AudioStreamPlayer.new()
	agua.stream = _cache["agua"]
	agua.volume_db = -10.0
	add_child(agua)
	ronroneo = AudioStreamPlayer.new()
	ronroneo.stream = _cache["ronroneo"]
	ronroneo.volume_db = -80.0
	add_child(ronroneo)

func _stream(id: String) -> AudioStream:
	if _cache.has(id):
		return _cache[id]
	var s: AudioStream = null
	for ext: String in [".ogg", ".wav"]:
		var path := "res://audio/" + id + ext
		if ResourceLoader.exists(path):
			s = load(path)
			break
	_cache[id] = s
	return s

func play(id: String, pitch := 1.0, vol_db := 0.0) -> void:
	var ef := float(Estado.cfg("efectos"))
	if ef <= 0.01:
		return
	var s := _stream(id)
	if s == null:
		s = _stream("sfx_" + id)
	if s == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = vol_db + linear_to_db(ef)
	p.play()

func musica(id: String) -> void:
	if id == _cancion:
		return
	_cancion = id
	var tmp := _m_b
	_m_b = _m_a
	_m_a = tmp
	var s := _stream(id)
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	_m_a.stream = s
	_m_a.volume_db = -80.0
	if s != null:
		_m_a.play()
	_fade = 0.0

func _process(dt: float) -> void:
	_fade = minf(1.0, _fade + dt / 1.2)
	var v := _vol_m * float(Estado.cfg("musica"))
	_m_a.volume_db = linear_to_db(maxf(0.0001, v * _fade))
	_m_b.volume_db = linear_to_db(maxf(0.0001, v * (1.0 - _fade)))
	if _fade >= 1.0 and _m_b.playing:
		_m_b.stop()

func set_ronroneo(k: float) -> void:
	k *= float(Estado.cfg("efectos"))
	if k > 0.01 and not ronroneo.playing:
		ronroneo.play()
	ronroneo.volume_db = linear_to_db(maxf(0.0001, k * 0.6))
	if k <= 0.01 and ronroneo.playing:
		ronroneo.stop()

func set_agua(on: bool) -> void:
	if on and float(Estado.cfg("efectos")) > 0.01:
		if not agua.playing:
			agua.play()
	elif agua.playing:
		agua.stop()

# ---------------- síntesis ----------------
func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var b := PackedByteArray()
	b.resize(samples.size() * 2)
	for i in samples.size():
		b.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w

## chillido: frecuencia que va de f0 a f1, con vibrato y envolvente suave
func _chirp(dur: float, f0: float, f1: float, vib := 0.0, vol := 0.5) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var u := float(i) / n
		var f := lerpf(f0, f1, u) * (1.0 + vib * sin(u * dur * 38.0))
		ph += TAU * f / RATE
		var env := minf(1.0, u * 18.0) * pow(1.0 - u, 1.4)
		out[i] = (sin(ph) * 0.8 + sin(ph * 2.0) * 0.2) * env * vol
	return out

func _concat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out

func _silencio(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	return out

func _sintetizar() -> void:
	# risita: tres "ji" que suben
	_cache["risa"] = _wav(_concat([_chirp(0.09, 900, 1300, 0.04), _silencio(0.04), _chirp(0.09, 1000, 1450, 0.04),
		_silencio(0.04), _chirp(0.12, 1100, 1600, 0.05)]))
	_cache["boop"] = _wav(_chirp(0.12, 700, 420, 0.0, 0.55))
	_cache["pop"] = _wav(_chirp(0.06, 500, 1400, 0.0, 0.45))
	_cache["tic"] = _wav(_chirp(0.035, 1800, 1500, 0.0, 0.3))
	_cache["mordisco"] = _wav(_concat([_ruido(0.05, 0.5, 0.35), _silencio(0.05), _ruido(0.05, 0.5, 0.3)]))
	_cache["feliz"] = _wav(_concat([_chirp(0.1, 800, 1200, 0.03), _chirp(0.16, 1200, 1500, 0.06)]))
	_cache["queja"] = _wav(_chirp(0.32, 650, 380, 0.08, 0.5))
	_cache["burbuja"] = _wav(_chirp(0.07, 900, 2200, 0.0, 0.3))
	_cache["bostezo"] = _wav(_chirp(0.7, 520, 300, 0.03, 0.4))
	# estornudo: inspiración (ruido que sube) + "¡chu!"
	_cache["estornudo"] = _wav(_concat([_ruido(0.35, 0.06, 0.15, true), _ruido(0.12, 0.9, 0.6)]))
	# ronroneo: zumbido grave que late (en bucle)
	var n := int(0.8 * RATE)
	var r := PackedFloat32Array()
	r.resize(n)
	for i in n:
		var t := float(i) / RATE
		var am := 0.55 + 0.45 * sin(TAU * 2.5 * t)
		r[i] = (sin(TAU * 52.0 * t) * 0.6 + sin(TAU * 104.0 * t) * 0.25 + (randf() - 0.5) * 0.12) * am * 0.5
	_cache["ronroneo"] = _wav(r, true)
	# agua de la ducha: ruido filtrado (en bucle)
	n = int(1.2 * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var lp := 0.0
	for i in n:
		lp += ((randf() - 0.5) - lp) * 0.35
		a[i] = lp * 0.9
	_cache["agua"] = _wav(a, true)

## ruido con envolvente (`sube`: crece en vez de apagarse); `brillo` 0..1 = cuán agudo
func _ruido(dur: float, brillo: float, vol: float, sube := false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var u := float(i) / n
		lp += ((randf() - 0.5) - lp) * (0.05 + brillo * 0.9)
		var env := u if sube else minf(1.0, u * 30.0) * pow(1.0 - u, 2.0)
		out[i] = lp * env * vol * 2.0
	return out
