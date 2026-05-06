extends CanvasLayer

# F3 토글 디버그 오버레이. 현재 룸 통계 + 누적 통계 + 좌표.

var _label: Label
var _enabled: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	visible = false
	_label = Label.new()
	_label.position = Vector2(8, 60)
	_label.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_enabled = not _enabled
			visible = _enabled


func _process(_delta: float) -> void:
	if not _enabled:
		return
	_label.text = _build_text()


func _build_text() -> String:
	var lines: Array = []
	# 현재 룸 통계
	var rm: Node = get_node_or_null("/root/RoomManager")
	if rm != null and "current_room" in rm and rm.current_room != null:
		var room: Node = rm.current_room
		var rid: String = room.room_id if "room_id" in room else "?"
		lines.append("[ROOM] %s" % rid)
		if "stats" in room:
			var s: Dictionary = room.stats
			lines.append("  throws=%d  plants=%d  tps=%d" % [
				s.get("throw_count", 0),
				s.get("plant_count", 0),
				s.get("teleport_count", 0),
			])
			lines.append("  executes=%d  deaths=%d" % [
				s.get("execute_count", 0),
				s.get("death_count", 0),
			])

		# 누적
		if "aggregate_stats" in rm:
			var ag: Dictionary = rm.aggregate_stats
			lines.append("[TOTAL]")
			lines.append("  rooms_cleared=%d  deaths=%d" % [
				ag.get("rooms_cleared", 0),
				ag.get("total_deaths", 0),
			])

	# Player 좌표
	var p: Node = get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null
	if p != null and p is Node2D:
		var pos: Vector2 = (p as Node2D).global_position
		lines.append("[POS] %.0f, %.0f" % [pos.x, pos.y])

	# Marker / Ammo
	var mm: Node = get_node_or_null("/root/MarkerManager")
	if mm != null:
		var n_markers: int = mm.get_marker_count() if mm.has_method("get_marker_count") else 0
		var n_ammo: int = mm.ammo if "ammo" in mm else 0
		lines.append("[INV] markers=%d  ammo=%d" % [n_markers, n_ammo])

	return "\n".join(lines)
