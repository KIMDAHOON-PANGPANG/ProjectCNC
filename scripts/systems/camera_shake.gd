extends Node

# Camera2D 셰이크 + 줌펀치 헬퍼.
# 사양: DOC/dagger_marker_roadmap_supplement.md §D-1, §G Day 5
# Phase 1 placeholder. Phase 5 GO 결정 시 phantom_camera로 교체 가능.

var _shake_amplitude: float = 0.0
var _shake_remaining: float = 0.0
var _camera: Camera2D = null
var _orig_zoom: Vector2 = Vector2(1, 1)
var _zoom_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _shake_remaining > 0.0:
		_shake_remaining -= delta
		var cam: Camera2D = _get_camera()
		if cam != null:
			cam.offset = Vector2(
				randf_range(-_shake_amplitude, _shake_amplitude),
				randf_range(-_shake_amplitude, _shake_amplitude)
			)
		if _shake_remaining <= 0.0 and cam != null:
			cam.offset = Vector2.ZERO


func shake(amplitude: float = -1.0, duration: float = -1.0) -> void:
	if amplitude < 0.0:
		amplitude = GameConstants.SHAKE_AMPLITUDE
	if duration < 0.0:
		duration = GameConstants.SHAKE_DURATION
	_shake_amplitude = amplitude
	_shake_remaining = duration


func zoom_punch(scale_factor: float = -1.0, duration: float = -1.0) -> void:
	if scale_factor < 0.0:
		scale_factor = GameConstants.ZOOM_PUNCH_SCALE
	if duration < 0.0:
		duration = GameConstants.ZOOM_PUNCH_DURATION

	var cam: Camera2D = _get_camera()
	if cam == null:
		return

	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()

	# 첫 호출 시 기준 zoom 저장
	if _orig_zoom == Vector2(1, 1) and cam.zoom != Vector2(1, 1):
		_orig_zoom = cam.zoom

	_zoom_tween = create_tween()
	_zoom_tween.tween_property(cam, "zoom", _orig_zoom * scale_factor, duration * 0.5)
	_zoom_tween.tween_property(cam, "zoom", _orig_zoom, duration * 0.5)


func reset_camera() -> void:
	var cam: Camera2D = _get_camera()
	if cam != null:
		cam.offset = Vector2.ZERO
		cam.zoom = _orig_zoom


func _get_camera() -> Camera2D:
	if _camera != null and is_instance_valid(_camera):
		return _camera
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var root: Node = tree.current_scene
	if root == null:
		return null
	_camera = _search_camera(root)
	return _camera


func _search_camera(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D
	for c in node.get_children():
		var found: Camera2D = _search_camera(c)
		if found != null:
			return found
	return null
