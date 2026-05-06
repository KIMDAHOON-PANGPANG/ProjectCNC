class_name DaggerBody2D extends RigidBody2D

# 2D 단검 wrapper. Logic은 DaggerLogic(차원 무관)에 위임.
# 사양: DOC/dagger_marker_roadmap_supplement.md §B-1, §H-2

@export var visual: VisualResource

var logic: DaggerLogic
var _view: Node = null

# Robust autoload lookup (compile 시 식별자 분석 회피)
@onready var _rumble: Node = get_node_or_null("/root/Rumble")
@onready var _camera_shake: Node = get_node_or_null("/root/CameraShake")


func _ready() -> void:
	logic = DaggerLogic.new()
	gravity_scale = 0.0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

	if visual != null:
		_view = Greybox.spawn_view(visual, self)


func launch(dir: Vector2, charged: bool = false) -> void:
	var speed: float = GameConstants.DAGGER_SPEED
	if charged:
		speed *= 1.3
		logic.is_charged = true
		logic.penetrate_remaining = 2  # 적 2명 관통 후 박힘
	var v: Vector2 = dir.normalized() * speed
	linear_velocity = v
	logic.velocity_x = v.x
	logic.velocity_y = v.y
	if v.length_squared() > 0.001:
		rotation = v.angle()


func _physics_process(delta: float) -> void:
	if logic.state == DaggerLogic.State.STUCK:
		logic.tick(delta)
		if logic.state == DaggerLogic.State.EXPIRED:
			MarkerManager.expire_marker(self)


func _on_body_entered(body: Node) -> void:
	if logic.state != DaggerLogic.State.FLYING:
		return

	var layer_bits: int = 0
	if "collision_layer" in body:
		layer_bits = body.collision_layer

	var is_world: bool = (layer_bits & (1 << 0)) != 0
	var is_world_bouncy: bool = (layer_bits & (1 << 1)) != 0
	var is_enemy: bool = (layer_bits & (1 << 3)) != 0

	# ISSUE-2 FIX (강화): RigidBody2D의 linear_velocity는 충돌 응답으로 0 근처로
	# 줄어드는 경우가 많음 (sim에서 vel=0,-11 같은 값 관측). 의도된 비행 속도는
	# logic.velocity_x/y에 보존되어 있으므로 그것을 우선 사용한다.
	var v: Vector2 = Vector2(logic.velocity_x, logic.velocity_y)
	if v.length() < 1.0:
		# launch 안 된 상태? 안전망.
		_plant()
		return
	var current_speed: float = v.length()

	if is_enemy:
		if body.has_method("receive_dagger_hit"):
			body.receive_dagger_hit()
		# 충전 던지기 — 적 관통 (bounce 없이 직진)
		if logic.is_charged and logic.penetrate_remaining > 0:
			logic.penetrate_remaining -= 1
			return
		var refl_dir: Vector2 = -v.normalized()
		if logic.try_bounce_enemy(refl_dir.x, refl_dir.y, current_speed):
			linear_velocity = Vector2(logic.velocity_x, logic.velocity_y)
			rotation = linear_velocity.angle()
			# Game Feel: 적 명중 셰이크 (약하게)
			if _camera_shake:
				_camera_shake.shake(GameConstants.SHAKE_AMPLITUDE * 0.5, GameConstants.SHAKE_DURATION * 0.5)
			return
		else:
			_plant()
	elif is_world_bouncy:
		var normal: Vector2 = _approx_normal(body)
		var refl: Vector2 = v.bounce(normal)
		var refl_dir: Vector2 = refl.normalized()
		if logic.try_bounce_wall_bouncy(refl_dir.x, refl_dir.y, current_speed):
			linear_velocity = Vector2(logic.velocity_x, logic.velocity_y)
			rotation = linear_velocity.angle()
			return
		else:
			_plant()
	elif is_world:
		_plant()


func _plant() -> void:
	logic.plant()
	# ISSUE-RUNTIME-1 FIX: body_entered 시그널 콜백 안에서 RigidBody2D mode를 직접
	# 변경하면 "Can't change this state while flushing queries" 에러 발생.
	# set_deferred로 다음 idle frame에 안전하게 적용.
	set_deferred("freeze", true)
	set_deferred("linear_velocity", Vector2.ZERO)
	set_deferred("angular_velocity", 0.0)
	MarkerManager.register_marker(self)
	DebugLog.log_action("plant", "%.0f,%.0f" % [global_position.x, global_position.y])

	# Game Feel placeholder (Day 5)
	if _camera_shake: _camera_shake.shake()
	if _rumble: _rumble.pulse_plant()
	_freeze_trail()
	# SFX + 파편
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("play"):
		sfx.play("plant")
	var hfx: Node = get_node_or_null("/root/HitFx")
	if hfx != null and hfx.has_method("spawn_hit"):
		hfx.spawn_hit(global_position, Greybox.COLORS.get("marker", Color.YELLOW), 6)


func _freeze_trail() -> void:
	var t: Node = get_node_or_null("Trail")
	if t != null and t.has_method("freeze_trail"):
		t.freeze_trail()


func _approx_normal(body: Node) -> Vector2:
	var to_dagger: Vector2 = global_position - body.global_position
	if absf(to_dagger.x) > absf(to_dagger.y):
		return Vector2(signf(to_dagger.x), 0.0)
	return Vector2(0.0, signf(to_dagger.y))


func get_position_2d() -> Vector2:
	return global_position
