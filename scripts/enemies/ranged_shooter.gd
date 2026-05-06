class_name RangedShooter extends EnemyBase

# 원거리 견제형. Player 시야에 들어오면 일정 간격으로 발사체.
# Phase 3 사양: 텔레포트 도착 위치를 견제 → 플레이어 텔레포트 선택을 강제 변경.

@export var detect_range: float = 220.0
@export var shoot_interval: float = 1.6
@export var projectile_speed: float = 140.0

var shoot_timer: float = 0.0


func _ready() -> void:
	super._ready()
	stun_duration = 0.4


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_stunned or hp <= 0:
		return
	shoot_timer -= delta
	var player_pos: Vector2 = _find_player_pos()
	if player_pos == Vector2.INF:
		return
	var dist: float = global_position.distance_to(player_pos)
	if dist < detect_range and shoot_timer <= 0.0:
		_shoot(player_pos)
		shoot_timer = shoot_interval


func _shoot(target_pos: Vector2) -> void:
	# Phase 1 placeholder: 별도 projectile 씬 없이 simple Area2D + Tween으로
	var dir: Vector2 = (target_pos - global_position).normalized()
	var proj := Area2D.new()
	proj.collision_layer = 1 << 5  # Hazard 비슷하게 처리
	proj.collision_mask = 1 << 2   # Player만
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(6, 6)
	shape.shape = rect
	proj.add_child(shape)
	# 비주얼 (greybox 노란색)
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_named_box_2d"):
		var box: Node = greybox.make_named_box_2d("hazard", Vector2(6, 6))
		proj.add_child(box)
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.body_entered.connect(_on_proj_hit_player.bind(proj))
	# 1초 비행 후 free
	var tw: Tween = proj.create_tween()
	tw.tween_property(proj, "global_position", global_position + dir * projectile_speed * 1.5, 1.5)
	tw.tween_callback(proj.queue_free)
	DebugLog_log("ranged_shoot", "")


func _on_proj_hit_player(proj: Node, body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	# Player 사망 트리거 — 룸 베이스 통해 respawn
	var room: Node = _find_room()
	if room != null and room.has_method("respawn_player"):
		room.respawn_player()
	if is_instance_valid(proj):
		proj.queue_free()


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


func DebugLog_log(action: String, payload: String) -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_method("log_action"):
		dbg.log_action(action, payload)
