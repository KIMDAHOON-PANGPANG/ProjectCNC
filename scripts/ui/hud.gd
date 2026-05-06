extends Control

# Phase 4 HUD — HP / ammo / 마커 카운트 / 룸 통계
# Phase 1 placeholder: 단순 텍스트 라벨

var _ammo_label: Label
var _markers_label: Label
var _stats_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	var box := VBoxContainer.new()
	box.position = Vector2(8, 8)
	add_child(box)

	_ammo_label = Label.new()
	_ammo_label.text = "DAGGERS: 3 / 3"
	_ammo_label.add_theme_color_override("font_color", Color(0, 0.898, 1))
	box.add_child(_ammo_label)

	_markers_label = Label.new()
	_markers_label.text = "MARKERS: 0 / 3"
	_markers_label.add_theme_color_override("font_color", Color(0.96, 0.69, 0.25))
	box.add_child(_markers_label)

	_stats_label = Label.new()
	_stats_label.text = "ROOM 01"
	_stats_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	box.add_child(_stats_label)

	# MarkerManager 시그널 연결
	var mm: Node = get_node_or_null("/root/MarkerManager")
	if mm != null:
		if mm.has_signal("ammo_changed"):
			mm.ammo_changed.connect(_on_ammo_changed)
		if mm.has_signal("markers_changed"):
			mm.markers_changed.connect(_on_markers_changed)

	# RoomManager 시그널
	var rm: Node = get_node_or_null("/root/RoomManager")
	if rm != null and rm.has_signal("room_changed"):
		rm.room_changed.connect(_on_room_changed)


func _on_ammo_changed(new_ammo: int) -> void:
	_ammo_label.text = "DAGGERS: %d / %d" % [new_ammo, GameConstants.DAGGER_AMMO_MAX]


func _on_markers_changed() -> void:
	var mm: Node = get_node_or_null("/root/MarkerManager")
	var count: int = 0
	if mm != null and mm.has_method("get_marker_count"):
		count = mm.get_marker_count()
	_markers_label.text = "MARKERS: %d / %d" % [count, GameConstants.MARKER_MAX_COUNT]


func _on_room_changed(room_id: String) -> void:
	_stats_label.text = "ROOM %s" % room_id.to_upper()
