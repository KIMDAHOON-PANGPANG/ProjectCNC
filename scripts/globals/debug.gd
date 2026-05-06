extends Node

# 디버그 오버레이 + 입력 시퀀스 CSV 로깅.
# Phase 1 Day 7의 60초 KILL Criteria 판정에 쓰임 (동사 시퀀스 비교).
# F3 토글로 오버레이 켜기/끄기.

signal action_logged(action: String, payload: String)

const LOG_PATH: String = "user://session_log.csv"

var enabled: bool = false
var session_start_ms: int = 0
var _file: FileAccess = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session_start_ms = Time.get_ticks_msec()
	_open_log()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			enabled = not enabled
			print("[debug] overlay = ", enabled)


func log_action(action: String, payload: String = "") -> void:
	# action: 동사 라벨 (예: "throw", "teleport", "attack", "plant", "execute")
	# payload: 부가 정보 (예: 위치, 마커 ID)
	if _file == null:
		return
	var t_ms: int = Time.get_ticks_msec() - session_start_ms
	var line := "%d,%s,%s\n" % [t_ms, action, payload]
	_file.store_string(line)
	action_logged.emit(action, payload)


func _open_log() -> void:
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file == null:
		push_warning("[debug] failed to open log: %s" % LOG_PATH)
		return
	_file.store_string("t_ms,action,payload\n")


func _exit_tree() -> void:
	if _file != null:
		_file.close()
		_file = null
