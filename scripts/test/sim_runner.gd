extends Node

# Day 1~6 자동 시뮬레이션 러너.
# headless 모드에서 Input.action_press/release로 입력을 자동 발화하고,
# DebugLog autoload가 csv에 기록한다. 종료 후 csv를 읽어 검증.

# (시간(s), 액션명, "press"|"release"|"__quit__"|"_marker_"+payload)
var _scenario: Array = [
	# === 안착 대기 ===
	[0.5, "_marker_", "anchor_settled"],

	# === Day 1: 이동 + 점프 + 점프 컷 ===
	[0.6, "move_right", "press"],
	[0.9, "jump", "press"],
	[0.96, "jump", "release"],   # 60ms = 점프 컷 트리거
	[1.4, "move_right", "release"],

	# === 첫 단검 던지기 → 적 명중 → 튕김 → wall/적 가까이 박힘 ===
	# move_right 활성화한 채 throw → 던지기 방향 우측 확정
	[1.7, "_marker_", "throw_1"],
	[1.65, "move_right", "press"],
	[1.7, "dagger_throw", "press"],
	[1.75, "dagger_throw", "release"],
	[1.78, "move_right", "release"],

	# === 2,3번째 던지기 — stun 갱신 누적 (3rd 명중 ~2.95s, stun until 3.45s) ===
	[2.4, "_marker_", "throw_2"],
	[2.35, "move_right", "press"],
	[2.4, "dagger_throw", "press"],
	[2.45, "dagger_throw", "release"],
	[2.48, "move_right", "release"],

	[2.9, "_marker_", "throw_3"],
	[2.85, "move_right", "press"],
	[2.9, "dagger_throw", "press"],
	[2.95, "dagger_throw", "release"],
	[2.98, "move_right", "release"],

	# === 텔레포트 — 1st plant(~2.68s) 있음. 적 stun until ~3.45s ===
	[3.0, "_marker_", "teleport_attempt"],
	[3.0, "teleport", "press"],
	[3.05, "teleport", "release"],

	# === 처형 — 텔레포트 도착(~3.12s) + 적 stunned + 거리 가까움 → execute ===
	[3.15, "attack", "press"],
	[3.2, "attack", "release"],

	# === 마커/ammo 한계 검증 (move_right 활성 채로) ===
	[3.7, "_marker_", "ammo_limit_phase"],
	[3.65, "move_right", "press"],
	[3.7, "dagger_throw", "press"],
	[3.75, "dagger_throw", "release"],
	[4.0, "dagger_throw", "press"],
	[4.05, "dagger_throw", "release"],
	[4.3, "dagger_throw", "press"],
	[4.35, "dagger_throw", "release"],
	# 4번째 — ammo 소진 시 throw_blocked 기록
	[4.6, "dagger_throw", "press"],
	[4.65, "dagger_throw", "release"],
	[4.9, "dagger_throw", "press"],
	[4.95, "dagger_throw", "release"],
	[4.98, "move_right", "release"],

	# === teleport_blocked (마커 없을 때) 검증 — 모든 마커 회수된 상태? skip
	# 단, ammo 소진 상태에서 teleport는 마커 있으면 가능.

	# === bouncy wall 튕김 시나리오 (적 처형됨 → wall_right만 hit) ===
	# 단, ammo 0 상태이므로 던지기 차단됨. 시연을 위해 추가 throw 안 함.

	# === 점프 중 throw / teleport 시도 (state 전이 검증) ===
	[5.0, "_marker_", "jump_action_phase"],
	[5.0, "jump", "press"],
	[5.05, "jump", "release"],
	[5.15, "dagger_throw", "press"],   # 공중 throw 시도 (ammo 0 → blocked)
	[5.2, "dagger_throw", "release"],
	[5.3, "teleport", "press"],         # 공중 teleport (마커 있다면 발동)
	[5.35, "teleport", "release"],

	# === 종료 ===
	[6.0, "_marker_", "scenario_end"],
	[6.5, "__quit__", ""],
]

var _start_ms: int = 0
var _next_idx: int = 0


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	print("[sim] sim_runner started, scenario steps=", _scenario.size())


func _physics_process(_delta: float) -> void:
	var now_s: float = float(Time.get_ticks_msec() - _start_ms) / 1000.0
	while _next_idx < _scenario.size():
		var step = _scenario[_next_idx]
		var t: float = step[0]
		if now_s < t:
			break
		var action: String = step[1]
		var op: String = step[2]
		if action == "__quit__":
			print("[sim] quit at t=%.2fs" % now_s)
			get_tree().quit()
			return
		if action == "_marker_":
			DebugLog.log_action("sim_marker", op)
			print("[sim] %.2fs marker: %s" % [now_s, op])
		else:
			if op == "press":
				Input.action_press(action)
				print("[sim] %.2fs press %s" % [now_s, action])
			elif op == "release":
				Input.action_release(action)
		_next_idx += 1
