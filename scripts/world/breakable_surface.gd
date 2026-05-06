class_name BreakableSurface extends StaticBody2D

# 부서지는 면. 단검이 박히면 짧은 후 free.
# Phase 2 사양: 4~6종 박힘 면 중 하나.

@export var visual_size: Vector2 = Vector2(16, 16)
@export var break_delay: float = 0.4  # 단검 박힌 후 부서지기까지

var _broken: bool = false


func _ready() -> void:
	collision_layer = 1 << 0  # Layer 1 World
	collision_mask = 0
	_spawn_visual()


func _spawn_visual() -> void:
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_box_2d"):
		var box: Node = greybox.make_box_2d(visual_size, Color(0.55, 0.4, 0.25, 1))  # 갈색
		add_child(box)


# 단검의 _on_body_entered에서 호출 가능 (or area2D approach).
# 간단히: 단검이 박힘 시 register_marker 후 자동 호출.
func trigger_break() -> void:
	if _broken:
		return
	_broken = true
	var t: SceneTreeTimer = get_tree().create_timer(break_delay)
	t.timeout.connect(queue_free)
