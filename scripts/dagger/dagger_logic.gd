class_name DaggerLogic extends RefCounted

# 차원 무관 단검 룰. Vector2 / Vector3 / RigidBody* import 금지.
# 사양: DOC/dagger_marker_roadmap_supplement.md §B-1
#
# Day 2: FLYING / STUCK / EXPIRED 3상태 (박힘 + 8초 수명)
# Day 4: try_bounce_enemy / try_bounce_wall_bouncy 활성화

enum State { FLYING = 0, STUCK = 1, EXPIRED = 2 }

var state: int = State.FLYING
var velocity_x: float = 0.0
var velocity_y: float = 0.0
var lifetime: float = 0.0
var bounce_count_enemy: int = 0
var bounce_count_wall: int = 0

# Phase 3 변수: 충전 던지기 — 관통 + 추가 튕김 1회 보너스.
var is_charged: bool = false
var penetrate_remaining: int = 0  # 관통 횟수 (적을 통과 — bounce_count 증가 안 함)


func tick(delta: float) -> void:
	if state == State.STUCK:
		lifetime += delta
		if lifetime >= GameConstants.DAGGER_LIFETIME:
			state = State.EXPIRED


func plant() -> void:
	state = State.STUCK
	velocity_x = 0.0
	velocity_y = 0.0
	lifetime = 0.0


# 적 명중 → 1회 튕김 후 다음 표면 박힘. 속도 70% 유지.
# rx/ry는 반사 방향 단위 벡터, speed는 이전 속도 크기.
# 반환 true = 튕김 성공(계속 비행), false = 박힘으로 전환해야 함.
func try_bounce_enemy(rx: float, ry: float, speed: float) -> bool:
	if bounce_count_enemy >= 1:
		return false
	bounce_count_enemy += 1
	velocity_x = rx * speed * GameConstants.BOUNCE_SPEED_RATIO
	velocity_y = ry * speed * GameConstants.BOUNCE_SPEED_RATIO
	return true


# 튕김면 1회 반사. 속도 100% 유지.
func try_bounce_wall_bouncy(rx: float, ry: float, speed: float) -> bool:
	if bounce_count_wall >= 1:
		return false
	bounce_count_wall += 1
	velocity_x = rx * speed
	velocity_y = ry * speed
	return true
