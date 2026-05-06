extends Node

# Engine.time_scale을 짧게 0으로 떨어뜨려 타격감을 만든다.
# Phase 1 placeholder: 50ms 단발 (GameConstants.HIT_STOP_MS)

var _restore_at_ms: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func freeze(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = GameConstants.HIT_STOP_MS
	Engine.time_scale = 0.0
	# 실시간으로 복원해야 하므로 Time.get_ticks_msec()로 측정 (time_scale 영향 없음).
	_restore_at_ms = Time.get_ticks_msec() + int(duration * 1000.0)


func _process(_delta: float) -> void:
	if _restore_at_ms > 0 and Time.get_ticks_msec() >= _restore_at_ms:
		Engine.time_scale = 1.0
		_restore_at_ms = -1
