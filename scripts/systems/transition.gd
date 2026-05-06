extends Node

# 룸 전환 시 화면 페이드 처리.
# RoomManager가 다음 룸 instance 직전에 fade_out → instance 후 fade_in.

const FADE_DURATION: float = 0.35
const FADE_HOLD: float = 0.15  # 검정 화면 유지 시간

var _layer: CanvasLayer = null
var _rect: ColorRect = null
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_overlay()


func _setup_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_rect)


func is_busy() -> bool:
	return _busy


# 페이드 아웃 → 콜백 실행 → 페이드 인. 콜백 안에서 룸 교체.
func fade_through(callback: Callable, duration: float = -1.0) -> void:
	if _busy:
		return
	_busy = true
	if duration < 0.0:
		duration = FADE_DURATION

	var tw: Tween = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_rect, "color:a", 1.0, duration)
	tw.tween_callback(func ():
		if callback.is_valid():
			callback.call()
	)
	tw.tween_interval(FADE_HOLD)
	tw.tween_property(_rect, "color:a", 0.0, duration)
	tw.tween_callback(func (): _busy = false)


# 즉시 페이드 인 (룸 첫 진입 시)
func fade_in_only(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = FADE_DURATION
	_rect.color.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_property(_rect, "color:a", 0.0, duration)
