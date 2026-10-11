extends Area3D

@export_group("Coleta")
@export_range(1, 100, 1) var quantidade_madeira: int = 1

var coletada: bool = false


func _ready() -> void:
	add_to_group("madeira_coletavel")


func coletar(jogador: Node) -> void:
	if coletada:
		return

	if not is_instance_valid(jogador):
		return

	if not jogador.is_in_group("player"):
		return

	if not jogador.has_method("adicionar_madeira"):
		return

	coletada = true
	jogador.call("adicionar_madeira", quantidade_madeira)
	queue_free()
