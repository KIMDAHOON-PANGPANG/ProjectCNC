class_name RoomBase extends Node2D

# 모든 룸의 베이스. 통계 / 클리어 시그널 / 리스폰 처리.
# 사양: DOC/dagger_marker_roadmap_supplement.md §C, §I-2

signal room_cleared(stats: Dictionary)
signal player_died

@export var room_id: String = ""
@export var spawn_point: NodePath
@export var goal_point: NodePath  # 도달 시 클리어
@export var next_room_path: String = ""  # 클리어 시 다음 룸 (.tscn 경로)

var stats: Dictionary = {
	"throw_count": 0,
	"plant_count": 0,
	"teleport_count": 0,
	"execute_count": 0,
	"death_count": 0,
	"start_ms": 0,
	"end_ms": 0,
}

var _player: Node = null
var _spawn_pos: Vector2 = Vector2.ZERO


@export var is_boss_room: bool = false
@export var boss_zoom_factor: float = 1.15  # 보스 룸 카메라 살짝 줌


func _ready() -> void:
	stats.start_ms = Time.get_ticks_msec()
	_find_player()
	_connect_debug_log()
	_setup_goal()
	_log("room_enter", room_id)
	_play_room_intro()


func _play_room_intro() -> void:
	# 보스 룸이면 살짝 줌인
	if is_boss_room:
		var cs: Node = get_node_or_null("/root/CameraShake")
		if cs != null and cs.has_method("zoom_punch"):
			cs.zoom_punch(boss_zoom_factor, 1.2)


func _find_player() -> void:
	_player = _search_player(self)
	if _player == null:
		# 부모 또는 sibling에서 찾기
		var root: Node = get_tree().current_scene
		if root != null:
			_player = _search_player(root)
	if _player != null:
		_spawn_pos = _player.global_position
		if not spawn_point.is_empty():
			var sp: Node2D = get_node_or_null(spawn_point)
			if sp != null:
				_spawn_pos = sp.global_position
				_player.global_position = _spawn_pos


func _search_player(node: Node) -> Node:
	if node is CharacterBody2D and node.get_script() != null:
		var sc = node.get_script()
		if sc.has_method("get_global_name") or "PlayerBody2D" in str(sc.resource_path):
			return node
	for c in node.get_children():
		var f: Node = _search_player(c)
		if f != null:
			return f
	return null


func _connect_debug_log() -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_signal("action_logged"):
		if not dbg.action_logged.is_connected(_on_action_logged):
			dbg.action_logged.connect(_on_action_logged)


func _on_action_logged(action: String, _payload: String) -> void:
	match action:
		"throw":
			stats.throw_count += 1
		"plant":
			stats.plant_count += 1
		"teleport_start":
			stats.teleport_count += 1
		"execute":
			stats.execute_count += 1


func _setup_goal() -> void:
	if goal_point.is_empty():
		return
	var g: Node = get_node_or_null(goal_point)
	if g == null:
		return
	if g is Area2D:
		(g as Area2D).body_entered.connect(_on_goal_entered)


func _on_goal_entered(body: Node) -> void:
	if body == _player:
		_clear_room()


func _clear_room() -> void:
	stats.end_ms = Time.get_ticks_msec()
	_log("room_clear", "%s,teleports=%d" % [room_id, stats.teleport_count])
	room_cleared.emit(stats)
	# room_manager가 다음 룸 로드
	var rm: Node = get_node_or_null("/root/RoomManager")
	if rm != null and rm.has_method("on_room_cleared"):
		rm.on_room_cleared(self)


func respawn_player() -> void:
	stats.death_count += 1
	_log("respawn", room_id)
	player_died.emit()
	# 마커 모두 제거 + ammo 풀
	var mm: Node = get_node_or_null("/root/MarkerManager")
	if mm != null and mm.has_method("reset"):
		mm.reset()
	if _player != null:
		_player.global_position = _spawn_pos
		if "logic" in _player and _player.logic != null:
			_player.logic.velocity_x = 0.0
			_player.logic.velocity_y = 0.0
			_player.logic.state = 0  # NORMAL


func _log(action: String, payload: String) -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_method("log_action"):
		dbg.log_action(action, payload)
