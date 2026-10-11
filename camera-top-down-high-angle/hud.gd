
extends CanvasLayer

@export_group("Aparência")
@export_range(1, 10, 1) var quantidade_slots: int = 5
@export var tamanho_slot: float = 64.0
@export var espaco_slots: float = 8.0

@export_group("Teclas")
@export var tecla_inventario: Key = KEY_TAB

var barra_rapida: PanelContainer
var slots_container: HBoxContainer
var slots: Array[PanelContainer] = []

var label_madeira: Label
var label_comida: Label

var jogador: Node = null
var barra_visivel: bool = true
var madeira_anterior: int = -1
var comida_anterior: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_criar_interface()
	_procurar_jogador()
	_atualizar_inventario()


func _process(_delta: float) -> void:
	if not is_instance_valid(jogador):
		_procurar_jogador()

	_atualizar_inventario()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var tecla := event as InputEventKey

		if tecla.keycode == tecla_inventario and tecla.pressed and not tecla.echo:
			barra_visivel = not barra_visivel
			barra_rapida.visible = barra_visivel
			get_viewport().set_input_as_handled()


func _criar_interface() -> void:
	barra_rapida = PanelContainer.new()
	barra_rapida.name = "BarraRapida"
	barra_rapida.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.055, 0.065, 0.075, 0.92)
	estilo.border_color = Color(0.28, 0.31, 0.34, 0.95)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 10.0
	estilo.content_margin_right = 10.0
	estilo.content_margin_top = 10.0
	estilo.content_margin_bottom = 10.0
	barra_rapida.add_theme_stylebox_override("panel", estilo)

	add_child(barra_rapida)

	barra_rapida.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	barra_rapida.grow_horizontal = Control.GROW_DIRECTION_BOTH
	barra_rapida.grow_vertical = Control.GROW_DIRECTION_BEGIN

	slots_container = HBoxContainer.new()
	slots_container.name = "Slots"
	slots_container.add_theme_constant_override(
		"separation",
		int(espaco_slots)
	)
	barra_rapida.add_child(slots_container)

	for i in range(maxi(quantidade_slots, 1)):
		var slot := _criar_slot(i)
		slots_container.add_child(slot)
		slots.append(slot)

	barra_rapida.resized.connect(_centralizar_barra)
	call_deferred("_centralizar_barra")


func _criar_slot(indice: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.name = "Slot" + str(indice + 1)
	slot.custom_minimum_size = Vector2(tamanho_slot, tamanho_slot)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo := StyleBoxFlat.new()

	if indice < 2:
		estilo.bg_color = Color(0.16, 0.18, 0.20, 1.0)
		estilo.border_color = Color(0.72, 0.74, 0.76, 0.9)
	else:
		estilo.bg_color = Color(0.09, 0.10, 0.12, 0.95)
		estilo.border_color = Color(0.25, 0.27, 0.30, 0.9)

	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(5)
	estilo.content_margin_left = 4.0
	estilo.content_margin_right = 4.0
	estilo.content_margin_top = 4.0
	estilo.content_margin_bottom = 4.0
	slot.add_theme_stylebox_override("panel", estilo)

	var conteudo := Control.new()
	conteudo.name = "Conteudo"
	conteudo.custom_minimum_size = Vector2(
		tamanho_slot - 8.0,
		tamanho_slot - 8.0
	)
	slot.add_child(conteudo)

	var numero := Label.new()
	numero.text = str(indice + 1)
	numero.position = Vector2(4.0, 2.0)
	numero.add_theme_font_size_override("font_size", 11)
	numero.add_theme_color_override(
		"font_color",
		Color(0.68, 0.70, 0.73, 1.0)
	)
	conteudo.add_child(numero)

	if indice == 0:
		var icone_madeira := Label.new()
		icone_madeira.text = "▰"
		icone_madeira.position = Vector2(12.0, 12.0)
		icone_madeira.add_theme_font_size_override("font_size", 27)
		icone_madeira.add_theme_color_override(
			"font_color",
			Color(0.76, 0.55, 0.32, 1.0)
		)
		conteudo.add_child(icone_madeira)

		label_madeira = _criar_contador(conteudo)

	elif indice == 1:
		var icone_comida := Label.new()
		icone_comida.text = "●"
		icone_comida.position = Vector2(12.0, 12.0)
		icone_comida.add_theme_font_size_override("font_size", 27)
		icone_comida.add_theme_color_override(
			"font_color",
			Color(0.88, 0.58, 0.32, 1.0)
		)
		conteudo.add_child(icone_comida)

		label_comida = _criar_contador(conteudo)

	return slot


func _criar_contador(pai: Control) -> Label:
	var label := Label.new()
	label.text = "0"
	label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label.position = Vector2(-31.0, -21.0)
	label.size = Vector2(27.0, 18.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)
	pai.add_child(label)
	return label


func _centralizar_barra() -> void:
	if not is_instance_valid(barra_rapida):
		return

	var tamanho_tela := get_viewport().get_visible_rect().size

	barra_rapida.position = Vector2(
		(tamanho_tela.x - barra_rapida.size.x) * 0.5,
		tamanho_tela.y - barra_rapida.size.y - 18.0
	)


func _procurar_jogador() -> void:
	jogador = null

	for no in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(no) and no.has_method("adicionar_comida"):
			jogador = no
			return


func _atualizar_inventario() -> void:
	if not is_instance_valid(jogador):
		return

	var madeira = jogador.get("madeira_coletada")
	var comida = jogador.get("comida_cozida")

	if madeira != null and int(madeira) != madeira_anterior:
		madeira_anterior = int(madeira)
		label_madeira.text = str(madeira_anterior)

	if comida != null and int(comida) != comida_anterior:
		comida_anterior = int(comida)
		label_comida.text = str(comida_anterior)
