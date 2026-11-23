## Pocket Pip — compras con dinero real (autoload "Pagos").
## VERSIÓN DE PRUEBA: `MODO_PRUEBA = true` entrega todo gratis y no se conecta a nada.
## Más adelante: con Google Play Billing (plugin oficial de Godot) `comprar` abrirá la ventana de Google Play,
## y solo al confirmarse el pago (y validarse la compra) se llamará a `_entregar`. Ver docs/PAGOS.md.
## Sin anuncios: el juego nunca muestra publicidad.
extends Node

signal compra_lista(id: String, bellotas: int)
signal compra_fallida(id: String, motivo: String)

const MODO_PRUEBA := true

func comprar(id: String) -> void:
	var p: Dictionary = Estado.busca(Estado.cat.paquetes, id)
	if p.is_empty():
		p = Estado.busca(Estado.cat.especiales, id)
	if p.is_empty():
		compra_fallida.emit(id, "Ese paquete no existe")
		return
	if MODO_PRUEBA:
		# simula la espera de la tienda para que la animación se sienta real
		await get_tree().create_timer(0.6).timeout
		_entregar(p)
		return
	compra_fallida.emit(id, "La tienda todavía no está conectada")

func _entregar(p: Dictionary) -> void:
	var n := int(p.get("bellotas", 0))
	if n > 0:
		Estado.dar_bellotas(n)
	var po: Dictionary = p.get("pociones", {})
	for k in po:
		Estado.sumar_pocion(str(k), int(po[k]))
	if p.get("una_vez", false):
		Estado.d.compras[str(p.id)] = true
		Estado.marcar()
	Estado.guardar()
	compra_lista.emit(str(p.id), n)
