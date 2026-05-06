class_name MeleeCharger extends EnemyBase

# 근접 돌격형. Player 일정 거리 안 들어오면 돌진.
# Phase 3 사양: 적 4종 중 1번. HP/속도 외에 메커닉적 차이 — "예고 후 돌진"으로 처형 윈도우 강제.

@export var detect_range: float = 120.0
@export var charge_speed: float = 80.0
@export var telegraph_duration: float = 0.6  # 돌진 직전 정지 시간

enum AIState { IDLE, TELEGRAPH, CHARGE, COOLDOWN }
var ai_state: int = AIState.IDLE
var ai_timer: float = 0.0
var charge_dir: float = 1.0


func _ready() -> void:
	super._ready()
	stun_duration = 0.7  # 무거운 적이라 stun 더 김


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_stunned or hp <= 0:
		return
	_ai_tick(delta)


func _ai_tick(delta: float) -> void:
	var player_pos: Vector2 = _find_player_pos()
	if player_pos == Vector2.INF:
		return
	var to_player: Vector2 = player_pos - global_position
	var dist: float = absf(to_player.x)

	match ai_state:
		AIState.IDLE:
			if dist < detect_range:
				ai_state = AIState.TELEGRAPH
				ai_timer = telegraph_duration
				charge_dir = signf(to_player.x)
				if charge_dir == 0.0:
					charge_dir = 1.0
		AIState.TELEGRAPH:
			ai_timer -= delta
			velocity.x = 0.0
			if ai_timer <= 0.0:
				ai_state = AIState.CHARGE
				ai_timer = 1.2
		AIState.CHARGE:
			ai_timer -= delta
			velocity.x = charge_dir * charge_speed
			if ai_timer <= 0.0:
				ai_state = AIState.COOLDOWN
				ai_timer = 0.8
				velocity.x = 0.0
		AIState.COOLDOWN:
			ai_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 200.0 * delta)
			if ai_timer <= 0.0:
				ai_state = AIState.IDLE


func _find_player_pos() -> Vector2:
	var tree: SceneTree = get_tree()
	if tree == null:
		return Vector2.INF
	var p: Node = tree.current_scene.get_node_or_null("Player") if tree.current_scene else null
	if p != null and p is Node2D:
		return (p as Node2D).global_position
	return Vector2.INF
