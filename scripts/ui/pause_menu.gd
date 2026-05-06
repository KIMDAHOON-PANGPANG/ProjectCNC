extends CanvasLayer

# Esc → 일시정지. 메뉴 표시 + tree.paused.
# 옵션: 재개 / 리셋 (현재 룸 재진입) / 종료.

var _panel: Panel
var _resume_btn: Button
var _restart_btn: Button
var _quit_btn: Button
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	visible = false
	_build_ui()


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(180, 130)
	_panel.position = -_panel.size * 0.5
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_resume_btn = _make_button("RESUME (Esc)")
	_resume_btn.pressed.connect(close)
	vbox.add_child(_resume_btn)

	_restart_btn = _make_button("RESTART ROOM")
	_restart_btn.pressed.connect(_on_restart)
	vbox.add_child(_restart_btn)

	_quit_btn = _make_button("QUIT")
	_quit_btn.pressed.connect(_on_quit)
	vbox.add_child(_quit_btn)


func _make_button(label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(140, 22)
	return b


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func open() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true


func close() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false


func _on_restart() -> void:
	close()
	var rm: Node = get_node_or_null("/root/RoomManager")
	if rm == null or not "current_room" in rm:
		return
	var room: Node = rm.current_room
	if room != null and room.has_method("respawn_player"):
		room.respawn_player()


func _on_quit() -> void:
	get_tree().paused = false
	get_tree().quit()
