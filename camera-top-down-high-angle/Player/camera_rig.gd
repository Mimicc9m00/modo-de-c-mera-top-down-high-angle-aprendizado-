extends Node3D

@export_category("Camera")
@export var distancia_camera: float = 12.0
@export var altura_camera: float = 10.0
@export var angulo_camera: float = 45.0
@export var rotacao_camera: float = 45.0

@export_category("Colisao")
@export var suavidade_retorno: float = 8.0
@export var margem_colisao: float = 0.2

@onready var braco: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
	braco.spring_length = distancia_camera
	braco.margin = margem_colisao
	rotation.y = deg_to_rad(rotacao_camera)
	braco.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO

	camera.position = Vector3.ZERO

func _process(delta: float) -> void:
	var distancia_atual: float = braco.spring_length
	var distancia_desejada: float = distancia_camera

	if absf(distancia_atual - distancia_desejada) > 0.01:
		braco.spring_length = lerpf(
			distancia_atual,
			distancia_desejada,
			clampf(suavidade_retorno * delta, 0.0, 1.0)
		)
