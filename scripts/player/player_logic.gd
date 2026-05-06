class_name PlayerLogic extends RefCounted

# 차원 무관 플레이어 로직.
# Vector2 / Vector3 / CharacterBody* 어떤 것도 import 금지.
# 모든 입출력은 float / int / bool / String.
#
# 사양: DOC/dagger_marker_roadmap_supplement.md §H-2

enum State { NORMAL = 0, TELEPORT = 1, ATTACK = 2, HIT = 3 }

# ── 입력 (Body가 채운다) ──────────────────────────────────────
var input_move: float = 0.0  # -1, 0, +1
var input_jump_pressed: bool = false
var input_jump_held: bool = false
var input_jump_just_released: bool = false

# ── 환경 (Body가 채운다) ──────────────────────────────────────
var on_floor: bool = false

# ── 상태 (logic이 갱신, Body가 읽는다) ────────────────────────
var state: int = State.NORMAL
var velocity_x: float = 0.0
var velocity_y: float = 0.0
var facing: int = 1  # +1=right, -1=left

# ── 내부 타이머 ──────────────────────────────────────────────
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# ── 체인 보너스 (Day 3+) ─────────────────────────────────────
var chain_window_timer: float = 0.0  # 텔레포트 직후 N초간 던지기 시 쿨다운 -50%


func tick(delta: float) -> void:
	# 텔레포트/처형/피격 중엔 이동/중력 모두 정지
	if state != State.NORMAL:
		return

	_update_timers(delta)
	_update_facing()
	_apply_horizontal_movement(delta)
	_try_jump()
	_apply_jump_cut()
	_apply_gravity(delta)


# 체인 윈도우 타이머는 텔레포트 중에도 흐름
func tick_always(delta: float) -> void:
	chain_window_timer = maxf(0.0, chain_window_timer - delta)


func is_chain_active() -> bool:
	return chain_window_timer > 0.0


func start_chain_window() -> void:
	chain_window_timer = GameConstants.CHAIN_BONUS_WINDOW


func _update_timers(delta: float) -> void:
	if on_floor:
		coyote_timer = GameConstants.COYOTE_TIME
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)

	if input_jump_pressed:
		jump_buffer_timer = GameConstants.JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)


func _update_facing() -> void:
	if input_move > 0.01:
		facing = 1
	elif input_move < -0.01:
		facing = -1


func _apply_horizontal_movement(delta: float) -> void:
	if absf(input_move) > 0.01:
		var accel: float = GameConstants.RUN_ACCEL if on_floor else GameConstants.AIR_ACCEL
		var target: float = input_move * GameConstants.MAX_RUN
		velocity_x = move_toward(velocity_x, target, accel * delta)
	else:
		var decel: float = GameConstants.RUN_DECEL if on_floor else GameConstants.RUN_DECEL * 0.5
		velocity_x = move_toward(velocity_x, 0.0, decel * delta)


func _try_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity_y = GameConstants.JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


func _apply_jump_cut() -> void:
	if input_jump_just_released and velocity_y < 0.0:
		velocity_y *= GameConstants.JUMP_CUT_MULT


func _apply_gravity(delta: float) -> void:
	var grav: float = GameConstants.GRAVITY
	if velocity_y > 0.0:
		grav *= GameConstants.FALL_GRAVITY_MULT
	velocity_y += grav * delta
	if velocity_y > GameConstants.MAX_FALL:
		velocity_y = GameConstants.MAX_FALL
