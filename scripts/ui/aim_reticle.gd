extends CanvasLayer

# 마우스 커서 위치에 투명 동그라미 (aim reticle).
# Phase 1 그레이박스 — Phase 3에서 SVG / 애니메이션 reticle로 폴리시.
# autoload 등록되어 모든 씬에서 자동 표시.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 70
	var renderer := ReticleRenderer.new()
	add_child(renderer)


class ReticleRenderer extends Control:
	@export var radius: float = 10.0
	@export var thickness: float = 1.5
	@export var color: Color = Color(1.0, 1.0, 1.0, 0.45)
	@export var dot_radius: float = 1.5
	@export var arc_segments: int = 32

	# 충전 던지기 진행도(0~1)에 따라 색/두께 변경 가능. 현재는 정적.
	# Phase 3에서 charge_progress 동기화 시 추가 시각화.

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchor_right = 1.0
		anchor_bottom = 1.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var pos: Vector2 = get_local_mouse_position()
		# 외곽 동그라미 (반투명)
		draw_arc(pos, radius, 0.0, TAU, arc_segments, color, thickness, true)
		# 중심점
		var dot_color: Color = Color(color.r, color.g, color.b, 0.85)
		draw_circle(pos, dot_radius, dot_color)
		# 십자 가이드 (4개 짧은 선) — 선택적 시각 강조
		var guide_color: Color = Color(color.r, color.g, color.b, 0.30)
		var inner: float = radius - 3.0
		var outer: float = radius - 0.5
		# 위
		draw_line(pos + Vector2(0, -inner), pos + Vector2(0, -outer), guide_color, thickness)
		# 아래
		draw_line(pos + Vector2(0, inner), pos + Vector2(0, outer), guide_color, thickness)
		# 좌
		draw_line(pos + Vector2(-inner, 0), pos + Vector2(-outer, 0), guide_color, thickness)
		# 우
		draw_line(pos + Vector2(inner, 0), pos + Vector2(outer, 0), guide_color, thickness)
