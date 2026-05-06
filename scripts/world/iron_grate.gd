class_name IronGrate extends StaticBody2D

# 쇠창살. 단검은 박힘, player는 통과 가능.
# Layer 1 World이지만 Player의 mask에서 분리하기 위해 Layer 2 World_Bouncy 사용 X.
# 대신 별도 mask 처리: Player.collision_mask에서 Iron Grate Layer 제외.
#
# 단순 구현: 별도 Layer 6 Hazard 미사용. Layer 1로 등록하되 Player만 통과.
# 그러나 player.mask=35는 layer 1 포함 → 충돌. 통과 안 됨.
# 해결: IronGrate를 Layer 2 World_Bouncy로 등록 → Player는 layer 2 mask 있어 충돌하나 단검도 충돌.
# 진정한 통과 위해선: Layer 1만 Player mask에서 제거. 또는 Player의 collision_mask를 dynamic으로 변경.
#
# Phase 2 단순 솔루션: Iron Grate를 collision_layer=0으로 두고 단검만 Area2D로 감지 → 박힘 트리거.

@export var visual_size: Vector2 = Vector2(8, 32)


func _ready() -> void:
	# Player가 통과해야 하므로 collision_layer = 0 (어떤 노드와도 안 부딪힘)
	# 단검 감지는 자식 Area2D로
	collision_layer = 0
	collision_mask = 0
	_spawn_visual()
	_setup_dagger_detector()


func _spawn_visual() -> void:
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_box_2d"):
		var box: Node = greybox.make_box_2d(visual_size, Color(0.5, 0.5, 0.6, 0.7))  # 반투명 회청색
		add_child(box)


func _setup_dagger_detector() -> void:
	var area := Area2D.new()
	area.collision_layer = 1 << 0  # Layer 1 — 단검의 mask=11에 포함되므로 감지
	area.collision_mask = 1 << 4   # Layer 5 = Dagger
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = visual_size
	shape.shape = rect
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_dagger_entered)


func _on_dagger_entered(body: Node) -> void:
	# 단검을 박힘 상태로 강제 (DaggerBody2D._plant 트리거)
	if body.has_method("_plant"):
		body.call_deferred("_plant")
