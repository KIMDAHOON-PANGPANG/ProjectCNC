class_name SuicideBomber extends EnemyBase

# 폭발 자살형. Player 가까이 가면 카운트다운 후 폭발 (Area2D).
# Phase 3 사양: 처형 vs 회피 의사결정 강요.

@export var trigger_radius: float = 60.0
@export var fuse_duration: float = 1.0
@export var explosion_radius: float = 36.0

var fuse_timer: float = 0.0
var fuse_active: bool = false
var _flash_t: float = 0.0


func _ready() -> void:
	super._ready()
	stun_duration = 0.5
	# 더 작은 박스 색상 — 주황으로 표시


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if hp <= 0:
		return

	if not fuse_active and not is_stunned:
		var player_pos: Vector2 = _find_player_pos()
		if player_pos != Vector2.INF and global_position.distance_to(player_pos) < trigger_radius:
			fuse_active = true
			fuse_timer = fuse_duration
			_log("bomber_armed", "")

	if fuse_active:
		fuse_timer -= delta
		_flash_t += delta * 8.0
		# 깜빡임 — 시각 placeholder
		if _view != null and _view is ColorRect:
			var alpha: float = 0.5 + 0.5 * sin(_flash_t)
			(_view as ColorRect).color.a = alpha
		if fuse_timer <= 0.0:
			_explode()


func _explode() -> void:
	var player_pos: Vector2 = _find_player_pos()
	if player_pos != Vector2.INF and global_position.distance_to(player_pos) < explosion_radius:
		var room: Node = _find_room()
		if room != null and room.has_method("respawn_player"):
			room.respawn_player()
	# Game Feel: 셰이크
	var cs: Node = get_node_or_null("/root/CameraShake")
	if cs != null and cs.has_method("shake"):
		cs.shake(8.0, 0.2)
	_log("bomber_explode", "")
	queue_free()


func _find_room() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n is RoomBase:
			return n
		n = n.get_parent()
	return null


func _find_player_pos() -> Vector2:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return Vector2.INF
	var p: Node = tree.current_scene.get_node_or_null("Player")
	if p != null and p is Node2D:
		return (p as Node2D).global_position
	return Vector2.INF


func _log(action: String, payload: String) -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_method("log_action"):
		dbg.log_action(action, payload)
