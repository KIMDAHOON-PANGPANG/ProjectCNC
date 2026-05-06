class_name Boss extends EnemyBase

# Phase 4 보스 (페이즈 2~3). 마커 메커닉 강제 활용.
# - Phase 1: HP 3, 큰 telegraph 후 돌진 (player 회피 + 단검 박기)
# - Phase 2: HP 1, 빠른 발사체 + 마커 거부 행동 혼합

enum BossPhase { ONE = 0, TWO = 1, DEAD = 2 }
enum BossAction { IDLE, TELEGRAPH, CHARGE, SHOOT, DENY }

@export var phase_threshold_hp: int = 2  # HP가 이 이하로 내려가면 phase 2
@export var charge_speed: float = 100.0
@export var telegraph_duration: float = 0.8
@export var phase_transition_pause: float = 1.0

var phase: int = BossPhase.ONE
var action: int = BossAction.IDLE
var action_timer: float = 0.0
var charge_dir: float = 1.0


func _ready() -> void:
	super._ready()
	max_hp = 4
	hp = max_hp
	stun_duration = 0.6


func receive_dagger_hit() -> void:
	# 보스는 단검 명중에 stun 짧게만, HP 처형으로만
	is_stunned = true
	stun_timer = stun_duration
	stunned.emit(stun_duration)
	_log("boss_hit", "")


func receive_execution() -> void:
	hp -= 1
	_log("boss_dmg", "hp=%d" % hp)
	if hp <= phase_threshold_hp and phase == BossPhase.ONE:
		_enter_phase_two()
	elif hp <= 0:
		_die()


func is_executable() -> bool:
	return is_stunned and hp > 0


func _physics_process(delta: float) -> void:
	# super는 중력 + stun 처리
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
	if not is_on_floor():
		velocity.y = minf(velocity.y + GameConstants.GRAVITY * delta, GameConstants.MAX_FALL)
	else:
		velocity.y = 0.0
	move_and_slide()

	if is_stunned or phase == BossPhase.DEAD:
		return
	_ai_tick(delta)


func _ai_tick(delta: float) -> void:
	action_timer -= delta
	if action_timer > 0.0:
		_apply_action_velocity()
		return

	# 다음 행동 결정
	if phase == BossPhase.ONE:
		_pick_phase1_action()
	else:
		_pick_phase2_action()


func _pick_phase1_action() -> void:
	# 단순: TELEGRAPH → CHARGE → IDLE
	match action:
		BossAction.IDLE:
			action = BossAction.TELEGRAPH
			action_timer = telegraph_duration
			var pp: Vector2 = _player_pos()
			charge_dir = signf(pp.x - global_position.x) if pp != Vector2.INF else 1.0
		BossAction.TELEGRAPH:
			action = BossAction.CHARGE
			action_timer = 1.4
		BossAction.CHARGE:
			action = BossAction.IDLE
			action_timer = 1.0


func _pick_phase2_action() -> void:
	# 발사체 + 가끔 charge
	match action:
		BossAction.IDLE:
			action = BossAction.SHOOT
			action_timer = 0.8
		BossAction.SHOOT:
			_shoot_at_player()
			action = BossAction.IDLE
			action_timer = 0.6


func _apply_action_velocity() -> void:
	match action:
		BossAction.CHARGE:
			velocity.x = charge_dir * charge_speed
		_:
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * get_physics_process_delta_time())


func _shoot_at_player() -> void:
	var pp: Vector2 = _player_pos()
	if pp == Vector2.INF:
		return
	var dir: Vector2 = (pp - global_position).normalized()
	var proj := Area2D.new()
	proj.collision_layer = 1 << 5
	proj.collision_mask = 1 << 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 8)
	shape.shape = rect
	proj.add_child(shape)
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_named_box_2d"):
		proj.add_child(greybox.make_named_box_2d("hazard", Vector2(8, 8)))
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.body_entered.connect(_on_proj_hit.bind(proj))
	var tw: Tween = proj.create_tween()
	tw.tween_property(proj, "global_position", global_position + dir * 200.0, 1.6)
	tw.tween_callback(proj.queue_free)


func _on_proj_hit(proj: Node, body: Node) -> void:
	if not (body is CharacterBody2D):
		return
	var room: Node = _find_room()
	if room != null and room.has_method("respawn_player"):
		room.respawn_player()
	if is_instance_valid(proj):
		proj.queue_free()


func _enter_phase_two() -> void:
	phase = BossPhase.TWO
	action = BossAction.IDLE
	action_timer = phase_transition_pause
	is_stunned = false
	_log("boss_phase_2", "")
	# 시각 색 변경 — 분홍 → 빨강
	if _view != null and _view is ColorRect:
		(_view as ColorRect).color = Color(1, 0.1, 0.1, 1)


func _die() -> void:
	phase = BossPhase.DEAD
	hp = 0
	executed.emit()
	died.emit()
	_log("boss_dead", "")
	# 룸 클리어 트리거
	var room: Node = _find_room()
	if room != null and room.has_method("_clear_room"):
		room.call_deferred("_clear_room")
	queue_free()


func _find_room() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n is RoomBase:
			return n
		n = n.get_parent()
	return null


func _player_pos() -> Vector2:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return Vector2.INF
	var p: Node = tree.current_scene.get_node_or_null("Player")
	if p != null and p is Node2D:
		return (p as Node2D).global_position
	return Vector2.INF


func _log(action_name: String, payload: String) -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_method("log_action"):
		dbg.log_action(action_name, payload)
