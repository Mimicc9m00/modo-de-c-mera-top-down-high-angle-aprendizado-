
extends Area3D

@export_group("Cozimento")
@export_range(1.0, 60.0, 0.5) var tempo_cozimento: float = 5.0
@export_range(1, 100, 1) var madeira_necessaria: int = 1
@export_range(1, 100, 1) var comida_por_ciclo: int = 1

@export_group("Interface")
@export var altura_interface: float = 2.0
@export var largura_barra: float = 140.0
@export var altura_barra: float = 14.0

var jogador_proximo: Node3D = null
var cozinhando: bool = false
var progresso: float = 0.0

var interface_3d: SubViewport
var barra_fundo: ColorRect
var barra_progresso: ColorRect
var icone_madeira: Label
var interface_sprite: Sprite3D


func _ready() -> void:
	add_to_group("fogoes")

	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)

	_criar_interface()


func _process(delta: float) -> void:
	if not cozinhando:
		return

	progresso += delta
	_atualizar_barra()

	if progresso >= tempo_cozimento:
		_finalizar_cozimento()


func _ao_entrar(body: Node3D) -> void:
	if body.is_in_group("player"):
		jogador_proximo = body


func _ao_sair(body: Node3D) -> void:
	if jogador_proximo == body:
		jogador_proximo = null


func interagir(jogador: Node) -> void:
	if cozinhando:
		print("O fogão já está cozinhando.")
		return

	if not is_instance_valid(jogador):
		return

	var madeira_atual = jogador.get("madeira_coletada")

	if madeira_atual == null:
		push_warning("O jogador não possui a variável madeira_coletada.")
		return

	if int(madeira_atual) < madeira_necessaria:
		print("Você precisa de mais madeira para cozinhar.")
		return

	if not jogador.has_method("adicionar_madeira"):
		push_warning("O jogador não possui adicionar_madeira().")
		return

	if not jogador.has_method("adicionar_comida"):
		push_warning("Adicione adicionar_comida() ao script do jogador.")
		return

	jogador.call("adicionar_madeira", -madeira_necessaria)

	cozinhando = true
	progresso = 0.0

	_atualizar_barra()
	print("Cozimento iniciado!")


func _finalizar_cozimento() -> void:
	cozinhando = false
	progresso = tempo_cozimento

	if is_instance_valid(jogador_proximo):
		jogador_proximo.call("adicionar_comida", comida_por_ciclo)
	else:
		# Se o jogador se afastar, procura-o novamente.
		for no in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(no) and no.has_method("adicionar_comida"):
				no.call("adicionar_comida", comida_por_ciclo)
				break

	progresso = 0.0
	_atualizar_barra()
	print("Cozimento concluído!")


func _criar_interface() -> void:
	interface_3d = SubViewport.new()
	interface_3d.name = "InterfaceCozimento"
	interface_3d.size = Vector2i(220, 55)
	interface_3d.transparent_bg = true
	interface_3d.disable_3d = true
	interface_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(interface_3d)

	var painel := Control.new()
	painel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface_3d.add_child(painel)

	icone_madeira = Label.new()
	icone_madeira.text = "▰"
	icone_madeira.position = Vector2(4, 0)
	icone_madeira.size = Vector2(32, 28)
	icone_madeira.add_theme_font_size_override("font_size", 25)
	icone_madeira.add_theme_color_override(
		"font_color",
		Color(0.76, 0.55, 0.32, 1.0)
	)
	painel.add_child(icone_madeira)

	barra_fundo = ColorRect.new()
	barra_fundo.position = Vector2(40, 8)
	barra_fundo.size = Vector2(largura_barra, altura_barra)
	barra_fundo.color = Color(0.08, 0.09, 0.10, 0.95)
	painel.add_child(barra_fundo)

	barra_progresso = ColorRect.new()
	barra_progresso.position = Vector2.ZERO
	barra_progresso.size = Vector2.ZERO
	barra_progresso.color = Color(0.78, 0.61, 0.35, 1.0)
	barra_fundo.add_child(barra_progresso)

	interface_sprite = Sprite3D.new()
	interface_sprite.name = "InterfaceVisivel"
	interface_sprite.texture = interface_3d.get_texture()
	interface_sprite.pixel_size = 0.01
	interface_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interface_sprite.position = Vector3.UP * altura_interface
	interface_sprite.visible = false
	add_child(interface_sprite)


func _atualizar_barra() -> void:
	if not is_instance_valid(interface_sprite):
		return

	interface_sprite.visible = cozinhando

	if cozinhando:
		var percentual := clampf(progresso / tempo_cozimento, 0.0, 1.0)
		barra_progresso.size = Vector2(
			largura_barra * percentual,
			altura_barra
		)
