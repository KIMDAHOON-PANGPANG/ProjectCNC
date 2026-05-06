class_name MarkerDenier extends EnemyBase

# 마커 거부형. 활성 마커가 있으면 가장 가까운 마커로 이동 → 닿으면 마커 expire.
# Phase 3 사양: 플레이어가 마커를 빠르게 소비/회수하도록 강제.

@export var detect_speed: float = 60.0
@export var consume_radius: float = 12.0


func _ready() -> void:
	super._ready()
	stun_duration = 0.6


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_stunned or hp <= 0:
		return

	var mm: Node = get_node_or_null("/root/MarkerManager")
	if mm == null or not "markers" in mm:
		velocity.x = 0.0
		return

	var markers: Array = mm.markers
	if markers.is_empty():
		velocity.x = 0.0
		return

	# 가장 가까운 마커
	var nearest: Node = null
	var nearest_d: float = INF
	for m in markers:
		if not is_instance_valid(m):
			continue
		var d: float = global_position.distance_to(m.global_position)
		if d < nearest_d:
			nearest_d = d
			nearest = m

	if nearest == null:
		velocity.x = 0.0
		return

	# 도달 시 expire
	if nearest_d < consume_radius:
		if mm.has_method("expire_marker"):
			mm.expire_marker(nearest)
		_log("marker_denied", "")
		return

	# 수평 이동 (placeholder — 점프 못함)
	var to_marker: Vector2 = nearest.global_position - global_position
	velocity.x = signf(to_marker.x) * detect_speed


func _log(action: String, payload: String) -> void:
	var dbg: Node = get_node_or_null("/root/DebugLog")
	if dbg != null and dbg.has_method("log_action"):
		dbg.log_action(action, payload)
