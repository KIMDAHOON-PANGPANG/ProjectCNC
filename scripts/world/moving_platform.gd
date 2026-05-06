class_name MovingPlatform extends AnimatableBody2D

# 이동 플랫폼. 단검이 박히면 함께 이동 (마커 위치도 따라감).
# 사양: §C-Phase 2 표면 4~6종 중 하나.

@export var visual_size: Vector2 = Vector2(48, 8)
@export var distance: Vector2 = Vector2(80, 0)
@export var period: float = 3.0  # 한 사이클 시간

var _t: float = 0.0
var _origin: Vector2


func _ready() -> void:
	collision_layer = 1 << 0  # Layer 1 World
	collision_mask = 0
	sync_to_physics = true
	_origin = global_position
	_spawn_visual()


func _spawn_visual() -> void:
	var greybox: Node = get_node_or_null("/root/Greybox")
	if greybox != null and greybox.has_method("make_box_2d"):
		var box: Node = greybox.make_box_2d(visual_size, Color(0.5, 0.65, 0.5, 1))  # 청록
		add_child(box)


func _physics_process(delta: float) -> void:
	_t += delta
	var phase: float = sin(_t * TAU / period)
	global_position = _origin + distance * phase
