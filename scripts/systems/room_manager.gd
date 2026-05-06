extends Node

# 룸 로딩 / 전환 / 통계 집계 autoload.
# 사양: DOC/dagger_marker_roadmap_supplement.md §C

signal room_changed(room_id: String)

const WORLD_NODE_NAME: String = "World"

var current_room: Node = null
var aggregate_stats: Dictionary = {
	"total_throws": 0,
	"total_plants": 0,
	"total_teleports": 0,
	"total_executes": 0,
	"total_deaths": 0,
	"rooms_cleared": 0,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# 현재 씬의 World 노드 아래 첫 RoomBase 인스턴스를 current_room으로 등록.
func register_room(room: Node) -> void:
	current_room = room
	if room.has_signal("room_cleared"):
		if not room.room_cleared.is_connected(_on_room_cleared):
			room.room_cleared.connect(_on_room_cleared)
	if room.has_signal("player_died"):
		if not room.player_died.is_connected(_on_player_died):
			room.player_died.connect(_on_player_died)


func on_room_cleared(room: Node) -> void:
	# RoomBase가 직접 호출 (통계 누적 + 다음 룸)
	if "stats" in room:
		var s: Dictionary = room.stats
		aggregate_stats.total_throws += s.get("throw_count", 0)
		aggregate_stats.total_plants += s.get("plant_count", 0)
		aggregate_stats.total_teleports += s.get("teleport_count", 0)
		aggregate_stats.total_executes += s.get("execute_count", 0)
		aggregate_stats.total_deaths += s.get("death_count", 0)
		aggregate_stats.rooms_cleared += 1
	if "next_room_path" in room and room.next_room_path != "":
		_load_room(room.next_room_path)


func _load_room(path: String) -> void:
	var transition: Node = get_node_or_null("/root/Transition")
	if transition != null and transition.has_method("fade_through"):
		transition.fade_through(_do_load_room.bind(path))
	else:
		_do_load_room(path)


func _do_load_room(path: String) -> void:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_warning("[room_manager] failed to load room: %s" % path)
		return
	var new_room: Node = packed.instantiate()
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var world: Node = tree.current_scene.get_node_or_null(WORLD_NODE_NAME)
	if world == null:
		tree.current_scene.add_child(new_room)
	else:
		if current_room != null and is_instance_valid(current_room):
			current_room.queue_free()
		world.add_child(new_room)
	register_room(new_room)
	# Player를 새 룸의 spawn으로 이동
	_move_player_to_spawn(new_room)
	room_changed.emit(new_room.room_id if "room_id" in new_room else "")


func _move_player_to_spawn(room: Node) -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var player: Node = tree.current_scene.get_node_or_null("Player")
	if player == null or not (player is Node2D):
		return
	var spawn: Node = room.get_node_or_null("Spawn")
	if spawn != null and spawn is Node2D:
		(player as Node2D).global_position = (spawn as Node2D).global_position
		# 마커 / velocity 초기화
		var mm: Node = get_node_or_null("/root/MarkerManager")
		if mm != null and mm.has_method("reset"):
			mm.reset()
		if "logic" in player and player.logic != null:
			player.logic.velocity_x = 0.0
			player.logic.velocity_y = 0.0
			player.logic.state = 0


func _on_room_cleared(_stats: Dictionary) -> void:
	pass  # on_room_cleared가 RoomBase에서 직접 호출


func _on_player_died() -> void:
	# 룸 manager에선 통계만. 실제 리스폰은 RoomBase.respawn_player가 처리.
	pass
