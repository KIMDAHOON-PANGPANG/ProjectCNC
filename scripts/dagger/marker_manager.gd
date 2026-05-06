extends Node

# 활성 마커 / 단검 잔여를 전역에서 관리.
# 사양: DOC/dagger_marker_roadmap_supplement.md §B-2

signal markers_changed
signal ammo_changed(new_ammo: int)

var markers: Array = []  # Array[Dagger]
var ammo: int = GameConstants.DAGGER_AMMO_MAX


func reset() -> void:
	# 룸 리셋 시 호출
	for m in markers:
		if is_instance_valid(m):
			m.queue_free()
	markers.clear()
	ammo = GameConstants.DAGGER_AMMO_MAX
	markers_changed.emit()
	ammo_changed.emit(ammo)


func consume_ammo() -> bool:
	# 단검 던지기 직전에 호출. false 반환 시 던질 수 없음.
	if ammo <= 0:
		return false
	ammo -= 1
	ammo_changed.emit(ammo)
	return true


func register_marker(dagger: Node) -> void:
	# 단검이 박혔을 때 호출.
	if markers.size() >= GameConstants.MARKER_MAX_COUNT:
		var oldest: Node = markers.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	markers.append(dagger)
	markers_changed.emit()


func recover_marker(dagger: Node) -> void:
	# 텔레포트 도착 또는 처형 시 호출. 단검 잔여 +1.
	markers.erase(dagger)
	if is_instance_valid(dagger):
		dagger.queue_free()
	ammo = min(ammo + 1, GameConstants.DAGGER_AMMO_MAX)
	markers_changed.emit()
	ammo_changed.emit(ammo)


func expire_marker(dagger: Node) -> void:
	# 8초 수명 만료 시 호출. 단검 사라지면 ammo 복구 (사용자 의도: dagger lost = ammo restored).
	# 사양 §B-2 갱신 — recover/expire 동일하게 ammo +1.
	markers.erase(dagger)
	if is_instance_valid(dagger):
		dagger.queue_free()
	ammo = min(ammo + 1, GameConstants.DAGGER_AMMO_MAX)
	markers_changed.emit()
	ammo_changed.emit(ammo)


func get_nearest_marker(from_pos: Vector2, input_dir: Vector2 = Vector2.ZERO) -> Node:
	# 거리 + 입력 방향 가중치로 가장 적합한 마커 반환.
	# input_dir이 zero면 거리만 본다.
	if markers.is_empty():
		return null
	var best: Node = null
	var best_score: float = INF
	for m in markers:
		if not is_instance_valid(m):
			continue
		var to: Vector2 = m.global_position - from_pos
		var dist: float = to.length()
		var score: float = dist
		if input_dir != Vector2.ZERO and dist > 0.001:
			# 입력 방향과 일치하면 거리를 80%로 환산 (가산점)
			var dot: float = input_dir.normalized().dot(to / dist)
			score = dist * (1.0 - 0.2 * max(dot, 0.0))
		if score < best_score:
			best_score = score
			best = m
	return best


func get_marker_count() -> int:
	return markers.size()
