class_name MeleeChaser extends EnemyBase

# 근접 추적형. detect_range 내에서 플레이어 방향으로 천천히 걸어옴.
# charger와 차별점: 텔레그래프 없이 항상 추적, chase_speed 절반.
# 절벽/벽 감지 시 정지 — 추락 방지.

@export var detect_range: float = 200.0
@export var chase_speed: float = 40.0
@export var stop_at_player_dist: float = 16.0

var facing_dir: float = 1.0

@onready var _wall_probe: RayCast2D = $WallProbe
@onready var _cliff_probe: RayCast2D = $CliffProbe


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_stunned or hp <= 0:
		return
	_ai_tick()


func _ai_tick() -> void:
	var player_pos: Vector2 = _find_player_pos()
	if player_pos == Vector2.INF:
		velocity.x = 0.0
		return
	var to_player: Vector2 = player_pos - global_position
	var dist: float = absf(to_player.x)

	if dist > detect_range or dist <= stop_at_player_dist:
		velocity.x = 0.0
		return

	var dir: float = signf(to_player.x)
	if dir == 0.0:
		dir = facing_dir
	facing_dir = dir
	_update_probes(dir)

	# 벽 정면이면 멈춤
	if _wall_probe.is_colliding():
		velocity.x = 0.0
		return
	# 발 앞에 floor 없으면 절벽 — 멈춤 (공중 점프 중에는 무시)
	if is_on_floor() and not _cliff_probe.is_colliding():
		velocity.x = 0.0
		return

	velocity.x = dir * chase_speed


func _update_probes(dir: float) -> void:
	_wall_probe.target_position = Vector2(16.0 * dir, 0.0)
	_cliff_probe.position = Vector2(8.0 * dir, 0.0)


func _find_player_pos() -> Vector2:
	var tree: SceneTree = get_tree()
	if tree == null:
		return Vector2.INF
	var p: Node = tree.current_scene.get_node_or_null("Player") if tree.current_scene else null
	if p != null and p is Node2D:
		return (p as Node2D).global_position
	return Vector2.INF
