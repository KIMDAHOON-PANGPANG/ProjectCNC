extends Node

# 컨트롤러 진동 헬퍼.
# 사양: DOC/dagger_marker_roadmap_supplement.md §D-1
# Phase 1 placeholder — Phase 3에서 곡선/분리진동으로 폴리시.
#
# NOTE: 메서드명에 'pulse_' 접두사를 붙인 이유는 GDScript 4.7-dev에서
# 'throw'가 예약어/내장 식별자와 충돌해 autoload 자체가 등록 실패하는
# 케이스 회피용. 안정 4.x에선 안전하지만 dev 빌드 호환성 우선.


func vibrate(weak: float, strong: float, duration: float) -> void:
	# device 0 = 첫 번째 게임패드. 키보드만 쓰면 무효 (에러 안 남).
	Input.start_joy_vibration(0, weak, strong, duration)


# ── 동사별 진동 (GameConstants 수치) ──────────────────────────
func pulse_throw() -> void:
	vibrate(GameConstants.RUMBLE_THROW_AMP, 0.0, GameConstants.RUMBLE_THROW_DURATION)


func pulse_plant() -> void:
	vibrate(0.0, GameConstants.RUMBLE_PLANT_AMP, GameConstants.RUMBLE_PLANT_DURATION)


func pulse_teleport() -> void:
	vibrate(
		GameConstants.RUMBLE_TELEPORT_AMP * 0.5,
		GameConstants.RUMBLE_TELEPORT_AMP,
		GameConstants.RUMBLE_TELEPORT_DURATION
	)


func pulse_execution() -> void:
	vibrate(
		GameConstants.RUMBLE_EXECUTION_AMP * 0.5,
		GameConstants.RUMBLE_EXECUTION_AMP,
		GameConstants.RUMBLE_EXECUTION_DURATION
	)
