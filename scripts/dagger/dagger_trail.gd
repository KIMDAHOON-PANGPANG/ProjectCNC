class_name DaggerTrail extends Line2D

# 단검 비행 시 마지막 N 프레임 위치를 추적해 잔광 트레일을 그린다.
# 사양: DOC/dagger_marker_roadmap_supplement.md §D-1 (Phase 1 placeholder)
# Phase 3 폴리시 단계에서 GPUParticles2D로 교체.

@export var trail_length: int = 6
@export var trail_color: Color = Color(0, 0.898, 1, 0.7)

var _dagger: Node2D = null


func _ready() -> void:
	top_level = true  # 부모 좌표계 무시, global 좌표로 그리기
	width = 2.0
	var grad := Gradient.new()
	grad.add_point(0.0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	grad.add_point(1.0, trail_color)
	gradient = grad
	_dagger = get_parent() as Node2D


func _physics_process(_delta: float) -> void:
	if _dagger == null or not is_instance_valid(_dagger):
		queue_free()
		return
	add_point(_dagger.global_position)
	while points.size() > trail_length:
		remove_point(0)


# 박힘 시 호출 — 트레일 갱신 정지 (점들은 그대로 남아 fade)
func freeze_trail() -> void:
	set_physics_process(false)
	# 0.3초 뒤 정리
	var t: SceneTreeTimer = get_tree().create_timer(0.3)
	t.timeout.connect(queue_free)
