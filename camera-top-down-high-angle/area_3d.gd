extends Area3D

@export_group("Árvore")
@export_range(1, 20, 1) var golpes_para_cair: int = 3

@export_group("Drops de madeira")
@export var cena_madeira: PackedScene
@export_range(1, 20, 1) var quantidade_drops: int = 3
@export_range(0.5, 5.0, 0.1) var raio_drop: float = 1.5
@export var altura_drop: float = 0.5

var golpes_recebidos: int = 0
var jogador_dentro: bool = false
var destruindo: bool = false
var jogador_atual: Node3D = null


func _ready() -> void:
	add_to_group("arvores")
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)


func _ao_entrar(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_dentro = true
		jogador_atual = body


func _ao_sair(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_dentro = false

		if jogador_atual == body:
			jogador_atual = null


func receber_golpe(jogador: Node = null) -> void:
	if destruindo:
		return

	if is_instance_valid(jogador) and jogador is Node3D:
		jogador_atual = jogador as Node3D

	golpes_recebidos += 1

	if golpes_recebidos >= golpes_para_cair:
		_destruir_arvore()


func _destruir_arvore() -> void:
	if destruindo:
		return

	if cena_madeira == null:
		return

	var mundo := get_tree().current_scene

	if mundo == null:
		return

	if not is_instance_valid(jogador_atual):
		var jogadores := get_tree().get_nodes_in_group("player")

		for no in jogadores:
			if no is Node3D:
				jogador_atual = no as Node3D
				break

	if not is_instance_valid(jogador_atual):
		return

	destruindo = true

	var origem_jogador: Vector3 = jogador_atual.global_position

	for i in range(quantidade_drops):
		var instancia := cena_madeira.instantiate()

		if not instancia is Node3D:
			instancia.free()
			continue

		var madeira := instancia as Node3D
		mundo.add_child(madeira)

		var angulo: float = (
			TAU * float(i) / float(maxi(quantidade_drops, 1))
		)

		var deslocamento := Vector3(
			cos(angulo) * raio_drop,
			altura_drop,
			sin(angulo) * raio_drop
		)

		madeira.global_position = origem_jogador + deslocamento
		madeira.visible = true

	get_parent().queue_free()
