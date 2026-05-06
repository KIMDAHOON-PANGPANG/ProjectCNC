class_name PlayerBody2D extends CharacterBody2D

# 2D 플레이어 바디 wrapper. Logic은 PlayerLogic(차원 무관)에 위임.
# 사양: DOC/dagger_marker_roadmap_supplement.md §H-2, §H-6

const DAGGER_SCENE: PackedScene = preload("res://scenes/dagger/dagger_2d.tscn")

@export var visual: VisualResource
@export var visual_offset: Vector2 = Vector2.ZERO
@export var dagger_layer_path: NodePath

var logic: PlayerLogic
var _view: Node = null
var _saved_collision_mask: int = 0
var _teleport_tween: Tween = null

var _execution_window_timer: float = 0.0
var _execution_target: Node = null

# Phase 3: 충전 던지기 (우클릭 길게 눌러 0.5초)
const CHARGE_THRESHOLD: float = 0.5
var _throw_held_time: float = 0.0
var _was_throw_held: bool = false

# 평타 3타 콤보 (좌클릭). 윈도우 안 다음 입력 = 콤보 진행, 밖이면 1타로 리셋.
const ATTACK_COMBO_WINDOW: float = 0.55
const ATTACK_HITBOX_OFFSET: float = 14.0
var _combo_index: int = 0  # 0=대기, 1~3=마지막 타
var _combo_window_timer: float = 0.0

# Robust autoload lookup — autoload identifier가 컴파일러에 인식 안 되어도 작동.
@onready var _rumble: Node = get_node_or_null("/root/Rumble")
@onready var _camera_shake: Node = get_node_or_null("/root/CameraShake")
@onready var _hit_stop: Node = get_node_or_null("/root/HitStop")
@onready var _sfx: Node = get_node_or_null("/root/Sfx")
@onready var _hit_fx: Node = get_node_or_null("/root/HitFx")

# Facing / Aim 시각 indicator (그레이박스)
var _facing_indicator: ColorRect = null
var _aim_dot: ColorRect = null


func _ready() -> void:
	logic = PlayerLogic.new()
	_saved_collision_mask = collision_mask
	if visual != null:
		_view = Greybox.spawn_view(visual, self)
		_apply_visual_offset()
	_spawn_indicators()


func _physics_process(delta: float) -> void:
	logic.tick_always(delta)
	_execution_window_timer = maxf(0.0, _execution_window_timer - delta)

	# 콤보 윈도우 갱신 — 타임아웃 시 인덱스 0으로 리셋
	_combo_window_timer = maxf(0.0, _combo_window_timer - delta)
	if _combo_window_timer <= 0.0:
		_combo_index = 0

	if logic.state == PlayerLogic.State.TELEPORT:
		velocity = Vector2.ZERO
		return

	logic.input_move = Input.get_axis("move_left", "move_right")
	logic.input_jump_pressed = Input.is_action_just_pressed("jump")
	logic.input_jump_held = Input.is_action_pressed("jump")
	logic.input_jump_just_released = Input.is_action_just_released("jump")
	logic.on_floor = is_on_floor()

	logic.tick(delta)

	# 키보드 입력 없을 때 마우스 위치로 facing 보정 (mouse-aim feel)
	_apply_mouse_facing()

	velocity = Vector2(logic.velocity_x, logic.velocity_y)
	move_and_slide()
	logic.velocity_x = velocity.x
	logic.velocity_y = velocity.y

	_apply_facing()
	_update_indicators()

	if Input.is_action_just_pressed("teleport"):
		_try_teleport()

	# 충전 던지기 — 누르고 있으면 시간 누적, 떼면 발사
	var throw_held: bool = Input.is_action_pressed("dagger_throw")
	if throw_held:
		_throw_held_time += delta
	if _was_throw_held and not throw_held:
		var charged: bool = _throw_held_time >= CHARGE_THRESHOLD
		_try_throw_dagger(charged)
		_throw_held_time = 0.0
	_was_throw_held = throw_held

	if Input.is_action_just_pressed("attack"):
		_try_attack()


# ── §H-6 인터페이스 컨벤션 ─────────────────────────────────────
func get_position_2d() -> Vector2:
	return global_position


func is_on_floor_logic() -> bool:
	return is_on_floor()


# ── Internals ────────────────────────────────────────────────
func _apply_visual_offset() -> void:
	if _view == null:
		return
	if _view is Node2D:
		(_view as Node2D).position = visual_offset
	elif _view is Control:
		(_view as Control).position += visual_offset


func _apply_facing() -> void:
	if _view == null:
		return
	if _view is Node2D:
		(_view as Node2D).scale.x = float(logic.facing) * absf((_view as Node2D).scale.x)


# 키보드 미입력 시 마우스 방향으로 facing 갱신 (mouse-aim).
# 헤드리스 / viewport 0이면 skip — 시뮬 일관성 유지.
func _apply_mouse_facing() -> void:
	if absf(logic.input_move) > 0.1:
		return  # 키보드 우선
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var mouse_world: Vector2 = get_global_mouse_position()
	if mouse_world == Vector2.ZERO:
		return  # 헤드리스 / 미초기화
	var to_mouse: Vector2 = mouse_world - global_position
	if absf(to_mouse.x) < 6.0:
		return  # 데드존 — player 위에 마우스면 유지
	logic.facing = 1 if to_mouse.x > 0.0 else -1


# Facing / Aim 그레이박스 indicator 생성.
# - facing_indicator: 캐릭터 옆 시안 박스 (좌/우 facing)
# - aim_dot: 머리 위 흰 점이 마우스 방향으로 약간 떨어진 곳 (조준 방향)
func _spawn_indicators() -> void:
	_facing_indicator = ColorRect.new()
	_facing_indicator.color = Color(0.0, 0.898, 1.0, 0.85)  # 시안
	_facing_indicator.size = Vector2(3, 6)
	_facing_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_facing_indicator)

	_aim_dot = ColorRect.new()
	_aim_dot.color = Color(1.0, 1.0, 1.0, 0.75)  # 흰색
	_aim_dot.size = Vector2(2, 2)
	_aim_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_aim_dot)


func _update_indicators() -> void:
	# facing indicator: 캐릭터 옆 (한쪽 면)
	if _facing_indicator != null:
		var f: float = float(logic.facing)
		# 캐릭터 8x16 → ±4. indicator 3x6 → 절반 1.5.
		# 우측 facing(+1): position.x = 4.0 (캐릭터 우측 가장자리)
		# 좌측 facing(-1): position.x = -4.0 - 3.0 = -7.0
		var off_x: float = (4.0 if f > 0 else -4.0 - _facing_indicator.size.x)
		_facing_indicator.position = Vector2(off_x, -3)

	# aim dot: 머리 위에서 마우스 방향으로 떨어진 곳
	if _aim_dot != null:
		var dir: Vector2 = Vector2(float(logic.facing), 0)
		var vp: Viewport = get_viewport()
		if vp != null:
			var vp_size: Vector2 = vp.get_visible_rect().size
			if vp_size.x > 0.0 and vp_size.y > 0.0:
				var mouse_world: Vector2 = get_global_mouse_position()
				if mouse_world != Vector2.ZERO:
					var to_mouse: Vector2 = mouse_world - global_position
					if to_mouse.length() > 4.0:
						dir = to_mouse.normalized()
		# 머리 위 (-10) 기준에서 마우스 방향으로 6px 이동
		var aim_pos: Vector2 = Vector2(0, -10) + dir * 6.0
		_aim_dot.position = aim_pos - _aim_dot.size * 0.5


# ── 단검 던지기 ──────────────────────────────────────────────
func _try_throw_dagger(charged: bool = false) -> void:
	if not MarkerManager.consume_ammo():
		DebugLog.log_action("throw_blocked", "no_ammo")
		return

	var dagger: Node = DAGGER_SCENE.instantiate()
	var dir: Vector2 = _resolve_throw_direction()

	var layer: Node = null
	if not dagger_layer_path.is_empty():
		layer = get_node_or_null(dagger_layer_path)
	if layer == null:
		layer = get_tree().current_scene
	layer.add_child(dagger)
	dagger.global_position = global_position
	if dagger.has_method("launch"):
		dagger.launch(dir, charged)

	if dir.x > 0.1:
		logic.facing = 1
	elif dir.x < -0.1:
		logic.facing = -1

	DebugLog.log_action("throw" if not charged else "throw_charged", "%.2f,%.2f" % [dir.x, dir.y])
	if _rumble: _rumble.pulse_throw()
	if _sfx: _sfx.play("throw")


func _resolve_throw_direction() -> Vector2:
	var x: float = Input.get_axis("move_left", "move_right")
	var y: float = Input.get_axis("jump", "move_down")
	if absf(x) > 0.1 or absf(y) > 0.1:
		return Vector2(x, y).normalized()

	var vp: Viewport = get_viewport()
	if vp != null:
		var vp_size: Vector2 = vp.get_visible_rect().size
		if vp_size.x > 0.0 and vp_size.y > 0.0:
			var mouse_world: Vector2 = get_global_mouse_position()
			var to_mouse: Vector2 = mouse_world - global_position
			if to_mouse.length() > 16.0:
				return to_mouse.normalized()

	return Vector2(float(logic.facing), 0.0)


# ── 텔레포트 ──────────────────────────────────────────────────
func _try_teleport() -> void:
	if logic.state != PlayerLogic.State.NORMAL:
		return

	var input_dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("jump", "move_down")
	)
	var target: Node = MarkerManager.get_nearest_marker(global_position, input_dir)
	if target == null:
		DebugLog.log_action("teleport_blocked", "no_marker")
		return

	_start_teleport(target)


func _start_teleport(target_marker: Node) -> void:
	if not is_instance_valid(target_marker):
		return

	logic.state = PlayerLogic.State.TELEPORT
	collision_mask = 0
	velocity = Vector2.ZERO
	logic.velocity_x = 0.0
	logic.velocity_y = 0.0

	var target_pos: Vector2 = target_marker.global_position
	DebugLog.log_action("teleport_start", "%.0f,%.0f" % [target_pos.x, target_pos.y])

	_spawn_afterimages(global_position, target_pos)
	if _rumble: _rumble.pulse_teleport()
	if _camera_shake: _camera_shake.zoom_punch()
	if _sfx: _sfx.play("teleport")

	if _teleport_tween != null and _teleport_tween.is_valid():
		_teleport_tween.kill()
	_teleport_tween = create_tween()
	_teleport_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_teleport_tween.tween_property(self, "global_position", target_pos, GameConstants.TELEPORT_DURATION)
	_teleport_tween.tween_callback(_end_teleport.bind(target_marker))


func _end_teleport(target_marker: Node) -> void:
	if is_instance_valid(target_marker):
		MarkerManager.recover_marker(target_marker)

	collision_mask = _saved_collision_mask

	logic.state = PlayerLogic.State.NORMAL
	logic.start_chain_window()

	var nearby: Node = _find_nearby_executable(20.0)
	if nearby != null:
		_execution_window_timer = GameConstants.EXECUTION_WINDOW
		_execution_target = nearby

	DebugLog.log_action("teleport_end", "%.0f,%.0f" % [global_position.x, global_position.y])


func _restore_collision() -> void:
	collision_mask = _saved_collision_mask


# ── Game Feel: 텔레포트 잔상 ────────────────────────────────
func _spawn_afterimages(from_pos: Vector2, _to_pos: Vector2) -> void:
	var color: Color = Greybox.COLORS.get("player", Color.WHITE)
	color.a = 0.5
	var size: Vector2 = Vector2(8, 16)
	if visual != null:
		size = visual.greybox_size_2d
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	for i in range(5):
		var box := ColorRect.new()
		box.color = color
		box.size = size
		box.position = from_pos - size * 0.5
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(box)
		var tw: Tween = box.create_tween()
		tw.tween_interval(i * 0.04)
		tw.tween_property(box, "modulate:a", 0.0, 0.3)
		tw.tween_callback(box.queue_free)


# ── 공격 (좌클릭) ─────────────────────────────────────────────
# 1순위: 처형 윈도우 안 + executable 적 → 처형
# 2순위: 평타 3타 콤보 (그레이박스 hitbox 시각화)
func _try_attack() -> void:
	# 처형 우선
	if _execution_window_timer > 0.0 and is_instance_valid(_execution_target):
		if _execution_target.has_method("receive_execution"):
			_execution_target.receive_execution()
			_execution_window_timer = 0.0
			_execution_target = null
			DebugLog.log_action("execute", "")
			if _hit_stop: _hit_stop.freeze()
			if _camera_shake:
				_camera_shake.shake(GameConstants.SHAKE_AMPLITUDE * 1.5, GameConstants.SHAKE_DURATION * 1.5)
				_camera_shake.zoom_punch(GameConstants.ZOOM_PUNCH_SCALE * 1.05)
			if _rumble: _rumble.pulse_execution()
			if _sfx: _sfx.play("execute")
			if _hit_fx: _hit_fx.spawn_hit(_execution_target.global_position if is_instance_valid(_execution_target) else global_position, Color(1, 0.4, 0.4), 12)
			return

	# 평타 콤보 진행
	_combo_index += 1
	if _combo_index > 3:
		_combo_index = 1
	_combo_window_timer = ATTACK_COMBO_WINDOW

	_spawn_attack_hitbox(_combo_index)
	DebugLog.log_action("attack", "combo=%d" % _combo_index)


# 평타 hitbox: ColorRect 시각 + Area2D 적 감지. 0.1~0.15초 후 자동 free.
func _spawn_attack_hitbox(combo: int) -> void:
	var size: Vector2
	var lifetime: float
	var color: Color
	match combo:
		1:
			size = Vector2(18, 10)
			lifetime = 0.10
			color = Color(0.0, 0.898, 1.0, 0.55)  # 시안
		2:
			size = Vector2(24, 12)
			lifetime = 0.12
			color = Color(0.5, 0.95, 1.0, 0.7)   # 밝은 시안
		_:  # 3타
			size = Vector2(34, 16)
			lifetime = 0.16
			color = Color(1.0, 1.0, 0.85, 0.9)   # 흰색+노랑 (강조)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 3  # Layer 4 Enemy

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)

	var box := ColorRect.new()
	box.color = color
	box.size = size
	box.position = -size * 0.5
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(box)

	add_child(area)
	# facing 앞쪽으로 hitbox 배치 (player local coord)
	area.position = Vector2(ATTACK_HITBOX_OFFSET * float(logic.facing), 0.0)

	# 적 감지 (한 번만)
	var hit_record: Dictionary = {"hit": false}
	area.body_entered.connect(_on_attack_hit_enemy.bind(hit_record, combo))

	# fade out + 자동 free
	var tw: Tween = area.create_tween()
	tw.tween_property(box, "modulate:a", 0.0, lifetime)
	tw.tween_callback(area.queue_free)

	# Game Feel: 콤보 단계별 강도
	if _camera_shake:
		var amp: float = GameConstants.SHAKE_AMPLITUDE * (0.4 + 0.3 * combo)
		_camera_shake.shake(amp, GameConstants.SHAKE_DURATION * 0.7)
	if _rumble:
		_rumble.vibrate(0.1 * combo, 0.05 * combo, 0.06)
	if combo == 3 and _hit_stop:
		_hit_stop.freeze(0.035)  # 3타 finisher 짧은 hit stop


func _on_attack_hit_enemy(body: Node, hit_record: Dictionary, combo: int) -> void:
	if hit_record.get("hit", false):
		return  # hitbox당 한 번만
	if not is_instance_valid(body):
		return
	hit_record["hit"] = true

	if body.has_method("receive_dagger_hit"):
		body.receive_dagger_hit()
	DebugLog.log_action("attack_hit", "combo=%d" % combo)

	# Game Feel: hit landed
	if _camera_shake:
		_camera_shake.shake(GameConstants.SHAKE_AMPLITUDE * 0.7, GameConstants.SHAKE_DURATION * 0.5)
	if _hit_stop:
		_hit_stop.freeze(0.025 * combo)
	if _sfx:
		_sfx.play("hit")
	if _hit_fx and is_instance_valid(body) and body is Node2D:
		_hit_fx.spawn_hit((body as Node2D).global_position, Color(1, 0.9, 0.4), 6)


func _find_nearby_executable(radius: float) -> Node:
	var best: Node = null
	var best_d: float = radius
	for b in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(b):
			continue
		if b.has_method("is_executable") and b.is_executable():
			var d: float = global_position.distance_to(b.global_position)
			if d < best_d:
				best_d = d
				best = b
	return best
