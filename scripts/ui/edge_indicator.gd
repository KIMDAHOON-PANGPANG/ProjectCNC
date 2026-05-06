extends Control

# 화면 밖 마커 → 화면 가장자리 화살표(박스) 표시.
# 사양: DOC/dagger_marker_roadmap_supplement.md §G Day 6
# Phase 1 placeholder (6×6 색깔 박스). Phase 3에서 화살표 SVG로 폴리시.

@export var arrow_size: Vector2 = Vector2(6, 6)
@export var edge_padding: float = 8.0

var _arrows: Dictionary = {}  # marker instance_id -> ColorRect
var _camera: Camera2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = _find_camera()
	if _camera == null:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var half: Vector2 = vp_size * 0.5
	var cam_pos: Vector2 = _camera.global_position

	var seen: Dictionary = {}
	for marker in MarkerManager.markers:
		if not is_instance_valid(marker):
			continue
		var id: int = marker.get_instance_id()
		seen[id] = true

		var rel: Vector2 = marker.global_position - cam_pos
		var on_screen: bool = absf(rel.x) < half.x and absf(rel.y) < half.y
		if on_screen:
			if _arrows.has(id):
				var a: ColorRect = _arrows[id]
				if is_instance_valid(a):
					a.queue_free()
				_arrows.erase(id)
			continue

		# 화면 경계로 클램프 (가장 큰 비율 축으로)
		var hx: float = half.x - edge_padding
		var hy: float = half.y - edge_padding
		var rx: float = absf(rel.x) / hx if hx > 0.0 else 0.0
		var ry: float = absf(rel.y) / hy if hy > 0.0 else 0.0
		var k: float = maxf(rx, ry)
		if k < 0.001:
			continue
		var clamped_rel: Vector2 = rel / k

		# 화면 좌표 (Control은 화면 좌상단 = (0,0))
		var screen_pos: Vector2 = clamped_rel + half

		var arrow: ColorRect
		if _arrows.has(id) and is_instance_valid(_arrows[id]):
			arrow = _arrows[id]
		else:
			arrow = ColorRect.new()
			arrow.color = Greybox.COLORS.get("marker", Color.YELLOW)
			arrow.size = arrow_size
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(arrow)
			_arrows[id] = arrow
		arrow.position = screen_pos - arrow_size * 0.5

	# 사라진 마커 정리
	for id in _arrows.keys():
		if not seen.has(id):
			var a2 = _arrows[id]
			if is_instance_valid(a2):
				a2.queue_free()
			_arrows.erase(id)


func _find_camera() -> Camera2D:
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	return _search_camera(root)


func _search_camera(node: Node) -> Camera2D:
	if node is Camera2D:
		return node as Camera2D
	for c in node.get_children():
		var f: Camera2D = _search_camera(c)
		if f != null:
			return f
	return null
