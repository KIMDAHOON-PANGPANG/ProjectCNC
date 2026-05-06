class_name SpikeHazard extends Area2D

# 가시 hazard. player 닿으면 즉시 리스폰.
# Layer: Hazard (6 = bit 5)

@export var visual_size: Vector2 = Vector2(16, 8)


func _ready() -> void:
	collision_layer = 1 << 5  # Layer 6 Hazard
	collision_mask = 1 << 2   # Layer 3 Player만 감지
	body_entered.connect(_on_body_entered)
	_spawn_visual()


func _spawn_visual() -> void:
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_named_box_2d"):
		var box: Node = greybox.make_named_box_2d("hazard", visual_size)
		add_child(box)


func _on_body_entered(body: Node) -> void:
	# 가장 가까운 RoomBase 찾아서 respawn 호출
	var room: Node = _find_room()
	if room != null and room.has_method("respawn_player"):
		room.respawn_player()


func _find_room() -> Node:
	var n: Node = get_parent()
	while n != null:
		if n is RoomBase:
			return n
		n = n.get_parent()
	return null
