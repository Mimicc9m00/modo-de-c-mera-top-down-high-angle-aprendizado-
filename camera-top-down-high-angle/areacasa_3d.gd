extends Area3D

@export var grupo_jogador: StringName = &"player"

var jogador_atual: CharacterBody3D = null


func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

	monitoring = true
	monitorable = true

	var forma := get_node_or_null(
		"CollisionShape3D"
	) as CollisionShape3D

	if forma == null:
		return

	if forma.shape == null:
		return

	if not forma.shape is BoxShape3D:
		return


func _ao_entrar(body: Node3D) -> void:
	if not body.is_in_group(grupo_jogador):
		return

	if not body is CharacterBody3D:
		return

	if not body.has_method("ativar_camera_overcooked"):
		return

	jogador_atual = body as CharacterBody3D
	jogador_atual.call("ativar_camera_overcooked", self)


func _ao_sair(body: Node3D) -> void:
	if body != jogador_atual:
		return

	if is_instance_valid(jogador_atual):
		if jogador_atual.has_method("desativar_camera_overcooked"):
			jogador_atual.call("desativar_camera_overcooked", self)

	jogador_atual = null
