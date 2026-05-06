extends Node

# 모든 placeholder 비주얼 / 충돌 박스를 한 곳에서 생성한다.
# 사양: DOC/dagger_marker_roadmap_supplement.md §H-1, §H-7
#
# Phase 1~4 동안 텍스처/메시 직접 참조 금지. 반드시 이 autoload를 거친다.
# Phase 3+ 폴리시 단계에서 VisualResource에 에셋 채우면 자동 교체된다.

const COLORS: Dictionary = {
	"player": Color("#3da5ff"),
	"enemy": Color("#ff3d3d"),
	"enemy_ranged": Color("#ff7700"),
	"enemy_bouncer": Color("#a83dff"),
	"wall": Color("#666666"),
	"wall_bouncy": Color("#ff3d8a"),
	"dagger": Color("#00e5ff"),
	"marker": Color("#f5b041"),
	"hazard": Color("#ff7700"),
	"goal": Color("#4ade80"),
}


# ── Public API ────────────────────────────────────────────────

# VisualResource를 받아 적절한 뷰 노드를 만들어 parent의 자식으로 붙인다.
# 2D 에셋이 있으면 Sprite2D / AnimatedSprite2D, 없으면 색깔 박스.
# 3D 에셋이 있으면 인스턴스, 없으면 BoxMesh.
func spawn_view(visual: VisualResource, parent: Node) -> Node:
	if visual == null:
		push_warning("[greybox] visual is null, returning empty Node2D")
		var empty := Node2D.new()
		parent.add_child(empty)
		return empty

	var node: Node = null
	match visual.dimension:
		VisualResource.Dimension.D2:
			node = _spawn_2d(visual)
		VisualResource.Dimension.D3:
			node = _spawn_3d(visual)
	parent.add_child(node)
	return node


# 색깔 박스 2D — 절대 좌표 사이즈, 중심 정렬.
func make_box_2d(size: Vector2, color: Color) -> ColorRect:
	var box := ColorRect.new()
	box.color = color
	box.size = size
	box.position = -size * 0.5
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box


# 색깔 박스 3D — 중심 정렬.
func make_box_3d(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	return mesh_inst


# 색상 키로 직접 박스 생성 (가장 흔한 경우).
func make_named_box_2d(role: String, size: Vector2 = Vector2(8, 16)) -> ColorRect:
	var color: Color = COLORS.get(role, Color.WHITE)
	return make_box_2d(size, color)


func make_named_box_3d(role: String, size: Vector3 = Vector3(0.5, 1.0, 0.5)) -> MeshInstance3D:
	var color: Color = COLORS.get(role, Color.WHITE)
	return make_box_3d(size, color)


# ── Internals ─────────────────────────────────────────────────

func _spawn_2d(visual: VisualResource) -> Node:
	if visual.sprite_frames != null:
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = visual.sprite_frames
		return anim
	if visual.texture_2d != null:
		var spr := Sprite2D.new()
		spr.texture = visual.texture_2d
		return spr
	# fallback to greybox
	return make_box_2d(visual.greybox_size_2d, visual.greybox_color)


func _spawn_3d(visual: VisualResource) -> Node:
	if visual.mesh_3d != null:
		return visual.mesh_3d.instantiate()
	# fallback to greybox
	return make_box_3d(visual.greybox_size_3d, visual.greybox_color)
