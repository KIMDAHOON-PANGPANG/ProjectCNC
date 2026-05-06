extends Node

# 히트 이펙트 — 작은 박스 파편을 폭발 패턴으로 spawn.
# Phase 1 placeholder. Phase 3에서 GPUParticles2D로 폴리시.


func spawn_hit(at_pos: Vector2, color: Color = Color(1, 0.9, 0.2), count: int = 8) -> void:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return
	var parent: Node = tree.current_scene
	for i in range(count):
		var box := ColorRect.new()
		box.color = color
		box.size = Vector2(3, 3)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(box)
		box.global_position = at_pos - box.size * 0.5

		var angle: float = TAU * float(i) / float(count) + randf_range(-0.2, 0.2)
		var dist: float = randf_range(8.0, 18.0)
		var target: Vector2 = at_pos + Vector2(cos(angle), sin(angle)) * dist - box.size * 0.5
		var tw: Tween = box.create_tween().set_parallel(true)
		tw.tween_property(box, "global_position", target, 0.25)
		tw.tween_property(box, "modulate:a", 0.0, 0.3)
		tw.chain().tween_callback(box.queue_free)
