class_name EnemyBase extends CharacterBody2D

# 공통 적 베이스. HP / 경직 / 처형 인터페이스.
# Phase 1 Day 4 사양: 단검은 경직만, HP는 처형으로만 0이 됨.

signal stunned(duration: float)
signal executed
signal died

@export var visual: VisualResource
@export var max_hp: int = 1
@export var stun_duration: float = 0.5

var hp: int = 1
var stun_timer: float = 0.0
var is_stunned: bool = false
var _view: Node = null


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	if visual != null:
		_view = Greybox.spawn_view(visual, self)


func _physics_process(delta: float) -> void:
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
			_on_stun_end()
	# 중력 적용 (지상 적 기본)
	if not is_on_floor():
		velocity.y = minf(velocity.y + GameConstants.GRAVITY * delta, GameConstants.MAX_FALL)
	else:
		velocity.y = 0.0
	move_and_slide()


# 단검 명중 시 호출
func receive_dagger_hit() -> void:
	is_stunned = true
	stun_timer = stun_duration
	stunned.emit(stun_duration)
	DebugLog.log_action("enemy_stun", "%.0f,%.0f" % [global_position.x, global_position.y])


# 텔레포트 후 attack 입력으로 처형
func receive_execution() -> void:
	hp = 0
	executed.emit()
	died.emit()
	DebugLog.log_action("enemy_executed", "%.0f,%.0f" % [global_position.x, global_position.y])
	queue_free()


func is_executable() -> bool:
	return is_stunned and hp > 0


# 자식 클래스에서 override (예: 보스의 경직 종료 후 다음 패턴 진입)
func _on_stun_end() -> void:
	pass
