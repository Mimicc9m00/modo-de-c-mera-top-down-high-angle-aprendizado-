
extends CharacterBody3D

@export_group("Movimento")
@export var velocidade: float = 4.0
@export var velocidade_rotacao: float = 12.0

@export_group("Gravidade")
@export var gravidade: float = 20.0
@export var velocidade_queda_maxima: float = 50.0

@export_group("Camera Diagonal")
@export var distancia_camera: float = 20.0
@export var altura_alvo_camera: float = 0.8
@export_range(20.0, 80.0, 1.0) var angulo_camera: float = 50.0
@export_range(-180.0, 180.0, 1.0) var rotacao_camera: float = 45.0
@export var suavidade_camera: float = 8.0
@export_range(30.0, 90.0, 1.0) var campo_visao: float = 40.0

@export_group("Colisao Suave da Camera")
@export var ativar_colisao_camera: bool = true
@export_flags_3d_physics var mascara_colisao_camera: int = 1
@export_range(0.05, 1.0, 0.05) var margem_colisao: float = 0.2
@export_range(0.1, 5.0, 0.1) var distancia_minima_camera: float = 2.5
@export_range(1.0, 30.0, 0.5) var suavidade_aproximacao: float = 18.0
@export_range(0.5, 10.0, 0.5) var suavidade_retorno: float = 3.0

@export_group("Modo Overcooked")
@export_range(30.0, 89.0, 1.0) var angulo_overcooked: float = 70.0
@export_range(-180.0, 180.0, 1.0) var rotacao_overcooked: float = 45.0
@export var distancia_overcooked: float = 18.0
@export var altura_alvo_overcooked: float = 0.8
@export var suavidade_transicao_camera: float = 3.0
@export_range(1.0, 2.0, 0.05) var margem_enquadramento_area: float = 1.15

@export_group("Orientacao do Modelo")
@export_range(-180.0, 180.0, 1.0) var correcao_rotacao_modelo: float = 0.0

@export_group("Animacao")
@export var animacao_andar: String = "Skeleton|Walking"

@export_group("Interacao")
@export_range(1.0, 1000.0, 1.0) var alcance_interacao: float = 100.0
@export_flags_3d_physics var mascara_interacao: int = 2
@export var alcance_coleta: float = 2.5
@export var alcance_fogao: float = 2.5

@export_group("Inventario")
@export var madeira_coletada: int = 0
@export var comida_cozida: int = 0

var camera_rig: Node3D
var camera: Camera3D
var ray_camera: RayCast3D
var animation_player: AnimationPlayer

var rotacao_fixa_camera: Basis

var distancia_atual: float = 20.0
var distancia_alvo: float = 20.0

var modo_overcooked: bool = false
var area_overcooked: Area3D = null

var centro_area_camera: Vector3 = Vector3.ZERO
var distancia_calculada_area: float = 18.0

var angulo_camera_atual: float
var rotacao_camera_atual: float
var distancia_camera_atual: float
var altura_camera_atual: float


func _ready() -> void:
	add_to_group("player")

	_criar_hierarquia_camera()

	animation_player = get_node_or_null(
		"Player/AnimationPlayer"
	) as AnimationPlayer

	angulo_camera_atual = angulo_camera
	rotacao_camera_atual = rotacao_camera
	distancia_camera_atual = distancia_camera
	altura_camera_atual = altura_alvo_camera

	distancia_atual = distancia_camera
	distancia_alvo = distancia_camera

	camera.fov = campo_visao
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.near = 0.05
	camera.far = 1000.0
	camera.current = true

	_atualizar_rotacao_camera()
	_atualizar_camera_imediata()
	_parar_animacao()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var clique := event as InputEventMouseButton

		if clique.button_index == MOUSE_BUTTON_LEFT and clique.pressed:
			_tentar_cortar_arvore()

	if event is InputEventKey:
		var tecla := event as InputEventKey

		if tecla.keycode == KEY_E and tecla.pressed and not tecla.echo:
			if not _tentar_interagir_fogao():
				_tentar_coletar_madeira()


func _obter_alvo_do_mouse() -> Object:
	if not is_instance_valid(camera):
		return null

	var mouse := get_viewport().get_mouse_position()
	var origem := camera.project_ray_origin(mouse)
	var direcao := camera.project_ray_normal(mouse)

	var consulta := PhysicsRayQueryParameters3D.create(
		origem,
		origem + direcao * alcance_interacao
	)

	consulta.collision_mask = mascara_interacao
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = true
	consulta.exclude = [get_rid()]

	var resultado := get_world_3d().direct_space_state.intersect_ray(consulta)

	if resultado.is_empty():
		return null

	return resultado.get("collider") as Object


func _encontrar_no_com_metodo(
	objeto: Object,
	nome_metodo: String
) -> Node:
	var no := objeto as Node

	while is_instance_valid(no):
		if no.has_method(nome_metodo):
			return no

		no = no.get_parent()

	return null


func _tentar_cortar_arvore() -> void:
	for no in get_tree().get_nodes_in_group("arvores"):
		if not is_instance_valid(no):
			continue

		if no is Area3D and no.get("jogador_dentro") == true:
			no.call("receber_golpe", self)
			return


func _tentar_coletar_madeira() -> void:
	var melhor_item: Node3D = null
	var menor_distancia: float = alcance_coleta

	for no in get_tree().get_nodes_in_group("madeira_coletavel"):
		if not is_instance_valid(no):
			continue

		if not no is Node3D:
			continue

		var item := no as Node3D
		var distancia := global_position.distance_to(
			item.global_position
		)

		if distancia <= menor_distancia:
			menor_distancia = distancia
			melhor_item = item

	if melhor_item == null:
		return

	if melhor_item.has_method("coletar"):
		melhor_item.call("coletar", self)


func _tentar_interagir_fogao() -> bool:
	var fogao_mais_proximo: Node3D = null
	var menor_distancia: float = alcance_fogao

	for no in get_tree().get_nodes_in_group("fogoes"):
		if not is_instance_valid(no):
			continue

		if not no.has_method("interagir"):
			continue

		if not no is Node3D:
			continue

		var fogao := no as Node3D
		var distancia := global_position.distance_to(
			fogao.global_position
		)

		if distancia <= menor_distancia:
			menor_distancia = distancia
			fogao_mais_proximo = fogao

	if fogao_mais_proximo == null:
		return false

	fogao_mais_proximo.call("interagir", self)
	return true


func adicionar_madeira(quantidade: int) -> void:
	if quantidade == 0:
		return

	madeira_coletada = maxi(
		0,
		madeira_coletada + quantidade
	)

	print("Madeira no inventário: ", madeira_coletada)


func adicionar_comida(quantidade: int) -> void:
	if quantidade <= 0:
		return

	comida_cozida += quantidade

	print("Comida cozida no inventário: ", comida_cozida)


func _criar_hierarquia_camera() -> void:
	camera_rig = get_node_or_null("CameraRig") as Node3D

	if camera_rig == null:
		camera_rig = Node3D.new()
		camera_rig.name = "CameraRig"
		add_child(camera_rig)

	camera_rig.top_level = true

	camera = camera_rig.get_node_or_null("Camera3D") as Camera3D

	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera_rig.add_child(camera)

	ray_camera = camera_rig.get_node_or_null("RayCast3D") as RayCast3D

	if ray_camera == null:
		ray_camera = RayCast3D.new()
		ray_camera.name = "RayCast3D"
		camera_rig.add_child(ray_camera)

	ray_camera.enabled = true
	ray_camera.exclude_parent = true
	ray_camera.collision_mask = mascara_colisao_camera
	ray_camera.add_exception(self)


func _physics_process(delta: float) -> void:
	_aplicar_gravidade(delta)
	_movimentar(delta)


func _process(delta: float) -> void:
	_atualizar_parametros_camera(delta)
	_atualizar_rotacao_camera()
	_atualizar_camera(delta)


func _aplicar_gravidade(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= gravidade * delta
		velocity.y = maxf(velocity.y, -velocidade_queda_maxima)


func _movimentar(delta: float) -> void:
	var entrada := Vector2(
		Input.get_action_strength("d") - Input.get_action_strength("a"),
		Input.get_action_strength("w") - Input.get_action_strength("s")
	)

	var yaw := deg_to_rad(rotacao_camera_atual)

	var direita_camera := Vector3(
		cos(yaw),
		0.0,
		-sin(yaw)
	)

	var frente_camera := Vector3(
		-sin(yaw),
		0.0,
		-cos(yaw)
	)

	var direcao := direita_camera * entrada.x + frente_camera * entrada.y

	if direcao.length_squared() > 1.0:
		direcao = direcao.normalized()

	if direcao.length_squared() > 0.001:
		velocity.x = direcao.x * velocidade
		velocity.z = direcao.z * velocidade

		var angulo_alvo := atan2(direcao.x, direcao.z)
		angulo_alvo += deg_to_rad(correcao_rotacao_modelo)

		var fator_rotacao := 1.0 - exp(
			-maxf(velocidade_rotacao, 0.1) * delta
		)

		rotation.y = lerp_angle(
			rotation.y,
			angulo_alvo,
			fator_rotacao
		)

		_tocar_animacao_andar()
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_parar_animacao()

	move_and_slide()


func ativar_camera_overcooked(area: Area3D) -> void:
	if not is_instance_valid(area):
		return

	area_overcooked = area
	modo_overcooked = true

	_calcular_enquadramento_area()


func desativar_camera_overcooked(area: Area3D) -> void:
	if is_instance_valid(area_overcooked) and area != area_overcooked:
		return

	modo_overcooked = false
	area_overcooked = null


func _calcular_enquadramento_area() -> void:
	if not is_instance_valid(area_overcooked):
		return

	var forma := area_overcooked.get_node_or_null(
		"CollisionShape3D"
	) as CollisionShape3D

	if forma == null or forma.shape == null:
		return

	if not forma.shape is BoxShape3D:
		return

	var caixa := forma.shape as BoxShape3D
	var centro := forma.global_position
	centro.y = global_position.y
	centro_area_camera = centro

	var meia_x := caixa.size.x * 0.5
	var meia_z := caixa.size.z * 0.5

	var cantos_locais: Array[Vector3] = [
		Vector3(-meia_x, 0.0, -meia_z),
		Vector3(-meia_x, 0.0, meia_z),
		Vector3(meia_x, 0.0, -meia_z),
		Vector3(meia_x, 0.0, meia_z)
	]

	var cantos_mundo: Array[Vector3] = []

	for canto_local in cantos_locais:
		var canto_mundo := forma.global_transform * Vector3(
			canto_local.x, 0.0, canto_local.z
		)
		canto_mundo.y = centro.y
		cantos_mundo.append(canto_mundo)

	var orientacao := Basis.from_euler(Vector3(
		deg_to_rad(-angulo_overcooked),
		deg_to_rad(rotacao_overcooked),
		0.0
	))

	var tamanho_tela := camera.get_viewport().get_visible_rect().size
	var proporcao := tamanho_tela.x / maxf(tamanho_tela.y, 1.0)

	var fov_vertical := deg_to_rad(camera.fov)
	var fov_horizontal := 2.0 * atan(
		tan(fov_vertical * 0.5) * proporcao
	)

	var limite_x := tan(fov_horizontal * 0.5) / margem_enquadramento_area
	var limite_y := tan(fov_vertical * 0.5) / margem_enquadramento_area

	var ponto_mira := centro + Vector3.UP * altura_alvo_overcooked
	var inversa_orientacao := orientacao.inverse()

	var distancia_inferior := 0.1
	var distancia_superior := 1000.0

	for _iteracao in range(36):
		var distancia_teste := (
			distancia_inferior + distancia_superior
		) * 0.5

		var posicao_camera := ponto_mira + (
			orientacao * Vector3(0.0, 0.0, distancia_teste)
		)

		var enquadra_tudo := true

		for canto in cantos_mundo:
			var local := inversa_orientacao * (
				canto - posicao_camera
			)

			var profundidade := -local.z

			if profundidade <= 0.01:
				enquadra_tudo = false
				break

			if absf(local.x) > profundidade * limite_x:
				enquadra_tudo = false
				break

			if absf(local.y) > profundidade * limite_y:
				enquadra_tudo = false
				break

		if enquadra_tudo:
			distancia_superior = distancia_teste
		else:
			distancia_inferior = distancia_teste

	distancia_calculada_area = distancia_superior


func _atualizar_parametros_camera(delta: float) -> void:
	var angulo_alvo := angulo_camera
	var rotacao_alvo := rotacao_camera
	var distancia_desejada := distancia_camera
	var altura_desejada := altura_alvo_camera

	if modo_overcooked:
		angulo_alvo = angulo_overcooked
		rotacao_alvo = rotacao_overcooked
		distancia_desejada = distancia_calculada_area
		altura_desejada = altura_alvo_overcooked

	var fator := 1.0 - exp(
		-maxf(suavidade_transicao_camera, 0.1) * delta
	)

	angulo_camera_atual = lerpf(
		angulo_camera_atual, angulo_alvo, fator
	)

	rotacao_camera_atual = ler_angle_degrees(
		rotacao_camera_atual, rotacao_alvo, fator
	)

	distancia_camera_atual = lerpf(
		distancia_camera_atual, distancia_desejada, fator
	)

	altura_camera_atual = lerpf(
		altura_camera_atual, altura_desejada, fator
	)


func ler_angle_degrees(atual: float, alvo: float, peso: float) -> float:
	return rad_to_deg(lerp_angle(
		deg_to_rad(atual),
		deg_to_rad(alvo),
		peso
	))


func _atualizar_rotacao_camera() -> void:
	rotacao_fixa_camera = Basis.from_euler(Vector3(
		deg_to_rad(-angulo_camera_atual),
		deg_to_rad(rotacao_camera_atual),
		0.0
	))


func _atualizar_camera(delta: float) -> void:
	if not is_instance_valid(camera_rig):
		return

	var alvo: Vector3

	if modo_overcooked and is_instance_valid(area_overcooked):
		alvo = centro_area_camera
	else:
		alvo = global_position

	alvo.y += altura_camera_atual

	var fator_seguimento := 1.0 - exp(
		-maxf(suavidade_camera, 0.1) * delta
	)

	camera_rig.global_position = camera_rig.global_position.lerp(
		alvo, fator_seguimento
	)

	camera_rig.global_basis = rotacao_fixa_camera

	var direcao_recuo := (
		rotacao_fixa_camera * Vector3(0.0, 0.0, 1.0)
	).normalized()

	if modo_overcooked:
		distancia_alvo = distancia_camera_atual

		distancia_atual = lerpf(
			distancia_atual,
			distancia_alvo,
			1.0 - exp(
				-maxf(suavidade_transicao_camera, 0.1) * delta
			)
		)
	else:
		ray_camera.position = Vector3.ZERO
		ray_camera.target_position = (
			direcao_recuo * distancia_camera_atual
		)
		ray_camera.collision_mask = mascara_colisao_camera
		ray_camera.force_raycast_update()

		distancia_alvo = distancia_camera_atual

		if ativar_colisao_camera and ray_camera.is_colliding():
			var ponto_colisao := ray_camera.get_collision_point()
			var distancia_obstaculo := (
				camera_rig.global_position.distance_to(ponto_colisao)
			)

			distancia_alvo = maxf(
				distancia_obstaculo - margem_colisao,
				distancia_minima_camera
			)

		var velocidade_ajuste := suavidade_retorno

		if distancia_alvo < distancia_atual:
			velocidade_ajuste = suavidade_aproximacao

		var fator_distancia := 1.0 - exp(
			-maxf(velocidade_ajuste, 0.1) * delta
		)

		distancia_atual = lerpf(
			distancia_atual, distancia_alvo, fator_distancia
		)

		distancia_atual = clampf(
			distancia_atual,
			distancia_minima_camera,
			distancia_camera_atual
		)

	camera.global_position = (
		camera_rig.global_position +
		direcao_recuo * distancia_atual
	)

	camera.global_basis = rotacao_fixa_camera


func _atualizar_camera_imediata() -> void:
	if not is_instance_valid(camera_rig):
		return

	camera_rig.global_position = (
		global_position + Vector3.UP * altura_camera_atual
	)

	camera_rig.global_basis = rotacao_fixa_camera

	var direcao_recuo := (
		rotacao_fixa_camera * Vector3(0.0, 0.0, 1.0)
	).normalized()

	camera.global_position = (
		camera_rig.global_position +
		direcao_recuo * distancia_camera_atual
	)

	camera.global_basis = rotacao_fixa_camera


func _tocar_animacao_andar() -> void:
	if not is_instance_valid(animation_player):
		return

	if not animation_player.has_animation(animacao_andar):
		return

	if animation_player.current_animation != animacao_andar:
		animation_player.play(animacao_andar)


func _parar_animacao() -> void:
	if not is_instance_valid(animation_player):
		return

	if animation_player.current_animation == animacao_andar:
		animation_player.stop()
